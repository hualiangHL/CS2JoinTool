


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

T.DialogButtonBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    spacing: 8
    padding: 8
    verticalPadding: 2
    alignment: Qt.AlignRight
    buttonLayout: T.DialogButtonBox.AndroidLayout

    Material.foreground: Material.accent
    Material.roundedScale: Material.ExtraLargeScale

    delegate: Button { flat: true }

    contentItem: ListView {
        implicitWidth: contentWidth
        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
    }

    background: PaddedRectangle {
        implicitHeight: control.Material.dialogButtonBoxHeight
        radius: control.Material.roundedScale
        color: control.Material.dialogColor
        
        topPadding: control.position === T.DialogButtonBox.Footer ? -radius : 0
        bottomPadding: control.position === T.DialogButtonBox.Header ? -radius : 0
        clip: true
    }
}