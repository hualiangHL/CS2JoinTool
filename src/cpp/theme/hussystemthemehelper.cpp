






















#include "hussystemthemehelper.h"

#include <QtCore/QBasicTimer>
#include <QtCore/QLibrary>
#include <QtCore/QSettings>

#ifdef QT_WIDGETS_LIB
# include <QtWidgets/QWidget>
#endif

#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
# include <QtGui/QGuiApplication>
# include <QtGui/QStyleHints>
#endif

#ifdef Q_OS_WIN
# include <Windows.h>

using DwmSetWindowAttributeFunc = HRESULT(WINAPI *)(HWND hwnd, DWORD dwAttribute, LPCVOID pvAttribute, DWORD cbAttribute);

static DwmSetWindowAttributeFunc pDwmSetWindowAttribute = nullptr;

static inline bool initializeFunctionPointers() {
    static bool initialized = false;
    if (!initialized) {
        HMODULE module = LoadLibraryW(L"dwmapi.dll");
        if (module) {
            if (!pDwmSetWindowAttribute) {
                pDwmSetWindowAttribute = reinterpret_cast<DwmSetWindowAttributeFunc>(
                    GetProcAddress(module, "DwmSetWindowAttribute"));
                if (!pDwmSetWindowAttribute) {
                    return false;
                }
            }
            initialized = true;
        }
    }
    return initialized;
}

#else
# include <QPalette>
#endif

class HusSystemThemeHelperPrivate
{
public:
    HusSystemThemeHelperPrivate(HusSystemThemeHelper *q) : q_ptr(q) { }

    Q_DECLARE_PUBLIC(HusSystemThemeHelper);

    void _updateAccentColor() {
        Q_Q(HusSystemThemeHelper);

        auto nowAccentColor = q->getAccentColor();
        if (nowAccentColor != m_accentColor) {
            m_accentColor = nowAccentColor;
            emit q->accentColorChanged(nowAccentColor);
        }
    }

    void _updateColorScheme() {
        Q_Q(HusSystemThemeHelper);

        auto nowColorScheme = q->getColorScheme() ;
        if (nowColorScheme != m_colorScheme) {
            m_colorScheme = nowColorScheme;
            emit q->colorSchemeChanged(nowColorScheme);
        }
    }

    HusSystemThemeHelper *q_ptr;
    QColor m_accentColor;
    HusSystemThemeHelper::ColorScheme m_colorScheme = HusSystemThemeHelper::ColorScheme::None;

    QBasicTimer m_timer;
#ifdef Q_OS_WIN
    QSettings m_accentColorSettings { QSettings::UserScope, "Microsoft", "Windows\\DWM" };
    QSettings m_colorSchemeSettings { QSettings::UserScope, "Microsoft", "Windows\\CurrentVersion\\Themes\\Personalize" };
#endif
};

HusSystemThemeHelper::HusSystemThemeHelper(QObject *parent)
    : QObject{ parent }
    , d_ptr(new HusSystemThemeHelperPrivate(this))
{
    Q_D(HusSystemThemeHelper);

    d->m_accentColor = getAccentColor();
    d->m_colorScheme = getColorScheme();

    d->m_timer.start(200, this);

#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, [this](Qt::ColorScheme scheme){
        emit colorSchemeChanged(scheme == Qt::ColorScheme::Dark ? ColorScheme::Dark : ColorScheme::Light);
    });
#endif

#ifdef Q_OS_WIN
    initializeFunctionPointers();
#endif
}

HusSystemThemeHelper::~HusSystemThemeHelper()
{

}

QColor HusSystemThemeHelper::getAccentColor() const
{
    Q_D(const HusSystemThemeHelper);

#ifdef Q_OS_WIN
    return QColor::fromRgb(d->m_accentColorSettings.value("ColorizationColor").toUInt());
#else
# if QT_VERSION >= QT_VERSION_CHECK(6, 6, 0)
    return QPalette().color(QPalette::Accent);
# else
    return QPalette().color(QPalette::Highlight);
# endif
#endif
}

HusSystemThemeHelper::ColorScheme HusSystemThemeHelper::getColorScheme() const
{
    Q_D(const HusSystemThemeHelper);
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
    const auto scheme = QGuiApplication::styleHints()->colorScheme();
    return scheme == Qt::ColorScheme::Dark ? ColorScheme::Dark : ColorScheme::Light;
#else
#ifdef Q_OS_WIN
    
    return !d->m_colorSchemeSettings.value("AppsUseLightTheme").toBool() ? ColorScheme::Dark : ColorScheme::Light;
#else
    const QPalette defaultPalette;
    const auto text = defaultPalette.color(QPalette::WindowText);
    const auto window = defaultPalette.color(QPalette::Window);
    return text.lightness() > window.lightness() ? ColorScheme::Dark : ColorScheme::Light;
#endif
#endif
}

QColor HusSystemThemeHelper::accentColor()
{
    Q_D(HusSystemThemeHelper);

    d->_updateAccentColor();

    return d->m_accentColor;
}

HusSystemThemeHelper::ColorScheme HusSystemThemeHelper::colorScheme()
{
    Q_D(HusSystemThemeHelper);

    d->_updateColorScheme();

    return d->m_colorScheme;
}

bool HusSystemThemeHelper::setWindowTitleBarMode(QWindow *window, bool isDark)
{
#ifdef Q_OS_WIN
    return bool(pDwmSetWindowAttribute ? !pDwmSetWindowAttribute(HWND(window->winId()), 20, &isDark, sizeof(BOOL)) : false);
#else
    return false;
#endif
}

#ifdef QT_WIDGETS_LIB
bool HusSystemThemeHelper::setWindowTitleBarMode(QWidget *window, bool isDark)
{
#ifdef Q_OS_WIN
    return bool(pDwmSetWindowAttribute ? !pDwmSetWindowAttribute(HWND(window->winId()), 20, &isDark, sizeof(BOOL)) : false);
#else
    return false;
#endif
}
#endif

void HusSystemThemeHelper::timerEvent(QTimerEvent *)
{
    Q_D(HusSystemThemeHelper);

    d->_updateAccentColor();

#if QT_VERSION < QT_VERSION_CHECK(6, 5, 0)
    d->_updateColorScheme();
#endif
}
