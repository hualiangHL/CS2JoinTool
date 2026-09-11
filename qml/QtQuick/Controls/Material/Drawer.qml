


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

T.Drawer {
    id: control

    parent: T.Overlay.overlay

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: SafeArea.margins.top + (edge !== Qt.TopEdge ? Material.roundedScale : 0)
    leftPadding: SafeArea.margins.left + (control.edge === Qt.RightEdge)
    rightPadding: SafeArea.margins.right + (control.edge === Qt.LeftEdge)
    bottomPadding: SafeArea.margins.bottom + (edge !== Qt.BottomEdge ? Material.roundedScale : 0)

    enter: Transition { SmoothedAnimation { velocity: 5 } }
    exit: Transition { SmoothedAnimation { velocity: 5 } }

    
    Material.elevation: !interactive && !dim ? 0 : 1
    Material.roundedScale: Material.LargeScale

    background: PaddedRectangle {
        
        implicitWidth: 360
        color: control.Material.dialogColor
        
        radius: control.Material.roundedScale
        leftPadding: edge === Qt.LeftEdge ? -radius : 0
        rightPadding: edge === Qt.RightEdge ? -radius : 0
        topPadding: edge === Qt.TopEdge ? -radius : 0
        bottomPadding: edge === Qt.BottomEdge ? -radius : 0
        clip: true

        layer.enabled: control.position > 0 && control.Material.elevation > 0
        layer.effect: RoundedElevationEffect {
            elevation: control.Material.elevation
            roundedScale: control.background.radius
        }
    }

    T.Overlay.modal: Rectangle {
        color: control.Material.backgroundDimColor
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    T.Overlay.modeless: Rectangle {
        color: control.Material.backgroundDimColor
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}