#ifndef BASERVERTIME_H
#define BASERVERTIME_H

#include <QObject>
#include <QSslSocket>
#include <QTimer>
#include <QHash>

class BaServerTime : public QObject
{
    Q_OBJECT
public:
    explicit BaServerTime(QObject *parent = nullptr);

    Q_INVOKABLE void connectWS();
    Q_INVOKABLE void disconnectWS();
    qint64 getMapTime(const QString &ip, int port) const;
    bool isConnected() const { return m_connected; }

signals:
    void dataUpdated();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onSslErrors(const QList<QSslError> &errors);
    void reconnect();

private:
    QSslSocket *m_socket;
    bool m_connected;
    bool m_handshakeDone;
    QByteArray m_readBuffer;
    QByteArray m_messageBuffer; 
    QTimer *m_reconnectTimer;
    int m_reconnectAttempt;
    QHash<QString, qint64> m_mapTimes; 

    void sendHandshake();
    void parseFrames();
    void handleTextMessage(const QByteArray &message);
};

#endif