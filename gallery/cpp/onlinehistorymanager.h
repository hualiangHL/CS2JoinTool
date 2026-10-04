#pragma once

#include <QObject>
#include <QVariantList>


class OnlineHistoryManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList days READ days NOTIFY changed)
    Q_PROPERTY(int maxValue READ maxValue NOTIFY changed)
public:
    explicit OnlineHistoryManager(const QString &filePath, QObject *parent = nullptr);

    QVariantList days() const { return m_days; }
    int maxValue() const { return m_max; }

    Q_INVOKABLE void record(int players, int servers);

signals:
    void changed();

private:
    void load();
    void save();

    QString m_path;
    QVariantList m_days;
    int m_max = 0;
};
