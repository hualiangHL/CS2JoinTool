#include "workshopmanager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>
#include <QSettings>
#include <QRegularExpression>
#include <QGuiApplication>
#include <QClipboard>
#include <QDesktopServices>
#include <QUrl>
#include <QTextStream>
#include <QDebug>
#include <QSet>
#include <QTimer>
#include <QProcess>
#include <QStandardPaths>
#include <algorithm>

WorkshopManager::WorkshopManager(QObject *parent)
    : QObject(parent)
{
    loadMapDb();
    // 加载保存的自定义工坊路径
    QSettings ws(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/workshop.ini", QSettings::IniFormat);
    QString saved = ws.value("customWorkshopPath").toString();
    if (!saved.isEmpty() && QDir(saved).exists()) {
        m_primaryWorkshopPath = saved;
        qDebug() << "[Workshop] loaded saved custom path:" << saved;
    }
}

int WorkshopManager::installedCount() const
{
    int count = 0;
    for (const QVariant &v : m_maps) {
        if (v.toMap().value("installed").toBool()) count++;
    }
    return count;
}

void WorkshopManager::loadMapDb()
{
    m_mapDb.clear();
    QString appDir = QCoreApplication::applicationDirPath();
    QStringList paths;
    paths << appDir + "/map_db.json";
    paths << QDir(appDir).absoluteFilePath("../map_db.json");

    for (const QString &path : paths) {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly)) continue;
        QByteArray data = file.readAll();
        file.close();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isArray()) continue;
        QJsonArray arr = doc.array();
        for (const QJsonValue &val : arr) {
            if (!val.isObject()) continue;
            QJsonObject obj = val.toObject();
            QString name = obj.value("Name").toString().toLower();
            QString wsid;
            QJsonValue wsidVal = obj.value("WorkshopId");
            if (wsidVal.isString()) wsid = wsidVal.toString();
            else if (wsidVal.isDouble()) wsid = QString::number((qint64)wsidVal.toDouble());
            if (!name.isEmpty() && !wsid.isEmpty()) {
                m_mapDb[name] = wsid;
            }
        }
        qDebug() << "[Workshop] loaded map_db:" << m_mapDb.size();
        return;
    }
}

QString WorkshopManager::findSteamPath()
{
    QSettings reg("HKEY_CURRENT_USER\\Software\\Valve\\Steam", QSettings::NativeFormat);
    QString steamPath = reg.value("SteamPath").toString();
    if (steamPath.isEmpty()) steamPath = reg.value("InstallPath").toString();
    if (!steamPath.isEmpty()) {
        steamPath = QDir::cleanPath(steamPath);
        if (QDir(steamPath).exists()) return steamPath;
    }
    QStringList fallbacks = {"C:/Program Files (x86)/Steam", "C:/Program Files/Steam", "D:/Steam", "E:/Steam"};
    for (const QString &p : fallbacks) {
        if (QDir(p).exists()) return p;
    }
    return "";
}

QStringList WorkshopManager::findLibraryPaths(const QString &steamPath)
{
    QStringList libs;
    if (!steamPath.isEmpty()) libs << steamPath;

    QString vdfPath = steamPath + "/steamapps/libraryfolders.vdf";
    QFile vdf(vdfPath);
    if (vdf.open(QIODevice::ReadOnly)) {
        QString content = QString::fromUtf8(vdf.readAll());
        vdf.close();
        static QRegularExpression re("\"path\"\\s+\"([^\"]+)\"");
        QRegularExpressionMatchIterator it = re.globalMatch(content);
        while (it.hasNext()) {
            QString lib = it.next().captured(1).replace("\\\\", "/");
            lib = QDir::cleanPath(lib);
            bool exists = false;
            for (const QString &existing : libs) {
                if (QDir::cleanPath(existing).toLower() == lib.toLower()) { exists = true; break; }
            }
            if (!exists && QDir(lib).exists()) {
                libs << lib;
            }
        }
    }
    return libs;
}

void WorkshopManager::scanLocalMaps()
{
    QString steamPath = findSteamPath();
    QVariantList result;
    QSet<QString> addedIds;

    if (!steamPath.isEmpty()) {
        QStringList libs = findLibraryPaths(steamPath);
        m_libraryPaths = libs;
        emit libraryPathsChanged();
        qDebug() << "[Workshop] detected" << libs.size() << "steam libraries:" << libs;
        QHash<QString, int> libMapCount;
        for (const QString &lib : libs) {
            libMapCount[lib] = 0;
            QString workshopDir = lib + "/steamapps/workshop/content/730";
            QDir dir(workshopDir);
            if (!dir.exists()) continue;
            QStringList idDirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &id : idDirs) {
                if (addedIds.contains(id)) continue;
                QString mapDirPath = workshopDir + "/" + id;
                QDir mapDir(mapDirPath);

                // V3逻辑：没有vpk文件直接跳过
                QStringList vpkFiles = mapDir.entryList(QStringList() << "*.vpk", QDir::Files);
                if (vpkFiles.isEmpty()) continue;

                // 先用vpk文件名
                QString mapName = vpkFiles.first();
                mapName.chop(4);

                // 关键：读 publish_data.txt 里的 title（创意工坊名称）
                QFile publishFile(mapDirPath + "/publish_data.txt");
                if (publishFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QTextStream in(&publishFile);
                    QString content = in.readAll();
                    publishFile.close();
                    static QRegularExpression titleRe("\"title\"\\s+\"([^\"]+)\"");
                    QRegularExpressionMatch titleMatch = titleRe.match(content);
                    if (titleMatch.hasMatch()) {
                        QString t = titleMatch.captured(1).trimmed();
                        if (!t.isEmpty()) mapName = t;
                    }
                }

                QVariantMap map;
                map["name"] = mapName;
                map["vpkName"] = vpkFiles.first().left(vpkFiles.first().length() - 4);
                map["workshopId"] = id;
                map["installed"] = true;
                map["path"] = mapDirPath;
                result.append(map);
                addedIds.insert(id);
                libMapCount[lib]++;
            }
        }
        // 选地图最多的库作为主路径
        QString bestLib;
        int bestCount = 0;
        for (auto it = libMapCount.begin(); it != libMapCount.end(); ++it) {
            if (it.value() > bestCount) {
                bestCount = it.value();
                bestLib = it.key();
            }
        }
        if (!bestLib.isEmpty()) {
            m_primaryWorkshopPath = bestLib + "/steamapps/workshop/content/730";
            emit primaryWorkshopPathChanged();
            qDebug() << "[Workshop] primary workshop path:" << m_primaryWorkshopPath << "(" << bestCount << "maps)";
        }
    }

    // 按名称排序（V3逻辑）
    std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("name").toString().toLower() < b.toMap().value("name").toString().toLower();
    });

    m_maps = result;
    qDebug() << "[Workshop] total maps:" << m_maps.size() << "(installed:" << addedIds.size() << ")";
}

void WorkshopManager::clearMaps()
{
    m_maps.clear();
    m_primaryWorkshopPath.clear();
    m_libraryPaths.clear();
    emit mapsChanged();
    emit libraryPathsChanged();
    emit primaryWorkshopPathChanged();
}

void WorkshopManager::refresh()
{
    if (m_scanning) return;
    m_scanning = true;
    emit scanningChanged();
    QTimer::singleShot(250, this, [this]() {
        loadMapDb();
        // 如果有保存的自定义路径且存在，直接用它；否则自动检测
        QSettings ws(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/workshop.ini", QSettings::IniFormat);
        QString saved = ws.value("customWorkshopPath").toString();
        if (!saved.isEmpty() && QDir(saved).exists()) {
            setCustomPath(saved);
        } else {
            scanLocalMaps();
        }
        m_scanning = false;
        emit scanningChanged();
        emit mapsChanged();
    });
}

void WorkshopManager::setCustomPath(const QString &path)
{
    qDebug() << "[Workshop] setCustomPath called with:" << path;
    if (path.isEmpty()) return;
    QString cleanPath = QDir::cleanPath(path);

    // 如果是 Steam 库根目录，自动补全工坊路径
    QDir dir(cleanPath);
    if (dir.exists() && !dir.exists("steamapps/workshop/content/730")) {
        // 检查是否是库根（有 steamapps 目录）
        if (dir.exists("steamapps")) {
            QString autoPath = cleanPath + "/steamapps/workshop/content/730";
            if (QDir(autoPath).exists()) {
                qDebug() << "[Workshop] auto-appended workshop subpath:" << autoPath;
                cleanPath = autoPath;
                dir = QDir(cleanPath);
            }
        }
    }

    if (!dir.exists()) {
        qDebug() << "[Workshop] path does not exist, still updating display:" << cleanPath;
        m_maps.clear();
        m_primaryWorkshopPath = cleanPath;
        // 保存自定义路径
        QSettings ws(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/workshop.ini", QSettings::IniFormat);
        ws.setValue("customWorkshopPath", cleanPath);
        emit primaryWorkshopPathChanged();
        m_scanning = false;
        emit scanningChanged();
        emit mapsChanged();
        return;
    }

    m_scanning = true;
    emit scanningChanged();

    QVariantList result;
    QSet<QString> addedIds;

    // 先检查路径本身是否直接含 .vpk（单个工坊物品目录）
    QStringList rootVpk = dir.entryList(QStringList() << "*.vpk", QDir::Files);
    if (!rootVpk.isEmpty()) {
        QString mapName = rootVpk.first();
        mapName.chop(4);
        QFile publishFile(cleanPath + "/publish_data.txt");
        if (publishFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream in(&publishFile);
            QString content = in.readAll();
            publishFile.close();
            static QRegularExpression titleRe("\"title\"\\s+\"([^\"]+)\"");
            QRegularExpressionMatch titleMatch = titleRe.match(content);
            if (titleMatch.hasMatch()) {
                QString t = titleMatch.captured(1).trimmed();
                if (!t.isEmpty()) mapName = t;
            }
        }
        QVariantMap map;
        map["name"] = mapName;
        map["vpkName"] = rootVpk.first().left(rootVpk.first().length() - 4);
        map["workshopId"] = dir.dirName();
        map["installed"] = true;
        map["path"] = cleanPath;
        result.append(map);
        qDebug() << "[Workshop] single item path, map:" << mapName;
    } else {
        // 正常：路径下有多个工坊物品子目录
        QStringList idDirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        qDebug() << "[Workshop] scanning" << idDirs.size() << "subdirs in" << cleanPath;
        for (const QString &id : idDirs) {
            if (addedIds.contains(id)) continue;
            QString mapDirPath = cleanPath + "/" + id;
            QDir mapDir(mapDirPath);
            QStringList vpkFiles = mapDir.entryList(QStringList() << "*.vpk", QDir::Files);
            if (vpkFiles.isEmpty()) continue;

            QString mapName = vpkFiles.first();
            mapName.chop(4);

            QFile publishFile(mapDirPath + "/publish_data.txt");
            if (publishFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&publishFile);
                QString content = in.readAll();
                publishFile.close();
                static QRegularExpression titleRe("\"title\"\\s+\"([^\"]+)\"");
                QRegularExpressionMatch titleMatch = titleRe.match(content);
                if (titleMatch.hasMatch()) {
                    QString t = titleMatch.captured(1).trimmed();
                    if (!t.isEmpty()) mapName = t;
                }
            }

            QVariantMap map;
            map["name"] = mapName;
            map["vpkName"] = vpkFiles.first().left(vpkFiles.first().length() - 4);
            map["workshopId"] = id;
            map["installed"] = true;
            map["path"] = mapDirPath;
            result.append(map);
            addedIds.insert(id);
        }
    }

    std::sort(result.begin(), result.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value("name").toString().toLower() < b.toMap().value("name").toString().toLower();
    });

    m_maps = result;
    m_primaryWorkshopPath = cleanPath;
    // 保存自定义路径
    QSettings ws(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/workshop.ini", QSettings::IniFormat);
    ws.setValue("customWorkshopPath", cleanPath);
    emit primaryWorkshopPathChanged();
    m_scanning = false;
    emit scanningChanged();
    emit mapsChanged();
    qDebug() << "[Workshop] custom path set:" << cleanPath << "maps:" << m_maps.size();
}

void WorkshopManager::copyId(const QString &id)
{
    QGuiApplication::clipboard()->setText(id);
}

void WorkshopManager::copyName(const QString &name)
{
    QGuiApplication::clipboard()->setText(name);
}

void WorkshopManager::openWeb(const QString &id)
{
    if (id.isEmpty()) return;
    QString url = QString("https://steamcommunity.com/sharedfiles/filedetails/?id=%1").arg(id);
    // 用 steam://openurl 协议在 Steam 客户端内置浏览器中打开
    QDesktopServices::openUrl(QUrl(QString("steam://openurl/%1").arg(url)));
}

void WorkshopManager::openFolder(const QString &path)
{
    if (path.isEmpty() || !QDir(path).exists()) return;
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

QString WorkshopManager::getSteamPath()
{
    return findSteamPath();
}

void WorkshopManager::deleteMapAndRestartSteam(const QString &path)
{
    qDebug() << "[Workshop] deleting map at:" << path;
    if (path.isEmpty()) return;

    // 删除地图目录
    QDir mapDir(path);
    if (mapDir.exists()) {
        bool ok = mapDir.removeRecursively();
        qDebug() << "[Workshop] delete result:" << ok;
    }

    // 刷新列表
    QTimer::singleShot(300, this, [this]() {
        refresh();
    });

    // 重启Steam
    QString steamPath = findSteamPath();
    QString steamExe = steamPath + "/steam.exe";
    qDebug() << "[Workshop] restarting steam from:" << steamExe;

    // 先关闭Steam
    QProcess::startDetached("taskkill", QStringList() << "/F" << "/IM" << "steam.exe");

    // 等2秒后重新启动Steam
    QTimer::singleShot(2000, this, [steamExe]() {
        if (QFile::exists(steamExe)) {
            QProcess::startDetached(steamExe, QStringList());
            qDebug() << "[Workshop] steam relaunched";
        }
    });
}

QString WorkshopManager::findWorkshopId(const QString &mapName)
{
    if (mapName.isEmpty()) return "";
    QString key = mapName.toLower();
    // 1. 从 map_db.json 查找
    if (m_mapDb.contains(key)) {
        qDebug() << "[Workshop] findWorkshopId from db:" << mapName << "->" << m_mapDb[key];
        return m_mapDb[key];
    }
    // 2. 从已扫描的本地地图列表查找（匹配 vpkName 或 name）
    for (const QVariant &v : m_maps) {
        QVariantMap m = v.toMap();
        QString vpk = m.value("vpkName").toString().toLower();
        QString nm = m.value("name").toString().toLower();
        if (vpk == key || nm == key) {
            QString wsid = m.value("workshopId").toString();
            if (!wsid.isEmpty()) {
                qDebug() << "[Workshop] findWorkshopId from scan:" << mapName << "->" << wsid;
                return wsid;
            }
        }
    }
    qDebug() << "[Workshop] findWorkshopId not found:" << mapName;
    return "";
}
