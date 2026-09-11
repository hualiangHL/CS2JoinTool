


import QtQuick
import QtQuick.Templates as T

T.Action {
    text: qsTr("Cut")
    icon.name: "edit-cut"
    
    
    icon.width: 24
    icon.height: 24
    
    
    shortcut: StandardKey.Cut
    
    enabled: !editor.readOnly && editor.selectedText.length > 0 && editor.hasOwnProperty("cut")
    onTriggered: editor.cut()

    
    
    required property Item editor
}
