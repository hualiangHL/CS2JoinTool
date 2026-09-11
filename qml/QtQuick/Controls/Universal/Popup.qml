


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Universal

T.Popup {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 12

    background: Rectangle {
        color: control.Universal.chromeMediumLowColor
        border.color: control.Universal.chromeHighColor
        border.width: 1 
    }

    T.Overlay.modal: Rectangle {
        color: control.Universal.baseLowColor
    }

    T.Overlay.modeless: Rectangle {
        color: control.Universal.baseLowColor
    }
}