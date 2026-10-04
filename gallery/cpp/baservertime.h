#ifndef BASERVERTIME_H
#define BASERVERTIME_H

#include <QObject>
#include <QSslSocket>
#include <QTimer>
#include <QHash>
#include <QElapsedTimer>
#include <QNetworkAccessManager>

class BaServerTime : public QObject
{
    Q_OBJECT
public:
    explicit BaServerTime(QObject *parent = nullptr);

    Q_INVOKABLE void connectWS();
    Q_INVOKABLE void disconnectWS();
    Q_INVOKABLE qint64 getMapTime(const QString &ip, int port) const;
    Q_INVOKABLE qint64 getMapTimeByName(const QString &name) const;
    Q_INVOKABLE bool isConnected() const { return m_connected; }

    Q_INVOKABLE void recalibrate();

    Q_INVOKABLE qint64 lastPushMs() const { return m_lastPushMs; }

    Q_INVOKABLE qint64 offsetMs() const { return m_offsetMs; }

signals:
    void dataUpdated();

private slots:
    void onSocketConnected();
    void onSocketDisconnected();
    void onSocketReadyRead();
    void onSocketError(QAbstractSocket::SocketError error);
    void onSslErrors(const QList<QSslError> &errors);
    void reconnect();
    void checkStale();
    void fetchServerTime();

private:
    QSslSocket *m_socket;
    bool m_connected;
    bool m_handshakeDone;
    QByteArray m_readBuffer;
    QByteArray m_messageBuffer;
    QTimer *m_reconnectTimer;
    QTimer *m_staleTimer;
    QTimer *m_timeSyncTimer;
    QNetworkAccessManager *m_nam;
    int m_reconnectAttempt;
    qint64 m_lastPushMs = 0;
    qint64 m_offsetMs = 0;
    QElapsedTimer m_lastRecal;
    QHash<QString, qint64> m_mapTimes;
    QHash<QString, qint64> m_nameMapTimes;
    QHash<QString, QString> m_ipAliases;

    void sendHandshake();
    void parseFrames();
    void handleTextMessage(const QByteArray &message);
};

#endif
