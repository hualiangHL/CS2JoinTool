#ifndef JOINHISTORYMANAGER_H
#define JOINHISTORYMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>
#include <QString>


class JoinHistoryManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)

public:
    explicit JoinHistoryManager(const QString &path, QObject *parent = nullptr);

    Q_INVOKABLE void record(const QString &mapName, const QString &serverName, const QString &ip);
    QVariantList items() const;

signals:
    void itemsChanged();

private:
    struct Entry {
        QString map;
        QString server;
        QString ip;
        int count = 0;
        qint64 lastMs = 0;
    };

    void load();
    void save();

    QVector<Entry> m_entries;
    QString m_path;
};

#endif
