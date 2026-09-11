


import QtQuick

@Deprecated {
    reason: "StyleImage component has been moved to private FluentWinUI3.impl module \
    and is no longer part of the public QML API."
}


Item {
    id: root

    Component.onCompleted: {
        print("StyleImage has been moved to private FluentWinUI3.impl module "
             + "and is no longer part of the public QML API.")
    }

    implicitWidth: horizontal ? imageConfig.width : imageConfig.height
    implicitHeight: horizontal ? imageConfig.height : imageConfig.width

    required property var imageConfig

    
    
    
    
    property bool horizontal: true

    
    property real minimumWidth: Math.max(1, imageConfig.leftOffset + imageConfig.rightOffset)
    property real minimumHeight: Math.max(1, imageConfig.topOffset + imageConfig.bottomOffset)

    BorderImage {
        x: -imageConfig.leftShadow
        y: -imageConfig.topShadow
        width: Math.max(root.minimumWidth, (root.horizontal ? root.width : root.height))
               + imageConfig.leftShadow + imageConfig.rightShadow
        height: Math.max(root.minimumHeight, (root.horizontal ? root.height : root.width))
                + imageConfig.topShadow + imageConfig.bottomShadow
        source: Qt.resolvedUrl(imageConfig.filePath)

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
