#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class MapTranslator : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    Q_INVOKABLE QString formatMap(const QString &name);
    Q_INVOKABLE QString difficulty(const QString &name);
    Q_INVOKABLE QString zhName(const QString &name);
    Q_INVOKABLE void copyText(const QString &text);

    Q_INVOKABLE void setEnglish(bool en);
private:
    static bool s_enMode;
};
