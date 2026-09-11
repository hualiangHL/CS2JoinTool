


import QtQuick
import QtQuick.Controls.impl
import QtQuick.Controls.Fusion

Rectangle {
    implicitWidth: 120
    implicitHeight: 24
    radius: 2
    color: control.palette.base
    border.color: control.activeFocus ? Fusion.highlightedOutline(control.palette) : Fusion.outline(control.palette)

    required property Item control

    Rectangle {
        x: 1
        y: 1
        width: parent.width - 2
        height: parent.height - 2
        color: "transparent"
        border.color: Color.transparent(Fusion.highlightedOutline(control.palette), 40 / 255)
        visible: control.activeFocus
        radius: 1.7
    }

    Rectangle {
        x: 2
        y: 1
        width: parent.width - 4
        height: 1
        color: Fusion.topShadow
    }
}