#include "webview2browser.h"
#include <QDebug>
#include <QStandardPaths>
#include <QDir>
#include <QCoreApplication>


struct ComCallbackBase {
    void *vtable;
    LONG refCount;
    void *userData;
};

static ULONG STDMETHODCALLTYPE Base_AddRef(IUnknown *This) {
    ComCallbackBase *self = (ComCallbackBase *)This;
    return InterlockedIncrement(&self->refCount);
}

static ULONG STDMETHODCALLTYPE Base_Release(IUnknown *This) {
    ComCallbackBase *self = (ComCallbackBase *)This;
    ULONG ref = InterlockedDecrement(&self->refCount);
    if (ref == 0) {
        free(self->vtable);
        free(self);
    }
    return ref;
}

static HRESULT STDMETHODCALLTYPE Base_QueryInterface(IUnknown *This, REFIID riid, void **ppv) {
    if (!ppv) return E_POINTER;
    *ppv = nullptr;
    if (IsEqualIID(riid, IID_IUnknown)) {
        *ppv = This;
        Base_AddRef(This);
        return S_OK;
    }
    return E_NOINTERFACE;
}

struct CallbackVTable {
    void *QueryInterface;
    void *AddRef;
    void *Release;
    void *Invoke;
};

static ComCallbackBase *CreateCallback(void *invoke, void *userData) {
    ComCallbackBase *obj = (ComCallbackBase *)calloc(1, sizeof(ComCallbackBase));
    CallbackVTable *vt = (CallbackVTable *)calloc(1, sizeof(CallbackVTable));
    vt->QueryInterface = (void *)Base_QueryInterface;
    vt->AddRef = (void *)Base_AddRef;
    vt->Release = (void *)Base_Release;
    vt->Invoke = invoke;
    obj->vtable = vt;
    obj->refCount = 1;
    obj->userData = userData;
    return obj;
}


typedef HRESULT(WINAPI *PFN_CreateCoreWebView2EnvironmentWithOptions)(
    PCWSTR browserExecutableFolder, PCWSTR userDataFolder,
    ICoreWebView2EnvironmentOptions *environmentOptions,
    ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *environment_created_handler);

static PFN_CreateCoreWebView2EnvironmentWithOptions g_pfnCreateEnv = nullptr;

static bool ensureLoaderLoaded()
{
    if (g_pfnCreateEnv)
        return true;
    HMODULE h = LoadLibraryW(L"WebView2Loader.dll");
    if (!h)
        return false;
    g_pfnCreateEnv = (PFN_CreateCoreWebView2EnvironmentWithOptions)
        GetProcAddress(h, "CreateCoreWebView2EnvironmentWithOptions");
    return g_pfnCreateEnv != nullptr;
}


static HRESULT STDMETHODCALLTYPE OnEnvCreated(IUnknown *This, HRESULT result, ICoreWebView2Environment *env);
static HRESULT STDMETHODCALLTYPE OnControllerCreated(IUnknown *This, HRESULT result, ICoreWebView2Controller *controller);
static HRESULT STDMETHODCALLTYPE OnNavigationStarting(IUnknown *This, ICoreWebView2 *sender, ICoreWebView2NavigationStartingEventArgs *args);
static HRESULT STDMETHODCALLTYPE OnNavigationCompleted(IUnknown *This, ICoreWebView2 *sender, ICoreWebView2NavigationCompletedEventArgs *args);


static const wchar_t kBrowserWndClass[] = L"HuskarUI_WebView2Browser";

static LRESULT CALLBACK BrowserWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}


WebView2Browser::WebView2Browser(QObject *parent)
    : QObject(parent)
{

    static bool classRegistered = false;
    if (!classRegistered) {
        WNDCLASSW wc{};
        wc.lpfnWndProc = BrowserWndProc;
        wc.hInstance = GetModuleHandleW(nullptr);
        wc.lpszClassName = kBrowserWndClass;
        RegisterClassW(&wc);
        classRegistered = true;
    }

}

WebView2Browser::~WebView2Browser()
{
    releaseNativeWindow();
}



void WebView2Browser::releaseNativeWindow()
{

    if (m_controller) {
        m_controller->put_IsVisible(FALSE);
        m_controller->Release();
        m_controller = nullptr;
    }
    if (m_webView) {
        m_webView->Release();
        m_webView = nullptr;
    }
    if (m_env) {
        m_env->Release();
        m_env = nullptr;
    }


    if (m_hwnd && IsWindow(m_hwnd))
        DestroyWindow(m_hwnd);
    m_hwnd = nullptr;
    m_parentHwnd = nullptr;
    m_initialized = false;
    m_showWhenReady = false;
    m_pendingUrl.clear();
}

bool WebView2Browser::attachToWindow(HWND parent)
{
    if (!parent)
        return false;

    if (hasValidWindow() && m_parentHwnd == parent)
        return m_initialized;



    releaseNativeWindow();
    m_parentHwnd = parent;
    m_hwnd = CreateWindowExW(
        WS_EX_NOACTIVATE | WS_EX_NOPARENTNOTIFY,
        kBrowserWndClass, L"WebMenuBrowser",
        WS_CHILD | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
        0, 0, 1, 1,
        parent, nullptr, GetModuleHandleW(nullptr), nullptr);
    if (!m_hwnd) {
        qWarning() << "WebView2: child window creation failed";
        return false;
    }
    initializeWebView2();
    return true;
}

void WebView2Browser::initializeWebView2()
{
    if (!ensureLoaderLoaded()) {
        qWarning() << "WebView2: Loader not found (WebView2Loader.dll missing)";
        emit initializationFinished(false);
        return;
    }

    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                     + QStringLiteral("/HuskarUIcs2配置文件/WebView2Cache");
    if (!QDir().mkpath(cacheDir))
        cacheDir = QCoreApplication::applicationDirPath() + QStringLiteral("/config/WebView2Cache");
    QDir().mkpath(cacheDir);
    const std::wstring cacheDirW = cacheDir.toStdWString();

    ComCallbackBase *envCb = CreateCallback((void *)OnEnvCreated, this);
    HRESULT hr = g_pfnCreateEnv(
        nullptr, cacheDirW.c_str(), nullptr,
        (ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler *)envCb);

    if (FAILED(hr)) {
        qWarning() << "WebView2: CreateCoreWebView2EnvironmentWithOptions failed:" << hr;
        emit initializationFinished(false);
    }
}

void WebView2Browser::navigate(const QString &url)
{
    if (!m_initialized || !m_webView) {
        m_pendingUrl = url;
        return;
    }
    const std::wstring wurl = url.toStdWString();
    m_webView->Navigate(wurl.c_str());
}

void WebView2Browser::setZoomFactor(double factor)
{
    m_zoomFactor = factor;
    if (m_controller)
        m_controller->put_ZoomFactor(factor);
    emit zoomFactorChanged(factor);
}

void WebView2Browser::showWhenReady()
{
    m_showWhenReady = true;
    if (m_controller)
        m_controller->put_IsVisible(TRUE);
}

void WebView2Browser::reload()
{
    if (m_webView) m_webView->Reload();
}

void WebView2Browser::goBack()
{
    if (m_webView) m_webView->GoBack();
}

void WebView2Browser::goForward()
{
    if (m_webView) m_webView->GoForward();
}

void WebView2Browser::updateBounds()
{
    if (m_controller && hasValidWindow()) {
        RECT bounds;
        GetClientRect(m_hwnd, &bounds);
        m_controller->put_Bounds(bounds);
    }
}

void WebView2Browser::showWindow()
{
    if (hasValidWindow())
        ShowWindow(m_hwnd, SW_SHOWNA);
}

void WebView2Browser::hideWindow()
{
    if (hasValidWindow())
        ShowWindow(m_hwnd, SW_HIDE);
}

void WebView2Browser::moveWindow(int x, int y, int w, int h)
{
    if (hasValidWindow()) {
        SetWindowPos(m_hwnd, nullptr, x, y, w, h,
                     SWP_NOACTIVATE | SWP_NOZORDER | SWP_NOOWNERZORDER);
        updateBounds();
        applyRoundedCorners();
    }
}

void WebView2Browser::setCornerRadius(int px)
{
    m_cornerRadiusPx = px;
    if (hasValidWindow())
        applyRoundedCorners();
}


static BOOL CALLBACK ApplyRoundRgnChildProc(HWND hwnd, LPARAM lParam)
{
    const int radius = (int)lParam;
    RECT rc;
    GetClientRect(hwnd, &rc);
    int w = rc.right - rc.left;
    int h = rc.bottom - rc.top;
    if (w > 0 && h > 0) {
        HRGN rgn = CreateRoundRectRgn(0, 0, w + 1, h + 1,
                                      radius * 2, radius * 2);
        if (rgn) {
            SetWindowRgn(hwnd, rgn, TRUE);
        }
    }
    return TRUE;
}

void WebView2Browser::applyRoundedCorners()
{
    if (!hasValidWindow() || m_cornerRadiusPx <= 0)
        return;
    RECT rc;
    GetClientRect(m_hwnd, &rc);
    int w = rc.right - rc.left;
    int h = rc.bottom - rc.top;
    if (w <= 0 || h <= 0)
        return;
    HRGN rgn = CreateRoundRectRgn(0, 0, w + 1, h + 1,
                                  m_cornerRadiusPx * 2, m_cornerRadiusPx * 2);
    if (rgn)
        SetWindowRgn(m_hwnd, rgn, TRUE);

    EnumChildWindows(m_hwnd, ApplyRoundRgnChildProc, (LPARAM)m_cornerRadiusPx);
}


static HRESULT STDMETHODCALLTYPE OnEnvCreated(IUnknown *This, HRESULT result, ICoreWebView2Environment *env)
{
    ComCallbackBase *cb = (ComCallbackBase *)This;
    WebView2Browser *browser = (WebView2Browser *)cb->userData;
    if (FAILED(result) || !env) {
        qWarning() << "WebView2: Environment creation failed, hr =" << result;
        emit browser->initializationFinished(false);
        return S_OK;
    }


    if (!browser->hasValidWindow()) {
        qWarning() << "WebView2: host window gone before env ready, abort init";
        return S_OK;
    }
    browser->m_env = env;
    env->AddRef();

    ComCallbackBase *ctrlCb = CreateCallback((void *)OnControllerCreated, browser);
    env->CreateCoreWebView2Controller(browser->m_hwnd,
        (ICoreWebView2CreateCoreWebView2ControllerCompletedHandler *)ctrlCb);
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE OnControllerCreated(IUnknown *This, HRESULT result, ICoreWebView2Controller *controller)
{
    ComCallbackBase *cb = (ComCallbackBase *)This;
    WebView2Browser *browser = (WebView2Browser *)cb->userData;
    if (FAILED(result) || !controller) {
        qWarning() << "WebView2: Controller creation failed, hr =" << result;
        emit browser->initializationFinished(false);
        return S_OK;
    }


    if (!browser->hasValidWindow()) {
        qWarning() << "WebView2: host window gone before controller ready, abort init";
        return S_OK;
    }
    browser->m_controller = controller;
    controller->AddRef();
    controller->get_CoreWebView2(&browser->m_webView);

    controller->put_IsVisible(FALSE);
    browser->setZoomFactor(0.8);

    if (browser->m_webView) {
        ComCallbackBase *navStartCb = CreateCallback((void *)OnNavigationStarting, browser);
        browser->m_webView->add_NavigationStarting(
            (ICoreWebView2NavigationStartingEventHandler *)navStartCb, nullptr);
        ComCallbackBase *navDoneCb = CreateCallback((void *)OnNavigationCompleted, browser);
        browser->m_webView->add_NavigationCompleted(
            (ICoreWebView2NavigationCompletedEventHandler *)navDoneCb, nullptr);
    }

    RECT bounds;
    GetClientRect(browser->m_hwnd, &bounds);
    controller->put_Bounds(bounds);

    browser->m_initialized = true;
    emit browser->initializationFinished(true);

    if (browser->m_showWhenReady)
        controller->put_IsVisible(TRUE);

    if (!browser->m_pendingUrl.isEmpty()) {
        browser->navigate(browser->m_pendingUrl);
        browser->m_pendingUrl.clear();
    }
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE OnNavigationStarting(IUnknown *This, ICoreWebView2 *sender, ICoreWebView2NavigationStartingEventArgs *args)
{
    Q_UNUSED(sender);
    ComCallbackBase *cb = (ComCallbackBase *)This;
    WebView2Browser *browser = (WebView2Browser *)cb->userData;
    LPWSTR url = nullptr;
    args->get_Uri(&url);
    if (url) {
        browser->m_currentUrl = QString::fromWCharArray(url);
        emit browser->urlChanged(browser->m_currentUrl);
        CoTaskMemFree(url);
    }
    return S_OK;
}

static HRESULT STDMETHODCALLTYPE OnNavigationCompleted(IUnknown *This, ICoreWebView2 *sender, ICoreWebView2NavigationCompletedEventArgs *args)
{
    Q_UNUSED(sender);
    Q_UNUSED(args);
    ComCallbackBase *cb = (ComCallbackBase *)This;
    WebView2Browser *browser = (WebView2Browser *)cb->userData;
    emit browser->navigationCompleted();
    return S_OK;
}
