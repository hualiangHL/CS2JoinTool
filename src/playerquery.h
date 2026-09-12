#ifndef PLAYERQUERY_H
#define PLAYERQUERY_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QString>
#include <QHostInfo>
#include <QHostAddress>
#include <QVariantList>

struct PlayerInfo {
    Q_GADGET
    Q_PROPERTY(QString name MEMBER name)
    Q_PROPERTY(int score MEMBER score)
    Q_PROPERTY(float duration MEMBER duration)
    Q_PROPERTY(int index MEMBER index)
public:
    QString name;
    int score = 0;
    float duration = 0;
    int index = 0;
};
Q_DECLARE_METATYPE(PlayerInfo)

class PlayerQuery : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool querying READ isQuerying NOTIFY queryingChanged)
    Q_PROPERTY(QVariantList players READ players NOTIFY playersChanged)

public:
    explicit PlayerQuery(QObject *parent = nullptr);
    ~PlayerQuery();

    Q_INVOKABLE void queryPlayers(const QString &ip, int port);
    Q_INVOKABLE void clearPlayers() { m_players.clear(); emit playersChanged(); }
    bool isQuerying() const { return m_querying; }
    QVariantList players() const { return m_players; }

signals:
    void queryFinished(const QVariantList &players);
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
