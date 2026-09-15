#ifndef SERVERMANAGER_H
#define SERVERMANAGER_H

#include <QObject>
#include <QAbstractListModel>
#include <QTimer>
#include <QList>
#include <QSet>
#include <QHash>
#include <QString>
#include "baservertime.h"
#include "serverquery.h"

struct ExgServerInfo {
    QString id;
    QString displayName;
    QString displayNameCN;
    QString gameName;
    QString ip;
    quint16 port;
    QString region;
    QString category;
    QString community;
    int currentPlayers;
    int maxPlayers;
    int bots;
    QString map;
    QString mapDifficulty;
    int status; 
    qint64 mapChangedAt; 
    bool hasBaTime; 
};

class ServerListModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum ServerRoles {
        IdRole = Qt::UserRole + 1,
        DisplayNameRole,
        DisplayNameCNRole,
        IpRole,
        PortRole,
        RegionRole,
        CategoryRole,
        CommunityRole,
        CurrentPlayersRole,
        MaxPlayersRole,
        BotsRole,
        MapRole,
        MapDifficultyRole,
        StatusRole,
        PlayersPercentRole,
        GameNameRole,
        MapChangedAtRole,
        HasBaTimeRole
    };

    explicit ServerListModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setServers(const QList<ExgServerInfo> &servers);
    void updateServerStatus(int index, int players, int maxPlayers, int bots, const QString &map, int status, const QString &gameName = QString());
    Q_INVOKABLE ExgServerInfo getServer(int index) const;
    Q_INVOKABLE QVariantMap get(int row) const;
    Q_INVOKABLE int count() const { return m_servers.size(); }

private:
    QList<ExgServerInfo> m_servers;
};

class ServerManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ServerListModel* model READ model CONSTANT)
    Q_PROPERTY(bool refreshing READ isRefreshing NOTIFY refreshingChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(bool hideOffline READ hideOffline WRITE setHideOffline NOTIFY hideOfflineChanged)
    Q_PROPERTY(int sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(QStringList filterOptions READ filterOptions WRITE setFilterOptions NOTIFY filterOptionsChanged)
    Q_PROPERTY(int modelVersion READ modelVersion NOTIFY modelVersionChanged)
    Q_PROPERTY(int refreshCountdown READ refreshCountdown NOTIFY refreshCountdownChanged)
    Q_PROPERTY(QStringList communityOrder READ communityOrder NOTIFY communityOrderChanged)
    Q_PROPERTY(QVariantList communityGroups READ communityGroups NOTIFY modelVersionChanged)

public:
    explicit ServerManager(QObject *parent = nullptr);

    ServerListModel* model() { return &m_model; }
    bool isRefreshing() const { return m_refreshing; }
    QString searchText() const { return m_searchText; }
    void setSearchText(const QString &text);
    bool hideOffline() const { return m_hideOffline; }
    void setHideOffline(bool hide);
    int sortMode() const { return m_sortMode; }
    void setSortMode(int mode);
    QStringList filterOptions() const { return m_filterOptions; }
    void setFilterOptions(const QStringList &opts);
    int modelVersion() const { return m_modelVersion; }
    int refreshCountdown() const { return m_refreshCountdown; }

    Q_INVOKABLE void refreshAll();
    Q_INVOKABLE void joinServer(int index, int protocol = 0);
    Q_INVOKABLE void copyAddress(int index);
    Q_INVOKABLE QStringList communities();
    Q_INVOKABLE QVariantList communityServers(const QString &community);
    Q_INVOKABLE QString mapTranslate(const QString &mapName);
    Q_INVOKABLE void moveCommunityUp(const QString &community);
    Q_INVOKABLE void moveCommunityDown(const QString &community);
    Q_INVOKABLE void resetCommunityOrder();
    Q_INVOKABLE int getSubGroupCount(int index);
    Q_INVOKABLE int findServerIndex(const QString &serverId);
    QVariantList communityGroups() const;
    QStringList communityOrder() const { return m_communityOrder; }

signals:
    void refreshingChanged(bool refreshing);
    void searchTextChanged(const QString &text);
    void hideOfflineChanged(bool hide);
    void sortModeChanged(int mode);
    void filterOptionsChanged(const QStringList &opts);
    void modelVersionChanged(int version);
    void refreshCountdownChanged(int countdown);
    void communityOrderChanged();
    void serverJoined(const QString &ip, int port, const QString &name);
    void serverMapUpdated(const QString &ip, int port, const QString &serverName,
                          const QString &community, const QString &mapName,
                          int players, int maxPlayers);

private slots:
    void onQueryFinished(const ServerInfo &info);
    void onQueryError(const QString &error);
    void onAutoRefresh();

private:
    ServerListModel m_model;
    QList<ExgServerInfo> m_allServers;
    QList<ServerQuery*> m_activeQueries;
    QTimer *m_autoRefreshTimer;
    QTimer *m_batchTimer;
    QList<int> m_pendingServerIndexes;
    bool m_refreshing;
    QString m_searchText;
    bool m_hideOffline = true;
    int m_sortMode; 
    QStringList m_filterOptions;
    int m_pendingQueries;
    int m_modelVersion;
    BaServerTime *m_baTime;
    bool m_filterPending = false;
    int m_refreshCountdown = 60;
    QHash<QString, QString> m_mapDict;
    QStringList m_communityOrder;

    void loadDefaultServers();
    void applyFilters();
    void startNextBatch();
    void loadCommunityOrder();
    void saveCommunityOrder();
    void initCommunityOrder();
};

#endif 
