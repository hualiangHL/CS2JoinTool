#include "backgroundfilemanager.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

BackgroundFileManager::BackgroundFileManager(const QString &cfgDir, QObject *parent)
    : QObject(parent)
    , m_cfgDir(cfgDir)
{
    QDir().mkpath(m_cfgDir + "/background");
}

QString BackgroundFileManager::importBackground(const QString &srcUrl)
{
    const QString src = QUrl(srcUrl).toLocalFile();
    if (src.isEmpty() || !QFile::exists(src))
        return QString();

    const QString ext = QFileInfo(src).suffix().toLower();
    if (ext.isEmpty())
        return QString();

    const QString dst = m_cfgDir + "/background/custom_background." + ext;
    QFile::remove(dst);

    QFile in(src), out(dst);
    if (!in.open(QIODevice::ReadOnly) || !out.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return QString();
    out.write(in.readAll());
    in.close();
    out.close();

    return QUrl::fromLocalFile(dst).toString();
}

QString BackgroundFileManager::customBackgroundUrl() const
{
    const QString dir = m_cfgDir + "/background";
    const QFileInfoList list = QDir(dir).entryInfoList(QStringList("custom_background.*"),
                                                       QDir::Files, QDir::Name);
    if (!list.isEmpty())
        return QUrl::fromLocalFile(list.first().absoluteFilePath()).toString();
    return QString();
}

void BackgroundFileManager::resetDefault()
{
    const QString dir = m_cfgDir + "/background";
    const QFileInfoList list = QDir(dir).entryInfoList(QStringList("custom_background.*"),
                                                       QDir::Files, QDir::Name);
    for (const QFileInfo &fi : list)
        QFile::remove(fi.absoluteFilePath());
}
