#ifndef UBSERVERMANAGER_H
#define UBSERVERMANAGER_H

#include <QObject>
#include <QSslSocket>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class UBServerManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList servers READ servers NOTIFY serversChanged)
    Q_PROPERTY(int onlineUsers READ onlineUsers NOTIFY onlineUsersChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(int totalPlayers READ totalPlayers NOTIFY totalPlayersChanged)

public:
    explicit UBServerManager(QObject *parent = nullptr);

    QVariantList servers() const { return m_servers; }
    int onlineUsers() const { return m_onlineUsers; }
    bool connected() const { return m_connected; }
    int totalPlayers() const;

    Q_INVOKABLE void connectWS();
    Q_INVOKABLE void disconnectWS();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE QVariantMap findServer(const QString &host, int port);

signals:
    void serversChanged();
    void onlineUsersChanged();
    void connectedChanged();
    void totalPlayersChanged();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onSslErrors(const QList<QSslError> &errors);
    void reconnect();

private:
    QSslSocket *m_socket;
    QVariantList m_servers;
    QMap<int, QVariantMap> m_serverMap;
    int m_onlineUsers;
    bool m_connected;
    bool m_handshakeDone;
    QByteArray m_readBuffer;
    QTimer *m_reconnectTimer;
    QTimer *m_pingTimer;
    int m_reconnectAttempt;

    void sendHandshake();
    void parseFrames();
    void handleTextMessage(const QByteArray &message);
    void sendPing();
    void handleServerInit(const QVariantMap &data);
    void handleServerDisconnect(const QVariantMap &data);
    void handleClientConnected(const QVariantMap &data);
    void handleClientDisconnected(const QVariantMap &data);
    void handleClientChangeName(const QVariantMap &data);
    void handleClientStatusUpdate(const QVariantMap &data);
    void handleLevelChange(const QVariantMap &data);
    void updateServerList();
};

#endif

