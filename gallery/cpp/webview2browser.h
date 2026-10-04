#ifndef WEBVIEW2BROWSER_H
#define WEBVIEW2BROWSER_H

#include <QObject>
#include <QString>
#include <windows.h>
#include "WebView2.h"




class WebView2Browser : public QObject
{
    Q_OBJECT
public:
    explicit WebView2Browser(QObject *parent = nullptr);
    ~WebView2Browser();

    void navigate(const QString &url);
    void reload();
    void goBack();
    void goForward();
    void setZoomFactor(double factor);
    void showWhenReady();
    void updateBounds();
    void showWindow();
    void hideWindow();
    bool attachToWindow(HWND parent);
    void moveWindow(int x, int y, int w, int h);
    void setCornerRadius(int px);
    bool isInitialized() const { return m_initialized; }
    QString currentUrl() const { return m_currentUrl; }
    HWND hwnd() const { return m_hwnd; }




    void releaseNativeWindow();

    bool hasValidWindow() const { return m_hwnd != nullptr && IsWindow(m_hwnd); }

    HWND m_hwnd = nullptr;
    HWND m_parentHwnd = nullptr;
    int m_cornerRadiusPx = 0;
    ICoreWebView2Environment *m_env = nullptr;
    ICoreWebView2Controller *m_controller = nullptr;
    ICoreWebView2 *m_webView = nullptr;
    bool m_initialized = false;
    bool m_showWhenReady = false;
    QString m_pendingUrl;
    QString m_currentUrl;
    double m_zoomFactor = 0.8;

signals:
    void initializationFinished(bool success);
    void urlChanged(const QString &url);
    void navigationCompleted();
    void zoomFactorChanged(double factor);

private:
    void initializeWebView2();
    void applyRoundedCorners();
};

#endif
