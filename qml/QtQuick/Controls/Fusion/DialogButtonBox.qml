


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Fusion
import QtQuick.Controls.Fusion.impl

T.DialogButtonBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    spacing: 6
    padding: 6
    alignment: Qt.AlignRight

    delegate: Button { }

    contentItem: ListView {
        implicitWidth: contentWidth
        model: control.contentModel
        spacing: control.spacing
        orientation: ListView.Horizontal
        boundsBehavior: Flickable.StopAtBounds
        snapMode: ListView.SnapToItem
    }

    background: Rectangle {
        implicitHeight: 34
        width: parent.width
        height: parent.height
        color: "transparent"
        border.color: Fusion.highContrast ? control.palette.windowText : "transparent"
        radius: 2
        Rectangle {
            x: 1; y: 1
            width: parent.width - 2
            height: parent.height - 2
            color: control.palette.window
            radius: 2
        }
    }
}