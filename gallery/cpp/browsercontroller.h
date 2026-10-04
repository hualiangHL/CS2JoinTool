#ifndef BROWSERCONTROLLER_H
#define BROWSERCONTROLLER_H

#include <QObject>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QtQml/qqmlregistration.h>

class WebView2Browser;


class BrowserController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool browserEmbedded READ browserEmbedded NOTIFY browserEmbeddedChanged)
    Q_PROPERTY(QString browserCurrentUrl READ browserCurrentUrl NOTIFY browserUrlChanged)
    Q_PROPERTY(int webMenuCommunity READ webMenuCommunity WRITE setWebMenuCommunity NOTIFY webMenuCommunityChanged)

public:
    explicit BrowserController(QObject *parent = nullptr);
    ~BrowserController();

    bool browserEmbedded() const { return m_embedded; }
    QString browserCurrentUrl() const { return m_currentUrl; }
    int webMenuCommunity() const { return m_community; }
    void setWebMenuCommunity(int v);

    Q_INVOKABLE void embedBrowser(QQuickItem *placeholder);
    Q_INVOKABLE void updateBrowserGeometry();
    Q_INVOKABLE void hideBrowserWindow();
    Q_INVOKABLE void showBrowserWindow();
    Q_INVOKABLE void detachBrowser();


    Q_INVOKABLE void shutdownBrowser();
    Q_INVOKABLE void browserNavigate(const QString &url);
    Q_INVOKABLE void browserGoBack();
    Q_INVOKABLE void browserGoForward();
    Q_INVOKABLE void browserReload();

signals:
    void browserEmbeddedChanged();
    void browserUrlChanged(const QString &url);
    void webMenuCommunityChanged();

private:
    void syncFromBrowser();
    void onHostWindowDestroyed();

    WebView2Browser *m_browser = nullptr;


    QPointer<QQuickItem> m_placeholder;
    QPointer<QQuickWindow> m_parentWin;
    bool m_embedded = false;
    QString m_currentUrl;
    int m_community = 0;
};

#endif
