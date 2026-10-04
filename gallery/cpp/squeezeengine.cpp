#include "squeezeengine.h"
#include "langmanager.h"
#include <QDesktopServices>
#include <QUrl>
#include <QDateTime>
#include <QThread>

bool SqueezeEngine::isEn() const
{
    return m_lang && m_lang->isEn();
}

SqueezeEngine::SqueezeEngine(QObject *parent)
    : QObject(parent)
{
    m_maxCores = qMax(1, QThread::idealThreadCount());
    m_coreCount = qBound(1, m_coreCount, m_maxCores);

    connect(&m_socket, &QUdpSocket::readyRead, this, &SqueezeEngine::onReadyRead);
    m_socket.bind();

    m_timer.setInterval(100);
    connect(&m_timer, &QTimer::timeout, this, &SqueezeEngine::queryOnce);

    m_queryTimer.setSingleShot(true);
    m_queryTimer.setInterval(1200);
    connect(&m_queryTimer, &QTimer::timeout, this, &SqueezeEngine::onQueryTimeout);
}

void SqueezeEngine::setCoreCount(int v)
{
    const int clamped = qBound(1, v, m_maxCores);
    if (m_coreCount == clamped)
        return;
    m_coreCount = clamped;
    emit coreCountChanged();
}

void SqueezeEngine::setIntervalMs(int v)
{


    const int clamped = qBound(0, v, 500);
    if (m_interval == clamped)
        return;
    m_interval = clamped;
    emit intervalMsChanged();
}

void SqueezeEngine::setThreshold(int v)
{
    const int clamped = qBound(20, v, 63);
    if (m_threshold == clamped)
        return;
    m_threshold = clamped;
    emit thresholdChanged();
}

void SqueezeEngine::start(const QString &ip, int port, const QString &name)
{
    if (ip.isEmpty() || port <= 0)
        return;
    if (m_running)
        return;

    m_ip = ip;
    m_port = quint16(port);
    m_serverName = name;
    m_retry = 0;
    m_players = 0;
    m_maxPlayers = 0;
    m_map.clear();
    m_gotChallenge = false;
    m_challenge.clear();
    m_waiting = false;
    m_addr = QHostAddress(ip);

    m_running = true;
    emit runningChanged();
    emit retryCountChanged();
    emit stateChanged();

    if (isEn())
        appendLog(QString("Start squeeze %1:%2[%3ms interval %4 cores %5 threshold]").arg(m_ip).arg(m_port).arg(m_interval).arg(m_coreCount).arg(m_threshold));
    else
        appendLog(QString("开始挤服%1:%2[%3间隔 %4核心 %5阈值]").arg(m_ip).arg(m_port).arg(m_interval).arg(m_coreCount).arg(m_threshold));
    setStatus(isEn() ? QStringLiteral("Querying server...") : QStringLiteral("正在查询服务器..."));

    m_timer.setInterval(qMax(20, m_interval));
    m_timer.start();
    queryOnce();
}

void SqueezeEngine::probe(const QString &ip, int port, const QString &name)
{
    if (m_running)
        return;
    if (ip.isEmpty() || port <= 0)
        return;

    m_ip = ip;
    m_port = quint16(port);
    m_serverName = name;
    m_retry = 0;
    m_players = 0;
    m_maxPlayers = 0;
    m_map.clear();
    m_gotChallenge = false;
    m_challenge.clear();
    m_waiting = false;
    m_addr = QHostAddress(ip);
    m_probe = true;
    emit stateChanged();

    setStatus(isEn() ? QStringLiteral("Querying server...") : QStringLiteral("正在查询服务器..."));
    m_waiting = true;
    m_queryTimer.start();
    sendQuery();
}

void SqueezeEngine::stop(bool manual)
{
    if (!m_running)
        return;
    m_running = false;
    m_timer.stop();
    m_queryTimer.stop();
    m_waiting = false;
    emit runningChanged();
    setStatus(isEn() ? QStringLiteral("Stopped") : QStringLiteral("已停止"));

    if (manual)
        appendLog(isEn() ? QStringLiteral("Squeeze stopped") : QStringLiteral("挤服已停止"));
}

void SqueezeEngine::setProtocol(int v)
{
    if (m_protocol == v)
        return;
    m_protocol = v;
    emit protocolChanged();
}

void SqueezeEngine::joinNow()
{
    if (m_ip.isEmpty() || m_port == 0)
        return;
    QString url;
    if (m_protocol == 1)
        url = QString("steam://run/730//+connect %1:%2").arg(m_ip).arg(m_port);
    else
        url = QString("steam://connect/%1:%2").arg(m_ip).arg(m_port);
    const bool ok = QDesktopServices::openUrl(QUrl(url));
    if (isEn())
        appendLog(ok ? QStringLiteral("Connecting... [If you don't get in, someone else was faster]")
                     : QStringLiteral("Cannot open Steam connect (please make sure Steam is installed)"));
    else
        appendLog(ok ? QStringLiteral("正在连接中...[如果你没有进去 说明别人网速比你快]")
                     : QStringLiteral("无法打开 Steam 连接（请确认已安装 Steam）"));
    if (ok) {
        setStatus(isEn() ? QStringLiteral("Connection request sent, entering server...") : QStringLiteral("已发送连接请求，正在进入服务器..."));
        emit connectSent();
    }
}

void SqueezeEngine::appendLog(const QString &msg)
{
    const QString line = QString("[%1] %2").arg(QDateTime::currentDateTime().toString("HH:mm:ss"), msg);
    m_log += line + "\n";
    if (m_log.size() > 6000)
        m_log = m_log.right(4800);
    emit logTextChanged();
}

void SqueezeEngine::setStatus(const QString &s)
{
    if (m_status == s)
        return;
    m_status = s;
    emit statusTextChanged();
}

void SqueezeEngine::queryOnce()
{
    if (!m_running)
        return;



    m_queryTimer.start();
    const int cores = qMax(1, m_coreCount);
    for (int i = 0; i < cores; ++i) {
        sendQuery();
    }
}

void SqueezeEngine::sendQuery()
{
    QByteArray req;
    req.fill(char(0xFF), 4);
    req.append(char(0x54));
    req.append("Source Engine Query");
    req.append(char(0x00));
    if (m_gotChallenge)
        req.append(m_challenge);
    m_socket.writeDatagram(req, m_addr, m_port);
}

void SqueezeEngine::onReadyRead()
{
    while (m_socket.hasPendingDatagrams()) {
        QByteArray buf;
        buf.resize(int(m_socket.pendingDatagramSize()));
        QHostAddress addr;
        quint16 port = 0;
        m_socket.readDatagram(buf.data(), buf.size(), &addr, &port);

        if (!m_running && !m_probe)
            continue;
        if (port != m_port)
            continue;
        if (!m_addr.isNull() && addr.toIPv4Address() != m_addr.toIPv4Address())
            continue;
        if (buf.size() < 5)
            continue;

        const int type = uchar(buf.at(4));

        if (type == 0x41 && buf.size() >= 9) {


            m_challenge = buf.right(4);
            m_gotChallenge = true;

            if (++m_challengeOnly >= 30) {
                m_challengeOnly = 0;
                m_retry++;
                emit retryCountChanged();
                setStatus(isEn() ? QStringLiteral("Server response abnormal, re-querying...") : QStringLiteral("服务器响应异常，重新建立查询..."));
            }
            sendQuery();

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

        cleanup(name);
        m_serverName = name;
        m_map = map;
        m_players = players;
        m_maxPlayers = maxPlayers;
        m_waiting = false;
        m_challengeOnly = 0;
        m_queryTimer.stop();
        emit stateChanged();


        if (m_probe) {
            m_probe = false;
            setStatus(QString("人数 %1/%2").arg(players).arg(maxPlayers));
            return;
        }

        const int human = players - bots;
        const bool hasSlot = (players < maxPlayers) && (human <= m_threshold);
        if (hasSlot) {
            if (isEn()) {
                const QString slotMsg = QString("Free Slot found! %1/%2 players, %3ms interval, %4 cores, %5 threshold. Connecting...")
                        .arg(players).arg(maxPlayers).arg(m_interval).arg(m_coreCount).arg(m_threshold);
                setStatus(slotMsg);
                appendLog(slotMsg);
            } else {
                const QString slotMsg = QString("发现空位！%1/%2人数 %3间隔 %4核心 %5阈值，正在连接...")
                        .arg(players).arg(maxPlayers).arg(m_interval).arg(m_coreCount).arg(m_threshold);
                setStatus(slotMsg);
                appendLog(slotMsg);
            }
            joinNow();
            stop(false);
        } else {
            m_retry++;
            emit retryCountChanged();
            if (isEn())
                setStatus(QString("Players %1/%2 (real %3) threshold %4, waiting...")
                              .arg(players).arg(maxPlayers).arg(human).arg(m_threshold));
            else
                setStatus(QString("人数 %1/%2（真人 %3）阈值 %4，等待中...")
                              .arg(players).arg(maxPlayers).arg(human).arg(m_threshold));
        }
    }
}

void SqueezeEngine::onQueryTimeout()
{
    if (!m_running && !m_probe)
        return;
    m_waiting = false;
    m_challengeOnly = 0;
    if (m_probe) {
        m_probe = false;
        setStatus(isEn() ? QStringLiteral("No response / offline") : QStringLiteral("无响应/离线"));
        return;
    }
    m_retry++;
    emit retryCountChanged();
    setStatus(isEn() ? QStringLiteral("No response / offline, keep trying...") : QStringLiteral("无响应/离线，继续尝试..."));
}

QString SqueezeEngine::readString(const QByteArray &data, int &off) const
{
    const int start = off;
    while (off < data.size() && data.at(off) != '\0')
        ++off;
    const QString s = QString::fromUtf8(data.constData() + start, off - start);
    ++off;
    return s;
}

void SqueezeEngine::cleanup(QString &s) const
{
    QString out;
    out.reserve(s.size());
    for (const QChar &ch : s) {
        if (ch.unicode() >= 0x20)
            out.append(ch);
    }
    s = out.trimmed();
}
