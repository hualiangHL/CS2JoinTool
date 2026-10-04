#include "customtheme.h"
#include "hustheme.h"

CustomTheme *CustomTheme::instance()
{
    static CustomTheme *ins = new CustomTheme;
    return ins;
}

CustomTheme *CustomTheme::create(QQmlEngine *, QJSEngine *)
{
    return instance();
}

void CustomTheme::registerAll()
{
    

}

CustomTheme::CustomTheme(QObject *parent)
    : QObject{parent}
{

}
