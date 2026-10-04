#include "updatechecker.h"

#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>
#include <QProcess>
#include <QTimer>
#include <QDebug>
#include <QDesktopServices>
#include <QFileDialog>

UpdateChecker::UpdateChecker(QObject *parent)
    : QObject(parent)
{
    m_currentVersion = QStringLiteral(GALLERY_VERSION);
}

void UpdateChecker::setChecking(bool v)
{
    if (m_checking != v) {
        m_checking = v;
        emit checkingChanged();
    }
}

void UpdateChecker::setDownloadReady(bool v)
{
    if (m_downloadReady != v) {
        m_downloadReady = v;
        emit downloadReadyChanged();
    }
}

void UpdateChecker::setDownloadProgress(qreal v)
{
    if (m_downloadProgress != v) {
        m_downloadProgress = v;
        emit downloadProgressChanged();
    }
}

void UpdateChecker::setDownloadUrl(const QString &url)
{
    if (m_downloadUrl != url) {
        m_downloadUrl = url;
        emit downloadUrlChanged();
    }
}

void UpdateChecker::checkForUpdate()
{
    if (m_checking) return;
    setChecking(true);

    QNetworkRequest request{QUrl("https://api.github.com/repos/hualiangHL/CS2JoinTool/releases/latest")};
    request.setHeader(QNetworkRequest::UserAgentHeader, "CS2JoinTool-UpdateChecker");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = m_nam.get(request, QByteArray());
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onCheckReply(reply);
        reply->deleteLater();
    });
}

void UpdateChecker::onCheckReply(QNetworkReply *reply)
{
    setChecking(false);

    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = reply->errorString();
        if (errorMsg.contains("403") || errorMsg.contains("rate limit")) {
            emit checkFailed("检查更新失败，访问太频繁，请稍后再试");
        } else {
            emit checkFailed("检查更新失败，请检查网络连接");
        }
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        emit checkFailed("解析版本信息失败");
        return;
    }

    QJsonObject obj = doc.object();
    QString tagName = obj.value("tag_name").toString();
    QString body = obj.value("body").toString();

    m_latestVersion = parseVersion(tagName);

    QJsonArray assets = obj.value("assets").toArray();
    for (const QJsonValue &asset : assets) {
        QJsonObject assetObj = asset.toObject();
        QString name = assetObj.value("name").toString().toLower();
        if (name.endsWith(".exe") || name.contains("windows") || name.contains("win")) {
            setDownloadUrl(assetObj.value("browser_download_url").toString());
            break;
        }
    }

    if (m_downloadUrl.isEmpty() && !assets.isEmpty()) {
        setDownloadUrl(assets.first().toObject().value("browser_download_url").toString());
    }

    if (isNewerVersion(m_latestVersion, m_currentVersion)) {
        m_hasUpdate = true;
        emit updateStateChanged();
        emit updateAvailable(m_latestVersion, body);
    } else {
        m_hasUpdate = false;
        emit updateStateChanged();
        emit upToDate();
    }
}

QString UpdateChecker::parseVersion(const QString &tag)
{
    QString v = tag;
    v.remove(QRegularExpression("^[vV]"));
    return v;
}

bool UpdateChecker::isNewerVersion(const QString &latest, const QString &current)
{
    QStringList latestParts = latest.split(".");
    QStringList currentParts = current.split(".");

    while (latestParts.size() < 3) latestParts << "0";
    while (currentParts.size() < 3) currentParts << "0";

    for (int i = 0; i < 3; i++) {
        int l = latestParts.value(i).toInt();
        int c = currentParts.value(i).toInt();
        if (l > c) return true;
        if (l < c) return false;
    }
    return false;
}

void UpdateChecker::downloadUpdate(const QString &url)
{
    QDesktopServices::openUrl(QUrl(url));
}

void UpdateChecker::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        setDownloadProgress((qreal)bytesReceived / bytesTotal);
    }
}

void UpdateChecker::onDownloadReply(QNetworkReply *reply)
{
    if (reply->error() != QNetworkReply::NoError) {
        m_downloadFile.close();
        m_downloadFile.remove();
        emit downloadFailed(reply->errorString());
        return;
    }

    m_downloadFile.write(reply->readAll());
    m_downloadFile.close();

    setDownloadReady(true);
    emit downloadFinished(m_downloadPath);
}

void UpdateChecker::applyUpdate()
{
    QString appDir = QCoreApplication::applicationDirPath();
    QString appPath = QCoreApplication::applicationFilePath();

    QString batPath = appDir + "/update_temp.bat";
    QFile bat(batPath);
    if (bat.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QString batContent = QString(
            "@echo off\n"
            "timeout /t 3 /nobreak >nul\n"
            ":loop\n"
            "tasklist /FI \"IMAGENAME eq CS2JoinTool.exe\" | find /i \"CS2JoinTool.exe\" >nul\n"
            "if not errorlevel 1 (\n"
            "    timeout /t 1 /nobreak >nul\n"
            "    goto loop\n"
            ")\n"
            "copy /Y \"%1\" \"%2\" >nul\n"
            "start \"\" \"%2\"\n"
            "del \"%%~f0\"\n"
        ).arg(m_downloadPath).arg(appPath);
        bat.write(batContent.toUtf8());
        bat.close();
    }

    QProcess::startDetached(batPath, QStringList());
    QCoreApplication::quit();
}
