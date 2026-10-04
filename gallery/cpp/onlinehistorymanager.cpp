#include "onlinehistorymanager.h"

#include <QDate>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>

OnlineHistoryManager::OnlineHistoryManager(const QString &filePath, QObject *parent)
    : QObject(parent), m_path(filePath)
{
    load();
}

void OnlineHistoryManager::load()
{
    QFile f(m_path);
    if (!f.open(QIODevice::ReadOnly)) {
        m_days.clear();
        m_max = 0;
        emit changed();
        return;
    }
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    const QJsonArray arr = doc.object().value(QStringLiteral("days")).toArray();
    m_days.clear();
    for (const QJsonValue &v : arr) {
        const QJsonObject o = v.toObject();
        m_days.append(QVariantMap{
            { QStringLiteral("date"), o.value(QStringLiteral("date")).toString() },
            { QStringLiteral("players"), o.value(QStringLiteral("players")).toInt() },
            { QStringLiteral("servers"), o.value(QStringLiteral("servers")).toInt() }
        });
    }
    m_max = 0;
    for (const QVariant &v : m_days)
        m_max = qMax(m_max, v.toMap().value(QStringLiteral("players")).toInt());
    emit changed();
}

void OnlineHistoryManager::save()
{
    QFile f(m_path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    QJsonArray arr;
    for (const QVariant &v : m_days) {
        const QVariantMap m = v.toMap();
        arr.append(QJsonObject{
            { QStringLiteral("date"), m.value(QStringLiteral("date")).toString() },
            { QStringLiteral("players"), m.value(QStringLiteral("players")).toInt() },
            { QStringLiteral("servers"), m.value(QStringLiteral("servers")).toInt() }
        });
    }
    f.write(QJsonDocument(arr).toJson(QJsonDocument::Indented));
}

void OnlineHistoryManager::record(int players, int servers)
{
    const QString today = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));
    bool updated = false;
    for (int i = 0; i < m_days.size(); ++i) {
        QVariantMap m = m_days.at(i).toMap();
        if (m.value(QStringLiteral("date")).toString() == today) {
            const int prev = m.value(QStringLiteral("players")).toInt();
            if (players > prev)
                m.insert(QStringLiteral("players"), players);
            m.insert(QStringLiteral("servers"), servers);
            m_days[i] = m;
            updated = true;
            break;
        }
    }
    if (!updated) {
        m_days.append(QVariantMap{
            { QStringLiteral("date"), today },
            { QStringLiteral("players"), players },
            { QStringLiteral("servers"), servers }
        });
    }

    std::sort(m_days.begin(), m_days.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("date")).toString()
             < b.toMap().value(QStringLiteral("date")).toString();
    });
    while (m_days.size() > 30)
        m_days.removeFirst();

    m_max = 0;
    for (const QVariant &v : m_days)
        m_max = qMax(m_max, v.toMap().value(QStringLiteral("players")).toInt());

    save();
    emit changed();
}
