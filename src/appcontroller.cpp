#include "appcontroller.h"
#include <QDateTime>
#include <QProcess>
#include <QDesktopServices>
#include <QUrl>
#include <QPainter>
#include <QMenu>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QClipboard>
#include <QWindow>
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QTimer>
#include <QQueue>
#include <QOperatingSystemVersion>

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <shellapi.h>
#endif

#ifdef Q_OS_WIN
static HWND g_sysNotifyHwnd = nullptr;
static const UINT g_sysNotifyUid = 0x57A2;
static QQueue<QPair<QString, QString>> g_sysNotifyQueue;
static bool g_sysNotifyShowing = false;
static bool g_trayIconRegistered = false;
static QTimer *g_sysNotifyWatchdog = nullptr;
static QTimer *g_trayCleanupTimer = nullptr;

static void deleteTrayIconOnly()
{
    if (g_trayIconRegistered && g_sysNotifyHwnd) {
        NOTIFYICONDATAW nid;
        memset(&nid, 0, sizeof(nid));
        nid.cbSize = sizeof(nid);
        nid.hWnd = g_sysNotifyHwnd;
        nid.uID = g_sysNotifyUid;
        Shell_NotifyIconW(NIM_DELETE, &nid);
        g_trayIconRegistered = false;
        qDebug() << "[Notify] tray icon removed after notification";
    }
}

static void ensureSysNotifyWindow()
{
    if (g_sysNotifyHwnd) return;
    static const wchar_t className[] = L"CS2JoinSysNotify";
    WNDCLASSEXW wc;
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = DefWindowProcW;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = className;
    RegisterClassExW(&wc);
    g_sysNotifyHwnd = CreateWindowExW(0, className, L"SysNotify", 0,
                                        0, 0, 0, 0, HWND_MESSAGE, nullptr, wc.hInstance, nullptr);
}

static HICON LoadAppIcon()
{
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);
    HICON hLarge = nullptr, hSmall = nullptr;
    if (ExtractIconExW(exePath, 0, &hLarge, &hSmall, 1) > 0) {
        if (hLarge) DestroyIcon(hLarge);
        if (hSmall) return hSmall;
    }
    return LoadIcon(nullptr, IDI_APPLICATION);
}

static void ensureTrayIconRegistered()
{
    if (g_trayIconRegistered) return;
    ensureSysNotifyWindow();
    if (!g_sysNotifyHwnd) return;

    NOTIFYICONDATAW nid;
    memset(&nid, 0, sizeof(nid));
    nid.cbSize = sizeof(nid);
    nid.hWnd = g_sysNotifyHwnd;
    nid.uID = g_sysNotifyUid;
    nid.uFlags = NIF_ICON | NIF_MESSAGE;
    nid.uCallbackMessage = WM_USER + 1;
    nid.hIcon = LoadAppIcon();
    wcsncpy(nid.szTip, L"CS2挤服工具v4_2", 127);
    nid.szTip[127] = L'\0';

    Shell_NotifyIconW(NIM_ADD, &nid);
    g_trayIconRegistered = true;
    qDebug() << "[Notify] tray icon registered for notifications";
}

static void showNotifyNow(const QString &title, const QString &message)
{
    ensureTrayIconRegistered();
    if (!g_sysNotifyHwnd) return;

    NOTIFYICONDATAW nid;
    memset(&nid, 0, sizeof(nid));
    nid.cbSize = sizeof(nid);
    nid.hWnd = g_sysNotifyHwnd;
    nid.uID = g_sysNotifyUid;
    nid.uFlags = NIF_INFO | NIF_ICON;
    nid.dwInfoFlags = 0;
    nid.hIcon = LoadAppIcon();

    QString safeTitle = title;
    if (safeTitle.length() > 60) safeTitle = safeTitle.left(60) + "...";
    QString safeMsg = message;
    if (safeMsg.length() > 250) safeMsg = safeMsg.left(250) + "...";

    std::wstring wTitle = safeTitle.toStdWString();
    std::wstring wMsg = safeMsg.toStdWString();
    wcsncpy(nid.szInfoTitle, wTitle.c_str(), 63);
    nid.szInfoTitle[63] = L'\0';
    wcsncpy(nid.szInfo, wMsg.c_str(), 255);
    nid.szInfo[255] = L'\0';

    Shell_NotifyIconW(NIM_MODIFY, &nid);
    qDebug() << "[Notify] shown:" << title << "-" << message.left(40);
}

static void processNextNotify()
{
    if (!g_sysNotifyQueue.isEmpty()) {
        QPair<QString, QString> next = g_sysNotifyQueue.dequeue();
        showNotifyNow(next.first, next.second);
        if (g_sysNotifyWatchdog) g_sysNotifyWatchdog->start(1500);
    } else {
        g_sysNotifyShowing = false;
        if (g_sysNotifyWatchdog) g_sysNotifyWatchdog->stop();
        if (!g_trayCleanupTimer) {
            g_trayCleanupTimer = new QTimer();
            g_trayCleanupTimer->setSingleShot(true);
            QObject::connect(g_trayCleanupTimer, &QTimer::timeout, []() { deleteTrayIconOnly(); });
        }
        g_trayCleanupTimer->start(5000);
    }
}

static void doShowSysNotify(const QString &title, const QString &message)
{
    if (g_trayCleanupTimer) g_trayCleanupTimer->stop();
    if (g_sysNotifyShowing) {
        g_sysNotifyQueue.enqueue(qMakePair(title, message));
        return;
    }
    g_sysNotifyShowing = true;
    showNotifyNow(title, message);

    if (!g_sysNotifyWatchdog) {
        g_sysNotifyWatchdog = new QTimer();
        g_sysNotifyWatchdog->setSingleShot(true);
        QObject::connect(g_sysNotifyWatchdog, &QTimer::timeout, []() { processNextNotify(); });
    }
    g_sysNotifyWatchdog->start(1500);
}

static void showSysNotification(const QString &title, const QString &message)
{
    doShowSysNotify(title, message);
}

static void cleanupSysNotifyTray()
{
    if (g_trayIconRegistered && g_sysNotifyHwnd) {
        NOTIFYICONDATAW nid;
        memset(&nid, 0, sizeof(nid));
        nid.cbSize = sizeof(nid);
        nid.hWnd = g_sysNotifyHwnd;
        nid.uID = g_sysNotifyUid;
        Shell_NotifyIconW(NIM_DELETE, &nid);
        g_trayIconRegistered = false;
        qDebug() << "[Notify] tray icon cleaned up";
    }
    if (g_sysNotifyHwnd) {
        DestroyWindow(g_sysNotifyHwnd);
        g_sysNotifyHwnd = nullptr;
    }
}
#endif

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_query(new ServerQuery(this))
    , m_autoJoinTimer(new QTimer(this))
    , m_toastForceTimer(new QTimer(this))
    , m_toastCooldownTimer(new QTimer(this))
    , m_toastGapTimer(new QTimer(this))
    , m_settings(new QSettings(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件/settings.ini", QSettings::IniFormat, this))
    , m_serverPort(27015)
    , m_interval(100.0)
    , m_autoJoining(false)
    , m_connected(false)
    , m_retryCount(0)
    , m_maxRetryCount(999999)
    , m_darkTheme(true)
    , m_alwaysOnTop(false)
    , m_autoRetryJoin(true)
    , m_currentPlayers(0)
    , m_maxPlayers(0)
    , m_serverStatus(0)
    , m_joinPhase(0)
    , m_connectProtocol(0)
    , m_defaultConnectProtocol(1)
    , m_joinThreshold(63)
    , m_bgMode(0)
    , m_transparentWindow(false)
    , m_proMode(false)
    , m_defaultJoinInterval(100.0)
    , m_cpuCoreCount(qMax(1, QThread::idealThreadCount()))
    , m_joinCoreCount(2)
    , m_activeJoinCoreCount(2)
    , m_floatWindowEnabled(true)
    , m_closeBehavior(0)
    , m_startMinimizedToTray(false)
    , m_difficultyTierMode(false)
    , m_joinNotificationEnabled(false)
    , m_debugPlayerList(false)
{
    connect(m_query, &ServerQuery::queryFinished, this, &AppController::onQueryFinished);
    connect(m_query, &ServerQuery::queryError, this, &AppController::onQueryError);

    
    m_autoJoinTimer->setInterval(50);
    m_autoJoinTimer->setTimerType(Qt::PreciseTimer);
    m_autoJoinTimer->setSingleShot(false);
    connect(m_autoJoinTimer, &QTimer::timeout, this, &AppController::onAutoJoinTick);

    m_toastForceTimer->setSingleShot(true);
    m_toastForceTimer->setInterval(5000);
    connect(m_toastForceTimer, &QTimer::timeout, this, [this]() {
        emit forceHideToast();
        m_toastShowing = false;
        emit toastShowingChanged(false);
        if (!m_toastQueue.isEmpty()) {
            m_toastGapTimer->start();
        }
    });

    m_toastGapTimer->setSingleShot(true);
    m_toastGapTimer->setInterval(800);
    connect(m_toastGapTimer, &QTimer::timeout, this, [this]() {
        tryShowNextToast();
    });

    m_toastCooldownTimer->setInterval(1000);
    connect(m_toastCooldownTimer, &QTimer::timeout, this, [this]() {
        m_toastCooldownRemaining--;
        emit toastCooldownRemainingChanged(m_toastCooldownRemaining);
        if (m_toastCooldownRemaining <= 0) {
            m_toastCooldownTimer->stop();
            m_toastCooldown = false;
            tryShowNextToast();
        }
    });

    
    QDir().mkpath(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件");

    loadSettings();
    setStatus("就绪");

    m_activateServer = new QLocalServer(this);
    QLocalServer::removeServer("CS2JoinTool_ActivatePipe");
    if (m_activateServer->listen("CS2JoinTool_ActivatePipe")) {
        connect(m_activateServer, &QLocalServer::newConnection, this, [this]() {
            QLocalSocket *socket = m_activateServer->nextPendingConnection();
            connect(socket, &QLocalSocket::readyRead, this, [this, socket]() {
                QString msg = QString::fromUtf8(socket->readAll());
                if (msg == "activate") {
                    emit activateRequested();
                }
                socket->close();
                socket->deleteLater();
            });
            connect(socket, &QLocalSocket::disconnected, socket, &QLocalSocket::deleteLater);
        });
    }

    
    if (QSystemTrayIcon::isSystemTrayAvailable()) {
        m_tray = new QSystemTrayIcon(this);
        m_tray->setIcon(QIcon(":/assets/app_icon.png"));
        m_tray->setToolTip("CS2挤服工具v4_2");

        QMenu *menu = new QMenu();
        QAction *showAct = menu->addAction("显示主窗口");
        QAction *quitAct = menu->addAction("退出");
        connect(showAct, &QAction::triggered, this, &AppController::showMainWindow);
        connect(quitAct, &QAction::triggered, this, &AppController::quitApp);
        m_tray->setContextMenu(menu);
        connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
            if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
                showMainWindow();
            }
        });
        m_tray->show();
    }
}

AppController::~AppController()
{
    saveSettings();
#ifdef Q_OS_WIN
    cleanupSysNotifyTray();
#endif
}

void AppController::setServerIp(const QString &ip)
{
    if (m_serverIp != ip) {
        m_serverIp = ip;
        emit serverIpChanged(ip);
    }
}

void AppController::setServerPort(int port)
{
    if (m_serverPort != port) {
        m_serverPort = port;
        emit serverPortChanged(port);
    }
}

void AppController::setServerPassword(const QString &pwd)
{
    if (m_serverPassword != pwd) {
        m_serverPassword = pwd;
        emit serverPasswordChanged(pwd);
    }
}

void AppController::setInterval(double ms)
{
    if (m_interval != ms) {
        m_interval = ms;
        emit intervalChanged(ms);
        
        if (m_autoJoining && m_autoJoinTimer) {
            int tickMs = qMax(1, (int)ceil(ms));
            m_autoJoinTimer->setInterval(tickMs);
        }
    }
}

void AppController::setConnectProtocol(int proto)
{
    if (m_connectProtocol != proto) {
        m_connectProtocol = proto;
        emit connectProtocolChanged(proto);
    }
}

void AppController::setDefaultConnectProtocol(int proto)
{
    if (m_defaultConnectProtocol != proto) {
        m_defaultConnectProtocol = proto;
        emit defaultConnectProtocolChanged(proto);
        saveSettings();
    }
}

void AppController::setJoinThreshold(int threshold)
{
    int clamped = qMax(20, qMin(63, threshold));
    if (m_joinThreshold != clamped) {
        m_joinThreshold = clamped;
        emit joinThresholdChanged(clamped);
    }
}

void AppController::setBgMode(int mode)
{
    if (m_bgMode != mode) {
        m_bgMode = mode;
        emit bgModeChanged(mode);
    }
}

void AppController::setTransparentWindow(bool t)
{
    if (m_transparentWindow != t) {
        m_transparentWindow = t;
        emit transparentWindowChanged(t);
    }
}

void AppController::setProMode(bool p)
{
    if (m_proMode != p) {
        m_proMode = p;
        emit proModeChanged(p);
        
        if (!p && m_interval < 50.0) {
            setInterval(50.0);
        }
    }
}

void AppController::setDefaultJoinInterval(double v)
{
    if (v < 50.0 || v > 500.0) v = 100.0;
    if (m_defaultJoinInterval != v) {
        m_defaultJoinInterval = v;
        emit defaultJoinIntervalChanged(v);
        setInterval(v);
    }
}

void AppController::setJoinCoreCount(int c)
{
    int maxCores = qMax(1, m_cpuCoreCount);
    if (c < 1) c = 1;
    if (c > maxCores) c = maxCores;
    if (m_joinCoreCount != c) {
        m_joinCoreCount = c;
        emit joinCoreCountChanged(c);
        saveSettings();
    }
}

void AppController::setActiveJoinCoreCount(int c)
{
    int maxCores = qMax(1, m_cpuCoreCount);
    if (c < 1) c = 1;
    if (c > maxCores) c = maxCores;
    if (m_activeJoinCoreCount != c) {
        m_activeJoinCoreCount = c;
        emit activeJoinCoreCountChanged(c);
    }
}

void AppController::setFloatWindowEnabled(bool e)
{
    if (m_floatWindowEnabled != e) {
        m_floatWindowEnabled = e;
        emit floatWindowEnabledChanged(e);
    }
}

void AppController::setMaxRetryCount(int max)
{
    if (m_maxRetryCount != max) {
        m_maxRetryCount = max < 0 ? 0 : max;
        emit maxRetryCountChanged(m_maxRetryCount);
    }
}

void AppController::setConnected(bool c)
{
    if (m_connected != c) {
        m_connected = c;
        emit connectedChanged(c);
    }
}

void AppController::setDarkTheme(bool dark)
{
    if (m_darkTheme != dark) {
        m_darkTheme = dark;
        emit darkThemeChanged(dark);
    }
}

void AppController::setAlwaysOnTop(bool top)
{
    if (m_alwaysOnTop != top) {
        m_alwaysOnTop = top;
        emit alwaysOnTopChanged(top);
    }
}

void AppController::setAutoRetryJoin(bool retry)
{
    if (m_autoRetryJoin != retry) {
        m_autoRetryJoin = retry;
        emit autoRetryJoinChanged(retry);
    }
}

void AppController::setStatus(const QString &text)
{
    m_statusText = text;
    emit statusTextChanged(text);
}

void AppController::setJoinStatus(const QString &text, int phase)
{
    m_joinStatus = text;
    m_joinPhase = phase;
    emit joinStatusChanged(text);
    emit joinPhaseChanged(phase);
}

void AppController::appendLog(const QString &msg, bool isError)
{
    QString timestamp = QDateTime::currentDateTime().toString("HH:mm:ss");
    QString line = QString("[%1] %2").arg(timestamp, msg);
    if (isError) line = "[错误] " + line;
    m_logText += line + "\n";
    if (m_logText.length() > 5000) {
        m_logText = m_logText.right(4000);
    }
    emit logTextChanged(m_logText);
}

void AppController::queryServer()
{
    if (m_serverIp.isEmpty() || m_serverPort <= 0) {
        appendLog("请输入有效的服务器IP和端口", true);
        return;
    }
    if (!m_autoJoining) {
        setStatus("查询中...");
        
        m_serverStatus = 0;
        m_currentPlayers = 0;
        m_maxPlayers = 0;
        m_currentMap = "";
        m_currentServerName = "";
        emit serverStatusChanged(0);
        emit currentPlayersChanged(0);
        emit maxPlayersChanged(0);
        emit currentMapChanged("");
        emit currentServerNameChanged("");
    }
    m_query->queryServer(m_serverIp, m_serverPort);
}

void AppController::onQueryFinished(const ServerInfo &info)
{
    m_currentPlayers = info.players;
    m_maxPlayers = info.maxPlayers;
    m_currentMap = info.mapName;
    m_currentServerName = info.serverName;
    m_serverStatus = 1;

    emit currentPlayersChanged(info.players);
    emit maxPlayersChanged(info.maxPlayers);
    emit currentMapChanged(info.mapName);
    emit currentServerNameChanged(info.serverName);
    emit serverStatusChanged(1);

    if (!m_autoJoining) {
        setStatus(QString("在线 - %1/%2 玩家").arg(info.players).arg(info.maxPlayers));
    }

    
    if (m_autoJoining) {
        m_retryCount++;
        emit retryCountChanged(m_retryCount);

        
        if (m_maxRetryCount > 0 && m_retryCount >= m_maxRetryCount) {
            setJoinStatus(QString("已达到最大尝试次数 %1，停止挤服").arg(m_maxRetryCount), 5);
            appendLog(QString("已达到最大尝试次数 %1，自动停止").arg(m_maxRetryCount));
            stopAutoJoin();
            return;
        }

        int humanPlayers = info.players - info.bots;
        bool hasSlot = (info.players < info.maxPlayers && humanPlayers <= m_joinThreshold);

        if (hasSlot) {
            
            setJoinStatus(QString("发现空位！人数 %1/%2 (人类%3)，正在连接...").arg(info.players).arg(info.maxPlayers).arg(humanPlayers), 3);
            appendLog(QString("发现空位！人数 %1/%2 (人类%3) 阈值%4，正在连接...").arg(info.players).arg(info.maxPlayers).arg(humanPlayers).arg(m_joinThreshold));
            joinNow(true);
        } else {
            setJoinStatus(QString("人数 %1/%2 (人类%3) 阈值%4，等待中...").arg(info.players).arg(info.maxPlayers).arg(humanPlayers).arg(m_joinThreshold), 2);
        }
    }
}

void AppController::onQueryError(const QString &error)
{
    m_serverStatus = 2;
    emit serverStatusChanged(2);
    if (!m_autoJoining) {
        setStatus("离线/无响应");
    }
    appendLog(error, true);
    
}

void AppController::startAutoJoin()
{
    if (m_serverIp.isEmpty() || m_serverPort <= 0) {
        appendLog("请先输入服务器地址", true);
        return;
    }
    if (m_autoJoining) return;

    m_autoJoining = true;
    m_retryCount = 0;
    emit autoJoiningChanged(true);
    emit retryCountChanged(0);

    setStatus("自动挤服中...");
    setJoinStatus("正在查询服务器...", 1);
    appendLog(QString("开始自动挤服: %1:%2 (间隔%3ms)").arg(m_serverIp).arg(m_serverPort).arg(m_interval));

    
    int tickMs = qMax(1, (int)ceil(m_interval));
    m_autoJoinTimer->setInterval(tickMs);

    
    queryServer();
    m_autoJoinTimer->start();
}

void AppController::stopAutoJoin()
{
    if (!m_autoJoining) return;
    m_autoJoining = false;
    m_autoJoinTimer->stop();
    emit autoJoiningChanged(false);
    setStatus("已停止");
    setJoinStatus("", 0);
    appendLog("自动挤服已停止");
}

void AppController::cancelJoin()
{
    if (!m_autoJoining) return;
    m_autoJoining = false;
    m_autoJoinTimer->stop();
    emit autoJoiningChanged(false);
    setStatus("已取消");
    setJoinStatus("已取消挤服", 0);
    appendLog("用户取消挤服");
}

void AppController::onAutoJoinTick()
{
    
    if (m_autoJoining) {
        int cores = qMax(1, m_activeJoinCoreCount);
        for (int i = 0; i < cores; i++) {
            m_query->queryServerWithoutReset();
        }
    }
}

void AppController::joinNow(bool autoJoin)
{
    if (m_serverIp.isEmpty() || m_serverPort <= 0) {
        appendLog("请先输入服务器地址", true);
        return;
    }
    appendLog(QString("正在连接 %1:%2 ...").arg(m_serverIp).arg(m_serverPort));

    bool ok = ServerQuery::connectToServer(m_serverIp, m_serverPort, m_serverPassword, m_connectProtocol);

    if (ok) {
        setStatus("已发送连接请求");
        setJoinStatus("连接成功！正在进入服务器...", 4);
        appendLog("连接指令已发送到Steam");
#ifdef Q_OS_WIN
        MessageBeep(MB_ICONINFORMATION);
#endif
        if (autoJoin) {
            setConnected(true);
            emit joinSuccess();
            if (m_joinNotificationEnabled) {
                showToastNotification("挤服成功", "已连接服务器，正在进入游戏...");
            }
        } else {
            if (m_joinNotificationEnabled) {
                showToastNotification("加入服务器成功", "已发送连接请求，正在进入游戏...");
            }
        }
        if (m_autoJoining) {
            m_autoJoining = false;
            m_autoJoinTimer->stop();
            emit autoJoiningChanged(false);
        }
    } else {
        setJoinStatus("连接失败，请检查Steam是否运行", 5);
        appendLog("连接失败", true);
        emit joinFailed("连接失败");
    }
}

void AppController::clearLog()
{
    m_logText.clear();
    emit logTextChanged(m_logText);
}

void AppController::saveSettings()
{
    m_settings->setValue("serverIp", m_serverIp);
    m_settings->setValue("serverPort", m_serverPort);
    m_settings->setValue("serverPassword", m_serverPassword);
    m_settings->setValue("interval", m_interval);
    m_settings->setValue("darkTheme", m_darkTheme);
    m_settings->setValue("alwaysOnTop", m_alwaysOnTop);
    m_settings->setValue("autoRetryJoin", m_autoRetryJoin);
    m_settings->setValue("connectProtocol", m_connectProtocol);
    m_settings->setValue("defaultConnectProtocol", m_defaultConnectProtocol);
    m_settings->setValue("joinThreshold", m_joinThreshold);
    m_settings->setValue("bgMode", m_bgMode);
    m_settings->setValue("transparentWindow", m_transparentWindow);
    m_settings->setValue("proMode", m_proMode);
    m_settings->setValue("defaultJoinInterval", m_defaultJoinInterval);
    m_settings->setValue("joinCoreCount", m_joinCoreCount);
    m_settings->setValue("floatWindowEnabled", m_floatWindowEnabled);
    m_settings->setValue("closeBehavior", m_closeBehavior);
    m_settings->setValue("startMinimizedToTray", m_startMinimizedToTray);
    m_settings->setValue("difficultyTierMode", m_difficultyTierMode);
    m_settings->setValue("joinNotificationEnabled", m_joinNotificationEnabled);
    m_settings->setValue("minimizeNotificationEnabled", m_minimizeNotificationEnabled);
    m_settings->setValue("debugPlayerList", m_debugPlayerList);
    m_settings->setValue("webMenuCommunity", m_webMenuCommunity);
    m_settings->setValue("maxRetryCount", m_maxRetryCount);
    m_settings->setValue("cardViewMode", m_cardViewMode);
    m_settings->setValue("serverListFilterOptions", m_serverListFilterOptions);
    m_settings->sync();
}

void AppController::loadSettings()
{
    m_serverIp = "";
    m_serverPort = m_settings->value("serverPort", 27015).toInt();
    m_serverPassword = m_settings->value("serverPassword", "").toString();
    m_interval = m_defaultJoinInterval;
    m_darkTheme = m_settings->value("darkTheme", true).toBool();
    m_alwaysOnTop = m_settings->value("alwaysOnTop", false).toBool();
    m_autoRetryJoin = m_settings->value("autoRetryJoin", true).toBool();
    m_connectProtocol = m_settings->value("connectProtocol", 0).toInt();
    m_defaultConnectProtocol = m_settings->value("defaultConnectProtocol", 1).toInt();
    m_joinThreshold = 63;
    m_bgMode = m_settings->value("bgMode", 0).toInt();
    m_transparentWindow = m_settings->value("transparentWindow", false).toBool();
    m_proMode = m_settings->value("proMode", false).toBool();
    m_defaultJoinInterval = m_settings->value("defaultJoinInterval", 100.0).toDouble();
    m_joinCoreCount = m_settings->value("joinCoreCount", 2).toInt();
    if (m_joinCoreCount < 1) m_joinCoreCount = 1;
    if (m_joinCoreCount > m_cpuCoreCount) m_joinCoreCount = m_cpuCoreCount;
    m_floatWindowEnabled = m_settings->value("floatWindowEnabled", true).toBool();
    m_closeBehavior = m_settings->value("closeBehavior", 0).toInt();
    m_startMinimizedToTray = m_settings->value("startMinimizedToTray", false).toBool();
    m_difficultyTierMode = m_settings->value("difficultyTierMode", false).toBool();
    m_joinNotificationEnabled = m_settings->value("joinNotificationEnabled", false).toBool();
    m_minimizeNotificationEnabled = m_settings->value("minimizeNotificationEnabled", true).toBool();
    m_debugPlayerList = m_settings->value("debugPlayerList", false).toBool();
    m_webMenuCommunity = m_settings->value("webMenuCommunity", 0).toInt();
    m_maxRetryCount = m_settings->value("maxRetryCount", 999999).toInt();
    m_cardViewMode = m_settings->value("cardViewMode", false).toBool();
    m_serverListFilterOptions = m_settings->value("serverListFilterOptions", QStringList()).toStringList();

    emit serverIpChanged(m_serverIp);
    emit serverPortChanged(m_serverPort);
    emit serverPasswordChanged(m_serverPassword);
    emit intervalChanged(m_interval);
    emit darkThemeChanged(m_darkTheme);
    emit alwaysOnTopChanged(m_alwaysOnTop);
    emit autoRetryJoinChanged(m_autoRetryJoin);
    
    m_connectProtocol = m_defaultConnectProtocol;
    emit connectProtocolChanged(m_connectProtocol);
    emit defaultConnectProtocolChanged(m_defaultConnectProtocol);
    emit joinThresholdChanged(m_joinThreshold);
    emit bgModeChanged(m_bgMode);
    emit transparentWindowChanged(m_transparentWindow);
    emit proModeChanged(m_proMode);
    emit defaultJoinIntervalChanged(m_defaultJoinInterval);
    emit floatWindowEnabledChanged(m_floatWindowEnabled);
    emit closeBehaviorChanged(m_closeBehavior);
    emit startMinimizedToTrayChanged(m_startMinimizedToTray);
    emit difficultyTierModeChanged(m_difficultyTierMode);
    emit joinNotificationEnabledChanged(m_joinNotificationEnabled);
    emit maxRetryCountChanged(m_maxRetryCount);
}

QString AppController::difficultyToTier(const QString &diff)
{
    if (diff.contains("简单")) return "T0";
    if (diff.contains("普通")) return "T1";
    if (diff.contains("困难")) return "T2";
    if (diff.contains("极难")) return "T3";
    if (diff.contains("史诗")) return "T4";
    if (diff.contains("梦魇")) return "T5";
    if (diff.contains("绝境")) return "T6";
    return diff;
}

void AppController::openUrlDefaultBrowser(const QString &url)
{
#ifdef Q_OS_WIN
    QString browserCmd;

    
    QSettings httpsChoice(
        "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\https\\UserChoice",
        QSettings::NativeFormat);
    QString progId = httpsChoice.value("ProgId").toString();
    if (!progId.isEmpty()) {
        QSettings cmdKey("HKEY_CLASSES_ROOT\\" + progId + "\\shell\\open\\command",
                         QSettings::NativeFormat);
        browserCmd = cmdKey.value(".").toString();
    }

    
    if (browserCmd.isEmpty()) {
        QSettings httpChoice(
            "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\Shell\\Associations\\UrlAssociations\\http\\UserChoice",
            QSettings::NativeFormat);
        progId = httpChoice.value("ProgId").toString();
        if (!progId.isEmpty()) {
            QSettings cmdKey("HKEY_CLASSES_ROOT\\" + progId + "\\shell\\open\\command",
                             QSettings::NativeFormat);
            browserCmd = cmdKey.value(".").toString();
        }
    }

    
    if (browserCmd.isEmpty()) {
        QSettings cmdKey("HKEY_CLASSES_ROOT\\http\\shell\\open\\command",
                         QSettings::NativeFormat);
        browserCmd = cmdKey.value(".").toString();
    }

    if (!browserCmd.isEmpty()) {
        
        QStringList parts = QProcess::splitCommand(browserCmd);
        if (!parts.isEmpty()) {
            QString exe = parts.takeFirst();
            for (QString &arg : parts) {
                if (arg == "%1") arg = url;
            }
            
            if (!parts.contains(url)) {
                bool hasPlaceholder = false;
                for (const QString &a : parts) {
                    if (a.contains("%1")) { hasPlaceholder = true; break; }
                }
                if (!hasPlaceholder) parts.append(url);
            }
            QProcess::startDetached(exe, parts);
            return;
        }
    }

    
    QDesktopServices::openUrl(QUrl(url));
#else
    QDesktopServices::openUrl(QUrl(url));
#endif
}

void AppController::copyToClipboard(const QString &text)
{
    QGuiApplication::clipboard()->setText(text);
}

void AppController::tryClose()
{
    
    if (m_autoJoinTimer && m_autoJoinTimer->isActive()) {
        emit closeDialogRequested();
        return;
    }
    if (m_closeBehavior == 1) {
        minimizeToTray();
    } else if (m_closeBehavior == 2) {
        quitApp();
    } else {
        emit closeDialogRequested();
    }
}

void AppController::setCloseBehavior(int b)
{
    if (m_closeBehavior != b) {
        m_closeBehavior = b;
        emit closeBehaviorChanged(b);
        saveSettings();
    }
}

void AppController::setStartMinimizedToTray(bool e)
{
    if (m_startMinimizedToTray != e) {
        m_startMinimizedToTray = e;
        emit startMinimizedToTrayChanged(e);
        saveSettings();
    }
}

void AppController::setDifficultyTierMode(bool v)
{
    if (m_difficultyTierMode != v) {
        m_difficultyTierMode = v;
        emit difficultyTierModeChanged(v);
        saveSettings();
    }
}

void AppController::setJoinNotificationEnabled(bool v)
{
    if (m_joinNotificationEnabled != v) {
        m_joinNotificationEnabled = v;
        emit joinNotificationEnabledChanged(v);
        saveSettings();
    }
}

void AppController::setMinimizeNotificationEnabled(bool v)
{
    if (m_minimizeNotificationEnabled != v) {
        m_minimizeNotificationEnabled = v;
        emit minimizeNotificationEnabledChanged(v);
        saveSettings();
    }
}

void AppController::setDebugPlayerList(bool v)
{
    if (m_debugPlayerList != v) {
        m_debugPlayerList = v;
        emit debugPlayerListChanged(v);
        saveSettings();
    }
}

void AppController::setWebMenuCommunity(int v)
{
    if (m_webMenuCommunity != v) {
        m_webMenuCommunity = v;
        emit webMenuCommunityChanged(v);
        saveSettings();
    }
}

void AppController::setCardViewMode(bool v)
{
    if (m_cardViewMode != v) {
        m_cardViewMode = v;
        emit cardViewModeChanged(v);
        saveSettings();
    }
}

void AppController::setServerListFilterOptions(const QStringList &v)
{
    if (m_serverListFilterOptions != v) {
        m_serverListFilterOptions = v;
        emit serverListFilterOptionsChanged(v);
        saveSettings();
    }
}

QString AppController::configFolderPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) + "/cs2挤服全部配置文件";
}

void AppController::openConfigFolder()
{
    QString path = configFolderPath();
    QDir dir(path);
    if (!dir.exists()) dir.mkpath(".");
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void AppController::minimizeToTray()
{
    if (m_mainWindow) {
        m_mainWindow->hide();
    }
    if (m_tray) {
        m_tray->show();
        if (m_minimizeNotificationEnabled) {
            QTimer::singleShot(100, [this]() {
                showToastNotification("CS2挤服工具v4_2", "已最小化到托盘，双击托盘图标恢复");
            });
        }
    }
}

void AppController::showMainWindow()
{
    if (m_mainWindow) {
        m_mainWindow->setVisibility(QWindow::Windowed);
        m_mainWindow->show();
        m_mainWindow->requestActivate();
        m_mainWindow->raise();
    }
    if (m_tray) m_tray->hide();
}

void AppController::quitApp()
{
    if (m_tray) m_tray->hide();
    QCoreApplication::quit();
}

void AppController::showToastNotification(const QString &title, const QString &message)
{
    if (m_toastQueue.size() >= 5) return;
    m_toastQueue.enqueue(qMakePair(title, message));
    tryShowNextToast();
}

void AppController::tryShowNextToast()
{
    if (m_toastShowing) return;
    if (m_toastQueue.isEmpty()) return;
    auto item = m_toastQueue.dequeue();
    m_toastShowing = true;
    emit toastShowingChanged(true);
    emit toastRequested(item.first, item.second);
    
    QTimer::singleShot(100, [item]() {
        for (QWindow *w : QGuiApplication::allWindows()) {
            if (w->objectName() == "toastFloatWindow") {
                w->setFlags(Qt::Tool | Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint);
                QMetaObject::invokeMethod(w, "showToast",
                    Qt::DirectConnection,
                    Q_ARG(QString, item.first),
                    Q_ARG(QString, item.second));
                
                QScreen *scr = QGuiApplication::primaryScreen();
                if (!scr && QGuiApplication::screens().size() > 0) scr = QGuiApplication::screens().first();
                if (scr) {
                    QRect g = scr->availableGeometry();
                    int margin = 16;
                    int px = g.x() + g.width() - w->width() - margin;
                    int py = g.y() + g.height() - w->height() - margin;
                    w->setPosition(px, py);
                    QTimer::singleShot(0, [w, px, py]() { w->setPosition(px, py); });
                }
                w->show();
                w->raise();
                break;
            }
        }
    });
    m_toastForceTimer->start();
    startToastCooldown();
    playNotificationSound();
}

void AppController::startToastCooldown()
{
    m_toastCooldown = true;
    m_toastCooldownRemaining = 10;
    emit toastCooldownRemainingChanged(10);
    m_toastCooldownTimer->start();
}

void AppController::playNotificationSound()
{
#ifdef Q_OS_WIN
    if (!PlaySound(L"Notification.Default", NULL, SND_ALIAS | SND_ASYNC | SND_NODEFAULT)) {
        PlaySound(L"SystemAsterisk", NULL, SND_ALIAS | SND_ASYNC | SND_NODEFAULT);
    }
#endif
}

void AppController::dismissToast()
{
    if (!m_toastShowing) return;
    m_toastForceTimer->stop();
    m_toastShowing = false;
    emit toastShowingChanged(false);
    if (!m_toastQueue.isEmpty()) {
        m_toastGapTimer->start();
    }
}

void AppController::positionFloatWindow()
{
    for (QWindow *w : QGuiApplication::allWindows()) {
        if (w->objectName() == "floatStatusWindow") {
            QScreen *scr = QGuiApplication::primaryScreen();
            if (!scr && QGuiApplication::screens().size() > 0) scr = QGuiApplication::screens().first();
            if (scr) {
                QRect g = scr->availableGeometry();
                int margin = 16;
                int px = g.x() + g.width() - w->width() - margin;
                int py = g.y() + g.height() - w->height() - margin;
                w->setPosition(px, py);
                QTimer::singleShot(0, [w, px, py]() { w->setPosition(px, py); });
            }
            break;
        }
    }
}

void AppController::applyWindowMask(QQuickWindow *window, int radius)
{
    if (!window) return;
    qreal dpr = window->devicePixelRatio();
    QSize sz = window->size() * dpr;
    if (sz.width() <= 0 || sz.height() <= 0) return;
    QBitmap bmp(sz);
    bmp.fill(Qt::color0);
    QPainter p(&bmp);
    p.setRenderHint(QPainter::Antialiasing);
    p.setBrush(Qt::color1);
    p.setPen(Qt::NoPen);
    p.drawRoundedRect(0, 0, sz.width(), sz.height(), radius * dpr, radius * dpr);
    p.end();
    window->setMask(QRegion(bmp));
}

void AppController::updateWindowMask()
{
    
}

static void applyWindowShadow(HWND hwnd)
{
    if (!hwnd) return;
    HMODULE hDwm = LoadLibraryW(L"dwmapi.dll");
    if (!hDwm) return;
    typedef struct _MARGINS { int cxLeftWidth; int cxRightWidth; int cyTopHeight; int cyBottomHeight; } DWM_MARGINS;
    typedef HRESULT(WINAPI *DwmExtendFrameIntoClientArea_t)(HWND, const DWM_MARGINS *);
    DwmExtendFrameIntoClientArea_t pFn = (DwmExtendFrameIntoClientArea_t)GetProcAddress(hDwm, "DwmExtendFrameIntoClientArea");
    if (pFn) {
        DWM_MARGINS margins = {0, 0, 1, 0};
        pFn(hwnd, &margins);
        qDebug() << "[DWM] window shadow applied";
    }
    FreeLibrary(hDwm);
}

bool AppController::applyDwmRoundedCorners(QQuickWindow *window)
{
    if (!window) return false;
    
    if (QOperatingSystemVersion::current() < QOperatingSystemVersion::Windows11) {
        qDebug() << "[DWM] Windows 10 detected, skip DWM rounded corners, use mask+renderer";
        return false;
    }
    HWND hwnd = (HWND)window->winId();
    if (!hwnd) return false;

    HMODULE hDwm = LoadLibraryW(L"dwmapi.dll");
    if (!hDwm) {
        qDebug() << "[DWM] dwmapi.dll not found, fallback to setMask";
        return false;
    }

    typedef HRESULT(WINAPI *DwmSetWindowAttribute_t)(HWND, DWORD, LPCVOID, DWORD);
    DwmSetWindowAttribute_t pFn = (DwmSetWindowAttribute_t)GetProcAddress(hDwm, "DwmSetWindowAttribute");
    if (!pFn) {
        qDebug() << "[DWM] DwmSetWindowAttribute not found, fallback to setMask";
        FreeLibrary(hDwm);
        return false;
    }

    DWORD pref = 2;
    HRESULT hr = pFn(hwnd, 33, &pref, sizeof(pref));
    FreeLibrary(hDwm);

    if (hr != 0) {
        qDebug() << "[DWM] rounded corner failed (hr=" << hr << "), fallback to setMask";
        return false;
    } else {
        qDebug() << "[DWM] rounded corner applied successfully";
        window->setMask(QRegion());
        return true;
    }
}

void AppController::setupRoundedCorners(QQuickWindow *window)
{
    if (!window) return;
    m_mainWindow = window;

    
    m_dwmRoundedAvailable = false;
    window->setMask(QRegion());
    if (m_roundedRenderer) {
        delete m_roundedRenderer;
        m_roundedRenderer = nullptr;
    }
    m_roundedRenderer = new RoundedCornerRenderer(window, this);
    m_roundedRenderer->setRadius(12.0f);
    qDebug() << "[RoundedCorner] 9px mode: setMask empty, renderer=12, visual=9, border=9";

    qDebug() << "[AppController] setupRoundedCorners done, DWM:" << m_dwmRoundedAvailable;
}

void AppController::setWindowMaximized(bool maximized)
{
    if (!m_mainWindow) return;
    HWND hwnd = (HWND)m_mainWindow->winId();
    if (maximized) {
        if (m_roundedRenderer) {
            delete m_roundedRenderer;
            m_roundedRenderer = nullptr;
        }
        if (hwnd) SetWindowRgn(hwnd, NULL, TRUE);
        qDebug() << "[RoundedCorner] maximized: corners disabled";
    } else {
        if (hwnd) SetWindowRgn(hwnd, NULL, TRUE);
        if (!m_roundedRenderer) {
            m_roundedRenderer = new RoundedCornerRenderer(m_mainWindow, this);
            m_roundedRenderer->setRadius(12.0f);
        }
        qDebug() << "[RoundedCorner] restored: renderer=12";
    }
}

void AppController::notifyExistingInstance()
{
    QLocalSocket socket;
    socket.connectToServer("CS2JoinTool_ActivatePipe", QIODevice::WriteOnly);
    if (socket.waitForConnected(1000)) {
        socket.write("activate");
        socket.waitForBytesWritten(500);
        socket.disconnectFromServer();
    }
}
