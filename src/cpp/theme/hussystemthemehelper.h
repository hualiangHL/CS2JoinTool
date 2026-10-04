#ifndef HUSSYSTEMTHEMEHELPER_H
#define HUSSYSTEMTHEMEHELPER_H

#include "husglobal.h"

#include <QtCore/QObject>
#include <QtGui/QColor>
#include <QtGui/QWindow>
#include <QtQml/qqml.h>

#ifdef QT_WIDGETS_LIB
#include <QtWidgets/QWidget>
#endif

QT_FORWARD_DECLARE_CLASS(HusSystemThemeHelperPrivate);

#ifndef BUILD_HUSKARUI_ON_DESKTOP_PLATFORM
Q_DECLARE_OPAQUE_POINTER(QWindow*);
Q_DECLARE_OPAQUE_POINTER(QWidget*);
#endif

class HUSKARUI_EXPORT HusSystemThemeHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QColor accentColor READ accentColor NOTIFY accentColorChanged)
    Q_PROPERTY(HusSystemThemeHelper::ColorScheme colorScheme READ colorScheme NOTIFY colorSchemeChanged)

    QML_NAMED_ELEMENT(HusSystemThemeHelper)

public:
    enum class ColorScheme {
        None = 0,
        Light = 1,
        Dark = 2,
    };
    Q_ENUM(ColorScheme);

    HusSystemThemeHelper(QObject *parent = nullptr);
    ~HusSystemThemeHelper();

    



    QColor accentColor();
    



    HusSystemThemeHelper::ColorScheme colorScheme();

    




    Q_INVOKABLE QColor getAccentColor() const;
    




    Q_INVOKABLE HusSystemThemeHelper::ColorScheme getColorScheme() const;

    Q_INVOKABLE static bool setWindowTitleBarMode(QWindow *window, bool isDark);

#ifdef QT_WIDGETS_LIB
    Q_INVOKABLE static bool setWindowTitleBarMode(QWidget *window, bool isDark);
#endif

signals:
    void accentColorChanged(const QColor &color);
    void colorSchemeChanged(HusSystemThemeHelper::ColorScheme scheme);

protected:
    virtual void timerEvent(QTimerEvent *);

private:
    Q_DECLARE_PRIVATE(HusSystemThemeHelper);
    QScopedPointer<HusSystemThemeHelperPrivate> d_ptr;
};


#endif
