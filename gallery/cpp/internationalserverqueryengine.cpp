#include "InternationalServerQueryEngine.h"
#include <QByteArray>
#include <QHostInfo>
#include <QAbstractSocket>
#include <QSet>

InternationalServerQueryEngine::InternationalServerQueryEngine(QObject *parent)
    : QObject(parent)
{
    struct Entry { const char *group; const char *host; quint16 port; };
    static const Entry kServers[] = {
        { "僵尸逃跑-国际", "74.91.124.21", 27015 },
        { "僵尸逃跑-国际", "87.98.228.196", 27040 },
        { "僵尸逃跑-国际", "103.62.49.55", 27015 },
        { "僵尸逃跑-国际", "14.6.92.207", 27015 },
        { "僵尸逃跑-国际", "rsscs2.kr", 27015 },
        { "僵尸逃跑-国际", "82.67.2.121", 27016 },
        { "僵尸逃跑-国际", "51.254.196.177", 27018 },
        { "僵尸逃跑-国际", "5.132.51.231", 27019 },
        { "僵尸逃跑-国际", "91.211.247.247", 27025 },
        { "僵尸逃跑-国际", "23.175.40.14", 27027 },
        { "僵尸逃跑-国际", "176.241.136.107", 27015 },
        { "僵尸逃跑-国际", "114.33.16.105", 27015 },
        { "僵尸逃跑-国际", "170.246.146.226", 27017 },
        { "僵尸逃跑-国际", "194.54.88.16", 27152 },
        { "cs起源-Zombie Escape", "46.105.73.18", 27015 },
        { "cs起源-Zombie Escape", "51.195.188.106", 27015 },
        { "cs起源-Zombie Escape", "51.195.188.106", 27035 },
        { "cs起源-Zombie Escape", "95.143.191.61", 27015 },
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

    connect(&m_socket, &QUdpSocket::readyRead, this, &InternationalServerQueryEngine::onReadyRead);
    m_socket.bind();
    m_roundTimer.setSingleShot(true);
    m_roundTimer.setInterval(4000);
    connect(&m_roundTimer, &QTimer::timeout, this, &InternationalServerQueryEngine::onRoundTimeout);

    refresh();
}

QVariantList InternationalServerQueryEngine::groups() const
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

void InternationalServerQueryEngine::refresh()
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

int InternationalServerQueryEngine::indexOf(const QHostAddress &addr, quint16 port) const
{
    const quint32 wantAddr = addr.toIPv4Address();
    for (int i = 0; i < m_servers.size(); ++i) {
        const ServerState &st = m_servers.at(i);
        if (st.port == port && QHostAddress(st.host).toIPv4Address() == wantAddr)
            return i;
    }
    return -1;
}

void InternationalServerQueryEngine::onReadyRead()
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

void InternationalServerQueryEngine::handleDatagram(int idx, const QByteArray &buf)
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

void InternationalServerQueryEngine::sendInfo(ServerState &st)
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

void InternationalServerQueryEngine::onRoundTimeout()
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

void InternationalServerQueryEngine::checkAllDone()
{
    for (const ServerState &st : m_servers) {
        if (st.pending)
            return;
    }
    m_roundTimer.stop();
}

QString InternationalServerQueryEngine::readString(const QByteArray &data, int &off) const
{
    const int start = off;
    while (off < data.size() && data.at(off) != '\0')
        ++off;
    const QString s = QString::fromUtf8(data.constData() + start, off - start);
    ++off;
    return s;
}

void InternationalServerQueryEngine::cleanup(QString &s) const
{
    QString out;
    out.reserve(s.size());
    for (const QChar &ch : s) {
        if (ch.unicode() >= 0x20)
            out.append(ch);
    }
    s = out.trimmed();
}
