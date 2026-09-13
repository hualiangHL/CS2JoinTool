#include "baservertime.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

BaServerTime::BaServerTime(QObject *parent)
    : QObject(parent)
    , m_connected(false)
    , m_handshakeDone(false)
    , m_reconnectAttempt(0)
{
    m_socket = new QSslSocket(this);
    connect(m_socket, &QSslSocket::connected, this, &BaServerTime::onSocketConnected);
    connect(m_socket, &QSslSocket::disconnected, this, &BaServerTime::onSocketDisconnected);
    connect(m_socket, &QSslSocket::readyRead, this, &BaServerTime::onSocketReadyRead);
    connect(m_socket, &QSslSocket::errorOccurred, this, &BaServerTime::onSocketError);
    connect(m_socket, &QSslSocket::sslErrors, this, &BaServerTime::onSslErrors);

    m_reconnectTimer = new QTimer(this);
    m_reconnectTimer->setSingleShot(true);
    m_reconnectTimer->setInterval(8000);
    connect(m_reconnectTimer, &QTimer::timeout, this, &BaServerTime::reconnect);
}

void BaServerTime::connectWS()
{
    if (m_socket->state() != QAbstractSocket::UnconnectedState) return;
    m_handshakeDone = false;
    m_readBuffer.clear();
    m_socket->connectToHostEncrypted("www.bluearchive.top", 443);
}

void BaServerTime::disconnectWS()
{
    m_reconnectTimer->stop();
    m_socket->disconnectFromHost();
}

qint64 BaServerTime::getMapTime(const QString &ip, int port) const
{
    QString key = ip + ":" + QString::number(port);
    return m_mapTimes.value(key, 0);
}

void BaServerTime::onSocketConnected()
{
    sendHandshake();
}

void BaServerTime::onSocketDisconnected()
{
    m_connected = false;
    m_handshakeDone = false;
    if (m_reconnectAttempt < 10) {
        m_reconnectAttempt++;
        m_reconnectTimer->start();
    }
}

void BaServerTime::onSocketReadyRead()
{
    m_readBuffer.append(m_socket->readAll());
    if (!m_handshakeDone) {
        int idx = m_readBuffer.indexOf("\r\n\r\n");
        if (idx >= 0) {
            m_handshakeDone = true;
            m_connected = true;
            m_reconnectAttempt = 0;
            m_readBuffer.remove(0, idx + 4);
            qDebug() << "[BA] WebSocket handshake done, remaining buffer:" << m_readBuffer.size();
        }
    }
    if (m_handshakeDone) {
        parseFrames();
    }
}

void BaServerTime::onSocketError(QAbstractSocket::SocketError error)
{
    Q_UNUSED(error);
    qDebug() << "[BA] socket error:" << m_socket->errorString();
}

void BaServerTime::onSslErrors(const QList<QSslError> &errors)
{
    Q_UNUSED(errors);
    m_socket->ignoreSslErrors();
}

void BaServerTime::reconnect()
{
    connectWS();
}

void BaServerTime::sendHandshake()
{
    QByteArray req;
    req += "GET /websocket/ws/public/server HTTP/1.1\r\n";
    req += "Host: www.bluearchive.top\r\n";
    req += "Upgrade: websocket\r\n";
    req += "Connection: Upgrade\r\n";
    req += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n";
    req += "Sec-WebSocket-Version: 13\r\n";
    req += "\r\n";
    m_socket->write(req);
}

void BaServerTime::parseFrames()
{
    while (m_readBuffer.size() >= 2) {
        uchar b1 = (uchar)m_readBuffer[0];
        uchar b2 = (uchar)m_readBuffer[1];
        bool fin = (b1 & 0x80) != 0;
        uchar opcode = b1 & 0x0F;
        bool masked = (b2 & 0x80) != 0;
        quint64 payloadLen = b2 & 0x7F;
        int headerLen = 2;

        if (payloadLen == 126) {
            if (m_readBuffer.size() < 4) return;
            payloadLen = ((uchar)m_readBuffer[2] << 8) | (uchar)m_readBuffer[3];
            headerLen = 4;
        } else if (payloadLen == 127) {
            if (m_readBuffer.size() < 10) return;
            payloadLen = 0;
            for (int i = 0; i < 8; i++) {
                payloadLen = (payloadLen << 8) | (uchar)m_readBuffer[2 + i];
            }
            headerLen = 10;
        }

        if (masked) headerLen += 4;
        if (m_readBuffer.size() < headerLen + (int)payloadLen) return;

        QByteArray payload = m_readBuffer.mid(headerLen, (int)payloadLen);
        m_readBuffer.remove(0, headerLen + (int)payloadLen);

        if (opcode == 0x8) {
            m_socket->disconnectFromHost();
            return;
        }

        
        if (opcode == 0x1 || opcode == 0x2) {
            m_messageBuffer = payload; 
        } else if (opcode == 0x0) {
            m_messageBuffer.append(payload); 
        }

        if (fin) {
            if (opcode == 0x1 || (opcode == 0x0 && !m_messageBuffer.isEmpty())) {
                handleTextMessage(m_messageBuffer);
            }
            m_messageBuffer.clear();
        }
    }
}

void BaServerTime::handleTextMessage(const QByteArray &message)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(message, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        qDebug() << "[BA] JSON parse error:" << err.errorString() << "first 200:" << message.left(200);
        return;
    }

    QJsonObject obj = doc.object();
    int code = obj.value("code").toInt();
    if (code == 0) code = obj.value("code").toString().toInt();

    if (code == 202) {
        QJsonArray servers = obj.value("data").toArray();
        int count = 0;
        for (const QJsonValue &sv : servers) {
            if (!sv.isObject()) continue;
            QJsonObject s = sv.toObject();
            QString connectStr = s.value("connectStr").toString();
            QString dateTimeStr = s.value("dateTimeOriginal").toString();
            if (!connectStr.isEmpty() && !dateTimeStr.isEmpty()) {
                
                QString dtStr = dateTimeStr.left(23); 
                QDateTime dt = QDateTime::fromString(dtStr, "yyyy-MM-dd HH:mm:ss.zzz");
                if (dt.isValid()) {
                    m_mapTimes[connectStr] = dt.toMSecsSinceEpoch();
                    count++;
                }
            }
        }
        qDebug() << "[BA] code 202, updated" << count << "server map times, total:" << m_mapTimes.size();
        emit dataUpdated();
    }
}
