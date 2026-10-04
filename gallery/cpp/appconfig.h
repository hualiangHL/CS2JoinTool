#ifndef APPCONFIG_H
#define APPCONFIG_H

#include <QObject>
#include <QSettings>
#include <QtQml/qqmlregistration.h>



class AppConfig : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool sortBySubs READ sortBySubs WRITE setSortBySubs NOTIFY sortBySubsChanged)
public:
    explicit AppConfig(const QString &cfgDir, QObject *parent = nullptr);

    bool sortBySubs() const { return m_sortBySubs; }
    void setSortBySubs(bool v);

signals:
    void sortBySubsChanged();

private:
    QSettings *m_settings = nullptr;
    bool m_sortBySubs = false;
};

#endif
