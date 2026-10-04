#include "appconfig.h"

AppConfig::AppConfig(const QString &cfgDir, QObject *parent)
    : QObject(parent)
    , m_settings(new QSettings(cfgDir + QStringLiteral("/appconfig.ini"), QSettings::IniFormat, this))
{
    m_sortBySubs = m_settings->value(QStringLiteral("sortBySubs"), false).toBool();
}

void AppConfig::setSortBySubs(bool v)
{
    if (m_sortBySubs == v)
        return;
    m_sortBySubs = v;
    m_settings->setValue(QStringLiteral("sortBySubs"), v);
    m_settings->sync();
    emit sortBySubsChanged();
}
