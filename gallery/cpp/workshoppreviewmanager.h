#pragma once

#include <QObject>
#include <QHash>
#include <QQueue>
#include <QNetworkAccessManager>







class WorkshopPreviewManager : public QObject
{
    Q_OBJECT
public:
    static WorkshopPreviewManager *instance();

    Q_INVOKABLE void requestPreview(const QString &mapName);
    Q_INVOKABLE QString cachedUrl(const QString &mapName);
    Q_INVOKABLE bool hasCached(const QString &mapName) const;

signals:
    void previewReady(const QString &mapName, const QString &url);
    void previewFailed(const QString &mapName);

private:
    explicit WorkshopPreviewManager(QObject *parent = nullptr);
    void processQueue();
    void searchWorkshopId(const QString &mapName);
    void fetchPreviewById(const QString &wsid, const QString &mapName);
    void downloadPreview(const QUrl &url, const QString &mapName);
    void finishFail(const QString &mapName);
    void loadMapDb();
    void scanLocalWorkshop();
    QString findWorkshopId(const QString &mapName) const;

    QNetworkAccessManager m_nam;
    QString m_cacheDir;
    QHash<QString, QString> m_mapDb;
    QHash<QString, QString> m_localMaps;
    QHash<QString, QString> m_cache;
    QQueue<QString> m_queue;
    int m_inflight = 0;
    static constexpr int kMaxInflight = 3;
};
