


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Paste")
    icon.name: "edit-paste"
    icon.width: 24
    icon.height: 24
    shortcut: StandardKey.Paste
    enabled: !editor.readOnly && editor.hasOwnProperty("paste")
    onTriggered: editor.paste()

    required property Item editor
}
