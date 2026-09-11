


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Material

T.Label {
    id: control

    color: enabled ? Material.foreground : Material.hintTextColor
    linkColor: Material.accentColor
}