#include "joinhistorymanager.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDateTime>
#include <QDir>
#include <algorithm>

JoinHistoryManager::JoinHistoryManager(const QString &path, QObject *parent)
    : QObject(parent)
    , m_path(path)
{
    load();
}

void JoinHistoryManager::record(const QString &mapName, const QString &serverName, const QString &ip)
{
    const QString key = mapName.trimmed();
    if (key.isEmpty())
        return;

    for (Entry &e : m_entries) {
        if (e.map == key) {
            e.count++;
            if (!serverName.isEmpty())
                e.server = serverName;
            if (!ip.isEmpty())
                e.ip = ip;
            e.lastMs = QDateTime::currentMSecsSinceEpoch();
            save();
            emit itemsChanged();
            return;
        }
    }

    Entry e;
    e.map = key;
    e.server = serverName;
    e.ip = ip;
    e.count = 1;
    e.lastMs = QDateTime::currentMSecsSinceEpoch();
    m_entries.append(e);
    save();
    emit itemsChanged();
}

QVariantList JoinHistoryManager::items() const
{
    QVector<Entry> sorted = m_entries;
    std::sort(sorted.begin(), sorted.end(),
              [](const Entry &a, const Entry &b) { return a.lastMs > b.lastMs; });

    QVariantList out;
    const int n = qMin(sorted.size(), 20);
    for (int i = 0; i < n; ++i) {
        QVariantMap m;
        m["map"] = sorted[i].map;
        m["server"] = sorted[i].server;
        m["ip"] = sorted[i].ip;
        m["count"] = sorted[i].count;
        out.append(m);
    }
    return out;
}

void JoinHistoryManager::load()
{
    m_entries.clear();
    QFile file(m_path);
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QByteArray data = file.readAll();
    file.close();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray())
        return;
    const QJsonArray arr = doc.array();
    for (const QJsonValue &val : arr) {
        if (!val.isObject())
            continue;
        const QJsonObject obj = val.toObject();
        Entry e;
        e.map = obj.value("map").toString();
        e.server = obj.value("server").toString();
        e.ip = obj.value("ip").toString();
        e.count = obj.value("count").toInt(1);
        e.lastMs = obj.value("lastMs").toVariant().toLongLong();
        if (!e.map.isEmpty())
            m_entries.append(e);
    }
}

void JoinHistoryManager::save()
{
    QDir().mkpath(QFileInfo(m_path).absolutePath());
    QJsonArray arr;
    for (const Entry &e : m_entries) {
        QJsonObject obj;
        obj["map"] = e.map;
        obj["server"] = e.server;
        obj["ip"] = e.ip;
        obj["count"] = e.count;
        obj["lastMs"] = e.lastMs;
        arr.append(obj);
    }
    QFile file(m_path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    file.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
    file.close();
}
