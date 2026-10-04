#include "MapRunServerQueryEngine.h"
#include <QByteArray>
#include <QHostInfo>
#include <QAbstractSocket>
#include <QSet>

MapRunServerQueryEngine::MapRunServerQueryEngine(QObject *parent)
    : QObject(parent)
{
    struct Entry { const char *group; const char *host; quint16 port; };
    static const Entry kServers[] = {
        { "xcq-小彩旗服", "frp-ten.com", 55612 },
        { "xcq-小彩旗服", "frp-ten.com", 63527 },
        { "萌萌魔界人-六月服", "101.35.9.103", 27015 },

        { "异常芙芙-训练跑图服", "103.236.70.18", 52119 },
        { "异常芙芙-训练跑图服", "103.236.70.18", 27016 },
        { "异常芙芙-训练跑图服", "103.236.70.18", 27017 },

        { "开水-跑图服", "202.189.6.37", 32010 },
        { "开水-跑图服", "202.189.6.37", 32020 },
        { "开水-跑图服", "202.189.6.37", 32030 },
        { "开水-跑图服", "202.189.6.37", 32040 },

        { "开水-训练服", "202.189.6.37", 31010 },
        { "开水-训练服", "202.189.6.37", 31020 },
        { "开水-训练服", "202.189.6.37", 31030 },
        { "开水-训练服", "202.189.6.37", 31040 },
    };
    const int count = int(sizeof(kServers) / sizeof(kServers[0]));
    m_servers.reserve(count);
    for (int i = 0; i < count; ++i) {
        ServerState st;
        st.group = QString::fromUtf8(kServers[i].group);
        st.host = QString::fromLatin1(kServers[i].host);
        st.port = kServers[i].port;
        m_servers.append(st);
    }

    connect(&m_socket, &QUdpSocket::readyRead, this, &MapRunServerQueryEngine::onReadyRead);
    m_socket.bind();
    m_roundTimer.setSingleShot(true);
    m_roundTimer.setInterval(4000);
    connect(&m_roundTimer, &QTimer::timeout, this, &MapRunServerQueryEngine::onRoundTimeout);

    refresh();
}

QVariantList MapRunServerQueryEngine::groups() const
{
    QVariantList out;
    const QDateTime now = QDateTime::currentDateTime();
    QString currentGroup;
    QVariantList currentServers;

    auto flushGroup = [&]() {
        if (!currentServers.isEmpty()) {
            QVariantMap g;
            g["name"] = currentGroup;
            g["servers"] = currentServers;
            out.append(g);
            currentServers.clear();
        }
    };

    for (const ServerState &st : m_servers) {
        if (st.group != currentGroup) {
            flushGroup();
            currentGroup = st.group;
        }
        QVariantMap m;
        m["ip"] = st.host + ':' + QString::number(st.port);
        m["online"] = st.online;
        m["checking"] = !st.done;
        if (st.online) {
            m["name"] = st.name;
            m["map"] = st.map;
            m["players"] = st.bots > 0
                ? QStringLiteral("%1玩家/%2bot/%3").arg(qMax(0, st.players - st.bots)).arg(st.bots).arg(st.maxPlayers)
                : QString::number(st.players) + " / " + QString::number(st.maxPlayers);
        } else if (!st.done) {
            m["name"] = QStringLiteral("检测中...");
            m["map"] = QStringLiteral("--");
            m["players"] = QStringLiteral("检测中");
        } else {
            m["name"] = QStringLiteral("离线");
            m["map"] = QStringLiteral("--");
            m["players"] = QStringLiteral("--");
        }
        currentServers.append(m);
    }
    flushGroup();
    return out;
}

void MapRunServerQueryEngine::refresh()
{

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (nowMs - m_lastRefreshMs < 4000)
        return;
    m_lastRefreshMs = nowMs;

    m_roundTimer.stop();


    for (ServerState &st : m_servers) {
        bool hasLetter = false;
        for (const QChar &ch : st.host) {
            if (ch.isLetter()) {
                hasLetter = true;
                break;
            }
        }
        if (hasLetter) {
            const QHostInfo info = QHostInfo::fromName(st.host);
            const QList<QHostAddress> addrs = info.addresses();
            for (const QHostAddress &a : addrs) {
                if (a.protocol() == QAbstractSocket::IPv4Protocol) {
                    st.host = a.toString();
                    break;
                }
            }
        }
    }


    QSet<QString> seen;
    QList<ServerState> dedup;
    dedup.reserve(m_servers.size());
    for (const ServerState &st : m_servers) {
        const QString key = st.host + ':' + QString::number(st.port);
        if (seen.contains(key))
            continue;
        seen.insert(key);
        dedup.append(st);
    }
    m_servers = dedup;

    const bool firstRun = m_firstQuery;
    m_firstQuery = false;
    for (ServerState &st : m_servers) {
        st.pending = true;
        if (firstRun) {
            st.online = false;
            st.done = false;
            st.gotChallenge = false;
            st.challenge.clear();
        } else {

            st.gotChallenge = false;
            st.challenge.clear();
        }
        sendInfo(st);
    }
    m_roundTimer.start();
    if (firstRun)
        emit serversUpdated();
}

int MapRunServerQueryEngine::indexOf(const QHostAddress &addr, quint16 port) const
{
    const quint32 wantAddr = addr.toIPv4Address();
    for (int i = 0; i < m_servers.size(); ++i) {
        const ServerState &st = m_servers.at(i);
        if (st.port == port && QHostAddress(st.host).toIPv4Address() == wantAddr)
            return i;
    }
    return -1;
}

void MapRunServerQueryEngine::onReadyRead()
{
    while (m_socket.hasPendingDatagrams()) {
        QByteArray buf;
        buf.resize(int(m_socket.pendingDatagramSize()));
        QHostAddress addr;
        quint16 port = 0;
        m_socket.readDatagram(buf.data(), buf.size(), &addr, &port);
        const int idx = indexOf(addr, port);
        if (idx < 0)
            continue;
        handleDatagram(idx, buf);
    }
}

void MapRunServerQueryEngine::handleDatagram(int idx, const QByteArray &buf)
{
    if (buf.size() < 5)
        return;
    ServerState &st = m_servers[idx];
    

    const int type = uchar(buf.at(4));

    if (type == 0x41 && buf.size() >= 9) {
        st.challenge = buf.right(4);
        st.gotChallenge = true;
        sendInfo(st);
        return;
    }

    if (type != 0x49)
        return;

    int off = 5;
    QString name = readString(buf, off);
    QString map = readString(buf, off);
    readString(buf, off);
    readString(buf, off);
    off += 2;
    const int players = uchar(buf.at(off++));
    const int maxPlayers = uchar(buf.at(off++));
    const int bots = uchar(buf.at(off++));
    Q_UNUSED(bots);

    st.name = name;
    cleanup(st.name);
    st.map = map;
    st.players = players;
    st.maxPlayers = maxPlayers;
    st.bots = bots;
    st.online = true;
    st.pending = false;
    st.done = true;
    if (st.firstSeen.isNull())
        st.firstSeen = QDateTime::currentDateTime();
    emit serversUpdated();
    checkAllDone();
}

void MapRunServerQueryEngine::sendInfo(ServerState &st)
{
    QByteArray req;
    req.fill(char(0xFF), 4);
    req.append(char(0x54));
    req.append("Source Engine Query");
    req.append(char(0x00));
    if (st.gotChallenge)
        req.append(st.challenge);

    m_socket.writeDatagram(req, QHostAddress(st.host), st.port);
}

void MapRunServerQueryEngine::onRoundTimeout()
{
    for (ServerState &st : m_servers) {
        if (st.pending) {
            st.pending = false;
            st.online = false;
            st.done = true;
        }
    }
    emit serversUpdated();
}

void MapRunServerQueryEngine::checkAllDone()
{
    for (const ServerState &st : m_servers) {
        if (st.pending)
            return;
    }
    m_roundTimer.stop();
}

QString MapRunServerQueryEngine::readString(const QByteArray &data, int &off) const
{
    const int start = off;
    while (off < data.size() && data.at(off) != '\0')
        ++off;
    const QString s = QString::fromUtf8(data.constData() + start, off - start);
    ++off;
    return s;
}

void MapRunServerQueryEngine::cleanup(QString &s) const
{
    QString out;
    out.reserve(s.size());
    for (const QChar &ch : s) {
        if (ch.unicode() >= 0x20)
            out.append(ch);
    }
    s = out.trimmed();
}
