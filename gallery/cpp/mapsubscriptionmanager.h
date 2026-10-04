#ifndef MAPSUBSCRIPTIONMANAGER_H
#define MAPSUBSCRIPTIONMANAGER_H

#include <QObject>
#include <QStringList>
#include <QSettings>
#include <QMap>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>


class LangManager;
class MapSubscriptionManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList subscribedMaps READ subscribedMaps NOTIFY subscribedMapsChanged)
    Q_PROPERTY(QStringList allMapNames READ allMapNames NOTIFY allMapNamesChanged)
    Q_PROPERTY(bool notificationsEnabled READ notificationsEnabled WRITE setNotificationsEnabled NOTIFY notificationsEnabledChanged)

public:
    explicit MapSubscriptionManager(const QString &cfgDir, QObject *parent = nullptr);
    ~MapSubscriptionManager();


    void setLangManager(LangManager *l) { m_lang = l; }
    bool isEn() const;

    QStringList subscribedMaps() const { return m_subscribedMaps; }
    QStringList allMapNames() const { return m_allMapNames; }
    bool notificationsEnabled() const { return m_notificationsEnabled; }
    void setNotificationsEnabled(bool e);

    Q_INVOKABLE void addSubscription(const QString &mapKeyword, const QString &community = QString());
    Q_INVOKABLE void removeSubscription(int index);
    Q_INVOKABLE void clearSubscriptions();
    Q_INVOKABLE void testNotification();
    Q_INVOKABLE QString translateMap(const QString &name);

    Q_INVOKABLE void checkAll(const QVariantList &groups, const QString &communityKey);

    Q_INVOKABLE bool isSubscribed(const QString &mapName, const QString &community) const;

signals:
    void subscribedMapsChanged();
    void allMapNamesChanged();
    void notificationRequested(const QString &title, const QString &message);
    void notificationsEnabledChanged(bool e);

private:
    struct SubEntry {
        QString community;
        QString mapKeyword;
    };

    void loadSubscriptions();
    void saveSubscriptions();
    SubEntry parseEntry(const QString &raw) const;
    QString stripMapVersion(const QString &mapName) const;
    bool communityMatches(const QString &serverCommunity, const QString &subCommunity) const;
    void checkServerMap(const QString &ip, int port, const QString &serverName,
                        const QString &community, const QString &mapName,
                        int currentPlayers, int maxPlayers);
    static int parsePlayers(const QString &playersText, bool max);

    QStringList m_subscribedMaps;
    QStringList m_allMapNames;
    QSettings *m_settings = nullptr;
    QMap<QString, QString> m_lastNotifiedMap;
    bool m_notificationsEnabled = true;
    LangManager *m_lang = nullptr;
};

#endif
