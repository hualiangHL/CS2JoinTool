






















import QtQuick
import QtQuick.Templates as T
import HuskarUI.Basic

T.Page {
    id: control

    property color colorBg: HusTheme.Primary.colorBgBase

    objectName: '__HusPage__'
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding,
                            implicitHeaderWidth,
                            implicitFooterWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding
                             + (implicitHeaderHeight > 0 ? implicitHeaderHeight + spacing : 0)
                             + (implicitFooterHeight > 0 ? implicitFooterHeight + spacing : 0))

    background: Rectangle {
        color: control.colorBg
    }
}
