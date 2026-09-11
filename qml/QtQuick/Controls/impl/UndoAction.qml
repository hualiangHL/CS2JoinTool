


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Undo")
    icon.name: "edit-undo"
    icon.width: 24
    icon.height: 24
    shortcut: StandardKey.Undo
    enabled: editor.canUndo
    onTriggered: editor.undo()

    required property Item editor
}