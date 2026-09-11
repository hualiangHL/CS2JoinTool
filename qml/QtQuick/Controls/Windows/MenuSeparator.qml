


import QtQuick
import QtQuick.Templates as T

T.MenuSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    horizontalPadding: 0
    verticalPadding: 2

    contentItem: Rectangle {
        implicitWidth: 188
        implicitHeight: 1
        color: control.palette.midlight
    }
}