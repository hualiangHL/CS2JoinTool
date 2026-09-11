#include "ubservermanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QRandomGenerator>
#include <QCryptographicHash>

UBServerManager::UBServerManager(QObject *parent)
    : QObject(parent)
    , m_socket(new QSslSocket(this))
    , m_onlineUsers(0)
    , m_connected(false)
    , m_handshakeDone(false)
    , m_reconnectTimer(new QTimer(this))
    , m_pingTimer(new QTimer(this))
    , m_reconnectAttempt(0)
{
    connect(m_socket, &QSslSocket::connected, this, &UBServerManager::onSocketConnected);
    connect(m_socket, &QSslSocket::disconnected, this, &UBServerManager::onSocketDisconnected);
    connect(m_socket, &QSslSocket::readyRead, this, &UBServerManager::onSocketReadyRead);
    connect(m_socket, &QSslSocket::errorOccurred, this, &UBServerManager::onSocketError);
    connect(m_socket, &QSslSocket::sslErrors, this, &UBServerManager::onSslErrors);

    m_reconnectTimer->setSingleShot(true);
    connect(m_reconnectTimer, &QTimer::timeout, this, &UBServerManager::reconnect);

    m_pingTimer->setInterval(25000);
    connect(m_pingTimer, &QTimer::timeout, this, &UBServerManager::sendPing);

    
    QTimer::singleShot(1000, this, &UBServerManager::connectWS);
}

void UBServerManager::connectWS()
{
    if (m_connected) return;
    qDebug() << "[UB] Connecting to wss://ws.moeub.cn/ws?files=0&appid=730";
    m_handshakeDone = false;
    m_readBuffer.clear();
    m_socket->connectToHostEncrypted("ws.moeub.cn", 443);
}

void UBServerManager::disconnectWS()
{
    m_reconnectTimer->stop();
    m_pingTimer->stop();
    m_socket->close();
}

void UBServerManager::refresh()
{
    m_serverMap.clear();
    m_servers.clear();
    emit serversChanged();
    emit totalPlayersChanged();
    if (m_connected) {
        m_socket->close();
    } else {
        connectWS();
    }
}

QVariantMap UBServerManager::findServer(const QString &host, int port)
{
    qDebug() << "[UB] findServer searching for" << host << ":" << port << ", total servers:" << m_serverMap.size();
    for (auto it = m_serverMap.begin(); it != m_serverMap.end(); ++it) {
        QString srvHost = it.value().value("host").toString();
        int srvPort = it.value().value("port").toInt();
        int clientsCount = it.value().value("clients").toList().size();
        qDebug() << "[UB]   candidate:" << srvHost << ":" << srvPort << "clients=" << clientsCount << "name=" << it.value().value("name").toString().left(30);
        if (srvHost == host && srvPort == port) {
            qDebug() << "[UB]   MATCHED! clients=" << clientsCount;
            return it.value();
        }
    }
    qDebug() << "[UB]   NO MATCH";
    return QVariantMap();
}

void UBServerManager::onSocketConnected()
{
    qDebug() << "[UB] TCP connected, sending handshake";
    sendHandshake();
}

void UBServerManager::sendHandshake()
{
    QByteArray key = "dGhlIHNhbXBsZSBub25jZQ==";
    QByteArray request;
    request += "GET /ws?files=0&appid=730 HTTP/1.1\r\n";
    request += "Host: ws.moeub.cn\r\n";
    request += "Upgrade: websocket\r\n";
    request += "Connection: Upgrade\r\n";
    request += "Sec-WebSocket-Key: " + key + "\r\n";
    request += "Sec-WebSocket-Version: 13\r\n";
    request += "Origin: https://cs.moeub.cn\r\n";
    request += "User-Agent: Mozilla/5.0\r\n";
    request += "\r\n";
    m_socket->write(request);
}

void UBServerManager::onSocketDisconnected()
{
    qDebug() << "[UB] Socket disconnected";
    m_connected = false;
    m_handshakeDone = false;
    m_pingTimer->stop();
    emit connectedChanged();
    m_reconnectAttempt++;
    int delay = (int)qMin(30000.0, 1000.0 * qPow(2, qMin(m_reconnectAttempt, 5)));
    m_reconnectTimer->start(delay);
}

void UBServerManager::onSocketError(QAbstractSocket::SocketError error)
{
    qDebug() << "[UB] Socket error:" << error << m_socket->errorString();
}

void UBServerManager::onSslErrors(const QList<QSslError> &errors)
{
    Q_UNUSED(errors);
    m_socket->ignoreSslErrors();
}

void UBServerManager::reconnect()
{
    if (!m_connected) {
        connectWS();
    }
}

void UBServerManager::onSocketReadyRead()
{
    QByteArray newData = m_socket->readAll();
    qDebug() << "[UB] onReadyRead, bytes:" << newData.size() << "total buffer:" << m_readBuffer.size();
    m_readBuffer += newData;

    if (!m_handshakeDone) {
        int headerEnd = m_readBuffer.indexOf("\r\n\r\n");
        if (headerEnd == -1) {
            qDebug() << "[UB] handshake header not complete yet, buffer size:" << m_readBuffer.size();
            return;
        }
        QByteArray header = m_readBuffer.left(headerEnd);
        qDebug() << "[UB] handshake response:" << header.left(200);
        if (header.contains("101") || header.contains("Switching Protocols")) {
            qDebug() << "[UB] WebSocket handshake done";
            m_handshakeDone = true;
            m_connected = true;
            emit connectedChanged();
            m_pingTimer->start();
            m_readBuffer = m_readBuffer.mid(headerEnd + 4);
            qDebug() << "[UB] remaining data after handshake:" << m_readBuffer.size();
        } else {
            qDebug() << "[UB] Handshake failed:" << header.left(200);
            m_socket->close();
            return;
        }
    }

    parseFrames();
}

void UBServerManager::parseFrames()
{
    qDebug() << "[UB] parseFrames, buffer size:" << m_readBuffer.size();
    while (m_readBuffer.size() >= 2) {
        uchar b0 = (uchar)m_readBuffer[0];
        uchar b1 = (uchar)m_readBuffer[1];
        bool fin = (b0 & 0x80) != 0;
        uchar opcode = b0 & 0x0F;
        bool masked = (b1 & 0x80) != 0;
        quint64 payloadLen = b1 & 0x7F;
        int headerLen = 2;

        if (payloadLen == 126) {
            if (m_readBuffer.size() < 4) { qDebug() << "[UB] need more data for 126 len"; return; }
            payloadLen = ((uchar)m_readBuffer[2] << 8) | (uchar)m_readBuffer[3];
            headerLen = 4;
        } else if (payloadLen == 127) {
            if (m_readBuffer.size() < 10) { qDebug() << "[UB] need more data for 127 len"; return; }
            payloadLen = 0;
            for (int i = 0; i < 8; i++) {
                payloadLen = (payloadLen << 8) | (uchar)m_readBuffer[2 + i];
            }
            headerLen = 10;
        }

        if (masked) headerLen += 4;
        if (m_readBuffer.size() < headerLen + (int)payloadLen) {
            qDebug() << "[UB] incomplete frame: have" << m_readBuffer.size() << "need" << headerLen + payloadLen;
            return;
        }

        QByteArray payload = m_readBuffer.mid(headerLen, (int)payloadLen);
        qDebug() << "[UB] frame parsed: opcode=" << opcode << "fin=" << fin << "payloadLen=" << payloadLen;

        if (masked) {
            QByteArray mask = m_readBuffer.mid(headerLen - 4, 4);
            for (int i = 0; i < payload.size(); i++) {
                payload[i] = payload[i] ^ mask[i % 4];
            }
        }

        m_readBuffer = m_readBuffer.mid(headerLen + (int)payloadLen);

        if (opcode == 0x1) {
            qDebug() << "[UB] text frame, first 100 chars:" << payload.left(100);
            handleTextMessage(payload);
        } else if (opcode == 0x9) {
            qDebug() << "[UB] ping received";
            QByteArray pong;
            pong.append((char)0x8A);
            pong.append((char)payload.size());
            pong.append(payload);
            m_socket->write(pong);
        } else if (opcode == 0xA) {
            qDebug() << "[UB] pong received";
        } else if (opcode == 0x8) {
            qDebug() << "[UB] close frame received";
            m_socket->close();
        } else {
            qDebug() << "[UB] unknown opcode:" << opcode;
        }
    }
    qDebug() << "[UB] parseFrames done, remaining buffer:" << m_readBuffer.size();
}

void UBServerManager::sendPing()
{
    if (!m_connected) return;
    QByteArray ping;
    ping.append((char)0x89);
    ping.append((char)0x00);
    m_socket->write(ping);
}

void UBServerManager::handleTextMessage(const QByteArray &message)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(message, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) return;

    QJsonObject obj = doc.object();
    QString event = obj.value("event").toString();
    QJsonObject data = obj.value("data").toObject();

    
    if (!event.startsWith("server/client/team") && !event.startsWith("server/client/spawn") && !event.startsWith("server/client/death")) {
        qDebug() << "[UB] event:" << event << "data keys:" << data.keys();
    }

    
    if (event.startsWith("server/client/") || event == "server/levelchange") {
        if (obj.contains("server")) data["server"] = obj.value("server");
        if (obj.contains("client")) data["client"] = obj.value("client");
    }

    if (event == "app/online") {
        m_onlineUsers = data.value("users").toInt();
        emit onlineUsersChanged();
    } else if (event == "server/init") {
        handleServerInit(data.toVariantMap());
    } else if (event == "server/disconnect") {
        handleServerDisconnect(data.toVariantMap());
    } else if (event == "server/client/connected") {
        qDebug() << "[UB] client/connected, server=" << data.value("server").toInt() << "name=" << data.value("name").toString();
        handleClientConnected(data.toVariantMap());
    } else if (event == "server/client/disconnect") {
        handleClientDisconnected(data.toVariantMap());
    } else if (event == "server/client/changename") {
        handleClientChangeName(data.toVariantMap());
    } else if (event == "server/levelchange") {
        handleLevelChange(data.toVariantMap());
    } else if (event == "server/client/team" || event == "server/client/spawn" || event == "server/client/death") {
        
        handleClientStatusUpdate(data.toVariantMap());
    }
}

int UBServerManager::totalPlayers() const
{
    int total = 0;
    for (const QVariant &sv : m_servers) {
        total += sv.toMap().value("players", 0).toInt();
    }
    return total;
}

void UBServerManager::handleServerInit(const QVariantMap &data)
{
    int id = data.value("id").toInt();
    QVariantMap server;
    server["id"] = id;
    server["name"] = data.value("name").toString();
    server["host"] = data.value("host").toString();
    server["port"] = data.value("port").toInt();
    server["maxplayers"] = data.value("maxplayers").toInt();
    server["mode"] = data.value("mode").toInt();

    QVariantMap map = data.value("map").toMap();
    server["mapName"] = map.value("name").toString();
    server["mapLabel"] = map.value("label").toString();

    QVariantList clients = data.value("clients").toList();
    int aliveCount = 0;
    int commanderCount = 0;
    for (int i = 0; i < clients.size(); i++) {
        QVariantMap cm = clients[i].toMap();
        if (cm.value("alive", true).toBool()) aliveCount++;
        
        bool isCmd = cm.value("commander", false).toBool();
        cm["commander"] = isCmd ? 1 : 0;
        if (isCmd) {
            commanderCount++;
            qDebug() << "[UB] COMMANDER:" << cm.value("name").toString();
        }
        clients[i] = cm;
    }
    qDebug() << "[UB] server" << id << "commanders:" << commanderCount << "/" << clients.size();
    server["players"] = aliveCount;
    server["clients"] = clients;
    qDebug() << "[UB] server/init keys:" << data.keys();
    qDebug() << "[UB] server/init" << server.value("name").toString().left(30) << "host=" << server.value("host").toString() << "port=" << server.value("port").toInt() << "clients=" << clients.size() << "alive=" << aliveCount;

    m_serverMap[id] = server;
    updateServerList();
}

void UBServerManager::handleServerDisconnect(const QVariantMap &data)
{
    int id = data.value("id").toInt();
    if (m_serverMap.contains(id)) {
        m_serverMap.remove(id);
        updateServerList();
    }
}

void UBServerManager::handleClientConnected(const QVariantMap &data)
{
    int serverId = data.value("server").toInt();
    if (!m_serverMap.contains(serverId)) return;

    QVariantMap &server = m_serverMap[serverId];
    QVariantList clients = server.value("clients").toList();

    QVariantMap client;
    client["index"] = data.value("index", data.value("client", 0)).toInt();
    client["name"] = data.value("name").toString();
    client["steam64"] = data.value("steam64").toString();
    client["alive"] = data.value("alive", true).toBool();
    client["team"] = data.value("team", 0).toInt();
    
    client["commander"] = data.value("commander", false).toBool() ? 1 : 0;
    clients.append(client);

    server["clients"] = clients;
    int aliveCount = 0;
    for (const QVariant &c : clients) {
        if (c.toMap().value("alive", true).toBool()) aliveCount++;
    }
    server["players"] = aliveCount;
    qDebug() << "[UB] client added to server" << serverId << "total clients now:" << clients.size();
    updateServerList();
}

void UBServerManager::handleClientDisconnected(const QVariantMap &data)
{
    int serverId = data.value("server").toInt();
    if (!m_serverMap.contains(serverId)) return;

    QVariantMap &server = m_serverMap[serverId];
    QVariantList clients = server.value("clients").toList();
    QString steam64 = data.value("steam64").toString();
    int clientIdx = data.value("client", data.value("index", -1)).toInt();

    QVariantList newClients;
    for (const QVariant &c : clients) {
        QVariantMap cm = c.toMap();
        bool match = false;
        if (!steam64.isEmpty() && cm.value("steam64").toString() == steam64) match = true;
        if (clientIdx >= 0 && cm.value("index").toInt() == clientIdx) match = true;
        if (!match) newClients.append(c);
    }
    server["clients"] = newClients;
    int aliveCount = 0;
    for (const QVariant &c : newClients) {
        if (c.toMap().value("alive", true).toBool()) aliveCount++;
    }
    server["players"] = aliveCount;
    updateServerList();
}

void UBServerManager::handleClientChangeName(const QVariantMap &data)
{
    int serverId = data.value("server").toInt();
    if (!m_serverMap.contains(serverId)) return;

    QVariantMap &server = m_serverMap[serverId];
    QVariantList clients = server.value("clients").toList();
    QString steam64 = data.value("steam64").toString();
    QString newName = data.value("name").toString();
    int clientIdx = data.value("client", -1).toInt();

    for (int i = 0; i < clients.size(); i++) {
        QVariantMap c = clients[i].toMap();
        bool match = (!steam64.isEmpty() && c.value("steam64").toString() == steam64) ||
                     (clientIdx >= 0 && c.value("index").toInt() == clientIdx);
        if (match) {
            c["name"] = newName;
            clients[i] = c;
            break;
        }
    }
    server["clients"] = clients;
    updateServerList();
}

void UBServerManager::handleClientStatusUpdate(const QVariantMap &data)
{
    int serverId = data.value("server").toInt();
    if (!m_serverMap.contains(serverId)) return;

    QVariantMap &server = m_serverMap[serverId];
    QVariantList clients = server.value("clients").toList();
    int clientIdx = data.value("client", -1).toInt();
    bool found = false;

    for (int i = 0; i < clients.size(); i++) {
        QVariantMap c = clients[i].toMap();
        if (c.value("index").toInt() == clientIdx) {
            if (data.contains("alive")) c["alive"] = data.value("alive").toBool();
            if (data.contains("team")) c["team"] = data.value("team").toInt();
            clients[i] = c;
            found = true;
            break;
        }
    }

    if (found) {
        server["clients"] = clients;
        int aliveCount = 0;
        for (const QVariant &c : clients) {
            if (c.toMap().value("alive", true).toBool()) aliveCount++;
        }
        server["players"] = aliveCount;
        updateServerList();
    }
}

void UBServerManager::handleLevelChange(const QVariantMap &data)
{
    int serverId = data.value("server").toInt();
    if (!m_serverMap.contains(serverId)) return;

    QVariantMap &server = m_serverMap[serverId];
    QVariantMap map = data.value("map").toMap();
    server["mapName"] = map.value("name").toString();
    server["mapLabel"] = map.value("label").toString();
    updateServerList();
}

void UBServerManager::updateServerList()
{
    m_servers.clear();
    QList<int> ids = m_serverMap.keys();
    std::sort(ids.begin(), ids.end(), [this](int a, int b) {
        return m_serverMap[a].value("name").toString() < m_serverMap[b].value("name").toString();
    });
    for (int id : ids) {
        m_servers.append(m_serverMap[id]);
    }
    emit serversChanged();
    emit totalPlayersChanged();
}