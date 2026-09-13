#include "mapsubscriptionmanager.h"
#include "maptranslations.h"
#include <QRegularExpression>
#include <QTimer>
#include <QHash>
#include <QStandardPaths>
#include <QDir>

static QHash<QString, QString> &translationDict()
{
    static QHash<QString, QString> dict;
    if (dict.isEmpty()) initMapTranslations(dict);
    return dict;
}

static QString translateMap(const QString &mapName)
{
    QString name = mapName.trimmed();
    if (name.isEmpty()) return "";
    QString lower = name.toLower();
    if (translationDict().contains(lower)) return translationDict().value(lower);
    
    static QRegularExpression re("_v\\d+(?=_|$)");
    QString stripped = lower;
    stripped.remove(re);
    if (translationDict().contains(stripped)) return translationDict().value(stripped);
    return name;
}

MapSubscriptionManager::MapSubscriptionManager(QObject *parent)
    : QObject(parent)
    , m_settings(new QSettings(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/subscriptions.ini", QSettings::IniFormat, this))
    , m_notificationsEnabled(true)
{
    m_allMapNames = translationDict().keys();
    m_allMapNames.sort(Qt::CaseInsensitive);
    qDebug() << "[MapSubMgr] loaded map names:" << m_allMapNames.size();
    loadSubscriptions();
}

MapSubscriptionManager::~MapSubscriptionManager()
{
    saveSubscriptions();
}

void MapSubscriptionManager::loadSubscriptions()
{
    m_subscribedMaps = m_settings->value("MapSubscriptions/list").toStringList();
    qDebug() << "[MapSub] loaded subscriptions:" << m_subscribedMaps;
}

void MapSubscriptionManager::saveSubscriptions()
{
    m_settings->setValue("MapSubscriptions/list", m_subscribedMaps);
    m_settings->sync();
}

SubEntry MapSubscriptionManager::parseEntry(const QString &raw)
{
    SubEntry s;
    QString t = raw.trimmed();
    if (t.isEmpty()) return s;

    static const QStringList communityKeywords = {"exg pve", "exg", "zed", "ub", "fys", "upkk", "zero", "国际"};

    int colon = t.indexOf(':');
    if (colon > 0) {
        QString c = t.left(colon).trimmed().toLower();
        if (communityKeywords.contains(c)) {
            s.community = c;
            s.mapKeyword = t.mid(colon + 1).trimmed();
            return s;
        }
    }

    int space = t.indexOf(' ');
    if (space > 0) {
        QString c = t.left(space).trimmed().toLower();
        if (communityKeywords.contains(c)) {
            s.community = c;
            s.mapKeyword = t.mid(space + 1).trimmed();
            return s;
        }
    }

    s.community.clear();
    s.mapKeyword = t;
    return s;
}

QString MapSubscriptionManager::stripMapVersion(const QString &mapName)
{
    QString name = mapName.trimmed().toLower();
    
    static QRegularExpression re("_v\\d+(?=_|$)");
    name.remove(re);
    static QRegularExpression re2("_final\\d*(?=_|$)");
    name.remove(re2);
    static QRegularExpression re3("_fix\\d*(?=_|$)");
    name.remove(re3);
    static QRegularExpression re4("_b\\d+(?=_|$)");
    name.remove(re4);
    static QRegularExpression re5("_rc\\d*(?=_|$)");
    name.remove(re5);
    static QRegularExpression re6("_a\\d+(?=_|$)");
    name.remove(re6);
    static QRegularExpression re7("_test\\d*(?=_|$)");
    name.remove(re7);
    static QRegularExpression re8("_demo\\d*(?=_|$)");
    name.remove(re8);
    static QRegularExpression re9("_\\d{4}(?=_|$)");
    name.remove(re9);
    static QRegularExpression re10("_v\\d+_\\d+(?=_|$)");
    name.remove(re10);
    return name;
}

bool MapSubscriptionManager::communityMatches(const QString &serverCommunity, const QString &subCommunity)
{
    if (subCommunity.isEmpty()) return true;
    QString sc = serverCommunity.toLower();
    QString sub = subCommunity.toLower();

    if (sub == "exg pve") {
        return sc.contains("pve");
    } else if (sub == "exg") {
        return sc.contains("exg") && !sc.contains("pve");
    } else {
        return sc.contains(sub);
    }
}

void MapSubscriptionManager::addSubscription(const QString &mapKeyword, const QString &community)
{
    QString kw = mapKeyword.trimmed();
    if (kw.isEmpty()) return;

    QString entry;
    if (!community.isEmpty() && community != "全部社区") {
        entry = community + ":" + kw;
    } else {
        entry = kw;
    }

    QString lower = entry.toLower();
    for (const QString &s : m_subscribedMaps) {
        if (s.toLower() == lower) return;
    }

    m_subscribedMaps.append(entry);
    qDebug() << "[MapSub] added subscription:" << entry << "| community param:" << community;
    saveSubscriptions();
    emit subscribedMapsChanged();
}

void MapSubscriptionManager::removeSubscription(int index)
{
    if (index < 0 || index >= m_subscribedMaps.size()) return;
    m_subscribedMaps.removeAt(index);
    saveSubscriptions();
    emit subscribedMapsChanged();
}

void MapSubscriptionManager::clearSubscriptions()
{
    m_subscribedMaps.clear();
    m_lastNotifiedMap.clear();
    saveSubscriptions();
    emit subscribedMapsChanged();
}

void MapSubscriptionManager::setNotificationsEnabled(bool e)
{
    if (m_notificationsEnabled != e) {
        m_notificationsEnabled = e;
        emit notificationsEnabledChanged(e);
    }
}

void MapSubscriptionManager::checkServerMap(const QString &ip, int port, const QString &serverName,
                                              const QString &community, const QString &mapName,
                                              int currentPlayers, int maxPlayers)
{
    if (!mapName.isEmpty()) addServerMap(mapName);
    if (mapName.isEmpty() || m_subscribedMaps.isEmpty()) return;

    QString mapBase = stripMapVersion(mapName);
    QString matched;

    for (const QString &sub : m_subscribedMaps) {
        SubEntry entry = parseEntry(sub);
        QString kwBase = stripMapVersion(entry.mapKeyword);
        if (kwBase.isEmpty()) continue;
        bool commOk = communityMatches(community, entry.community);
        if (!commOk) {
            qDebug() << "[MapSub] skip (community mismatch):" << sub << "| server community:" << community;
            continue;
        }
        if (mapBase == kwBase) {
            matched = sub;
            qDebug() << "[MapSub] MATCHED:" << sub << "| server:" << serverName << "map:" << mapName;
            break;
        }
    }

    QString key = ip + ":" + QString::number(port);
    if (matched.isEmpty()) {
        m_lastNotifiedMap.remove(key);
        return;
    }

    if (m_lastNotifiedMap.value(key) == matched) {
        qDebug() << "[MapSub] skip (already notified):" << matched << "for" << key;
        return;
    }
    m_lastNotifiedMap[key] = matched;
    qDebug() << "[MapSub] EMITTING notification for:" << matched;

    
    QString mapCN = translateMap(mapName);
    if (mapCN.isEmpty() || mapCN == mapName) mapCN = mapName;

    QString title = "订阅地图出现";
    QString players = (maxPlayers > 0)
            ? QString("%1/%2").arg(currentPlayers).arg(maxPlayers)
            : "--";
    QString comm = community.isEmpty() ? "未知社区" : community;
    QString msg = QString("社区：%1\n服务器：%2\n地图：%4「%3」\n人数：%5")
            .arg(comm, serverName, mapCN, mapName, players);

    emit subscriptionDetected(title, msg, ip, port);
    if (m_notificationsEnabled) {
        emit notificationRequested(title, msg);
    }
}

void MapSubscriptionManager::testNotification()
{
    emit notificationRequested("订阅地图测试",
                               "社区：EXG\n服务器：ZE装备 #1\n地图：ze_pirates_port_royal「加勒比海盗」\n人数：5/64");
}

QString MapSubscriptionManager::translateMap(const QString &name)
{
    return ::translateMap(name);
}

void MapSubscriptionManager::addServerMap(const QString &mapName)
{
    QString base = stripMapVersion(mapName).trimmed();
    if (base.isEmpty()) return;
    if (!m_allMapNames.contains(base, Qt::CaseInsensitive)) {
        m_allMapNames.append(base);
        emit allMapNamesChanged();
    }
}

