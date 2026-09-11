


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Copy")
    icon.name: "edit-copy"
    icon.width: 24
    icon.height: 24
    shortcut: StandardKey.Copy
    enabled: editor.selectedText.length > 0 && editor.hasOwnProperty("copy")
    onTriggered: editor.copy()

    required property Item editor
}