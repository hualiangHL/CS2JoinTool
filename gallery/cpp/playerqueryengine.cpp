#include "playerqueryengine.h"
#include <QDataStream>

PlayerQueryEngine::PlayerQueryEngine(QObject *parent)
    : QObject(parent)
    , m_socket(new QUdpSocket(this))
    , m_timer(new QTimer(this))
    , m_querying(false)
    , m_challenge(0)
    , m_retry(0)
{
    m_timer->setSingleShot(true);
    m_timer->setInterval(3000);
    connect(m_socket, &QUdpSocket::readyRead, this, &PlayerQueryEngine::onReadyRead);
    connect(m_timer, &QTimer::timeout, this, &PlayerQueryEngine::onTimeout);
    m_socket->bind(QHostAddress(QHostAddress::Any), 0);
}

PlayerQueryEngine::~PlayerQueryEngine()
{
    m_timer->stop();
    m_socket->abort();
}

void PlayerQueryEngine::queryPlayers(const QString &ip, int port)
{
    m_timer->stop();
    m_socket->abort();
    m_socket->bind(QHostAddress(QHostAddress::Any), 0);
    while (m_socket->hasPendingDatagrams())
        m_socket->readDatagram(nullptr, 0);

    QString cleanIp = ip.trimmed();
    int effectivePort = port;
    const int colonIdx = cleanIp.lastIndexOf(':');
    if (colonIdx > 0) {
        const QString portStr = cleanIp.mid(colonIdx + 1).trimmed();
        bool ok = false;
        const int parsedPort = portStr.toInt(&ok);
        if (ok && parsedPort > 0 && parsedPort < 65536) {
            cleanIp = cleanIp.left(colonIdx).trimmed();
            effectivePort = parsedPort;
        }
    }

    m_ip = cleanIp;
    m_port = static_cast<quint16>(effectivePort);

    const QHostAddress addrCheck(m_ip);
    if (addrCheck.isNull()) {
        const QHostInfo dns = QHostInfo::fromName(m_ip);
        if (!dns.addresses().isEmpty())
            m_resolvedIp = dns.addresses().first();
        else
            m_resolvedIp = QHostAddress();
    } else {
        m_resolvedIp = addrCheck;
    }

    m_querying = true;
    m_challenge = 0;
    m_retry = 0;
    m_players.clear();
    emit queryingChanged(true);
    emit playersChanged();

    if (!m_resolvedIp.isNull())
        m_socket->connectToHost(m_resolvedIp, m_port);
    else
        m_socket->connectToHost(m_ip, m_port);

    m_timer->start();
    sendPlayerQuery();
}

bool PlayerQueryEngine::sendPlayerQuery()
{
    QByteArray packet;
    packet.append(char(0xFF));
    packet.append(char(0xFF));
    packet.append(char(0xFF));
    packet.append(char(0xFF));
    packet.append(char(0x55));
    if (m_challenge != 0) {
        packet.append(char(m_challenge & 0xFF));
        packet.append(char((m_challenge >> 8) & 0xFF));
        packet.append(char((m_challenge >> 16) & 0xFF));
        packet.append(char((m_challenge >> 24) & 0xFF));
    } else {
        packet.append(char(0xFF));
        packet.append(char(0xFF));
        packet.append(char(0xFF));
        packet.append(char(0xFF));
    }

    qint64 sent = 0;
    if (!m_resolvedIp.isNull())
        sent = m_socket->writeDatagram(packet, m_resolvedIp, m_port);
    else
        sent = m_socket->write(packet);
    return sent > 0;
}

void PlayerQueryEngine::onReadyRead()
{
    while (m_socket->hasPendingDatagrams()) {
        QByteArray data;
        data.resize(int(m_socket->pendingDatagramSize()));
        m_socket->readDatagram(data.data(), data.size());

        if (data.size() < 5)
            continue;

        const unsigned char type = static_cast<unsigned char>(data.at(4));

        if (type == 0x41) {
            handleChallenge(data);
            continue;
        }

        if (type == 0x44) {
            QVariantList players;
            if (parsePlayerResponse(data, players)) {
                m_players = players;
                m_timer->stop();
                m_querying = false;
                emit queryingChanged(false);
                emit playersChanged();
            }
        }
    }
}

void PlayerQueryEngine::handleChallenge(const QByteArray &data)
{
    m_challenge = 0;
    if (data.size() >= 9) {
        m_challenge = static_cast<unsigned char>(data.at(5)) |
                      (static_cast<unsigned char>(data.at(6)) << 8) |
                      (static_cast<unsigned char>(data.at(7)) << 16) |
                      (static_cast<unsigned char>(data.at(8)) << 24);
    }
    sendPlayerQuery();
}

bool PlayerQueryEngine::parsePlayerResponse(const QByteArray &data, QVariantList &players)
{
    if (data.size() < 6 || static_cast<unsigned char>(data.at(4)) != 0x44)
        return false;

    int pos = 5;
    if (pos >= data.size())
        return false;
    const int count = static_cast<unsigned char>(data.at(pos++));

    for (int i = 0; i < count; ++i) {
        if (pos >= data.size())
            break;
        const int index = static_cast<unsigned char>(data.at(pos++));

        const int start = pos;
        while (pos < data.size() && data.at(pos) != 0)
            ++pos;
        QString name = QString::fromUtf8(data.mid(start, pos - start));
        ++pos;

        if (pos + 8 > data.size())
            break;

        QDataStream ds(data.mid(pos, 4));
        ds.setByteOrder(QDataStream::LittleEndian);
        qint32 score = 0;
        ds >> score;
        pos += 4;

        QDataStream ds2(data.mid(pos, 4));
        ds2.setByteOrder(QDataStream::LittleEndian);
        float duration = 0.0f;
        ds2 >> duration;
        pos += 4;

        QVariantMap map;
        map["name"] = name;
        map["score"] = score;
        map["duration"] = duration;
        map["index"] = index;
        players.append(map);
    }

    return true;
}

void PlayerQueryEngine::onTimeout()
{
    if (m_retry < 2) {
        m_retry++;
        sendPlayerQuery();
        m_timer->start();
        return;
    }
    m_querying = false;
    emit queryingChanged(false);
    emit queryError(QStringLiteral("查询超时: %1:%2").arg(m_ip).arg(m_port));
}
