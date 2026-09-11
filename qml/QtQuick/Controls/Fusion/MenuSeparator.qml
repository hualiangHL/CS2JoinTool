


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Fusion
import QtQuick.Controls.Fusion.impl

T.MenuSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: Fusion.highContrast ? 0 : 5
    verticalPadding: 1

    contentItem: Rectangle {
        implicitWidth: 188
        implicitHeight: 1
        color: Fusion.highContrast ? Fusion.outline(control.palette) : Qt.lighter(Fusion.darkShade, 1.06)
    }
}