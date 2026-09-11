


import QtQuick
import QtQuick.Templates as T
import QtQuick.Shapes

T.SelectionRectangle {
    id: control

    readonly property bool __notCustomizable: true

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
