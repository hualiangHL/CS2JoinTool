


import QtQuick



Item {
    id: root
    implicitWidth: horizontal ? imageConfig.width : imageConfig.height
    implicitHeight: horizontal ? imageConfig.height : imageConfig.width

    required property var imageConfig

    
    
    
    
    property bool horizontal: true
    property bool drawShadowWithinBounds: false

    
    property real minimumWidth: Math.max(1, imageConfig.leftOffset + imageConfig.rightOffset)
    property real minimumHeight: Math.max(1, imageConfig.topOffset + imageConfig.bottomOffset)

    BorderImage {
        x: root.drawShadowWithinBounds ? 0 : -imageConfig.leftShadow
        y: root.drawShadowWithinBounds ? 0 : -imageConfig.topShadow
        width: Math.max(root.minimumWidth, (root.horizontal ? root.width : root.height))
               + (root.drawShadowWithinBounds ? 0 : imageConfig.leftShadow + imageConfig.rightShadow)
        height: Math.max(root.minimumHeight, (root.horizontal ? root.height : root.width))
                + (root.drawShadowWithinBounds ? 0 : imageConfig.topShadow + imageConfig.bottomShadow)
        source: imageConfig.filePath ? `qrc:/qt-project.org/imports/QtQuick/Controls/FluentWinUI3/${imageConfig.filePath}` : ""

        border {
            top: Math.min(height / 2, imageConfig.topOffset + imageConfig.topShadow)
            left: Math.min(width / 2, imageConfig.leftOffset + imageConfig.leftShadow)
            bottom: Math.min(height / 2, imageConfig.bottomOffset + imageConfig.bottomShadow)
            right: Math.min(width / 2, imageConfig.rightOffset + imageConfig.rightShadow)
        }

        transform: [
            Rotation {
                angle: root.horizontal ? 0 : 90
            },
            Scale {
                xScale: root.horizontal ? 1 : -1
            }
        ]
    }
}