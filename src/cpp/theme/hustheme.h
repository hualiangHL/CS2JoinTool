#ifndef HUSTHEME_H
#define HUSTHEME_H

#include "husglobal.h"
#include "husdefinitions.h"

#include <QtQml/qqml.h>

QT_FORWARD_DECLARE_CLASS(HusThemePrivate)

class HUSKARUI_EXPORT HusTheme : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(HusTheme)

    Q_PROPERTY(bool isDark READ isDark NOTIFY isDarkChanged)
    Q_PROPERTY(DarkMode darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged FINAL)
    Q_PROPERTY(TextRenderType textRenderType READ textRenderType WRITE setTextRenderType NOTIFY textRenderTypeChanged FINAL)
    Q_PROPERTY(QVariantMap sizeHint READ sizeHint NOTIFY sizeHintChanged FINAL)

    HUS_PROPERTY_INIT(bool, animationEnabled, setAnimationEnabled, true);

    HUS_PROPERTY_READONLY(QVariantMap, Primary); 

    HUS_PROPERTY_READONLY(QVariantMap, HusAutoComplete)
    HUS_PROPERTY_READONLY(QVariantMap, HusBreadcrumb)
    HUS_PROPERTY_READONLY(QVariantMap, HusButton)
    HUS_PROPERTY_READONLY(QVariantMap, HusCaptionButton)
    HUS_PROPERTY_READONLY(QVariantMap, HusCard)
    HUS_PROPERTY_READONLY(QVariantMap, HusCarousel)
    HUS_PROPERTY_READONLY(QVariantMap, HusCheckBox)
    HUS_PROPERTY_READONLY(QVariantMap, HusCollapse)
    HUS_PROPERTY_READONLY(QVariantMap, HusColorPicker)
    HUS_PROPERTY_READONLY(QVariantMap, HusCopyableText)
    HUS_PROPERTY_READONLY(QVariantMap, HusDateTimePicker)
    HUS_PROPERTY_READONLY(QVariantMap, HusDivider)
    HUS_PROPERTY_READONLY(QVariantMap, HusDrawer)
    HUS_PROPERTY_READONLY(QVariantMap, HusEmpty)
    HUS_PROPERTY_READONLY(QVariantMap, HusGroupBox)
    HUS_PROPERTY_READONLY(QVariantMap, HusIconText)
    HUS_PROPERTY_READONLY(QVariantMap, HusImage)
    HUS_PROPERTY_READONLY(QVariantMap, HusImagePreview)
    HUS_PROPERTY_READONLY(QVariantMap, HusImagePreviewPanel)
    HUS_PROPERTY_READONLY(QVariantMap, HusInput)
    HUS_PROPERTY_READONLY(QVariantMap, HusLabel)
    HUS_PROPERTY_READONLY(QVariantMap, HusMenu)
    HUS_PROPERTY_READONLY(QVariantMap, HusMessage)
    HUS_PROPERTY_READONLY(QVariantMap, HusModal)
    HUS_PROPERTY_READONLY(QVariantMap, HusMultiCheckBox)
    HUS_PROPERTY_READONLY(QVariantMap, HusMultiSelect)
    HUS_PROPERTY_READONLY(QVariantMap, HusNotification)
    HUS_PROPERTY_READONLY(QVariantMap, HusPagination)
    HUS_PROPERTY_READONLY(QVariantMap, HusPopconfirm)
    HUS_PROPERTY_READONLY(QVariantMap, HusPopover)
    HUS_PROPERTY_READONLY(QVariantMap, HusPopup)
    HUS_PROPERTY_READONLY(QVariantMap, HusProgress)
    HUS_PROPERTY_READONLY(QVariantMap, HusRadio)
    HUS_PROPERTY_READONLY(QVariantMap, HusRadioBlock)
    HUS_PROPERTY_READONLY(QVariantMap, HusRate)
    HUS_PROPERTY_READONLY(QVariantMap, HusScrollBar)
    HUS_PROPERTY_READONLY(QVariantMap, HusSelect)
    HUS_PROPERTY_READONLY(QVariantMap, HusSlider)
    HUS_PROPERTY_READONLY(QVariantMap, HusSpin)
    HUS_PROPERTY_READONLY(QVariantMap, HusSplitView)
    HUS_PROPERTY_READONLY(QVariantMap, HusSwitch)
    HUS_PROPERTY_READONLY(QVariantMap, HusTabView)
    HUS_PROPERTY_READONLY(QVariantMap, HusTableView)
    HUS_PROPERTY_READONLY(QVariantMap, HusTag)
    HUS_PROPERTY_READONLY(QVariantMap, HusTextArea)
    HUS_PROPERTY_READONLY(QVariantMap, HusTimeline)
    HUS_PROPERTY_READONLY(QVariantMap, HusToolTip)
    HUS_PROPERTY_READONLY(QVariantMap, HusTour)
    HUS_PROPERTY_READONLY(QVariantMap, HusTransfer)
    HUS_PROPERTY_READONLY(QVariantMap, HusTreeView)
    HUS_PROPERTY_READONLY(QVariantMap, HusSegmented)

public:
    enum class DarkMode {
        Light = 0,
        Dark,
        System
    };
    Q_ENUM(DarkMode);

    enum class TextRenderType {
        QtRendering = 0,
        NativeRendering = 1,
        CurveRendering = 2
    };
    Q_ENUM(TextRenderType);

    ~HusTheme();

    static HusTheme *instance();
    static HusTheme *create(QQmlEngine *, QJSEngine *);

    bool isDark() const;

    DarkMode darkMode() const;
    void setDarkMode(DarkMode mode);

    TextRenderType textRenderType() const;
    void setTextRenderType(TextRenderType renderType);

    QVariantMap sizeHint() const;

    






    void registerCustomComponentTheme(QObject *themeObject, const QString &component, QVariantMap *themeMap, const QString &themePath);

    


    Q_INVOKABLE void reloadTheme();

    



    Q_INVOKABLE void installThemeColorTextBase(const QString &lightAndDark);
    



    Q_INVOKABLE void installThemeColorBgBase(const QString &lightAndDark);
    



    Q_INVOKABLE void installThemePrimaryColorBase(const QColor &colorBase);
    



    Q_INVOKABLE void installThemePrimaryFontSizeBase(int fontSizeBase);
    



    Q_INVOKABLE void installThemePrimaryFontFamiliesBase(const QString &familiesBase);
    



    Q_INVOKABLE void installThemePrimaryRadiusBase(int radiusBase);
    





    Q_INVOKABLE void installThemePrimaryAnimationBase(int durationFast, int durationMid, int durationSlow);
    




    Q_INVOKABLE void installSizeHintRatio(const QString &size, qreal ratio);


    



    Q_INVOKABLE void installIndexTheme(const QString &themePath);
    





    Q_INVOKABLE void installIndexToken(const QString &token, const QString &value);

    




    Q_INVOKABLE void installComponentTheme(const QString &component, const QString &themePath);
    





    Q_INVOKABLE void installComponentToken(const QString &component, const QString &token, const QString &value);

signals:
    void isDarkChanged();
    void darkModeChanged();
    void textRenderTypeChanged();
    void sizeHintChanged();

private:
    explicit HusTheme(QObject *parent = nullptr);

    Q_DECLARE_PRIVATE(HusTheme);
    QScopedPointer<HusThemePrivate> d_ptr;
};

#endif
