#ifndef SERVERQUERY_H
#define SERVERQUERY_H

#include <QObject>
#include <QUdpSocket>
#include <QTimer>
#include <QString>
#include <QDateTime>
#include <QHostInfo>
#include <QHostAddress>

struct ServerInfo {
    Q_GADGET
    Q_PROPERTY(QString ip MEMBER ip)
    Q_PROPERTY(quint16 port MEMBER port)
    Q_PROPERTY(int players MEMBER players)
    Q_PROPERTY(int maxPlayers MEMBER maxPlayers)
    Q_PROPERTY(int bots MEMBER bots)
    Q_PROPERTY(QString mapName MEMBER mapName)
    Q_PROPERTY(QString serverName MEMBER serverName)
    Q_PROPERTY(QString gameName MEMBER gameName)
    Q_PROPERTY(bool success MEMBER success)
    Q_PROPERTY(QString error MEMBER error)
public:
    QString ip;
    quint16 port = 0;
    int players = 0;
    int maxPlayers = 0;
    int bots = 0;
    QString mapName;
    QString serverName;
    QString gameName;
    bool success = false;
    QString error;
};
Q_DECLARE_METATYPE(ServerInfo)

class ServerQuery : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool querying READ isQuerying NOTIFY queryingChanged)

public:
    explicit ServerQuery(QObject *parent = nullptr);
    ~ServerQuery();

    Q_INVOKABLE void queryServer(const QString &ip, int port);
    Q_INVOKABLE void queryServerWithoutReset();
    Q_INVOKABLE void reset();
    bool isQuerying() const { return m_isQuerying; }

    Q_INVOKABLE static bool connectToServer(const QString &ip, int port, const QString &password = QString(), int protocol = 0);

signals:
    void queryFinished(const ServerInfo &info);
    void queryError(const QString &error);
    void queryingChanged(bool querying);

private slots:
    void onReadyRead();
    void onTimeout();

private:
    QUdpSocket *m_socket;
    QTimer *m_timer;
    QString m_ip;
    QHostAddress m_resolvedIp;
    quint16 m_port;
    bool m_isQuerying;
    quint32 m_challenge = 0;
    int m_retryCount;

    bool sendA2SInfoQuery();
    bool parseA2SResponse(const QByteArray &data, ServerInfo &info);
    QByteArray buildA2SInfoPacket();
    void handleChallenge(const QByteArray &data);
};

#endif 
