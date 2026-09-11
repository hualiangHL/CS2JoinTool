


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

T.Frame {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 12
    verticalPadding: Material.frameVerticalPadding

    Material.roundedScale: Material.ExtraSmallScale

    background: Rectangle {
        radius: control.Material.roundedScale
        color: control.Material.elevation > 0 ? control.Material.backgroundColor : "transparent"
        border.color: control.Material.frameColor

        layer.enabled: control.enabled && control.Material.elevation > 0
        layer.effect: RoundedElevationEffect {
            elevation: control.Material.elevation
            roundedScale: control.background.radius
        }
    }
}
