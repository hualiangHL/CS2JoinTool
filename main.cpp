#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QEvent>
#include <QSharedMemory>

#include "src/appcontroller.h"
#include "src/serverquery.h"
#include "src/servermanager.h"
#include "src/mapcooldownmanager.h"
#include "src/mapsubscriptionmanager.h"
#include "src/workshopmanager.h"
#include "src/ubservermanager.h"
#include "src/playerquery.h"

#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

static QFile *g_logFile = nullptr;

class ContextMenuBlocker : public QObject {
protected:
    bool eventFilter(QObject *obj, QEvent *event) override {
        if (event->type() == QEvent::ContextMenu) {
            event->accept();
            return true;
        }
        return QObject::eventFilter(obj, event);
    }
};

void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(context);
    if (!g_logFile) return;
    QTextStream out(g_logFile);
    QString prefix;
    switch (type) {
    case QtDebugMsg: prefix = "[DEBUG]"; break;
    case QtWarningMsg: prefix = "[WARN]"; break;
    case QtCriticalMsg: prefix = "[CRIT]"; break;
    case QtFatalMsg: prefix = "[FATAL]"; break;
    default: prefix = "[INFO]"; break;
    }
    out << QDateTime::currentDateTime().toString("hh:mm:ss.zzz") << " " << prefix << " " << msg << "\n";
    out.flush();
}

int main(int argc, char *argv[])
{
    g_logFile = new QFile(QDir::tempPath() + "/cs2join_debug.log");
    g_logFile->open(QIODevice::WriteOnly | QIODevice::Truncate);
    qInstallMessageHandler(messageHandler);

    
    qputenv("QSG_RHI_BACKEND", "opengl");

    
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    QApplication app(argc, argv);
    app.setApplicationName("CS2挤服工具");
    app.setApplicationVersion("4.0.0");
    app.setOrganizationName("CS2JoinTool");

    QSharedMemory singleInstance("CS2JoinTool_SingleInstance_Lock");
    if (singleInstance.attach()) {
        AppController::notifyExistingInstance();
        return 0;
    }
    if (!singleInstance.create(1)) {
        AppController::notifyExistingInstance();
        return 0;
    }

    ContextMenuBlocker menuBlocker;
    app.installEventFilter(&menuBlocker);

    QQuickStyle::setStyle("Basic");

    qmlRegisterType<ServerQuery>("CS2JoinTool", 1, 0, "ServerQuery");
    qmlRegisterType<ServerListModel>("CS2JoinTool", 1, 0, "ServerListModel");

    AppController controller;
    ServerManager serverManager;
    MapCooldownManager cooldownManager;
    MapSubscriptionManager subscriptionManager;
    WorkshopManager workshopManager;
    UBServerManager ubManager;
    PlayerQuery playerQuery;

    QQmlApplicationEngine engine;
    engine.addImportPath("qrc:/");
    engine.rootContext()->setContextProperty("appController", &controller);
    engine.rootContext()->setContextProperty("serverManager", &serverManager);
    engine.rootContext()->setContextProperty("cooldownManager", &cooldownManager);
    engine.rootContext()->setContextProperty("subscriptionManager", &subscriptionManager);
    engine.rootContext()->setContextProperty("workshopManager", &workshopManager);
    engine.rootContext()->setContextProperty("ubManager", &ubManager);
    engine.rootContext()->setContextProperty("playerQuery", &playerQuery);

    QObject::connect(&serverManager, &ServerManager::serverMapUpdated,
                     &subscriptionManager, &MapSubscriptionManager::checkServerMap);
    
    QObject::connect(&subscriptionManager, &MapSubscriptionManager::notificationRequested,
                     &controller, &AppController::showToastNotification);
    QString appDir = QCoreApplication::applicationDirPath();
    appDir.replace("\\", "/");
    engine.rootContext()->setContextProperty("appDir", appDir);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    
    app.setWindowIcon(QIcon(":/assets/app_icon.png"));

    return app.exec();
}