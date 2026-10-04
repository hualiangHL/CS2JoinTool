#ifndef PLAYERQUERYENGINE_H
#define PLAYERQUERYENGINE_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QString>
#include <QHostInfo>
#include <QHostAddress>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class PlayerQueryEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool querying READ isQuerying NOTIFY queryingChanged)
    Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)

public:
    explicit PlayerQueryEngine(QObject *parent = nullptr);
    ~PlayerQueryEngine();

    Q_INVOKABLE void queryPlayers(const QString &ip, int port);
    Q_INVOKABLE void clearPlayers() { m_players.clear(); emit playersChanged(); }
    bool isQuerying() const { return m_querying; }
    QVariantList players() const { return m_players; }

signals:
    void queryError(const QString &error);
    void queryingChanged(bool querying);
    void playersChanged();

private slots:
    void onReadyRead();
    void onTimeout();

private:
    QUdpSocket *m_socket;
    QTimer *m_timer;
    QString m_ip;
    QHostAddress m_resolvedIp;
    quint16 m_port;
    bool m_querying;
    quint32 m_challenge;
    int m_retry;
    QVariantList m_players;

    bool sendPlayerQuery();
    void handleChallenge(const QByteArray &data);
    bool parsePlayerResponse(const QByteArray &data, QVariantList &players);
};

#endif
