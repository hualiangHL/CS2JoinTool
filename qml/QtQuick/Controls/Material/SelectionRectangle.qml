


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

T.SelectionRectangle {
    id: control

    topLeftHandle: handle
    bottomRightHandle: handle

    Component {
        id: handle
        SliderHandle {
            palette: SelectionRectangle.control.palette
            handlePressed: tapHandler.pressed || SelectionRectangle.dragging
            handleHovered: hoverHandler.hovered
            visible: SelectionRectangle.control.active

            HoverHandler {
                id: hoverHandler
            }

            TapHandler  {
                id: tapHandler
            }
        }
    }
}