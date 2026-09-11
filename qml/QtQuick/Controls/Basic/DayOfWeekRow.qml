


import QtQuick
import QtQuick.Templates as T

T.AbstractDayOfWeekRow {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)

    spacing: 6
    topPadding: 6
    bottomPadding: 6
    font.bold: true

    
    delegate: Text {
        text: shortName
        font: control.font
        color: control.palette.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        required property string shortName
    }
    

    
    contentItem: Row {
        spacing: control.spacing
        Repeater {
            model: control.source
            delegate: control.delegate
        }
    }
    
}