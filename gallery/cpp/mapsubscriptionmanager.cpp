#include "mapsubscriptionmanager.h"
#include "langmanager.h"
#include <QRegularExpression>
#include <QDir>
#include <QStringList>


QString translateMapZh(const QString &name);
QStringList mapTranslationNames();

bool MapSubscriptionManager::isEn() const
{
    return m_lang && m_lang->isEn();
}

MapSubscriptionManager::MapSubscriptionManager(const QString &cfgDir, QObject *parent)
    : QObject(parent)
    , m_settings(new QSettings(cfgDir + QStringLiteral("/subscriptions.ini"), QSettings::IniFormat, this))
    , m_notificationsEnabled(true)
{
    m_allMapNames = mapTranslationNames();
    m_allMapNames.sort(Qt::CaseInsensitive);
    loadSubscriptions();
}

MapSubscriptionManager::~MapSubscriptionManager()
{
    saveSubscriptions();
}

void MapSubscriptionManager::loadSubscriptions()
{
    m_subscribedMaps = m_settings->value(QStringLiteral("MapSubscriptions/list")).toStringList();
}

void MapSubscriptionManager::saveSubscriptions()
{
    m_settings->setValue(QStringLiteral("MapSubscriptions/list"), m_subscribedMaps);
    m_settings->sync();
}

MapSubscriptionManager::SubEntry MapSubscriptionManager::parseEntry(const QString &raw) const
{
    SubEntry s;
    QString t = raw.trimmed();
    if (t.isEmpty()) return s;

    static const QStringList communityKeywords = {
        QStringLiteral("exg"), QStringLiteral("zed"), QStringLiteral("ub"),
        QStringLiteral("fys"), QStringLiteral("upkk"), QStringLiteral("star"),
        QStringLiteral("international"), QStringLiteral("maprun")
    };

    int colon = t.indexOf(':');
    if (colon > 0) {
        QString c = t.left(colon).trimmed().toLower();
        if (communityKeywords.contains(c)) {
            s.community = c;
            s.mapKeyword = t.mid(colon + 1).trimmed();
            return s;
        }
    }
    s.community.clear();
    s.mapKeyword = t;
    return s;
}

QString MapSubscriptionManager::stripMapVersion(const QString &mapName) const
{
    QString name = mapName.trimmed().toLower();
    static const QRegularExpression re("_v\\d+(?=_|$)");
    name.remove(re);
    static const QRegularExpression re2("_final\\d*(?=_|$)");
    name.remove(re2);
    static const QRegularExpression re3("_fix\\d*(?=_|$)");
    name.remove(re3);
    static const QRegularExpression re4("_b\\d+(?=_|$)");
    name.remove(re4);
    static const QRegularExpression re5("_rc\\d*(?=_|$)");
    name.remove(re5);
    static const QRegularExpression re6("_a\\d+(?=_|$)");
    name.remove(re6);
    static const QRegularExpression re7("_test\\d*(?=_|$)");
    name.remove(re7);
    static const QRegularExpression re8("_demo\\d*(?=_|$)");
    name.remove(re8);
    static const QRegularExpression re9("_\\d{4}(?=_|$)");
    name.remove(re9);
    static const QRegularExpression re10("_v\\d+_\\d+(?=_|$)");
    name.remove(re10);
    return name;
}

bool MapSubscriptionManager::communityMatches(const QString &serverCommunity, const QString &subCommunity) const
{
    if (subCommunity.isEmpty()) return true;
    QString sc = serverCommunity.toLower();
    QString sub = subCommunity.toLower();
    return sc.contains(sub);
}

bool MapSubscriptionManager::isSubscribed(const QString &mapName, const QString &community) const
{
    if (mapName.isEmpty() || m_subscribedMaps.isEmpty())
        return false;
    const QString mapBase = stripMapVersion(mapName);
    for (const QString &sub : m_subscribedMaps) {
        const SubEntry entry = parseEntry(sub);
        const QString kwBase = stripMapVersion(entry.mapKeyword);
        if (kwBase.isEmpty())
            continue;
        if (!communityMatches(community, entry.community))
            continue;
        if (mapBase == kwBase)
            return true;
    }
    return false;
}

int MapSubscriptionManager::parsePlayers(const QString &playersText, bool max)
{

    QString t = playersText.trimmed();
    const QStringList parts = t.split('/');
    static const QRegularExpression nonDigit(QStringLiteral("[^0-9]"));
    if (parts.size() >= 3 && parts.at(1).contains(QLatin1String("bot"))) {
        return max ? parts.at(2).trimmed().toInt() : QString(parts.at(0)).remove(nonDigit).toInt();
    }
    if (parts.size() >= 2) {
        return max ? parts.at(1).trimmed().toInt() : QString(parts.at(0)).remove(nonDigit).toInt();
    }
    return 0;
}

void MapSubscriptionManager::addSubscription(const QString &mapKeyword, const QString &community)
{
    QString kw = mapKeyword.trimmed();
    if (kw.isEmpty()) return;

    QString entry;
    if (!community.isEmpty() && community != QStringLiteral("全部社区"))
        entry = community + QLatin1Char(':') + kw;
    else
        entry = kw;

    const QString lower = entry.toLower();
    for (const QString &s : m_subscribedMaps) {
        if (s.toLower() == lower) return;
    }
    m_subscribedMaps.append(entry);
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

void MapSubscriptionManager::checkAll(const QVariantList &groups, const QString &communityKey)
{
    for (const QVariant &gv : groups) {
        const QVariantMap g = gv.toMap();
        const QVariantList servers = g.value(QStringLiteral("servers")).toList();
        for (const QVariant &sv : servers) {
            const QVariantMap m = sv.toMap();
            if (!m.value(QStringLiteral("online")).toBool()) continue;
            const QString ip = m.value(QStringLiteral("ip")).toString();
            const QString map = m.value(QStringLiteral("map")).toString();
            if (map.isEmpty() || map == QStringLiteral("--")) continue;
            const QString hp = ip;
            int port = 0;
            const int c = hp.lastIndexOf(':');
            if (c > 0) port = hp.mid(c + 1).toInt();
            const QString name = m.value(QStringLiteral("name")).toString();
            const QString playersText = m.value(QStringLiteral("players")).toString();
            checkServerMap(hp.left(c), port, name, communityKey, map,
                           parsePlayers(playersText, false), parsePlayers(playersText, true));
        }
    }
}

void MapSubscriptionManager::checkServerMap(const QString &ip, int port, const QString &serverName,
                                            const QString &community, const QString &mapName,
                                            int currentPlayers, int maxPlayers)
{
    if (mapName.isEmpty() || m_subscribedMaps.isEmpty()) return;

    const QString mapBase = stripMapVersion(mapName);
    QString matched;

    for (const QString &sub : m_subscribedMaps) {
        const SubEntry entry = parseEntry(sub);
        const QString kwBase = stripMapVersion(entry.mapKeyword);
        if (kwBase.isEmpty()) continue;
        if (!communityMatches(community, entry.community)) continue;
        if (mapBase == kwBase) {
            matched = sub;
            break;
        }
    }

    const QString key = ip + QLatin1Char(':') + QString::number(port);
    if (matched.isEmpty()) {
        m_lastNotifiedMap.remove(key);
        return;
    }
    if (m_lastNotifiedMap.value(key) == matched)
        return;
    m_lastNotifiedMap[key] = matched;

    const QString mapCN = translateMapZh(mapName);
    QString title, msg;
    if (isEn()) {
        title = QStringLiteral("Subscribed map appeared");
        const QString players = maxPlayers > 0
                ? QStringLiteral("%1/%2").arg(currentPlayers).arg(maxPlayers)
                : QStringLiteral("--");
        const QString comm = community.isEmpty() ? QStringLiteral("Unknown community") : community;

        msg = QStringLiteral("Community: %1\nServer: %2\nMap: %3\nPlayers: %4")
                .arg(comm, serverName, mapName, players);
    } else {
        title = QStringLiteral("订阅地图出现");
        const QString players = maxPlayers > 0
                ? QStringLiteral("%1/%2").arg(currentPlayers).arg(maxPlayers)
                : QStringLiteral("--");
        const QString comm = community.isEmpty() ? QStringLiteral("未知社区") : community;
        msg = QStringLiteral("社区：%1\n服务器：%2\n地图：%4「%3」\n人数：%5")
                .arg(comm, serverName, mapCN, mapName, players);
    }
    if (m_notificationsEnabled)
        emit notificationRequested(title, msg);
}

void MapSubscriptionManager::testNotification()
{
    if (isEn())
        emit notificationRequested(QStringLiteral("Subscription test"),
                                   QStringLiteral("Community: EXG\nServer: ZE Gear #1\nMap: ze_pirates_port_royal\nPlayers: 5/64"));
    else
        emit notificationRequested(QStringLiteral("订阅地图测试"),
                                   QStringLiteral("社区：EXG社区\n服务器：ZE装备 #1\n地图：ze_pirates_port_royal「加勒比海盗」\n人数：5/64"));
}

QString MapSubscriptionManager::translateMap(const QString &name)
{
    const QString zh = translateMapZh(name);
    if (zh.isEmpty()) return name;
    return name + QStringLiteral("\u300c") + zh + QStringLiteral("\u300d");
}
