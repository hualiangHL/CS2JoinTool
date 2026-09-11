


import QtQuick
import QtQuick.Templates as T

T.HeaderViewDelegate {
    id: control

    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 8

    highlighted: selected

    background: Rectangle {
        border.color: Qt.styleHints.accessibility.contrastPreference === Qt.HighContrast ?
                      control.palette.windowText : control.palette.midlight
        color: control.palette.light
    }

    contentItem: Label {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: control.palette.windowText
        text: control.model[control.headerView.textRole]
    }
}