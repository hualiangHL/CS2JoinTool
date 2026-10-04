#ifndef WHEELEXPORTER_H
#define WHEELEXPORTER_H

#include <QObject>
#include <QString>


class WheelExporter : public QObject
{
    Q_OBJECT
public:
    explicit WheelExporter(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void exportFiles(const QString &cfg1, const QString &cfg2, const QString &cfg3,
                                 const QString &autoexec, const QString &txt);
};

#endif
