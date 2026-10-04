






















import QtQuick
import QtQuick.Templates as T
import HuskarUI.Basic

T.Label {
    id: control

    property alias colorText: control.color
    property color colorBg: enabled ? themeSource.colorBg : themeSource.colorBgDisabled
    property color colorBorder: themeSource.colorBorder
    property HusRadius radiusBg: HusRadius { all: themeSource.radiusBg }
    property HusBorder borderBg: HusBorder { color: themeSource.colorBorder }
    property string sizeHint: 'normal'
    property real sizeRatio: HusTheme.sizeHint[sizeHint]
    property var themeSource: HusTheme.HusLabel

    objectName: '__HusLabel__'
    padding: 5 * sizeRatio
    leftPadding: 8 * sizeRatio
    rightPadding: 8 * sizeRatio
    renderType: HusTheme.textRenderType
    color: enabled ? themeSource.colorText : themeSource.colorTextDisabled
    linkColor: enabled ? themeSource.colorLinkText : themeSource.colorTextDisabled
    font {
        family: themeSource.fontFamily
        pixelSize: parseInt(themeSource.fontSize) * sizeRatio
    }
    background: HusRectangleInternal {
        color: control.colorBg
        border.width: control.borderBg.width
        border.color: control.borderBg.color
        border.pixelAligned: control.borderBg.pixelAligned
        radius: control.radiusBg.all
        topLeftRadius: control.radiusBg.topLeft
        topRightRadius: control.radiusBg.topRight
        bottomLeftRadius: control.radiusBg.bottomLeft
        bottomRightRadius: control.radiusBg.bottomRight
    }
}
