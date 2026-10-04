#include <QGuiApplication>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCoreApplication>
#include <QUrl>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QSettings>
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QPixmap>
#include <QPainter>
#ifdef BUILD_HUSKARUI_STATIC_LIBRARY
#include <QtQml/qqmlextensionplugin.h>
Q_IMPORT_QML_PLUGIN(HuskarUI_ImplPlugin)
Q_IMPORT_QML_PLUGIN(HuskarUI_BasicPlugin)
#endif

#include "customtheme.h"
#include "husapp.h"
#include "workshoppreviewmanager.h"
#include "mapcooldownmanager.h"
#include "baservertime.h"
#include "backgroundfilemanager.h"
#include "appconfig.h"
#include "squeezeengine.h"
#include "mapsubscriptionmanager.h"
#include "workshopmanager.h"
#include "wheelExporter.h"
#include "browsercontroller.h"
#include "onlinehistorymanager.h"
#include "joinhistorymanager.h"
#include "updatechecker.h"
#include "langmanager.h"
#include <QtQml/qqml.h>
#include <QFile>
#include <QLockFile>
#include <QLocalServer>
#include <QLocalSocket>
#include <QTimer>
#include <QTextStream>
#include <QDateTime>
#include <QtGlobal>
#include <QScreen>
#include <QTimer>
#include <QRect>
#ifdef Q_OS_WIN
#include <windows.h>
#include <mmsystem.h>
#endif


void galleryLogHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg);




static QString resolveConfigDir()
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                   + QStringLiteral("/HuskarUIcs2配置文件");
    if (QDir().mkpath(cfgDir))
        return cfgDir;
    cfgDir = QCoreApplication::applicationDirPath() + "/config";
    QDir().mkpath(cfgDir);
    return cfgDir;
}


class FloatWindowPositioner : public QObject
{
    Q_OBJECT
public:

    static void forceBottomRight(QWindow *w, int px, int py)
    {
        w->setPosition(px, py);
#ifdef Q_OS_WIN
        if (w->winId()) {
            QScreen *s = w->screen();
            const qreal dpr = s ? s->devicePixelRatio() : 1.0;
            const int physX = qRound(px * dpr);
            const int physY = qRound(py * dpr);
            HWND hwnd = reinterpret_cast<HWND>(w->winId());
            SetWindowPos(hwnd, HWND_TOPMOST, physX, physY, 0, 0,
                         SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOZORDER);
        }
#endif
    }

    explicit FloatWindowPositioner(QObject *parent = nullptr) : QObject(parent)
    {


        QTimer *persistTimer = new QTimer(this);
        persistTimer->setInterval(400);
        connect(persistTimer, &QTimer::timeout, this, [this]() {
            QScreen *scr = resolveScreen();
            if (!scr) return;
            static bool logged = false;
            if (!logged) {
                logged = true;
                qInfo().noquote() << "[FloatPosPersist] active, screen=" << scr->name()
                                  << " geom=" << scr->availableGeometry().x() << scr->availableGeometry().y()
                                  << scr->availableGeometry().width() << scr->availableGeometry().height();
            }
            const QRect g = scr->availableGeometry();
            const int margin = 16;
            for (QWindow *w : QGuiApplication::allWindows()) {
                const QString n = w->objectName();
                if (n != QStringLiteral("toastFloatWindow") && n != QStringLiteral("updateFloatWindow"))
                    continue;
                if (!w->isVisible())
                    continue;
                const int px = g.x() + g.width() - w->width() - margin;
                const int py = g.y() + g.height() - w->height() - margin;
                forceBottomRight(w, px, py);
            }
        });
        persistTimer->start();
    }


    QScreen *resolveScreen()
    {
        QWindow *mainW = nullptr;
        int maxArea = 0;
        for (QWindow *w : QGuiApplication::allWindows()) {
            const QString n = w->objectName();
            if (n == QStringLiteral("floatStatusWindow") || n == QStringLiteral("toastFloatWindow") || n == QStringLiteral("updateFloatWindow"))
                continue;
            if (!w->isVisible())
                continue;
            const int area = w->width() * w->height();
            if (area > maxArea) {
                maxArea = area;
                mainW = w;
            }
        }
        if (mainW && mainW->screen())
            return mainW->screen();
        if (QGuiApplication::primaryScreen())
            return QGuiApplication::primaryScreen();
        if (QGuiApplication::screens().size() > 0)
            return QGuiApplication::screens().first();
        return nullptr;
    }

    Q_INVOKABLE void positionAll()
    {
        QScreen *scr = resolveScreen();
        if (!scr) return;

        const QRect g = scr->availableGeometry();
        const int margin = 16;
        qInfo().noquote() << "[FloatPos] screen=" << scr->name()
                          << " geom=" << g.x() << g.y() << g.width() << g.height();

        for (QWindow *w : QGuiApplication::allWindows()) {
            const QString n = w->objectName();
            if (n == QStringLiteral("floatStatusWindow") || n == QStringLiteral("toastFloatWindow") || n == QStringLiteral("updateFloatWindow")) {
                const int px = g.x() + g.width() - w->width() - margin;
                const int py = g.y() + g.height() - w->height() - margin;
                qInfo().noquote() << "[FloatPos] set" << n << "->" << px << py
                                  << "winsize=" << w->width() << w->height() << "visible=" << w->isVisible();
                forceBottomRight(w, px, py);
            }
        }
    }
};



class TrayController : public QObject
{
    Q_OBJECT
public:
    explicit TrayController(QQmlApplicationEngine *engine, QObject *parent = nullptr)
        : QObject(parent), m_engine(engine) {}

    Q_INVOKABLE void init()
    {
        if (m_tray || !QSystemTrayIcon::isSystemTrayAvailable()) {
            galleryLogHandler(QtInfoMsg, QMessageLogContext(),
                              QStringLiteral("TrayController: init skipped (tray=") +
                              (m_tray ? QStringLiteral("yes") : QStringLiteral("no")) +
                              QStringLiteral(", available=") +
                              (QSystemTrayIcon::isSystemTrayAvailable() ? QStringLiteral("yes") : QStringLiteral("no")) + QStringLiteral(")"));
            return;
        }


        QPixmap pm(QStringLiteral(":/Gallery/images/app_icon.png"));
        if (pm.isNull()) {
            pm = QPixmap(32, 32);
            pm.fill(Qt::transparent);
        } else if (pm.width() > 64) {
            pm = pm.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        }
        QIcon icon(pm);

        m_tray = new QSystemTrayIcon(icon, this);
        m_tray->setToolTip(QStringLiteral("CS2挤服工具"));

        QMenu *menu = new QMenu();
        QAction *showAct = menu->addAction(QStringLiteral("显示主界面"));
        connect(showAct, &QAction::triggered, this, &TrayController::showMainWindow);
        QAction *quitAct = menu->addAction(QStringLiteral("退出"));
        connect(quitAct, &QAction::triggered, this, &TrayController::quitApp);
        m_tray->setContextMenu(menu);
        connect(m_tray, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason r) {
            if (r == QSystemTrayIcon::Trigger || r == QSystemTrayIcon::DoubleClick)
                showMainWindow();
        });
        m_tray->show();
        galleryLogHandler(QtInfoMsg, QMessageLogContext(), QStringLiteral("TrayController: tray icon shown"));
    }

    Q_INVOKABLE void showMainWindow()
    {
        QObject *root = m_engine->rootObjects().isEmpty() ? nullptr : m_engine->rootObjects().first();
        if (root) {
            root->setProperty("visible", true);
            QMetaObject::invokeMethod(root, "raise", Qt::QueuedConnection);
            galleryLogHandler(QtInfoMsg, QMessageLogContext(), QStringLiteral("TrayController: show main window"));
        }
    }

    Q_INVOKABLE void quitApp()
    {

        QCoreApplication::quit();
    }

private:
    QQmlApplicationEngine *m_engine = nullptr;
    QSystemTrayIcon *m_tray = nullptr;
};




class CloseGuard : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool closeToTray READ closeToTray WRITE setCloseToTray)
public:
    explicit CloseGuard(QObject *parent = nullptr) : QObject(parent) {}
    bool closeToTray() const { return m_closeToTray; }
    void setCloseToTray(bool v) { m_closeToTray = v; }

    bool eventFilter(QObject *obj, QEvent *ev) override
    {
        if (ev->type() == QEvent::Close && m_closeToTray) {
            QWindow *w = qobject_cast<QWindow *>(obj);

            if (w && !w->transientParent()) {
                galleryLogHandler(QtInfoMsg, QMessageLogContext(), QStringLiteral("CloseGuard: intercept close, hide window"));
                ev->ignore();
                w->hide();
                return true;
            }
        }
        return QObject::eventFilter(obj, ev);
    }

private:
    bool m_closeToTray = true;
};




class SystemSound : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString customSoundPath READ customSoundPath NOTIFY customSoundPathChanged)
    Q_PROPERTY(int volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString yinpinDirUrl READ yinpinDirUrl CONSTANT)
public:
    explicit SystemSound(const QString &cfgDir, QObject *parent = nullptr)
        : QObject(parent), m_cfgDir(cfgDir)
    {

        m_yinpinDir = m_cfgDir + QStringLiteral("/yinpin");
        QDir().mkpath(m_yinpinDir);
        QSettings s;
        m_custom = s.value(QStringLiteral("customSoundPath")).toString();
        if (!m_custom.isEmpty() && !QFile::exists(m_custom))
            m_custom.clear();
        m_volume = qBound(0, s.value(QStringLiteral("customSoundVolume"), 100).toInt(), 100);
    }

    QString customSoundPath() const { return m_custom; }
    QString yinpinDirUrl() const { return QUrl::fromLocalFile(m_yinpinDir).toString(); }

    int volume() const { return m_volume; }
    void setVolume(int v)
    {
        v = qBound(0, v, 100);
        if (m_volume == v)
            return;
        m_volume = v;
        QSettings s;
        s.setValue(QStringLiteral("customSoundVolume"), v);
        emit volumeChanged();
    }


    Q_INVOKABLE QString importCustomSound(const QString &srcUrl)
    {
        const QUrl url(srcUrl);
        const QString srcPath = url.isLocalFile() ? url.toLocalFile() : srcUrl;
        const QFileInfo fi(srcPath);
        if (!fi.exists() || !fi.isFile())
            return QString();
        const QString suffix = fi.suffix().toLower();
        const QString dstPath = m_yinpinDir + QStringLiteral("/custom_sound.")
                              + (suffix.isEmpty() ? QStringLiteral("wav") : suffix);
        if (QFile::exists(dstPath))
            QFile::remove(dstPath);
        if (!QFile::copy(srcPath, dstPath))
            return QString();
        m_custom = dstPath;
        QSettings s;
        s.setValue(QStringLiteral("customSoundPath"), dstPath);
        emit customSoundPathChanged();
        return dstPath;
    }


    Q_INVOKABLE void resetCustomSound()
    {
        if (!m_custom.isEmpty())
            QFile::remove(m_custom);
        m_custom.clear();
        QSettings s;
        s.remove(QStringLiteral("customSoundPath"));
        emit customSoundPathChanged();
    }


    Q_INVOKABLE void playCustom()
    {
        playSound();
    }


    Q_INVOKABLE void playNotification()
    {
        if (!m_custom.isEmpty() && QFile::exists(m_custom)) {
            playSound();
            return;
        }
#ifdef Q_OS_WIN

        const QStringList notifyWavs = {
            QStringLiteral("C:/Windows/Media/Windows Notify System Generic.wav"),
            QStringLiteral("C:/Windows/Media/Windows Notify.wav")
        };
        for (const QString &wav : notifyWavs) {
            if (QFile::exists(wav)
                && PlaySoundW((LPCWSTR)wav.utf16(), nullptr, SND_FILENAME | SND_ASYNC | SND_NODEFAULT))
                return;
        }

        if (!PlaySoundW(L"SystemNotification", nullptr, SND_ALIAS | SND_ASYNC))
            if (!PlaySoundW(L"SystemAsterisk", nullptr, SND_ALIAS | SND_ASYNC))
                MessageBeep(MB_ICONASTERISK);
#endif
    }

signals:
    void customSoundPathChanged();
    void volumeChanged();

private:
    void playSound()
    {
        if (m_custom.isEmpty() || !QFile::exists(m_custom))
            return;
#ifdef Q_OS_WIN

        mciSendStringW(L"close custSound", nullptr, 0, nullptr);
        const QString type = m_custom.endsWith(QLatin1String(".wav"), Qt::CaseInsensitive)
                           ? QStringLiteral("waveaudio") : QStringLiteral("mpegvideo");
        const QString openCmd = QStringLiteral("open \"%1\" type %2 alias custSound").arg(m_custom, type);
        if (mciSendStringW((LPCWSTR)openCmd.utf16(), nullptr, 0, nullptr) == 0) {
            const QString volCmd = QStringLiteral("setaudio custSound volume to %1").arg(m_volume * 10);
            mciSendStringW((LPCWSTR)volCmd.utf16(), nullptr, 0, nullptr);
            mciSendStringW(L"play custSound", nullptr, 0, nullptr);
        }
#endif
    }

    QString m_cfgDir;
    QString m_yinpinDir;
    QString m_custom;
    int m_volume = 100;
};


void galleryLogHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    Q_UNUSED(ctx)
    static QString logDir = resolveConfigDir();
    QFile f(logDir + QStringLiteral("/qml_log.txt"));
    if (f.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream ts(&f);
        ts << QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss.zzz")) << ' '
           << (type == QtWarningMsg ? QStringLiteral("W") : (type == QtCriticalMsg || type == QtFatalMsg ? QStringLiteral("C") : QStringLiteral("I")))
           << ' ' << msg << '\n';
    }
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(galleryLogHandler);
#ifndef Q_OS_MAC
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
#endif
    QQuickWindow::setDefaultAlphaBuffer(true);

    QApplication app(argc, argv);


    CloseGuard closeGuard;
    app.installEventFilter(&closeGuard);
    app.setOrganizationName("MenPenS");
    app.setApplicationName("HuskarUI");
    app.setApplicationDisplayName(QStringLiteral("CS2挤服工具"));
    app.setApplicationVersion(HusApp::libVersion());


    const QString cfgDir = resolveConfigDir();


    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, cfgDir);
    QSettings::setPath(QSettings::IniFormat, QSettings::SystemScope, cfgDir);

    QQmlApplicationEngine engine;




    QLockFile singleLock(cfgDir + "/Gallery.lock");
    if (!singleLock.tryLock(100)) {
        qInfo() << "[SingleInstance] another instance detected, notifying and exiting";

        QLocalSocket sock;
        sock.connectToServer("CS2JoinTool_SingleInstance");
        if (sock.waitForConnected(300)) {
            sock.write("show");
            sock.flush();
            sock.waitForBytesWritten(300);
        }
        return 0;
    }
    qInfo() << "[SingleInstance] lock acquired (first instance)";
    QLocalServer *singleServer = new QLocalServer(&app);
    QObject::connect(singleServer, &QLocalServer::newConnection, &app, [&engine, singleServer]() {
        QLocalSocket *conn = singleServer->nextPendingConnection();
        if (conn)
            conn->deleteLater();

        std::function<void()> activate = [&engine, &activate]() {
            QQuickWindow *w = nullptr;
            const auto roots = engine.rootObjects();
            for (QObject *obj : roots) {
                w = qobject_cast<QQuickWindow *>(obj);
                if (w)
                    break;
            }
            if (w) {
                w->show();
                w->raise();
                w->requestActivate();
            } else {
                QTimer::singleShot(300, activate);
            }
        };
        activate();
    });
    singleServer->listen("CS2JoinTool_SingleInstance");


    engine.rootContext()->setContextProperty("ConfigDir", cfgDir);


    engine.rootContext()->setContextProperty("MapImagesDir",
        QUrl::fromLocalFile(QCoreApplication::applicationDirPath() + "/map_images").toString());


    engine.rootContext()->setContextProperty("AppBackground",
        QUrl::fromLocalFile(QCoreApplication::applicationDirPath() + "/background/background.jpg").toString());


    engine.rootContext()->setContextProperty("WorkshopPreviewManager", WorkshopPreviewManager::instance());


    OnlineHistoryManager historyManager(cfgDir + "/online_history.json");
    engine.rootContext()->setContextProperty("OnlineHistoryManager", &historyManager);


    JoinHistoryManager joinHistoryManager(cfgDir + "/join_history.json");
    engine.rootContext()->setContextProperty("JoinHistoryManager", &joinHistoryManager);


    engine.rootContext()->setContextProperty("CooldownManager", new MapCooldownManager(&engine));


    BaServerTime *baServerTime = new BaServerTime(&engine);
    engine.rootContext()->setContextProperty("BaServerTime", baServerTime);
    baServerTime->connectWS();


    engine.rootContext()->setContextProperty("BackgroundFileManager", new BackgroundFileManager(cfgDir, &engine));


    engine.rootContext()->setContextProperty("AppConfig", new AppConfig(cfgDir, &engine));


    SqueezeEngine *squeezeEngineObj = new SqueezeEngine(&engine);
    engine.rootContext()->setContextProperty("SqueezeEngineObj", squeezeEngineObj);


    MapSubscriptionManager *subscriptionManagerObj = new MapSubscriptionManager(cfgDir, &engine);
    engine.rootContext()->setContextProperty("SubscriptionManagerObj", subscriptionManagerObj);


    engine.rootContext()->setContextProperty("FloatWindowPos", new FloatWindowPositioner(&engine));
    engine.rootContext()->setContextProperty("TrayController", new TrayController(&engine, &engine));
    engine.rootContext()->setContextProperty("CloseGuard", &closeGuard);
    engine.rootContext()->setContextProperty("SystemSound", new SystemSound(cfgDir, &engine));


    engine.rootContext()->setContextProperty("UpdateChecker", new UpdateChecker(&engine));
    LangManager *langMgr = new LangManager(cfgDir, &engine);
    engine.rootContext()->setContextProperty("Lang", langMgr);

    subscriptionManagerObj->setLangManager(langMgr);

    squeezeEngineObj->setLangManager(langMgr);


    BrowserController *browserCtrl = new BrowserController(&engine);
    engine.rootContext()->setContextProperty("BrowserControllerObj", browserCtrl);
engine.rootContext()->setContextProperty("WorkshopManager", new WorkshopManager(&engine));
    engine.rootContext()->setContextProperty("WheelExporterObj", new WheelExporter(&engine));
    CustomTheme::instance()->registerAll();



    HusApp::initialize(&engine);

    const QUrl url = QUrl(QStringLiteral("qrc:/Gallery/qml/Gallery.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.addImportPath(HUSKARUI_IMPORT_PATH);
    engine.load(url);




    QObject::connect(langMgr, &LangManager::languageChanged, &engine, [&engine, &url, browserCtrl]() {



        if (browserCtrl)
            browserCtrl->shutdownBrowser();
        const auto roots = engine.rootObjects();
        for (QObject *r : roots) {
            if (r)
                r->deleteLater();
        }
        QTimer::singleShot(0, &engine, [&engine, &url]() {
            engine.load(url);
        });
    });


    QObject::connect(&app, &QCoreApplication::aboutToQuit, [cfgDir]() {
        const QString cacheDirPath = cfgDir + "/preview_cache";
        QDir cacheDir(cacheDirPath);
        if (cacheDir.exists()) {
            const QFileInfoList entries = cacheDir.entryInfoList(QDir::NoDotAndDotDot | QDir::AllEntries);
            for (const QFileInfo &fi : entries) {
                if (fi.isDir())
                    QDir(fi.absoluteFilePath()).removeRecursively();
                else
                    QFile::remove(fi.absoluteFilePath());
            }
        }
    });

    return app.exec();
}

#include "main.moc"


