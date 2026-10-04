






















#include "husapp.h"

#include <QtGui/QFontDatabase>








Q_GLOBAL_STATIC_WITH_ARGS(bool, g_initialized, (false));

HusApp::~HusApp()
{

}

void HusApp::initialize(QQmlEngine *engine)
{
    QFontDatabase::addApplicationFont(":/HuskarUI/resources/font/HuskarUI-Icons.ttf");

    *g_initialized = true;
}

QString HusApp::libName()
{
    return "HuskarUI";
}

QString HusApp::libVersion()
{
    return HUSKARUI_LIBRARY_VERSION;
}

HusApp *HusApp::instance()
{
    static HusApp *ins = new HusApp;
    return ins;
}

HusApp *HusApp::create(QQmlEngine *qmlEngine, QJSEngine *)
{
    
    








    if (!*g_initialized)
        initialize(qmlEngine);

    return instance();
}

HusApp::HusApp(QObject *parent)
    : QObject{parent}
{

}
