#ifndef INTERNATIONALSERVERQUERYENGINE_H
#define INTERNATIONALSERVERQUERYENGINE_H

#include <QObject>
#include <QHostAddress>
#include <QVariantList>
#include <QVariantMap>
#include <QDateTime>
#include <QTimer>
#include <QUdpSocket>
#include <QtQml/qqmlregistration.h>

class InternationalServerQueryEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantList groups READ groups NOTIFY serversUpdated)

public:
    explicit InternationalServerQueryEngine(QObject *parent = nullptr);

    QVariantList groups() const;

    Q_INVOKABLE void refresh();

signals:
    void serversUpdated();

private slots:
    void onReadyRead();
    void onRoundTimeout();

private:
    struct ServerState {
        QString group;
        QString host;
        quint16 port;
        QString name;
        QString map;
        int players = 0;
        int maxPlayers = 0;
        int bots = 0;
        bool online = false;
        bool done = false;
        bool pending = false;
        bool gotChallenge = false;
        QByteArray challenge;
        QDateTime firstSeen;
    };

    int indexOf(const QHostAddress &addr, quint16 port) const;
    void handleDatagram(int idx, const QByteArray &buf);
    void sendInfo(ServerState &st);
    void checkAllDone();
    QString readString(const QByteArray &data, int &off) const;
    void cleanup(QString &s) const;

    QList<ServerState> m_servers;
    QUdpSocket m_socket;
    QTimer m_roundTimer;
    bool m_firstQuery = true;
    qint64 m_lastRefreshMs = 0;
};

#endif
