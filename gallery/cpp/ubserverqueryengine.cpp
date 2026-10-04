#include "ubserverqueryengine.h"
#include <QByteArray>
#include <QHostInfo>
#include <QAbstractSocket>
#include <QSet>

UbServerQueryEngine::UbServerQueryEngine(QObject *parent)
    : QObject(parent)
{
    struct Entry { const char *group; const char *host; quint16 port; };
    static const Entry kServers[] = {
        { "僵尸逃跑-神之可乐", "110.42.9.188", 27011 },
        { "僵尸逃跑-神之可乐", "110.42.9.188", 27021 },
        { "僵尸逃跑-神之可乐", "110.42.9.188", 27031 },
        { "僵尸逃跑-神之可乐", "110.42.9.188", 27031 },
        { "僵尸逃跑-神之可乐", "110.42.9.127", 27051 },
        { "僵尸逃跑-神之可乐", "110.42.9.127", 27061 },
        { "僵尸逃跑-神之可乐", "110.42.9.127", 27071 },
        { "僵尸逃跑-神之可乐", "110.42.9.195", 27111 },
        { "僵尸逃跑-神之可乐", "110.42.9.195", 27121 },
        { "僵尸逃跑-神之可乐", "110.42.9.195", 27131 },
        { "僵尸感染-csol生化3", "103.45.130.84", 27017 },
        { "僵尸感染-csol生化3", "110.42.9.195", 27027 },
        { "女装混战-对抗", "103.45.130.84", 27055 },
        { "女装混战-对抗", "103.45.130.84", 27065 },
        { "攀岩竞速-KZ", "103.45.130.84", 27014 },
        { "攀岩竞速-KZ", "103.45.130.84", 27024 },
        { "攀岩竞速-KZ", "103.45.130.84", 27034 },
        { "攀岩竞速-KZ", "103.45.130.84", 27044 },
        { "攀岩竞速-KZ", "103.45.130.84", 27054 },
        { "攀岩竞速-KZ", "103.45.130.84", 27064 },
        { "滑翔竞速-SURF", "103.45.130.84", 27019 },
        { "滑翔竞速-SURF", "103.45.130.84", 27029 },
        { "滑翔竞速-SURF", "103.45.130.84", 27039 },
        { "休闲大厅-挂机", "103.45.130.84", 27016 },
        { "cs僵尸逃跑-CSGO", "110.42.9.200", 27021 },
        { "cs僵尸逃跑-CSGO", "110.42.9.200", 27051 },
        { "cs僵尸逃跑-CSGO", "110.42.9.200", 27071 },
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

    connect(&m_socket, &QUdpSocket::readyRead, this, &UbServerQueryEngine::onReadyRead);
    m_socket.bind();
    m_roundTimer.setSingleShot(true);
    m_roundTimer.setInterval(4000);
    connect(&m_roundTimer, &QTimer::timeout, this, &UbServerQueryEngine::onRoundTimeout);

    refresh();
}

QVariantList UbServerQueryEngine::groups() const
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

void UbServerQueryEngine::refresh()
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

int UbServerQueryEngine::indexOf(const QHostAddress &addr, quint16 port) const
{
    const quint32 wantAddr = addr.toIPv4Address();
    for (int i = 0; i < m_servers.size(); ++i) {
        const ServerState &st = m_servers.at(i);
        if (st.port == port && QHostAddress(st.host).toIPv4Address() == wantAddr)
            return i;
    }
    return -1;
}

void UbServerQueryEngine::onReadyRead()
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

void UbServerQueryEngine::handleDatagram(int idx, const QByteArray &buf)
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

void UbServerQueryEngine::sendInfo(ServerState &st)
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

void UbServerQueryEngine::onRoundTimeout()
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

void UbServerQueryEngine::checkAllDone()
{
    for (const ServerState &st : m_servers) {
        if (st.pending)
            return;
    }
    m_roundTimer.stop();
}

QString UbServerQueryEngine::readString(const QByteArray &data, int &off) const
{
    const int start = off;
    while (off < data.size() && data.at(off) != '\0')
        ++off;
    const QString s = QString::fromUtf8(data.constData() + start, off - start);
    ++off;
    return s;
}

void UbServerQueryEngine::cleanup(QString &s) const
{
    QString out;
    out.reserve(s.size());
    for (const QChar &ch : s) {
        if (ch.unicode() >= 0x20)
            out.append(ch);
    }
    s = out.trimmed();
}
