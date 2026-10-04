#ifndef LANGMANAGER_H
#define LANGMANAGER_H

#include <QObject>
#include <QSettings>


class LangManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
public:
    explicit LangManager(const QString &cfgDir, QObject *parent = nullptr);

    QString language() const { return m_language; }
    void setLanguage(const QString &v);

    Q_INVOKABLE QString tr(const QString &zh, const QString &en) const {
        return m_language == QLatin1String("en") ? en : zh;
    }
    Q_INVOKABLE bool isEn() const { return m_language == QLatin1String("en"); }

signals:
    void languageChanged();

private:
    QSettings *m_settings = nullptr;
    QString m_language = QStringLiteral("zh");
};

#endif
