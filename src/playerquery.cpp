#include "playerquery.h"
#include <QDataStream>

PlayerQuery::PlayerQuery(QObject *parent)
    : QObject(parent)
    , m_socket(new QUdpSocket(this))
    , m_timer(new QTimer(this))
    , m_querying(false)
    , m_challenge(0)
    , m_retry(0)
{
    m_timer->setSingleShot(true);
    m_timer->setInterval(3000);
    connect(m_socket, &QUdpSocket::readyRead, this, &PlayerQuery::onReadyRead);
    connect(m_timer, &QTimer::timeout, this, &PlayerQuery::onTimeout);
    m_socket->bind(QHostAddress(QHostAddress::Any), 0);
}

PlayerQuery::~PlayerQuery()
{
    m_timer->stop();
    m_socket->abort();
}

void PlayerQuery::queryPlayers(const QString &ip, int port)
{
    m_timer->stop();
    m_socket->abort();
    m_socket->bind(QHostAddress(QHostAddress::Any), 0);
    while (m_socket->hasPendingDatagrams()) m_socket->readDatagram(nullptr, 0);

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
        } else {
            m_resolvedIp = QHostAddress();
        }
    } else {
        m_resolvedIp = addrCheck;
    }

    m_querying = true;
    m_challenge = 0;
    m_retry = 0;
    m_players.clear();
    emit queryingChanged(true);
    emit playersChanged();

    if (!m_resolvedIp.isNull()) {
        m_socket->connectToHost(m_resolvedIp, m_port);
    } else {
        m_socket->connectToHost(m_ip, m_port);
    }

    m_timer->start();
    sendPlayerQuery();
}

bool PlayerQuery::sendPlayerQuery()
{
    QByteArray packet;
    packet.append((char)0xFF);
    packet.append((char)0xFF);
    packet.append((char)0xFF);
    packet.append((char)0xFF);
    packet.append((char)0x55); 
    if (m_challenge != 0) {
        packet.append((char)(m_challenge & 0xFF));
        packet.append((char)((m_challenge >> 8) & 0xFF));
        packet.append((char)((m_challenge >> 16) & 0xFF));
        packet.append((char)((m_challenge >> 24) & 0xFF));
    } else {
        packet.append((char)0xFF);
        packet.append((char)0xFF);
        packet.append((char)0xFF);
        packet.append((char)0xFF);
    }

    qint64 sent;
    if (!m_resolvedIp.isNull()) {
        sent = m_socket->writeDatagram(packet, m_resolvedIp, m_port);
    } else {
        sent = m_socket->write(packet);
    }
    return sent > 0;
}

void PlayerQuery::onReadyRead()
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

        if (type == 0x44) {
            QVariantList players;
            if (parsePlayerResponse(data, players)) {
                m_players = players;
                m_timer->stop();
                m_querying = false;
                emit queryingChanged(false);
                emit playersChanged();
                emit queryFinished(players);
                return;
            }
        }
    }
}

void PlayerQuery::handleChallenge(const QByteArray &data)
{
    m_challenge = 0;
    if (data.size() >= 9) {
        m_challenge = (unsigned char)data[5] |
                     ((unsigned char)data[6] << 8) |
                     ((unsigned char)data[7] << 16) |
                     ((unsigned char)data[8] << 24);
    }
    sendPlayerQuery();
}

bool PlayerQuery::parsePlayerResponse(const QByteArray &data, QVariantList &players)
{
    if (data.size() < 6 || (unsigned char)data[4] != 0x44) return false;

    int pos = 5;
    if (pos >= data.size()) return false;
    int count = (unsigned char)data[pos++];

    for (int i = 0; i < count; i++) {
        if (pos >= data.size()) break;
        PlayerInfo p;
        p.index = (unsigned char)data[pos++];

        int start = pos;
        while (pos < data.size() && data[pos] != 0) pos++;
        p.name = QString::fromUtf8(data.mid(start, pos - start));
        pos++;

        if (pos + 8 > data.size()) break;
        QDataStream ds(data.mid(pos, 4));
        ds.setByteOrder(QDataStream::LittleEndian);
        ds >> p.score;
        pos += 4;

        QDataStream ds2(data.mid(pos, 4));
        ds2.setByteOrder(QDataStream::LittleEndian);
        ds2 >> p.duration;
        pos += 4;

        QVariantMap map;
        map["name"] = p.name;
        map["score"] = p.score;
        map["duration"] = p.duration;
        map["index"] = p.index;
        players.append(map);
    }

    return true;
}

void PlayerQuery::onTimeout()
{
    if (m_retry < 2) {
        m_retry++;
        sendPlayerQuery();
        m_timer->start();
        return;
    }
    m_querying = false;
    emit queryingChanged(false);
    emit queryError(QString("查询超时: %1:%2").arg(m_ip).arg(m_port));
}

