#include "langmanager.h"

LangManager::LangManager(const QString &cfgDir, QObject *parent)
    : QObject(parent)
    , m_settings(new QSettings(cfgDir + QStringLiteral("/appconfig.ini"), QSettings::IniFormat, this))
{
    m_language = m_settings->value(QStringLiteral("language"), QStringLiteral("zh")).toString();
}

void LangManager::setLanguage(const QString &v)
{
    if (m_language == v)
        return;
    m_language = v;
    m_settings->setValue(QStringLiteral("language"), v);
    emit languageChanged();
}
