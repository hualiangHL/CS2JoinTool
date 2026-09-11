#include "mapcooldownmanager.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QSslConfiguration>
#include <QSslError>

MapCooldownManager::MapCooldownManager(QObject *parent)
    : QObject(parent)
{
    m_manager = new QNetworkAccessManager(this);
}

void MapCooldownManager::setSearchText(const QString &text)
{
    if (m_searchText != text) {
        m_searchText = text;
        emit searchTextChanged();
        applyFilter();
    }
}

void MapCooldownManager::setOnlyCooling(bool only)
{
    if (m_onlyCooling != only) {
        m_onlyCooling = only;
        emit onlyCoolingChanged();
        applyFilter();
    }
}

QString MapCooldownManager::formatCooldown(int minutes)
{
    if (minutes <= 0) return "无";
    if (minutes < 180) return QString("%1分钟").arg(minutes);
    if (minutes < 4320) return QString("%1小时").arg(minutes / 60.0, 0, 'f', 1);
    return QString("%1天").arg(minutes / 1440.0, 0, 'f', 1);
}

void MapCooldownManager::refresh()
{
    if (m_loading) return;

    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }

    m_loading = true;
    m_error.clear();
    emit loadingChanged();
    emit errorChanged();

    QNetworkRequest request(QUrl("https://list.darkrp.cn:9000/ServerList/CurrentCs2MapStatus"));
    request.setHeader(QNetworkRequest::UserAgentHeader, "CS2JoinToolV4/1.0");
    QSslConfiguration sslConfig = QSslConfiguration::defaultConfiguration();
    sslConfig.setPeerVerifyMode(QSslSocket::VerifyNone);
    request.setSslConfiguration(sslConfig);

    m_currentReply = m_manager->get(request);
    connect(m_currentReply, &QNetworkReply::sslErrors, m_currentReply,
            [](const QList<QSslError> &) { });
    connect(m_currentReply, &QNetworkReply::finished, this, &MapCooldownManager::onReplyFinished);
}

QString MapCooldownManager::getMapDifficulty(const QString &mapName)
{
    QString name = mapName.trimmed().toLower();
    if (name.isEmpty()) return "";
    for (const QVariant &v : m_allMaps) {
        QVariantMap m = v.toMap();
        if (m.value("enName").toString().toLower() == name) {
            return m.value("difficulty").toString();
        }
    }
    return "";
}

void MapCooldownManager::onReplyFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    m_loading = false;
    emit loadingChanged();

    if (reply->error() != QNetworkReply::NoError) {
        m_error = "加载失败：" + reply->errorString();
        emit errorChanged();
        reply->deleteLater();
        m_currentReply = nullptr;
        return;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();
    m_currentReply = nullptr;

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isArray()) {
        m_error = "数据解析失败";
        emit errorChanged();
        return;
    }

    QJsonArray array = doc.array();
    QDateTime now = QDateTime::currentDateTime();
    m_allMaps.clear();

    for (const QJsonValue &val : array) {
        if (!val.isObject()) continue;
        QJsonObject obj = val.toObject();

        QString enName = obj.value("Name").toString();
        QString cnName = obj.value("CnName").toString();
        QString displayName = cnName.isEmpty() ? enName : enName + " [" + cnName + "]";
        QString achievement = obj.value("Achievement10").toString("-");
        QString difficulty = obj.value("DifficultyName").toString();
        int cooldownMin = obj.value("CooldownMinute").toInt();
        QString cooldownStr = formatCooldown(cooldownMin);

        QString lastRunStr = obj.value("LastRun").toString();
        QDateTime lastRun = QDateTime::fromString(lastRunStr, Qt::ISODate);
        QString cooldownEnd = "无";
        bool isCooling = false;

        if (lastRun.isValid() && cooldownMin > 0) {
            QDateTime endTime = lastRun.addSecs(cooldownMin * 60);
            if (endTime > now) {
                cooldownEnd = endTime.toString("MM-dd HH:mm:ss");
                isCooling = true;
            }
        }

        QVariantMap map;
        map["displayName"] = displayName;
        map["enName"] = enName;
        map["cnName"] = cnName;
        map["achievement"] = achievement;
        map["difficulty"] = difficulty;
        map["cooldown"] = cooldownStr;
        map["cooldownMinutes"] = cooldownMin;
        map["cooldownEnd"] = cooldownEnd;
        map["isCooling"] = isCooling;
        m_allMaps.append(map);
    }

    emit totalCountChanged();
    m_error.clear();
    emit errorChanged();
    applyFilter();
}

void MapCooldownManager::applyFilter()
{
    QVariantList result;
    QString keyword = m_searchText.trimmed().toLower();

    for (const QVariant &v : m_allMaps) {
        QVariantMap m = v.toMap();
        if (m_onlyCooling && !m["isCooling"].toBool()) continue;
        if (!keyword.isEmpty()) {
            QString name = m["displayName"].toString().toLower();
            QString ach = m["achievement"].toString().toLower();
            if (!name.contains(keyword) && !ach.contains(keyword)) continue;
        }
        result.append(v);
    }

    m_filteredMaps = result;
    emit filteredMapsChanged();
}