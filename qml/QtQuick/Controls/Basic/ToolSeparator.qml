


import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.ToolSeparator {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: vertical ? 6 : 2
    verticalPadding: vertical ? 2 : 6

    contentItem: Rectangle {
        implicitWidth: control.vertical ? (Qt.styleHints.accessibility.contrastPreference === Qt.HighContrast ? 2 : 1) : 30
        implicitHeight: control.vertical ? 30 : (Qt.styleHints.accessibility.contrastPreference === Qt.HighContrast ? 2 : 1)
        color: control.palette.mid
    }
}
