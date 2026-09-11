


import QtQuick
import QtQuick.Controls.Material

Rectangle {
    id: cursor

    color: parent.Material.accentColor
    width: 2
    visible: parent.activeFocus && !parent.readOnly && parent.selectionStart === parent.selectionEnd

    Connections {
        target: cursor.parent
        function onCursorPositionChanged() {
            
            cursor.opacity = 1
            timer.restart()
        }
    }

    Timer {
        id: timer
        running: cursor.parent.activeFocus && !cursor.parent.readOnly && interval != 0
        repeat: true
        interval: Application.styleHints.cursorFlashTime / 2
        onTriggered: cursor.opacity = !cursor.opacity ? 1 : 0
        
        onRunningChanged: cursor.opacity = 1
    }
}