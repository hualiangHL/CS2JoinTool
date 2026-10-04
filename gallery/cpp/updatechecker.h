#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>

class UpdateChecker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString displayVersion READ displayVersion CONSTANT)
    Q_PROPERTY(bool checking READ checking NOTIFY checkingChanged)
    Q_PROPERTY(bool downloadReady READ downloadReady NOTIFY downloadReadyChanged)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress NOTIFY downloadProgressChanged)
    Q_PROPERTY(QString downloadUrl READ downloadUrl NOTIFY downloadUrlChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY updateStateChanged)
    Q_PROPERTY(bool hasUpdate READ hasUpdate NOTIFY updateStateChanged)

public:
    explicit UpdateChecker(QObject *parent = nullptr);

    QString currentVersion() const { return m_currentVersion; }


    QString displayVersion() const { return QStringLiteral(GALLERY_VERSION); }
    bool checking() const { return m_checking; }
    bool downloadReady() const { return m_downloadReady; }
    qreal downloadProgress() const { return m_downloadProgress; }
    QString downloadUrl() const { return m_downloadUrl; }
    QString latestVersion() const { return m_latestVersion; }
    bool hasUpdate() const { return m_hasUpdate; }

signals:
    void checkingChanged();
    void downloadReadyChanged();
    void downloadProgressChanged();
    void downloadUrlChanged();
    void updateStateChanged();
    void updateAvailable(const QString &version, const QString &notes);
    void upToDate();
    void checkFailed(const QString &error);
    void downloadFinished(const QString &filePath);
    void downloadFailed(const QString &error);

public slots:
    void checkForUpdate();
    void downloadUpdate(const QString &url);
    void applyUpdate();

private slots:
    void onCheckReply(QNetworkReply *reply);
    void onDownloadReply(QNetworkReply *reply);
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    QNetworkAccessManager m_nam;
    QString m_currentVersion;
    bool m_checking = false;
    bool m_downloadReady = false;
    qreal m_downloadProgress = 0.0;
    QString m_latestVersion;
    bool m_hasUpdate = false;
    QString m_downloadUrl;
    QString m_downloadPath;
    QFile m_downloadFile;

    void setChecking(bool v);
    void setDownloadReady(bool v);
    void setDownloadProgress(qreal v);
    void setDownloadUrl(const QString &url);
    QString parseVersion(const QString &tag);
    bool isNewerVersion(const QString &latest, const QString &current);
};

#endif
