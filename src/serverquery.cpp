#include "serverquery.h"
#include <QNetworkDatagram>
#include <QDataStream>
#include <QProcess>
#include <QSettings>
#include <QDir>
#include <QDesktopServices>
#include <QUrl>

ServerQuery::ServerQuery(QObject *parent)
    : QObject(parent)
    , m_socket(new QUdpSocket(this))
    , m_timer(new QTimer(this))
    , m_isQuerying(false)
    , m_challenge(0)
    , m_retryCount(0)
{
    m_timer->setSingleShot(true);
    m_timer->setInterval(3000);
    connect(m_socket, &QUdpSocket::readyRead, this, &ServerQuery::onReadyRead);
    connect(m_timer, &QTimer::timeout, this, &ServerQuery::onTimeout);
}

ServerQuery::~ServerQuery()
{
    reset();
}

void ServerQuery::reset()
{
    m_timer->stop();
    m_socket->abort();
    m_socket->bind(QHostAddress(QHostAddress::Any), 0);
    while (m_socket->hasPendingDatagrams()) {
        m_socket->readDatagram(nullptr, 0);
    }
    if (m_isQuerying) {
        m_isQuerying = false;
        emit queryingChanged(false);
    }
    m_challenge = 0;
    m_retryCount = 0;
}

void ServerQuery::queryServer(const QString &ip, int port)
{
    reset();

    
    QString cleanIp = ip.trimmed();
    int effectivePort = port;
    int colonIdx = cleanIp.lastIndexOf(':');
    if (colonIdx > 0) {
        QString portStr = cleanIp.mid(colonIdx + 1).trimmed();
        bool ok = false;
        int parsedPort = portStr.toInt(&ok);
        if (ok && parsedPort > 0 && parsedPort < 65536) {
            cleanIp = cleanIp.left(colonIdx).trimmed();
            effectivePort = parsedPort;
        }
    }

    m_ip = cleanIp;
    m_port = static_cast<quint16>(effectivePort);

    
    QHostAddress addrCheck(m_ip);
    if (addrCheck.isNull()) {
        QHostInfo dns = QHostInfo::fromName(m_ip);
        if (!dns.addresses().isEmpty()) {
            m_resolvedIp = dns.addresses().first();
            m_ip = m_resolvedIp.toString();
        } else {
            
            m_resolvedIp = QHostAddress();
        }
    } else {
        m_resolvedIp = addrCheck;
    }

    m_isQuerying = true;
    m_challenge = 0;
    emit queryingChanged(true);

    
    if (m_socket->state() == QUdpSocket::ConnectedState) {
        m_socket->disconnectFromHost();
    }
    if (!m_resolvedIp.isNull()) {
        m_socket->connectToHost(m_resolvedIp, m_port);
    } else {
        
        m_socket->connectToHost(m_ip, m_port);
    }

    if (m_timer->isActive()) m_timer->stop();
    m_timer->start();

    sendA2SInfoQuery();
}

void ServerQuery::queryServerWithoutReset()
{
    if (m_ip.isEmpty() || m_port == 0) {
        emit queryError("未设置服务器地址");
        return;
    }
    
    
    m_challenge = 0;
    m_isQuerying = true;
    emit queryingChanged(true);

    if (sendA2SInfoQuery()) {
        if (m_timer->isActive()) m_timer->stop();
        m_timer->start();
    } else {
        m_isQuerying = false;
        emit queryingChanged(false);
        emit queryError("发送查询包失败");
    }
}

bool ServerQuery::sendA2SInfoQuery()
{
    QByteArray packet = buildA2SInfoPacket();
    if (m_challenge != 0) {
        packet.append((char)(m_challenge & 0xFF));
        packet.append((char)((m_challenge >> 8) & 0xFF));
        packet.append((char)((m_challenge >> 16) & 0xFF));
        packet.append((char)((m_challenge >> 24) & 0xFF));
    }
    qint64 sent;
    if (!m_resolvedIp.isNull()) {
        sent = m_socket->writeDatagram(packet, m_resolvedIp, m_port);
    } else {
        
        sent = m_socket->write(packet);
    }
    if (sent > 0) {
        m_timer->start();
        return true;
    }
    emit queryError("发送查询数据包失败");
    reset();
    return false;
}

QByteArray ServerQuery::buildA2SInfoPacket()
{
    return QByteArray::fromHex(
        "FFFFFFFF54536F7572636520456E67696E6520517565727900"
    );
}

void ServerQuery::onReadyRead()
{
    while (m_socket->hasPendingDatagrams()) {
        QByteArray data;
        data.resize(m_socket->pendingDatagramSize());
        m_socket->readDatagram(data.data(), data.size());

        if (data.size() < 5) continue;

        unsigned char type = (unsigned char)data[4];

        if (type == 0x41) {
            handleChallenge(data);
            return;
        }

        if (type == 0x49) {
            ServerInfo info;
            if (parseA2SResponse(data, info)) {
                info.ip = m_ip;
                info.port = m_port;
                info.success = true;
                m_timer->stop();
                m_isQuerying = false;
                m_challenge = 0;
                emit queryingChanged(false);
                emit queryFinished(info);
                return;
            }
        }
    }
}

void ServerQuery::handleChallenge(const QByteArray &data)
{
    m_challenge = 0;
    if (data.size() >= 9) {
        m_challenge = (unsigned char)data[5] |
                     ((unsigned char)data[6] << 8) |
                     ((unsigned char)data[7] << 16) |
                     ((unsigned char)data[8] << 24);
    }
    sendA2SInfoQuery();
}

bool ServerQuery::parseA2SResponse(const QByteArray &data, ServerInfo &info)
{
    if (data.size() < 6 || (unsigned char)data[4] != 'I') return false;

    int pos = 6;

    int start = pos;
    while (pos < data.size() && data[pos] != 0) pos++;
    info.serverName = QString::fromUtf8(data.mid(start, pos - start));
    pos++;

    start = pos;
    while (pos < data.size() && data[pos] != 0) pos++;
    info.mapName = QString::fromUtf8(data.mid(start, pos - start));
    pos++;

    while (pos < data.size() && data[pos] != 0) pos++;
    pos++;

    while (pos < data.size() && data[pos] != 0) pos++;
    pos++;

    pos += 2;

    if (pos < data.size()) {
        info.players = (unsigned char)data[pos++];
    }
    if (pos < data.size()) {
        info.maxPlayers = (unsigned char)data[pos++];
    }
    if (pos < data.size()) {
        info.bots = (unsigned char)data[pos++];
    }

    return true;
}

void ServerQuery::onTimeout()
{
    if (m_retryCount < 2) {
        m_retryCount++;
        sendA2SInfoQuery();
        return;
    }
    QString err = QString("查询超时: %1:%2").arg(m_ip).arg(m_port);
    m_isQuerying = false;
    emit queryingChanged(false);
    emit queryError(err);
}

bool ServerQuery::connectToServer(const QString &ip, int port, const QString &password, int protocol)
{
    if (ip.isEmpty() || port == 0) return false;

    QString url;
    if (protocol == 1) {
        url = QString("steam://run/730//+connect %1:%2").arg(ip).arg(port);
        if (!password.isEmpty()) url += " +password " + password;
    } else {
        url = QString("steam://connect/%1:%2").arg(ip).arg(port);
        if (!password.isEmpty()) url += "/" + password;
    }

    return QDesktopServices::openUrl(QUrl(url));
}

