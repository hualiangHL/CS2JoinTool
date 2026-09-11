#ifndef MAPSUBSCRIPTIONMANAGER_H
#define MAPSUBSCRIPTIONMANAGER_H

#include <QObject>
#include <QStringList>
#include <QSettings>
#include <QMap>

struct SubEntry {
    QString community;
    QString mapKeyword;
};

class MapSubscriptionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList subscribedMaps READ subscribedMaps NOTIFY subscribedMapsChanged)
    Q_PROPERTY(QStringList allMapNames READ allMapNames NOTIFY allMapNamesChanged)
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)

public:
    explicit MapSubscriptionManager(QObject *parent = nullptr);
    ~MapSubscriptionManager();

    QStringList subscribedMaps() const { return m_subscribedMaps; }
    bool notificationsEnabled() const { return m_notificationsEnabled; }
    void setNotificationsEnabled(bool e);

    Q_INVOKABLE void addSubscription(const QString &mapKeyword, const QString &community = "");
    Q_INVOKABLE void removeSubscription(int index);
    Q_INVOKABLE void clearSubscriptions();
    Q_INVOKABLE void testNotification();
    Q_INVOKABLE QString translateMap(const QString &name);
    QStringList allMapNames() const { return m_allMapNames; }
    void addServerMap(const QString &mapName);

    
    void checkServerMap(const QString &ip, int port, const QString &serverName,
                        const QString &community, const QString &mapName,
                        int currentPlayers, int maxPlayers);

signals:
    void subscribedMapsChanged();
    void allMapNamesChanged();
    void subscriptionDetected(const QString &title, const QString &message,
                              const QString &ip, int port);
    void notificationRequested(const QString &title, const QString &message);
    void notificationsEnabledChanged(bool e);

private:
    QStringList m_subscribedMaps;
    QStringList m_allMapNames;
    QSettings *m_settings;
    QMap<QString, QString> m_lastNotifiedMap;
    bool m_notificationsEnabled;

    void loadSubscriptions();
    void saveSubscriptions();
    SubEntry parseEntry(const QString &raw);
    QString stripMapVersion(const QString &mapName);
    bool communityMatches(const QString &serverCommunity, const QString &subCommunity);
};

#endif