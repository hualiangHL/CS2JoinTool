#ifndef WORKSHOPMANAGER_H
#define WORKSHOPMANAGER_H

#include <QObject>
#include <QVariantList>
#include <QString>
#include <QHash>

class WorkshopManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList maps READ maps NOTIFY mapsChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY mapsChanged)
    Q_PROPERTY(int installedCount READ installedCount NOTIFY mapsChanged)
    Q_PROPERTY(QStringList libraryPaths READ libraryPaths NOTIFY libraryPathsChanged)
    Q_PROPERTY(QString primaryWorkshopPath READ primaryWorkshopPath NOTIFY primaryWorkshopPathChanged)

public:
    explicit WorkshopManager(QObject *parent = nullptr);

    QVariantList maps() const { return m_maps; }
    bool scanning() const { return m_scanning; }
    int totalCount() const { return m_maps.size(); }
    int installedCount() const;
    QStringList libraryPaths() const { return m_libraryPaths; }
    QString primaryWorkshopPath() const { return m_primaryWorkshopPath; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clearMaps();
    Q_INVOKABLE void setCustomPath(const QString &path);
    Q_INVOKABLE void copyId(const QString &id);
    Q_INVOKABLE void copyName(const QString &name);
    Q_INVOKABLE void openWeb(const QString &id);
    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void deleteMapAndRestartSteam(const QString &path);
    Q_INVOKABLE QString getSteamPath();
    Q_INVOKABLE QString findWorkshopId(const QString &mapName);

signals:
    void mapsChanged();
    void scanningChanged();
    void libraryPathsChanged();
    void primaryWorkshopPathChanged();

private:
    QVariantList m_maps;
    bool m_scanning = false;
    QHash<QString, QString> m_mapDb; 
    QStringList m_libraryPaths;
    QString m_primaryWorkshopPath;

    void loadMapDb();
    void scanLocalMaps();
    QString findSteamPath();
    QStringList findLibraryPaths(const QString &steamPath);
};

#endif