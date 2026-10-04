#include "serverqueryengine.h"
#include <QByteArray>

ServerQueryEngine::ServerQueryEngine(QObject *parent)
    : QObject(parent)
{
    struct Entry { const char *group; const char *host; quint16 port; };
    static const Entry kServers[] = {
        { "挂机大厅", "202.189.10.19", 27001 },
        { "挂机大厅", "202.189.10.19", 27002 },
        { "挂机大厅", "202.189.10.19", 27003 },
        { "僵尸逃跑-装备", "202.189.4.212", 27001 },
        { "僵尸逃跑-装备", "202.189.4.212", 27002 },
        { "僵尸逃跑-装备", "202.189.4.124", 27001 },
        { "僵尸逃跑-装备", "202.189.4.124", 27002 },
        { "僵尸逃跑-装备", "202.189.10.196", 27001 },
        { "僵尸逃跑-装备", "202.189.10.196", 27002 },
        { "僵尸逃跑-装备", "202.189.5.221", 27001 },
        { "僵尸逃跑-装备", "202.189.10.203", 27001 },
        { "僵尸逃跑-装备", "202.189.10.208", 27001 },
        { "僵尸逃跑-装备", "202.189.10.208", 27002 },
        { "僵尸逃跑-装备", "202.189.5.225", 27001 },
        { "僵尸逃跑-装备", "202.189.5.225", 27002 },
        { "僵尸逃跑-装备", "202.189.5.227", 27001 },
        { "僵尸逃跑-装备", "202.189.5.227", 27002 },
        { "僵尸逃跑-装备", "202.189.5.236", 27001 },
        { "僵尸逃跑-装备", "202.189.5.236", 27002 },
        { "僵尸逃跑-装备", "202.189.4.110", 27001 },
        { "僵尸逃跑-装备", "202.189.4.110", 27002 },
        { "僵尸逃跑-普通", "202.189.4.230", 27001 },
        { "僵尸逃跑-普通", "202.189.4.230", 27002 },
        { "僵尸逃跑-普通", "202.189.10.85", 27001 },
        { "僵尸逃跑-PVE", "202.189.5.229", 27001 },
        { "僵尸逃跑-PVE", "202.189.5.229", 27002 },
        { "僵尸逃跑-PVE", "202.189.5.229", 27003 },
        { "僵尸逃跑-PVE", "202.189.5.229", 27004 },
        { "僵尸逃跑-PVE", "103.45.134.202", 27005 },
        { "僵尸逃跑-活动专用", "202.189.5.221", 27008 },
        { "僵尸逃跑-活动专用", "202.189.5.212", 27008 },
        { "躲猫猫-娱乐", "202.189.10.184", 27001 },
        { "躲猫猫-娱乐", "202.189.10.184", 27002 },
        { "娱乐闯关-MG", "202.189.5.232", 27001 },
        { "娱乐闯关-MG", "202.189.5.232", 27002 },
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

    connect(&m_socket, &QUdpSocket::readyRead, this, &ServerQueryEngine::onReadyRead);
    m_socket.bind();
    m_roundTimer.setSingleShot(true);
    m_roundTimer.setInterval(4000);
    connect(&m_roundTimer, &QTimer::timeout, this, &ServerQueryEngine::onRoundTimeout);

    m_batchTimer.setSingleShot(true);
    m_batchTimer.setInterval(200);
    connect(&m_batchTimer, &QTimer::timeout, this, &ServerQueryEngine::onBatchEmit);

    refresh();
}

QVariantList ServerQueryEngine::groups() const
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
            m["uptime"] = uptimeText(st.firstSeen.secsTo(now));
            m["uptimeSec"] = static_cast<qint64>(st.firstSeen.toMSecsSinceEpoch() / 1000);
        } else if (!st.done) {
            m["name"] = QStringLiteral("检测中...");
            m["map"] = QStringLiteral("--");
            m["players"] = QStringLiteral("检测中");
            m["uptime"] = QStringLiteral("--");
            m["uptimeSec"] = 0;
        } else {
            m["name"] = QStringLiteral("离线");
            m["map"] = QStringLiteral("--");
            m["players"] = QStringLiteral("--");
            m["uptime"] = QStringLiteral("--");
            m["uptimeSec"] = 0;
        }
        currentServers.append(m);
    }
    flushGroup();
    return out;
}

void ServerQueryEngine::refresh()
{

    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    if (nowMs - m_lastRefreshMs < 4000)
        return;
    m_lastRefreshMs = nowMs;

    m_roundTimer.stop();
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

void ServerQueryEngine::addServer(const QString &hostPort)
{
    const QStringList hp = hostPort.trimmed().split(':');
    if (hp.size() != 2)
        return;
    bool ok = false;
    const quint16 port = hp.at(1).toUShort(&ok);
    const QString host = hp.at(0).trimmed();
    if (!ok || host.isEmpty())
        return;

    for (const ServerState &st : m_servers) {
        if (st.host == host && st.port == port)
            return;
    }

    ServerState st;
    st.group = QStringLiteral("自定义");
    st.host = host;
    st.port = port;
    m_servers.append(st);
    refresh();
}

int ServerQueryEngine::indexOf(const QHostAddress &addr, quint16 port) const
{
    const quint32 wantAddr = addr.toIPv4Address();
    for (int i = 0; i < m_servers.size(); ++i) {
        const ServerState &st = m_servers.at(i);
        if (st.port == port && QHostAddress(st.host).toIPv4Address() == wantAddr)
            return i;
    }
    return -1;
}

void ServerQueryEngine::onReadyRead()
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

void ServerQueryEngine::onBatchEmit()
{
    m_batchTimer.stop();
    emit serversUpdated();
}

void ServerQueryEngine::handleDatagram(int idx, const QByteArray &buf)
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
    m_batchTimer.start();
    checkAllDone();
}

void ServerQueryEngine::sendInfo(ServerState &st)
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

void ServerQueryEngine::onRoundTimeout()
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

void ServerQueryEngine::checkAllDone()
{
    for (const ServerState &st : m_servers) {
        if (st.pending)
            return;
    }
    m_roundTimer.stop();
}

QString ServerQueryEngine::readString(const QByteArray &data, int &off) const
{
    const int start = off;
    while (off < data.size() && data.at(off) != '\0')
        ++off;
    const QString s = QString::fromUtf8(data.constData() + start, off - start);
    ++off;
    return s;
}

void ServerQueryEngine::cleanup(QString &s) const
{
    QString out;
    out.reserve(s.size());
    for (const QChar &ch : s) {
        if (ch.unicode() >= 0x20)
            out.append(ch);
    }
    s = out.trimmed();
}

QString ServerQueryEngine::uptimeText(qint64 secs) const
{
    if (secs < 0)
        secs = 0;
    if (secs < 60)
        return QString::number(secs) + QStringLiteral("s");
    if (secs < 3600)
        return QString::number(secs / 60) + QStringLiteral("min");
    if (secs < 86400)
        return QString::number(secs / 3600) + QStringLiteral("h ") +
               QString::number((secs % 3600) / 60) + QStringLiteral("min");
    return QString::number(secs / 86400) + QStringLiteral("d ") +
           QString::number((secs % 86400) / 3600) + QStringLiteral("h");
}
