


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Redo")
    icon.name: "edit-redo"
    icon.width: 24
    icon.height: 24
    shortcut: StandardKey.Redo
    enabled: editor.canRedo
    onTriggered: editor.redo()

    required property Item editor
}