


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Fusion
import QtQuick.Controls.Fusion.impl

T.SelectionRectangle {
    id: control

    topLeftHandle: Item {
        width: 20
        height: 20
        visible: SelectionRectangle.control.active
        
        
        
    }

    bottomRightHandle: Item {
        width: 20
        height: 20
        visible: SelectionRectangle.control.active
        
        
        
    }
}