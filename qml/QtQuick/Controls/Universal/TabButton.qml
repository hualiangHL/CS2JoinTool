


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Universal

T.TabButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 12 
    spacing: 8

    icon.width: 20
    icon.height: 20

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        defaultIconColor: Color.transparent(enabled && control.hovered
            ? control.Universal.baseMediumHighColor : control.Universal.foreground,
            control.checked || control.down || (enabled && control.hovered) ? 1.0 : 0.2)
        text: control.text
        font: control.font
        color: defaultIconColor
    }
}