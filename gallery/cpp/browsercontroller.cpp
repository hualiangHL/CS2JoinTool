#include "browsercontroller.h"
#include "webview2browser.h"
#include <QQuickWindow>
#include <QDebug>

BrowserController::BrowserController(QObject *parent)
    : QObject(parent)
{
    m_browser = new WebView2Browser(this);
    connect(m_browser, &WebView2Browser::urlChanged, this, [this](const QString &u) {
        m_currentUrl = u;
        emit browserUrlChanged(u);
    });
    connect(m_browser, &WebView2Browser::initializationFinished, this, [this](bool ok) {
        qWarning() << "BrowserController: WebView2 init finished, ok =" << ok;
        if (ok && m_placeholder) {
            embedBrowser(m_placeholder);
        }
    });
}

BrowserController::~BrowserController()
{


    if (m_browser)
        m_browser->releaseNativeWindow();
}

void BrowserController::setWebMenuCommunity(int v)
{
    if (m_community == v)
        return;
    m_community = v;
    emit webMenuCommunityChanged();
}

void BrowserController::embedBrowser(QQuickItem *placeholder)
{
    if (!placeholder)
        return;
    m_placeholder = placeholder;

    QQuickWindow *win = placeholder->window();
    if (!win) {
        qWarning() << "BrowserController: placeholder has no window";
        return;
    }





    if (m_parentWin != win) {
        if (m_parentWin)
            disconnect(m_parentWin.data(), nullptr, this, nullptr);
        m_parentWin = win;


        connect(win, &QObject::destroyed,
                this, &BrowserController::onHostWindowDestroyed);
        connect(win, &QQuickWindow::xChanged,
                this, &BrowserController::updateBrowserGeometry);
        connect(win, &QQuickWindow::yChanged,
                this, &BrowserController::updateBrowserGeometry);
        connect(win, &QQuickWindow::widthChanged,
                this, &BrowserController::updateBrowserGeometry);
        connect(win, &QQuickWindow::heightChanged,
                this, &BrowserController::updateBrowserGeometry);
    }


    m_browser->attachToWindow((HWND)win->winId());


    syncFromBrowser();
    m_browser->showWhenReady();
    m_browser->showWindow();
    m_embedded = true;
    emit browserEmbeddedChanged();
}

void BrowserController::updateBrowserGeometry()
{
    if (!m_placeholder || !m_embedded)
        return;
    syncFromBrowser();
}

void BrowserController::syncFromBrowser()
{
    if (!m_placeholder || !m_browser)
        return;
    HWND browserHwnd = m_browser->hwnd();
    if (!browserHwnd)
        return;

    QQuickWindow *win = m_placeholder->window();
    if (!win)
        return;


    const QPointF localPos = m_placeholder->mapToItem(win->contentItem(), QPointF(0, 0));
    const qreal dpr = win->devicePixelRatio();

    const int x = qRound(localPos.x() * dpr);
    const int y = qRound(localPos.y() * dpr);
    const int cw = qMax(1, qRound(m_placeholder->width() * dpr));
    const int ch = qMax(1, qRound(m_placeholder->height() * dpr));


    m_browser->setCornerRadius(0);
    const int pad = qRound(2 * dpr);
    m_browser->moveWindow(x + pad, y + pad, qMax(1, cw - 2 * pad), qMax(1, ch - 2 * pad));
}

void BrowserController::hideBrowserWindow()
{
    if (m_browser)
        m_browser->hideWindow();
}

void BrowserController::showBrowserWindow()
{
    if (m_browser) {
        m_browser->showWhenReady();
        m_browser->showWindow();
    }
}

void BrowserController::detachBrowser()
{
    if (m_browser)
        m_browser->hideWindow();
    if (m_parentWin) {
        disconnect(m_parentWin.data(), nullptr, this, nullptr);
        m_parentWin = nullptr;
    }
    m_placeholder = nullptr;
    m_embedded = false;
    emit browserEmbeddedChanged();
}




void BrowserController::shutdownBrowser()
{
    if (m_browser)
        m_browser->releaseNativeWindow();
    if (m_parentWin) {
        disconnect(m_parentWin.data(), nullptr, this, nullptr);
        m_parentWin = nullptr;
    }
    m_placeholder = nullptr;
    m_embedded = false;
    emit browserEmbeddedChanged();
}



void BrowserController::onHostWindowDestroyed()
{
    m_placeholder = nullptr;
    m_embedded = false;
    emit browserEmbeddedChanged();
}

void BrowserController::browserNavigate(const QString &url)
{
    if (m_browser)
        m_browser->navigate(url);
}

void BrowserController::browserGoBack()
{
    if (m_browser)
        m_browser->goBack();
}

void BrowserController::browserGoForward()
{
    if (m_browser)
        m_browser->goForward();
}

void BrowserController::browserReload()
{
    if (m_browser)
        m_browser->reload();
}
