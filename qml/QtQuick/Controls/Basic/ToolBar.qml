


import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.ToolBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: SafeArea.margins.top
    leftPadding: SafeArea.margins.left
    rightPadding: SafeArea.margins.right
    bottomPadding: SafeArea.margins.bottom

    background: Rectangle {
        implicitHeight: 40
        color: control.palette.button
    }
}