


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Select All")
    icon.name: "edit-select-all"
    icon.width: 24
    icon.height: 24
    shortcut: StandardKey.SelectAll
    onTriggered: editor.selectAll()

    required property Item editor
}
