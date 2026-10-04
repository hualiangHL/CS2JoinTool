






















import QtQuick
import QtQuick.Templates as T
import HuskarUI.Basic

T.Frame {
    id: control

    property color colorBg: 'transparent'
    property HusRadius radiusBg: HusRadius { all: HusTheme.Primary.radiusPrimary }
    property HusBorder borderBg: HusBorder { color: HusTheme.Primary.colorSplit }

    objectName: '__HusFrame__'
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)
    padding: 5
    font {
        family: HusTheme.Primary.fontPrimaryFamily
        pixelSize: parseInt(HusTheme.Primary.fontPrimarySize)
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
