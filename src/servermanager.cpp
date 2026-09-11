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
            if (baTime > 0) {
                m_allServers[i].mapChangedAt = baTime / 1000;
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
        {"exg_ze01", "ZE装备 #1", "ZE装备 #1", "", "202.189.4.212", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze02", "ZE装备 #2", "ZE装备 #2", "", "202.189.4.212", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze05", "ZE装备 #5", "ZE装备 #5", "", "202.189.4.230", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze06", "ZE装备 #6 [热门]", "ZE装备 #6 [热门]", "", "202.189.4.230", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze07", "ZE装备 #7", "ZE装备 #7", "", "202.189.10.196", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze08", "ZE装备 #8", "ZE装备 #8", "", "202.189.10.196", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze09", "ZE装备 #9", "ZE装备 #9", "", "202.189.5.221", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze10", "ZE装备 #10", "ZE装备 #10", "", "202.189.10.203", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze11", "ZE装备 #11", "ZE装备 #11", "", "202.189.10.208", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze12", "ZE装备 #12", "ZE装备 #12", "", "202.189.5.225", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze13", "ZE装备 #13", "ZE装备 #13", "", "202.189.5.227", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze14", "ZE装备 #14", "ZE装备 #14", "", "202.189.5.236", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze16", "ZE装备 #16", "ZE装备 #16", "", "202.189.10.208", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze17", "ZE装备 #17", "ZE装备 #17", "", "202.189.5.225", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze18", "ZE装备 #18", "ZE装备 #18", "", "202.189.5.227", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze19", "ZE装备 #19", "ZE装备 #19", "", "202.189.5.236", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze23", "ZE装备 #23", "ZE装备 #23", "", "202.189.4.110", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze24", "ZE装备 #24", "ZE装备 #24", "", "202.189.4.110", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze_n02", "ZE #2", "ZE #2", "", "202.189.10.85", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze_n03", "ZE #3", "ZE #3", "", "202.189.4.124", 27001, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"exg_ze_n04", "ZE #4", "ZE #4", "", "202.189.4.124", 27002, "山东", "ZE", "ExG服务器装备/普通", 0, 64, 0, "", "", 0},
        {"zombie1_ze01", "僵尸逃跑 #1", "僵尸逃跑 #1", "", "cs1.zombieden.cn", 27016, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_ze02", "僵尸逃跑 #2", "僵尸逃跑 #2", "", "cs3.zombieden.cn", 27015, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_ze03", "僵尸逃跑 #3", "僵尸逃跑 #3", "", "cs3.zombieden.cn", 27016, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_ze04", "僵尸逃跑 #4", "僵尸逃跑 #4", "", "cs5.zombieden.cn", 27015, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_ze05", "僵尸逃跑 #5", "僵尸逃跑 #5", "", "cs5.zombieden.cn", 27016, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_cs01", "[CS]僵尸逃跑 #1", "[CS]僵尸逃跑 #1", "", "cs2.zombieden.cn", 27050, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"zombie1_cs02", "[CS]僵尸逃跑 #2", "[CS]僵尸逃跑 #2", "", "cs2.zombieden.cn", 27051, "山东", "ZE", "ZED僵尸乐园服务器", 0, 64, 0, "", "", 0},
        {"ub_ze01", "僵尸逃跑 #01", "僵尸逃跑 #01", "", "110.42.9.188", 27011, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze02", "僵尸逃跑 #02", "僵尸逃跑 #02", "", "110.42.9.188", 27021, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze03", "僵尸逃跑 #03", "僵尸逃跑 #03", "", "110.42.9.188", 27031, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze05", "僵尸逃跑 #05", "僵尸逃跑 #05", "", "110.42.9.127", 27051, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze06", "僵尸逃跑 #06", "僵尸逃跑 #06", "", "110.42.9.127", 27061, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze07", "僵尸逃跑 #07", "僵尸逃跑 #07", "", "110.42.9.127", 27071, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze11", "僵尸逃跑 #11", "僵尸逃跑 #11", "", "110.42.9.195", 27111, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze12", "僵尸逃跑 #12", "僵尸逃跑 #12", "", "110.42.9.195", 27121, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze13", "僵尸逃跑 #13", "僵尸逃跑 #13", "", "110.42.9.195", 27131, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze17", "UB社区 #17", "UB社区 #17", "", "103.45.130.84", 27017, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"ub_ze27", "UB社区 #27", "UB社区 #27", "", "110.42.9.195", 27027, "山东", "ZE", "UB服务器", 0, 64, 0, "", "", 0},
        {"fys_ze01", "僵尸逃跑 01# 大逃杀", "僵尸逃跑 01# 大逃杀", "", "110.42.9.155", 27015, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze02", "僵尸逃跑 02# 大逃杀", "僵尸逃跑 02# 大逃杀", "", "110.42.9.203", 27025, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze03", "僵尸逃跑 03# 大逃杀", "僵尸逃跑 03# 大逃杀", "", "110.42.9.139", 27035, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze04", "僵尸逃跑 04# 大逃杀", "僵尸逃跑 04# 大逃杀", "", "110.42.9.138", 27045, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze05", "僵尸逃跑 05# 大逃杀", "僵尸逃跑 05# 大逃杀", "", "110.42.9.138", 27055, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze06", "僵尸逃跑 06# 大逃杀", "僵尸逃跑 06# 大逃杀", "", "110.42.9.107", 27065, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze07", "僵尸逃跑 07# 大逃杀", "僵尸逃跑 07# 大逃杀", "", "110.42.9.139", 27075, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze08", "僵尸逃跑 08# 大逃杀", "僵尸逃跑 08# 大逃杀", "", "110.42.9.107", 27085, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze09", "僵尸逃跑 09# 大逃杀", "僵尸逃跑 09# 大逃杀", "", "110.42.9.203", 27095, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze10", "僵尸逃跑 10# 大逃杀", "僵尸逃跑 10# 大逃杀", "", "110.42.9.107", 27105, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze13", "僵尸逃跑 13# 大逃杀", "僵尸逃跑 13# 大逃杀", "", "110.42.9.155", 28000, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"fys_ze15", "僵尸逃跑 15# 大逃杀", "僵尸逃跑 15# 大逃杀", "", "110.42.9.52", 29000, "山东", "ZE", "FyS服务器", 0, 64, 0, "", "", 0},
        {"exg_pve01", "PVE模式 #1", "PVE模式 #1", "", "202.189.5.229", 27001, "山东", "ZE", "EXG PVE服务器", 0, 64, 0, "", "", 0},
        {"exg_pve02", "PVE模式 #2", "PVE模式 #2", "", "202.189.5.229", 27002, "山东", "ZE", "EXG PVE服务器", 0, 64, 0, "", "", 0},
        {"exg_pve03", "PVE模式 #3", "PVE模式 #3", "", "202.189.5.229", 27003, "山东", "ZE", "EXG PVE服务器", 0, 64, 0, "", "", 0},
        {"exg_pve04", "PVE模式 #4", "PVE模式 #4", "", "202.189.5.229", 27004, "山东", "ZE", "EXG PVE服务器", 0, 64, 0, "", "", 0},
        {"exg_pve05", "PVE模式 #5", "PVE模式 #5", "", "103.45.134.202", 27005, "湖北", "ZE", "EXG PVE服务器", 0, 64, 0, "", "", 0},
        {"exg_event01", "僵尸逃跑 活动#1", "僵尸逃跑 活动#1", "", "202.189.5.221", 27008, "山东", "ZE", "EXG活动服务器", 0, 64, 0, "", "", 0},
        {"exg_event02", "僵尸逃跑 活动#1 备用", "僵尸逃跑 活动#1 备用", "", "202.189.5.212", 27008, "山东", "ZE", "EXG活动服务器", 0, 64, 0, "", "", 0},
        {"upkk_ze01", "[UPKK] CS2 僵尸逃跑 #1", "[UPKK] CS2 僵尸逃跑 #1", "", "cs2ze.upkk.com", 27015, "台湾", "ZE", "UPKK/Zero服务器", 0, 64, 0, "", "", 0},
        {"zero_ze01", "Zero #1", "Zero #1", "", "43.248.117.109", 27015, "海外", "ZE", "UPKK/Zero服务器", 0, 64, 0, "", "", 0},
        {"intl_gfl", "GFL Zombie Escape", "GFL Zombie Escape", "", "74.91.124.21", 27015, "美国", "ZE", "国际服", 0, 64, 0, "", "", 0},
        {"intl_mapeadores", "[EU] MAPEADORES ZE", "[EU] MAPEADORES ZE", "", "87.98.228.196", 27040, "欧洲", "ZE", "国际服", 0, 64, 0, "", "", 0},
        {"intl_possession", "POSSESSION [PSE]", "POSSESSION [PSE]", "", "103.62.49.55", 27015, "东南亚", "ZE", "国际服", 0, 64, 0, "", "", 0},
        {"intl_rss", "[RSS] Zombie Escape", "[RSS] Zombie Escape", "", "14.6.92.207", 27015, "韩国", "ZE", "国际服", 0, 64, 0, "", "", 0},
        {"zed_surf01", "SURF滑翔 #1 简单", "SURF滑翔 #1 简单", "", "cs1.zombieden.cn", 27019, "山东", "ZE", "ZED滑翔攀岩服务器", 0, 64, 0, "", "", 0},
        {"zed_surf02", "SURF滑翔 #2 困难", "SURF滑翔 #2 困难", "", "cs1.zombieden.cn", 27020, "山东", "ZE", "ZED滑翔攀岩服务器", 0, 64, 0, "", "", 0},
        {"zed_kz01", "KZ攀岩#1", "KZ攀岩#1", "", "cs2.zombieden.cn", 27090, "山东", "ZE", "ZED滑翔攀岩服务器", 0, 64, 0, "", "", 0},
        {"zed_kz02", "KZ攀岩#2", "KZ攀岩#2", "", "cs2.zombieden.cn", 27091, "山东", "ZE", "ZED滑翔攀岩服务器", 0, 64, 0, "", "", 0},
        {"zed_kz03", "KZ攀岩#3", "KZ攀岩#3", "", "cs2.zombieden.cn", 27092, "山东", "ZE", "ZED滑翔攀岩服务器", 0, 64, 0, "", "", 0},
        {"exg_afk01", "EXG挂机大厅 #1", "EXG挂机大厅 #1", "", "202.189.10.86", 27001, "山东", "ZE", "挂机服务器", 0, 64, 0, "", "", 0},
        {"exg_afk02", "EXG挂机大厅 #2", "EXG挂机大厅 #2", "", "202.189.10.86", 27002, "山东", "ZE", "挂机服务器", 0, 64, 0, "", "", 0},
        {"exg_afk03", "EXG挂机大厅 #3", "EXG挂机大厅 #3", "", "202.189.10.86", 27003, "山东", "ZE", "挂机服务器", 0, 64, 0, "", "", 0},
        {"zed_afk01", "ZED挂机幻想乡大厅", "ZED挂机幻想乡大厅", "", "cs1.zombieden.cn", 27015, "山东", "ZE", "挂机服务器", 0, 64, 0, "", "", 0},
        {"paotu_01", "xcq跑图服", "xcq跑图服", "", "frp-ten.com", 55612, "跑图", "ZE", "ze跑图服务器", 0, 64, 0, "", "", 0},
        {"paotu_02", "xcq跑图服", "xcq跑图服", "", "frp-ten.com", 63527, "跑图", "ZE", "ze跑图服务器", 0, 64, 0, "", "", 0},
        {"paotu_03", "六月跑图服", "六月跑图服", "", "101.35.9.103", 27015, "跑图", "ZE", "ze跑图服务器", 0, 64, 0, "", "", 0},
    };

    m_allServers.append(allServers);
}

void ServerManager::initCommunityOrder()
{
    m_communityOrder.clear();
    for (const auto &s : m_allServers) {
        if (!m_communityOrder.contains(s.community)) {
            m_communityOrder.append(s.community);
        }
    }
}

void ServerManager::loadCommunityOrder()
{
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/serverlist.ini", QSettings::IniFormat);
    QStringList saved = settings.value("communityOrder").toStringList();
    if (!saved.isEmpty()) {
        
        initCommunityOrder();
        QStringList merged;
        for (const QString &c : saved) {
            if (m_communityOrder.contains(c) && !merged.contains(c)) {
                merged.append(c);
            }
        }
        for (const QString &c : m_communityOrder) {
            if (!merged.contains(c)) merged.append(c);
        }
        m_communityOrder = merged;
    } else {
        initCommunityOrder();
    }
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
                
                int aRank = (a.status == 1) ? 0 : (a.status == 0) ? 1 : 2;
                int bRank = (b.status == 1) ? 0 : (b.status == 0) ? 1 : 2;
                if (aRank != bRank) return aRank < bRank;
                if (m_sortMode == 1) return a.currentPlayers > b.currentPlayers;
                if (m_sortMode == 2) return a.currentPlayers < b.currentPlayers;
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

void ServerManager::joinServer(int index)
{
    ExgServerInfo s = m_model.getServer(index);
    if (s.ip.isEmpty()) return;
    ServerQuery::connectToServer(s.ip, s.port);
    emit serverJoined(s.ip, s.port, s.displayNameCN);
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