#include "servermanager.h"
#include "maptranslations.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QSettings>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <algorithm>

ServerListModel::ServerListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ServerListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_servers.size();
}

QVariant ServerListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_servers.size())
        return QVariant();

    const ExgServerInfo &s = m_servers[index.row()];
    switch (role) {
    case IdRole: return s.id;
    case DisplayNameRole: return s.displayName;
    case DisplayNameCNRole: return s.displayNameCN;
    case IpRole: return s.ip;
    case PortRole: return s.port;
    case RegionRole: return s.region;
    case CategoryRole: return s.category;
    case CommunityRole: return s.community;
    case CurrentPlayersRole: return s.currentPlayers;
    case MaxPlayersRole: return s.maxPlayers;
    case BotsRole: return s.bots;
    case MapRole: return s.map;
    case MapDifficultyRole: return s.mapDifficulty;
    case StatusRole: return s.status;
    case PlayersPercentRole:
        return s.maxPlayers > 0 ? (double)s.currentPlayers / s.maxPlayers : 0.0;
    case GameNameRole: return s.gameName;
    case MapChangedAtRole: return s.mapChangedAt;
    case HasBaTimeRole: return s.hasBaTime;
    }
    return QVariant();
}

QHash<int, QByteArray> ServerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "serverId";
    roles[DisplayNameRole] = "displayName";
    roles[DisplayNameCNRole] = "displayNameCN";
    roles[IpRole] = "ip";
    roles[PortRole] = "port";
    roles[RegionRole] = "region";
    roles[CategoryRole] = "category";
    roles[CommunityRole] = "community";
    roles[CurrentPlayersRole] = "currentPlayers";
    roles[MaxPlayersRole] = "maxPlayers";
    roles[BotsRole] = "bots";
    roles[MapRole] = "map";
    roles[MapDifficultyRole] = "mapDifficulty";
    roles[StatusRole] = "status";
    roles[PlayersPercentRole] = "playersPercent";
    roles[GameNameRole] = "gameName";
    roles[MapChangedAtRole] = "mapChangedAt";
    roles[HasBaTimeRole] = "hasBaTime";
    return roles;
}

void ServerListModel::setServers(const QList<ExgServerInfo> &servers)
{
    beginResetModel();
    m_servers = servers;
    endResetModel();
}

void ServerListModel::updateServerStatus(int index, int players, int maxPlayers, int bots, const QString &map, int status, const QString &gameName)
{
    if (index < 0 || index >= m_servers.size()) return;
    
    if (status == 1 && !map.isEmpty() && m_servers[index].map != map) {
        m_servers[index].mapChangedAt = QDateTime::currentSecsSinceEpoch();
    }
    m_servers[index].currentPlayers = players;
    m_servers[index].maxPlayers = maxPlayers;
    m_servers[index].bots = bots;
    m_servers[index].map = map;
    m_servers[index].status = status;
    if (!gameName.isEmpty()) m_servers[index].gameName = gameName;
    emit dataChanged(createIndex(index, 0), createIndex(index, 0),
                     {CurrentPlayersRole, MaxPlayersRole, BotsRole, MapRole, StatusRole, PlayersPercentRole, GameNameRole, MapChangedAtRole});
}

ExgServerInfo ServerListModel::getServer(int index) const
{
    if (index >= 0 && index < m_servers.size())
        return m_servers[index];
    return ExgServerInfo();
}

QVariantMap ServerListModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_servers.size()) return map;
    const ExgServerInfo &s = m_servers[row];
    map["id"] = s.id;
    map["displayName"] = s.displayName;
    map["displayNameCN"] = s.displayNameCN;
    map["ip"] = s.ip;
    map["port"] = s.port;
    map["region"] = s.region;
    map["category"] = s.category;
    map["community"] = s.community;
    map["currentPlayers"] = s.currentPlayers;
    map["maxPlayers"] = s.maxPlayers;
    map["bots"] = s.bots;
    map["map"] = s.map;
    map["mapDifficulty"] = s.mapDifficulty;
    map["status"] = s.status;
    map["gameName"] = s.gameName;
    map["mapChangedAt"] = s.mapChangedAt;
    map["hasBaTime"] = s.hasBaTime;
    map["row"] = row;
    return map;
}

ServerManager::ServerManager(QObject *parent)
    : QObject(parent)
    , m_refreshing(false)
    , m_hideOffline(true)
    , m_sortMode(0)
    , m_pendingQueries(0)
    , m_modelVersion(0)
{
    m_autoRefreshTimer = new QTimer(this);
    m_autoRefreshTimer->setInterval(1000);
    connect(m_autoRefreshTimer, &QTimer::timeout, this, &ServerManager::onAutoRefresh);
    m_autoRefreshTimer->start();
    m_batchTimer = new QTimer(this);
    m_batchTimer->setSingleShot(true);
    m_batchTimer->setInterval(200);
    connect(m_batchTimer, &QTimer::timeout, this, &ServerManager::startNextBatch);
    loadDefaultServers();
    initMapTranslations(m_mapDict);
    loadCommunityOrder();
    applyFilters();
    m_baTime = new BaServerTime(this);
    connect(m_baTime, &BaServerTime::dataUpdated, this, [this](){
        
        for (int i = 0; i < m_allServers.size(); i++) {
            if (m_allServers[i].status != 1) continue;
            qint64 baTime = m_baTime->getMapTime(m_allServers[i].ip, m_allServers[i].port);
            if (baTime <= 0) {
                QString srvName = m_allServers[i].gameName;
                if (srvName.isEmpty()) srvName = m_allServers[i].displayNameCN;
                if (!srvName.isEmpty()) baTime = m_baTime->getMapTimeByName(srvName);
            }
            if (baTime > 0) {
                m_allServers[i].mapChangedAt = baTime / 1000;
                m_allServers[i].hasBaTime = true;
            }
        }
        m_modelVersion++;
        emit modelVersionChanged(m_modelVersion);
        applyFilters();
    });
    QTimer::singleShot(1500, m_baTime, &BaServerTime::connectWS);
}

void ServerManager::loadDefaultServers()
{
    m_allServers.clear();

    QList<ExgServerInfo> allServers = {
        {"exg_ze01", "ZE装备 #1", "ZE装备 #1", "", "202.189.4.212", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze02", "ZE装备 #2", "ZE装备 #2", "", "202.189.4.212", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze05", "ZE #5", "ZE #5", "", "202.189.4.230", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze06", "ZE #6", "ZE #6", "", "202.189.4.230", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze07", "ZE装备 #7", "ZE装备 #7", "", "202.189.10.196", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze08", "ZE装备 #8", "ZE装备 #8", "", "202.189.10.196", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze09", "ZE装备 #9", "ZE装备 #9", "", "202.189.5.221", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze10", "ZE装备 #10", "ZE装备 #10", "", "202.189.10.203", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze11", "ZE装备 #11", "ZE装备 #11", "", "202.189.10.208", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze12", "ZE装备 #12", "ZE装备 #12", "", "202.189.5.225", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze13", "ZE装备 #13", "ZE装备 #13", "", "202.189.5.227", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze14", "ZE装备 #14", "ZE装备 #14", "", "202.189.5.236", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze16", "ZE装备 #16", "ZE装备 #16", "", "202.189.10.208", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze17", "ZE装备 #17", "ZE装备 #17", "", "202.189.5.225", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze18", "ZE装备 #18", "ZE装备 #18", "", "202.189.5.227", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze19", "ZE装备 #19", "ZE装备 #19", "", "202.189.5.236", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze23", "ZE装备 #23", "ZE装备 #23", "", "202.189.4.110", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze24", "ZE装备 #24", "ZE装备 #24", "", "202.189.4.110", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze_n02", "ZE #2", "ZE #2", "", "202.189.10.85", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze_n03", "ZE #3", "ZE #3", "", "202.189.4.124", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_ze_n04", "ZE #4", "ZE #4", "", "202.189.4.124", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_ze01", "僵尸逃跑 #1", "僵尸逃跑 #1", "", "cs1.zombieden.cn", 27016, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_ze02", "僵尸逃跑 #2", "僵尸逃跑 #2", "", "cs3.zombieden.cn", 27015, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_ze03", "僵尸逃跑 #3", "僵尸逃跑 #3", "", "cs3.zombieden.cn", 27016, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_ze04", "僵尸逃跑 #4", "僵尸逃跑 #4", "", "cs5.zombieden.cn", 27015, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_ze05", "僵尸逃跑 #5", "僵尸逃跑 #5", "", "cs5.zombieden.cn", 27016, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_surf01", "SURF滑翔 #1 简单", "SURF滑翔 #1 简单", "", "cs1.zombieden.cn", 27019, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_surf02", "SURF滑翔 #2 困难", "SURF滑翔 #2 困难", "", "cs1.zombieden.cn", 27020, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_kz01", "KZ攀岩#1", "KZ攀岩#1", "", "cs2.zombieden.cn", 27090, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_kz02", "KZ攀岩#2", "KZ攀岩#2", "", "cs2.zombieden.cn", 27091, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_kz03", "KZ攀岩#3", "KZ攀岩#3", "", "cs2.zombieden.cn", 27092, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_mg01", "娱乐闯关 #1", "娱乐闯关 #1", "", "cs6.zombieden.cn", 27091, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_mg02", "娱乐闯关 #2", "娱乐闯关 #2", "", "cs5.zombieden.cn", 27017, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_mg03", "娱乐闯关 #3", "娱乐闯关 #3", "", "cs5.zombieden.cn", 27018, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_misc01", "娱乐混战 #1", "娱乐混战 #1", "", "cs6.zombieden.cn", 27089, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zed_misc02", "娱乐混战 #2", "娱乐混战 #2", "", "cs6.zombieden.cn", 27090, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_cs01", "[CS]僵尸逃跑 #1", "[CS]僵尸逃跑 #1", "", "cs2.zombieden.cn", 27050, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"zombie1_cs02", "[CS]僵尸逃跑 #2", "[CS]僵尸逃跑 #2", "", "cs2.zombieden.cn", 27051, "山东", "ZE", "ZED服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze01", "僵尸逃跑 #01", "僵尸逃跑 #01", "", "110.42.9.188", 27011, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze02", "僵尸逃跑 #02", "僵尸逃跑 #02", "", "110.42.9.188", 27021, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze03", "僵尸逃跑 #03", "僵尸逃跑 #03", "", "110.42.9.188", 27031, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze05", "僵尸逃跑 #05", "僵尸逃跑 #05", "", "110.42.9.127", 27051, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze06", "僵尸逃跑 #06", "僵尸逃跑 #06", "", "110.42.9.127", 27061, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze07", "僵尸逃跑 #07", "僵尸逃跑 #07", "", "110.42.9.127", 27071, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze11", "僵尸逃跑 #11", "僵尸逃跑 #11", "", "110.42.9.195", 27111, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze12", "僵尸逃跑 #12", "僵尸逃跑 #12", "", "110.42.9.195", 27121, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_ze13", "僵尸逃跑 #13", "僵尸逃跑 #13", "", "110.42.9.195", 27131, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_inf17", "僵尸感染 #17", "僵尸感染 #17", "", "103.45.130.84", 27017, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_inf27", "僵尸感染 #27", "僵尸感染 #27", "", "110.42.9.195", 27027, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_misc01", "女装混战 #1", "女装混战 #1", "", "103.45.130.84", 27055, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_misc02", "女装混战 #2", "女装混战 #2", "", "103.45.130.84", 27065, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz01", "攀岩滑翔 #1", "攀岩滑翔 #1", "", "103.45.130.84", 27014, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz02", "攀岩滑翔 #2", "攀岩滑翔 #2", "", "103.45.130.84", 27024, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz03", "攀岩滑翔 #3", "攀岩滑翔 #3", "", "103.45.130.84", 27034, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz04", "攀岩滑翔 #4", "攀岩滑翔 #4", "", "103.45.130.84", 27044, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz05", "攀岩滑翔 #5", "攀岩滑翔 #5", "", "103.45.130.84", 27054, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz06", "攀岩滑翔 #6", "攀岩滑翔 #6", "", "103.45.130.84", 27064, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_kz07", "攀岩滑翔 #7", "攀岩滑翔 #7", "", "103.45.130.84", 27019, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_csgo01", "CSGO僵尸逃跑 #1", "CSGO僵尸逃跑 #1", "", "110.42.9.200", 27021, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_csgo02", "CSGO僵尸逃跑 #2", "CSGO僵尸逃跑 #2", "", "110.42.9.200", 27051, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_csgo03", "CSGO僵尸逃跑 #3", "CSGO僵尸逃跑 #3", "", "110.42.9.200", 27071, "山东", "ZE", "UB 服务器列表", 0, 64, 0, "", "", 0},
        {"ub_afk01", "UB挂机服 #1", "UB挂机服 #1", "", "103.45.130.84", 27016, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze01", "僵尸逃跑 01# 大逃杀", "僵尸逃跑 01# 大逃杀", "", "110.42.9.155", 27015, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze02", "僵尸逃跑 02# 大逃杀", "僵尸逃跑 02# 大逃杀", "", "110.42.9.203", 27025, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze03", "僵尸逃跑 03# 大逃杀", "僵尸逃跑 03# 大逃杀", "", "110.42.9.139", 27035, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze04", "僵尸逃跑 04# 大逃杀", "僵尸逃跑 04# 大逃杀", "", "110.42.9.138", 27045, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze05", "僵尸逃跑 05# 大逃杀", "僵尸逃跑 05# 大逃杀", "", "110.42.9.138", 27055, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze06", "僵尸逃跑 06# 大逃杀", "僵尸逃跑 06# 大逃杀", "", "110.42.9.107", 27065, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze07", "僵尸逃跑 07# 大逃杀", "僵尸逃跑 07# 大逃杀", "", "110.42.9.139", 27075, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze08", "僵尸逃跑 08# 大逃杀", "僵尸逃跑 08# 大逃杀", "", "110.42.9.107", 27085, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze09", "僵尸逃跑 09# 大逃杀", "僵尸逃跑 09# 大逃杀", "", "110.42.9.203", 27095, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze10", "僵尸逃跑 10# 大逃杀", "僵尸逃跑 10# 大逃杀", "", "110.42.9.107", 27105, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze13", "僵尸逃跑 13# 大逃杀", "僵尸逃跑 13# 大逃杀", "", "110.42.9.155", 28000, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_ze15", "僵尸逃跑 15# 大逃杀", "僵尸逃跑 15# 大逃杀", "", "110.42.9.52", 29000, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_fun01", "娱乐对抗", "娱乐对抗", "", "110.42.9.155", 27025, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_fun02", "魔兽混战", "魔兽混战", "", "110.42.9.52", 27215, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_fun03", "匪镇谍影", "匪镇谍影", "", "110.42.9.203", 27315, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_fun04", "娱乐对抗 #2", "娱乐对抗 #2", "", "110.42.9.52", 27035, "山东", "ZE", "FyS服务器列表", 0, 64, 0, "", "", 0},
        {"fys_afk01", "FyS挂机服 #1", "FyS挂机服 #1", "", "110.42.9.52", 27900, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"fys_afk02", "FyS挂机服 #2", "FyS挂机服 #2", "", "110.42.9.52", 27901, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"exg_pve01", "PVE模式 #1", "PVE模式 #1", "", "202.189.5.229", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_pve02", "PVE模式 #2", "PVE模式 #2", "", "202.189.5.229", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_pve03", "PVE模式 #3", "PVE模式 #3", "", "202.189.5.229", 27003, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_pve04", "PVE模式 #4", "PVE模式 #4", "", "202.189.5.229", 27004, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_pve05", "PVE模式 #5", "PVE模式 #5", "", "103.45.134.202", 27005, "湖北", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_event01", "僵尸逃跑 活动#1", "僵尸逃跑 活动#1", "", "202.189.5.221", 27008, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_event02", "僵尸逃跑 活动#1 备用", "僵尸逃跑 活动#1 备用", "", "202.189.5.212", 27008, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_hide01", "躲猫猫模式 #1", "躲猫猫模式 #1", "", "202.189.10.184", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_hide02", "躲猫猫模式 #2", "躲猫猫模式 #2", "", "202.189.10.184", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_mg01", "娱乐闯关MG #1", "娱乐闯关MG #1", "", "202.189.5.232", 27001, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"exg_mg02", "娱乐闯关MG #2", "娱乐闯关MG #2", "", "202.189.5.232", 27002, "山东", "ZE", "ExG服务器列表", 0, 64, 0, "", "", 0},
        {"upkk_ze01", "[UPKK] CS2 僵尸逃跑 #1", "[UPKK] CS2 僵尸逃跑 #1", "", "cs2ze.upkk.com", 27015, "台湾", "ZE", "UPKK/Zero服务器列表", 0, 64, 0, "", "", 0},
        {"zero_ze01", "Zero #1", "Zero #1", "", "43.248.117.109", 27015, "海外", "ZE", "UPKK/Zero服务器列表", 0, 64, 0, "", "", 0},
        {"zero_ze02", "Zero #2", "Zero #2", "", "43.248.117.109", 27025, "海外", "ZE", "UPKK/Zero服务器列表", 0, 64, 0, "", "", 0},
        {"star_01", "SCP-感染-叛乱 #1", "SCP-感染-叛乱 #1", "", "110.42.9.142", 27028, "山东", "ZE", "星社区服务器列表", 0, 64, 0, "", "", 0},
        {"star_02", "SCP-感染-叛乱 #2", "SCP-感染-叛乱 #2", "", "110.42.9.142", 27041, "山东", "ZE", "星社区服务器列表", 0, 64, 0, "", "", 0},
        {"star_03", "SCP-感染-叛乱 #3", "SCP-感染-叛乱 #3", "", "110.42.9.56", 27043, "山东", "ZE", "星社区服务器列表", 0, 64, 0, "", "", 0},
        {"star_afk01", "星社区挂机服 #1", "星社区挂机服 #1", "", "110.42.9.56", 27049, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"intl_gfl", "GFL Zombie Escape", "GFL Zombie Escape", "", "74.91.124.21", 27015, "美国", "ZE", "国际服列表", 0, 64, 0, "", "", 0},
        {"intl_mapeadores", "[EU] MAPEADORES ZE", "[EU] MAPEADORES ZE", "", "87.98.228.196", 27040, "欧洲", "ZE", "国际服列表", 0, 64, 0, "", "", 0},
        {"intl_possession", "POSSESSION [PSE]", "POSSESSION [PSE]", "", "103.62.49.55", 27015, "东南亚", "ZE", "国际服列表", 0, 64, 0, "", "", 0},
        {"intl_rss", "[RSS] Zombie Escape", "[RSS] Zombie Escape", "", "14.6.92.207", 27015, "韩国", "ZE", "国际服列表", 0, 64, 0, "", "", 0},
        {"exg_afk01", "EXG挂机大厅 #1", "EXG挂机大厅 #1", "", "202.189.10.86", 27001, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"exg_afk02", "EXG挂机大厅 #2", "EXG挂机大厅 #2", "", "202.189.10.86", 27002, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"exg_afk03", "EXG挂机大厅 #3", "EXG挂机大厅 #3", "", "202.189.10.86", 27003, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"zed_afk01", "ZED挂机幻想乡大厅", "ZED挂机幻想乡大厅", "", "cs1.zombieden.cn", 27015, "山东", "ZE", "挂机服务器列表", 0, 64, 0, "", "", 0},
        {"xcq_paotu01", "xcq跑图服", "xcq跑图服", "", "frp-ten.com", 55612, "跑图", "ZE", "跑图服务器列表", 0, 64, 0, "", "", 0},
        {"xcq_paotu02", "xcq跑图服", "xcq跑图服", "", "frp-ten.com", 63527, "跑图", "ZE", "跑图服务器列表", 0, 64, 0, "", "", 0},
        {"liuyue_paotu01", "六月跑图服", "六月跑图服", "", "101.35.9.103", 27015, "跑图", "ZE", "跑图服务器列表", 0, 64, 0, "", "", 0},
    };

    m_allServers.append(allServers);
}

void ServerManager::initCommunityOrder()
{
    m_communityOrder.clear();
    QStringList fixedOrder = {
        "ExG服务器列表",
        "ZED服务器列表",
        "UB 服务器列表",
        "FyS服务器列表",
        "UPKK/Zero服务器列表",
        "星社区服务器列表",
        "国际服列表",
        "跑图服务器列表",
        "挂机服务器列表"
    };
    QStringList existing;
    for (const auto &s : m_allServers) {
        QString c = s.community.trimmed();
        if (!existing.contains(c)) existing.append(c);
    }
    for (const QString &c : fixedOrder) {
        if (existing.contains(c) && !m_communityOrder.contains(c)) {
            m_communityOrder.append(c);
        }
    }
    for (const QString &c : existing) {
        if (!m_communityOrder.contains(c)) m_communityOrder.append(c);
    }
}

void ServerManager::loadCommunityOrder()
{
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/serverlist.ini", QSettings::IniFormat);
    QStringList saved = settings.value("communityOrder").toStringList();
    initCommunityOrder();
    QStringList merged;
    for (const QString &c : saved) {
        QString trimmed = c.trimmed();
        if (m_communityOrder.contains(trimmed) && !merged.contains(trimmed)) {
            merged.append(trimmed);
        }
    }
    for (const QString &c : m_communityOrder) {
        if (!merged.contains(c)) merged.append(c);
    }
    m_communityOrder = merged;
}

void ServerManager::saveCommunityOrder()
{
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/serverlist.ini", QSettings::IniFormat);
    settings.setValue("communityOrder", m_communityOrder);
}

void ServerManager::moveCommunityUp(const QString &community)
{
    int idx = m_communityOrder.indexOf(community);
    if (idx > 0) {
        m_communityOrder.move(idx, idx - 1);
        saveCommunityOrder();
        emit communityOrderChanged();
        applyFilters();
    }
}

void ServerManager::moveCommunityDown(const QString &community)
{
    int idx = m_communityOrder.indexOf(community);
    if (idx >= 0 && idx < m_communityOrder.size() - 1) {
        m_communityOrder.move(idx, idx + 1);
        saveCommunityOrder();
        emit communityOrderChanged();
        applyFilters();
    }
}

void ServerManager::resetCommunityOrder()
{
    initCommunityOrder();
    saveCommunityOrder();
    emit communityOrderChanged();
    applyFilters();
}

static int serverSubTypeOf(const ExgServerInfo &s)
{
    QString id = s.id.toLower();
    if (id.contains("pve")) return 2;
    if (id.contains("event")) return 3;
    if (id.contains("hide")) return 4;
    if (id.startsWith("zed_mg")) return 27;
    if (id.startsWith("zed_misc")) return 28;
    if (id.contains("mg")) return 5;
    if (id.startsWith("zombie1_ze")) return 6;
    if (id.startsWith("zombie1_cs")) return 29;
    if (id.startsWith("zed_surf")) return 7;
    if (id.startsWith("zed_kz")) return 8;
    if (id.startsWith("ub_ze")) return 10;
    if (id.startsWith("ub_inf")) return 11;
    if (id.startsWith("ub_misc")) return 12;
    if (id.startsWith("ub_kz")) return 13;
    if (id.startsWith("ub_csgo")) return 14;
    if (id.startsWith("fys_ze")) return 15;
    if (id.startsWith("fys_fun")) return 16;
    if (id.startsWith("upkk_")) return 17;
    if (id.startsWith("zero_")) return 18;
    if (id.startsWith("exg_afk")) return 20;
    if (id.startsWith("zed_afk")) return 21;
    if (id.startsWith("ub_afk")) return 22;
    if (id.startsWith("fys_afk")) return 23;
    if (id.startsWith("star_afk")) return 24;
    if (id.startsWith("star_")) return 19;
    if (id.startsWith("xcq_paotu")) return 25;
    if (id.startsWith("liuyue_paotu")) return 26;
    QString subName = s.gameName.isEmpty() ? s.displayName : s.gameName;
    if (subName.contains("装备")) return 0;
    return 1;
}

static QString subTypeNameOf(int type)
{
    switch (type) {
    case 0: return "ZE装备服";
    case 1: return "ZE普通服";
    case 2: return "PVE模式";
    case 3: return "ZE活动服务器";
    case 4: return "躲猫猫模式";
    case 5: return "娱乐闯关MG";
    case 6: return "僵尸逃跑服";
    case 7: return "滑翔服surf";
    case 8: return "攀岩服Kz";
    case 9: return "csgo僵尸逃跑";
    case 10: return "UB僵尸逃跑";
    case 11: return "UB僵尸感染模式";
    case 12: return "女装混战";
    case 13: return "攀岩滑翔";
    case 14: return "CSGO僵尸逃跑";
    case 15: return "FyS僵尸逃跑";
    case 16: return "娱乐对抗";
    case 17: return "x社区";
    case 18: return "零次元社";
    case 19: return "scp-感染-叛乱";
    case 20: return "exg挂机服";
    case 21: return "zed挂机服";
    case 22: return "ub挂机服";
    case 23: return "fys挂机服";
    case 24: return "星社区挂机服";
    case 25: return "xcq跑图服务器";
    case 26: return "六月跑图服";
    case 27: return "娱乐闯关";
    case 28: return "娱乐混战";
    case 29: return "csgo服";
    default: return "未知";
    }
}

static QString subTypeColorOf(int type)
{
    switch (type) {
    case 0: return "38BDF8";
    case 1: return "34D399";
    case 2: return "A78BFA";
    case 3: return "F0B429";
    case 4: return "34D399";
    case 5: return "FB923C";
    case 6: return "EC4899";
    case 7: return "22D3EE";
    case 8: return "4ADE80";
    case 9: return "F87171";
    case 10: return "60A5FA";
    case 11: return "C084FC";
    case 12: return "F472B6";
    case 13: return "2DD4BF";
    case 14: return "FCA5A5";
    case 15: return "3B82F6";
    case 16: return "F59E0B";
    case 17: return "818CF8";
    case 18: return "34D399";
    case 19: return "FBBF24";
    case 20: return "38BDF8";
    case 21: return "EC4899";
    case 22: return "C084FC";
    case 23: return "F59E0B";
    case 24: return "FBBF24";
    case 25: return "22D3EE";
    case 26: return "4ADE80";
    case 27: return "FB923C";
    case 28: return "F472B6";
    case 29: return "60A5FA";
    default: return "4ADE80";
    }
}

int ServerManager::getSubGroupCount(int index)
{
    if (index < 0 || index >= m_model.count()) return 0;
    ExgServerInfo first = m_model.getServer(index);
    int targetType = serverSubTypeOf(first);
    QString community = first.community;
    int count = 0;
    for (int i = index; i < m_model.count(); i++) {
        ExgServerInfo s = m_model.getServer(i);
        if (s.community != community) break;
        if (serverSubTypeOf(s) != targetType) break;
        count++;
    }
    return count;
}

int ServerManager::findServerIndex(const QString &serverId)
{
    for (int i = 0; i < m_model.count(); i++) {
        ExgServerInfo s = m_model.getServer(i);
        if (s.id == serverId) return i;
    }
    return -1;
}

QVariantList ServerManager::communityGroups() const
{
    QVariantList groups;
    struct SubGroup { int type; QVariantList indexes; };
    QMap<QString, QList<SubGroup>> communityMap;
    QStringList order;
    for (int i = 0; i < m_model.count(); i++) {
        ExgServerInfo s = m_model.getServer(i);
        int st = serverSubTypeOf(s);
        if (!communityMap.contains(s.community)) {
            communityMap[s.community] = QList<SubGroup>();
            order.append(s.community);
        }
        QList<SubGroup> &sgs = communityMap[s.community];
        bool found = false;
        for (SubGroup &sg : sgs) {
            if (sg.type == st) {
                sg.indexes.append(i);
                found = true;
                break;
            }
        }
        if (!found) {
            SubGroup sg;
            sg.type = st;
            sg.indexes.append(i);
            sgs.append(sg);
        }
    }
    for (const QString &name : order) {
        QVariantMap g;
        g["name"] = name;
        QVariantList subgroups;
        for (const SubGroup &sg : communityMap[name]) {
            QVariantMap sm;
            sm["name"] = subTypeNameOf(sg.type);
            sm["color"] = subTypeColorOf(sg.type);
            sm["indexes"] = sg.indexes;
            subgroups.append(sm);
        }
        g["subgroups"] = subgroups;
        groups.append(g);
    }
    return groups;
}

void ServerManager::applyFilters()
{
    QList<ExgServerInfo> filtered = m_allServers;

    
    if (!m_searchText.isEmpty()) {
        QString search = m_searchText.toLower();
        filtered.erase(std::remove_if(filtered.begin(), filtered.end(),
            [&search](const ExgServerInfo &s) {
                return !s.displayName.toLower().contains(search)
                    && !s.displayNameCN.toLower().contains(search)
                    && !s.ip.contains(search)
                    && !s.map.toLower().contains(search);
            }), filtered.end());
    }

    
    if (m_hideOffline) {
        filtered.erase(std::remove_if(filtered.begin(), filtered.end(),
            [](const ExgServerInfo &s) { return s.status == 2; }), filtered.end());
    }

    
    auto isZET = [](const ExgServerInfo &s) {
        int t = serverSubTypeOf(s);
        return t==0||t==1||t==3||t==6||t==29||t==10||t==11||t==14||t==15||t==17||t==18||t==19;
    };
    auto isKZT = [](const ExgServerInfo &s) { int t=serverSubTypeOf(s); return t==5||t==8||t==13||t==27; };
    auto isSurfT = [](const ExgServerInfo &s) { return serverSubTypeOf(s)==7; };
    auto isMiscT = [](const ExgServerInfo &s) { int t=serverSubTypeOf(s); return t==5||t==12||t==16||t==28; };
    auto isHideT = [](const ExgServerInfo &s) { return serverSubTypeOf(s)==4; };

    if (m_filterOptions.contains("隐藏 ze 服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),isZET),filtered.end());
    if (m_filterOptions.contains("隐藏 kz 服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),isKZT),filtered.end());
    if (m_filterOptions.contains("隐藏 surf 服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),isSurfT),filtered.end());
    if (m_filterOptions.contains("隐藏混战服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),isMiscT),filtered.end());
    if (m_filterOptions.contains("隐藏躲猫猫服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),isHideT),filtered.end());
    if (m_filterOptions.contains("隐藏 0 人服"))
        filtered.erase(std::remove_if(filtered.begin(),filtered.end(),
            [](const ExgServerInfo &s){return s.currentPlayers==0;}),filtered.end());

    
    QHash<QString, QList<ExgServerInfo>> groups;
    for (const auto &s : filtered) {
        groups[s.community].append(s);
    }

    
    QList<ExgServerInfo> result;
    for (const QString &comm : m_communityOrder) {
        if (!groups.contains(comm)) continue;
        QList<ExgServerInfo> &group = groups[comm];
        std::stable_sort(group.begin(), group.end(),
            [&](const ExgServerInfo &a, const ExgServerInfo &b) -> bool {
                int aSub = serverSubTypeOf(a);
                int bSub = serverSubTypeOf(b);
                if (aSub != bSub) return aSub < bSub;
                int aRank = (a.status == 1) ? 0 : (a.status == 0) ? 1 : 2;
                int bRank = (b.status == 1) ? 0 : (b.status == 0) ? 1 : 2;
                if (m_sortMode == 1) {
                    if (a.currentPlayers != b.currentPlayers) return a.currentPlayers > b.currentPlayers;
                    return aRank < bRank;
                }
                if (m_sortMode == 2) {
                    if (a.currentPlayers != b.currentPlayers) return a.currentPlayers < b.currentPlayers;
                    return aRank < bRank;
                }
                if (aRank != bRank) return aRank < bRank;
                return false;
            });
        result.append(group);
        groups.remove(comm);
    }
    
    for (auto it = groups.begin(); it != groups.end(); ++it) {
        result.append(it.value());
    }

    m_model.setServers(result);
    m_modelVersion++;
    emit modelVersionChanged(m_modelVersion);
}

void ServerManager::setSearchText(const QString &text)
{
    if (m_searchText != text) {
        m_searchText = text;
        emit searchTextChanged(text);
        applyFilters();
    }
}

void ServerManager::setHideOffline(bool hide)
{
    if (m_hideOffline != hide) {
        m_hideOffline = hide;
        emit hideOfflineChanged(hide);
        applyFilters();
    }
}

void ServerManager::setSortMode(int mode)
{
    if (m_sortMode != mode) {
        m_sortMode = mode;
        emit sortModeChanged(mode);
        applyFilters();
    }
}

void ServerManager::setFilterOptions(const QStringList &opts)
{
    if (m_filterOptions != opts) {
        m_filterOptions = opts;
        emit filterOptionsChanged(opts);
        if (opts.contains("按人数排序")) {
            if (m_sortMode != 1) { m_sortMode = 1; emit sortModeChanged(1); }
        } else {
            if (m_sortMode != 0) { m_sortMode = 0; emit sortModeChanged(0); }
        }
        applyFilters();
    }
}

void ServerManager::refreshAll()
{
    if (m_refreshing) return;
    m_refreshing = true;
    emit refreshingChanged(true);
    m_refreshCountdown = 60;
    emit refreshCountdownChanged(m_refreshCountdown);

    qDeleteAll(m_activeQueries);
    m_activeQueries.clear();
    m_pendingServerIndexes.clear();

    for (int i = 0; i < m_allServers.size(); ++i) {
        m_pendingServerIndexes.append(i);
    }
    m_pendingQueries = m_allServers.size();

    startNextBatch();
}

void ServerManager::startNextBatch()
{
    const int batchSize = 5;
    int count = 0;
    while (!m_pendingServerIndexes.isEmpty() && count < batchSize) {
        int i = m_pendingServerIndexes.takeFirst();
        ServerQuery *q = new ServerQuery(this);
        connect(q, &ServerQuery::queryFinished, this, &ServerManager::onQueryFinished);
        connect(q, &ServerQuery::queryError, this, &ServerManager::onQueryError);
        m_activeQueries.append(q);

        int modelIdx = -1;
        for (int j = 0; j < m_model.count(); ++j) {
            if (m_model.getServer(j).id == m_allServers[i].id) {
                modelIdx = j;
                break;
            }
        }
        q->setProperty("serverIndex", i);
        q->setProperty("modelIndex", modelIdx);
        q->queryServer(m_allServers[i].ip, m_allServers[i].port);
        count++;
    }
}

void ServerManager::onQueryFinished(const ServerInfo &info)
{
    ServerQuery *q = qobject_cast<ServerQuery*>(sender());
    if (!q) return;

    int serverIdx = q->property("serverIndex").toInt();

    if (serverIdx >= 0 && serverIdx < m_allServers.size()) {
        
        qint64 baTime = m_baTime->getMapTime(m_allServers[serverIdx].ip, m_allServers[serverIdx].port);
        if (baTime <= 0) {
            
            QString srvName = m_allServers[serverIdx].gameName;
            if (srvName.isEmpty()) srvName = m_allServers[serverIdx].displayNameCN;
            if (!srvName.isEmpty()) baTime = m_baTime->getMapTimeByName(srvName);
        }
        m_allServers[serverIdx].hasBaTime = (baTime > 0);
        if (baTime > 0) {
            m_allServers[serverIdx].mapChangedAt = baTime / 1000;
        } else if (!info.mapName.isEmpty() && m_allServers[serverIdx].map != info.mapName) {
            m_allServers[serverIdx].mapChangedAt = QDateTime::currentSecsSinceEpoch();
        }
        m_allServers[serverIdx].currentPlayers = info.players;
        m_allServers[serverIdx].maxPlayers = info.maxPlayers;
        m_allServers[serverIdx].bots = info.bots;
        m_allServers[serverIdx].map = info.mapName;
        m_allServers[serverIdx].gameName = info.serverName;
        m_allServers[serverIdx].status = 1; 

        const ExgServerInfo &srv = m_allServers[serverIdx];
        
        QString srvName = srv.gameName.isEmpty() ? srv.displayNameCN : srv.gameName;
        emit serverMapUpdated(srv.ip, srv.port, srvName, srv.community,
                              srv.map, srv.currentPlayers, srv.maxPlayers);

        
        for (int i = 0; i < m_model.count(); i++) {
            ExgServerInfo mi = m_model.getServer(i);
            if (mi.ip == srv.ip && mi.port == srv.port) {
                m_model.updateServerStatus(i, srv.currentPlayers, srv.maxPlayers,
                    srv.bots, srv.map, srv.status, srv.gameName);
                break;
            }
        }
    }

    m_modelVersion++;
    emit modelVersionChanged(m_modelVersion);

    m_pendingQueries--;
    if (!m_pendingServerIndexes.isEmpty()) {
        m_batchTimer->start();
    }

    m_activeQueries.removeOne(q);
    q->deleteLater();

    if (m_pendingQueries <= 0) {
        m_refreshing = false;
        emit refreshingChanged(false);
        applyFilters(); 
    }
}

void ServerManager::onQueryError(const QString &error)
{
    Q_UNUSED(error);
    ServerQuery *q = qobject_cast<ServerQuery*>(sender());
    if (!q) return;

    int serverIdx = q->property("serverIndex").toInt();

    if (serverIdx >= 0 && serverIdx < m_allServers.size()) {
        m_allServers[serverIdx].status = 2; 
        const ExgServerInfo &srv = m_allServers[serverIdx];
        for (int i = 0; i < m_model.count(); i++) {
            ExgServerInfo mi = m_model.getServer(i);
            if (mi.ip == srv.ip && mi.port == srv.port) {
                m_model.updateServerStatus(i, 0, mi.maxPlayers, 0, mi.map, 2, QString());
                break;
            }
        }
    }

    m_modelVersion++;
    emit modelVersionChanged(m_modelVersion);

    m_pendingQueries--;
    if (!m_pendingServerIndexes.isEmpty()) {
        m_batchTimer->start();
    }

    m_activeQueries.removeOne(q);
    q->deleteLater();

    if (m_pendingQueries <= 0) {
        m_refreshing = false;
        emit refreshingChanged(false);
        applyFilters(); 
    }
}

void ServerManager::onAutoRefresh()
{
    if (m_refreshing) return; 
    if (m_refreshCountdown > 0) m_refreshCountdown--;
    if (m_refreshCountdown <= 0) {
        m_refreshCountdown = 60;
        if (!m_refreshing) refreshAll();
    }
    emit refreshCountdownChanged(m_refreshCountdown);
}

QString ServerManager::mapTranslate(const QString &mapName)
{
    if (mapName.isEmpty()) return QString();

    QString lower = mapName.toLower();

    
    int cutPos = lower.length();
    int vPos = lower.indexOf("_v");
    while (vPos >= 0) {
        if (vPos + 2 < lower.length() && lower.at(vPos + 2).isDigit()) {
            cutPos = vPos;
            break;
        }
        vPos = lower.indexOf("_v", vPos + 1);
    }

    QString base = lower.left(cutPos);

    
    while (true) {
        if (base.endsWith("_final")) { base.chop(6); continue; }
        if (base.endsWith("_fix")) { base.chop(4); continue; }
        if (base.endsWith("_p")) { base.chop(2); continue; }
        break;
    }

    
    QHash<QString, QString>::const_iterator it = m_mapDict.constFind(base);
    if (it != m_mapDict.constEnd()) return it.value();

    it = m_mapDict.constFind(lower);
    if (it != m_mapDict.constEnd()) return it.value();

    
    if (lower.startsWith("ze_")) return mapName.mid(3);
    return mapName;
}

void ServerManager::joinServer(int index, int protocol)
{
    ExgServerInfo s = m_model.getServer(index);
    if (s.ip.isEmpty()) return;
    ServerQuery::connectToServer(s.ip, s.port, "", protocol);
    QString realName = s.gameName.isEmpty() ? s.displayNameCN : s.gameName;
    emit serverJoined(s.ip, s.port, realName);
}

void ServerManager::copyAddress(int index)
{
    ExgServerInfo s = m_model.getServer(index);
    if (s.ip.isEmpty()) return;
    QGuiApplication::clipboard()->setText(QString("%1:%2").arg(s.ip).arg(s.port));
}

QStringList ServerManager::communities()
{
    QStringList list;
    QSet<QString> seen;
    for (const ExgServerInfo &s : m_allServers) {
        if (!seen.contains(s.community)) {
            seen.insert(s.community);
            list.append(s.community);
        }
    }
    return list;
}

QVariantList ServerManager::communityServers(const QString &community)
{
    QVariantList list;
    for (int i = 0; i < m_model.count(); ++i) {
        QVariantMap s = m_model.get(i);
        if (s["community"].toString() == community) {
            list.append(s);
        }
    }
    return list;
}

