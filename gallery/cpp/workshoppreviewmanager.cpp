#include "workshoppreviewmanager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QCoreApplication>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrl>
#include <QRegularExpression>
#include <QSettings>
#include <QDir>
#include <QStandardPaths>

WorkshopPreviewManager *WorkshopPreviewManager::instance()
{
    static WorkshopPreviewManager inst;
    return &inst;
}

WorkshopPreviewManager::WorkshopPreviewManager(QObject *parent)
    : QObject(parent)
{
    loadMapDb();
    scanLocalWorkshop();

    QString cfgBase = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                    + QStringLiteral("/HuskarUIcs2配置文件");
    if (!QDir().mkpath(cfgBase))
        cfgBase = QCoreApplication::applicationDirPath() + QStringLiteral("/config");
    m_cacheDir = cfgBase + QStringLiteral("/preview_cache");
    QDir().mkpath(m_cacheDir);
}

void WorkshopPreviewManager::loadMapDb()
{
    m_mapDb.clear();
    const QString appDir = QCoreApplication::applicationDirPath();
    QStringList paths;
    paths << appDir + "/map_db.json";
    paths << appDir + "/../map_db.json";
    for (const QString &path : paths) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            continue;
        const QByteArray data = file.readAll();
        file.close();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isArray())
            continue;
        const QJsonArray arr = doc.array();
        for (const QJsonValue &val : arr) {
            if (!val.isObject())
                continue;
            const QJsonObject obj = val.toObject();
            const QString name = obj.value("Name").toString().toLower();
            QString wsid;
            const QJsonValue wsidVal = obj.value("WorkshopId");
            if (wsidVal.isString())
                wsid = wsidVal.toString();
            else if (wsidVal.isDouble())
                wsid = QString::number(qint64(wsidVal.toDouble()));
            if (!name.isEmpty() && !wsid.isEmpty())
                m_mapDb.insert(name, wsid);
        }
        return;
    }
}

QString WorkshopPreviewManager::findWorkshopId(const QString &mapName) const
{
    const QString key = mapName.toLower().split('.').first().trimmed();
    const QString db = m_mapDb.value(key);
    if (!db.isEmpty())
        return db;

    return m_localMaps.value(key);
}

void WorkshopPreviewManager::scanLocalWorkshop()
{
    m_localMaps.clear();

    QSettings reg(QStringLiteral("HKEY_CURRENT_USER\\Software\\Valve\\Steam"), QSettings::NativeFormat);
    QString steamPath = reg.value(QStringLiteral("SteamPath")).toString();
    if (steamPath.isEmpty())
        steamPath = reg.value(QStringLiteral("InstallPath")).toString();


    QStringList libs;
    if (!steamPath.isEmpty() && QDir(steamPath).exists())
        libs << steamPath;
    const QString vdfPath = steamPath + "/steamapps/libraryfolders.vdf";
    QFile vdf(vdfPath);
    if (vdf.open(QIODevice::ReadOnly)) {
        const QString vdfContent = QString::fromUtf8(vdf.readAll());
        vdf.close();
        static const QRegularExpression pathRe(QStringLiteral("\"path\"\\s+\"([^\"]+)\""));
        QRegularExpressionMatchIterator it = pathRe.globalMatch(vdfContent);
        while (it.hasNext()) {
            QString lib = it.next().captured(1).replace(QStringLiteral("\\\\"), QStringLiteral("/"));
            lib = QDir::cleanPath(lib);
            if (QDir(lib).exists() && !libs.contains(lib, Qt::CaseInsensitive))
                libs << lib;
        }
    }


    for (const QString &lib : libs) {
        const QString workshopDir = lib + "/steamapps/workshop/content/730";
        QDir dir(workshopDir);
        if (!dir.exists())
            continue;
        const QStringList idDirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &id : idDirs) {
            const QString mapDirPath = workshopDir + "/" + id;
            QDir mapDir(mapDirPath);
            const QStringList vpkFiles = mapDir.entryList(QStringList() << "*.vpk", QDir::Files);
            if (vpkFiles.isEmpty())
                continue;
            const QString vpkName = vpkFiles.first().left(vpkFiles.first().length() - 4);
            m_localMaps.insert(vpkName.toLower(), id);
            QFile pf(mapDirPath + "/publish_data.txt");
            if (pf.open(QIODevice::ReadOnly | QIODevice::Text)) {
                const QString content = QString::fromUtf8(pf.readAll());
                pf.close();
                static const QRegularExpression titleRe(QStringLiteral("\"title\"\\s+\"([^\"]+)\""));
                const QRegularExpressionMatch tm = titleRe.match(content);
                if (tm.hasMatch()) {
                    const QString t = tm.captured(1).trimmed();
                    if (!t.isEmpty())
                        m_localMaps.insert(t.toLower(), id);
                }
            }
        }
    }
}

void WorkshopPreviewManager::requestPreview(const QString &mapName)
{
    if (mapName.isEmpty())
        return;

    const QString cached = m_cache.value(mapName);
    if (!cached.isEmpty())
        return;
    if (m_queue.contains(mapName))
        return;
    m_queue.enqueue(mapName);
    processQueue();
}

QString WorkshopPreviewManager::cachedUrl(const QString &mapName)
{
    return m_cache.value(mapName);
}

bool WorkshopPreviewManager::hasCached(const QString &mapName) const
{
    return m_cache.contains(mapName);
}

void WorkshopPreviewManager::processQueue()
{
    while (m_inflight < kMaxInflight && !m_queue.isEmpty()) {
        const QString mapName = m_queue.dequeue();
        m_cache.insert(mapName, QStringLiteral("loading"));
        const QString wsid = findWorkshopId(mapName);
        ++m_inflight;
        if (!wsid.isEmpty()) {
            fetchPreviewById(wsid, mapName);
        } else {

            searchWorkshopId(mapName);
        }
    }
}

void WorkshopPreviewManager::searchWorkshopId(const QString &mapName)
{
    const QString encoded = QString::fromLatin1(QUrl::toPercentEncoding(mapName));
    const QUrl url(QStringLiteral("https://steamcommunity.com/workshop/browse/?appid=730&searchtext=%1&browsesort=textmatch&actualsearch=1").arg(encoded));
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setTransferTimeout(8000);
    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, mapName]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            finishFail(mapName);
            return;
        }
        const QString html = QString::fromUtf8(reply->readAll());
        static const QRegularExpression re(QStringLiteral("filedetails/\\?id=(\\d+)"));
        const QRegularExpressionMatch m = re.match(html);
        if (m.hasMatch()) {
            fetchPreviewById(m.captured(1), mapName);
        } else {
            finishFail(mapName);
        }
    });
}

void WorkshopPreviewManager::fetchPreviewById(const QString &wsid, const QString &mapName)
{
    const QUrl url(QStringLiteral("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/x-www-form-urlencoded"));
    req.setTransferTimeout(10000);
    const QByteArray body = QStringLiteral("itemcount=1&publishedfileids[0]=%1").arg(wsid).toUtf8();
    QNetworkReply *reply = m_nam.post(req, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, mapName]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            finishFail(mapName);
            return;
        }
        const QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        const QJsonObject root = doc.object();
        const QJsonObject resp = root.value("response").toObject();
        const QJsonArray details = resp.value("publishedfiledetails").toArray();
        if (!details.isEmpty()) {
            const QString url = details.first().toObject().value("preview_url").toString();
            if (!url.isEmpty()) {

                downloadPreview(QUrl(url), mapName);
                return;
            }
        }
        finishFail(mapName);
    });
}

void WorkshopPreviewManager::downloadPreview(const QUrl &url, const QString &mapName)
{
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)");
    req.setTransferTimeout(15000);
    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, url, mapName]() {
        reply->deleteLater();
        QString finalUrl = url.toString();
        if (reply->error() == QNetworkReply::NoError) {
            const QByteArray data = reply->readAll();
            if (!data.isEmpty()) {

                QString safeName = mapName.toLower().split('.').first().trimmed();
                safeName.replace(QRegularExpression(QStringLiteral("[^a-z0-9_\-]")), QStringLiteral("_"));
                const QString filePath = m_cacheDir + "/" + safeName + ".jpg";
                QFile f(filePath);
                if (f.open(QIODevice::WriteOnly)) {
                    f.write(data);
                    f.close();
                    finalUrl = QUrl::fromLocalFile(filePath).toString();
                }
            }
        }

        m_cache.insert(mapName, finalUrl);
        emit previewReady(mapName, finalUrl);
        --m_inflight;
        processQueue();
    });
}

void WorkshopPreviewManager::finishFail(const QString &mapName)
{
    m_cache.insert(mapName, QString());
    emit previewFailed(mapName);
    --m_inflight;
    processQueue();
}
