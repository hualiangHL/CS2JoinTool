#ifndef BACKGROUNDFILEMANAGER_H
#define BACKGROUNDFILEMANAGER_H

#include <QObject>
#include <QUrl>


class BackgroundFileManager : public QObject
{
    Q_OBJECT
public:
    explicit BackgroundFileManager(const QString &cfgDir, QObject *parent = nullptr);


    Q_INVOKABLE QString importBackground(const QString &srcUrl);

    Q_INVOKABLE QString customBackgroundUrl() const;

    Q_INVOKABLE void resetDefault();

private:
    QString m_cfgDir;
};

#endif
