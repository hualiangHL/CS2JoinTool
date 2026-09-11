


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import QtQuick.Controls.impl
import QtQuick.NativeStyle as NativeStyle

T.CheckBox {
    id: control

    readonly property bool nativeIndicator: indicator instanceof NativeStyle.StyleItem
    readonly property bool __notCustomizable: true

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    spacing: nativeIndicator ? 0 : 6
    padding: nativeIndicator ? 0 : 6

    indicator: NativeStyle.CheckBox {
        control: control
        y: control.topPadding + (control.availableHeight - height) >> 1
        contentWidth: contentItem.implicitWidth
        contentHeight: contentItem.implicitHeight
        useNinePatchImage: false
        overrideState: NativeStyle.StyleItem.NeverHovered

        readonly property bool __ignoreNotCustomizable: true
    }

    NativeStyle.CheckBox {
        id: hoverCheckBox
        control: control
        x: indicator.x
        y: indicator.y
        z: 99   
        width: indicator.width
        height: indicator.height
        useNinePatchImage: false
        overrideState: NativeStyle.StyleItem.AlwaysHovered
        opacity: control.hovered ? 1 : 0
        visible: opacity !== 0
        Behavior on opacity { NumberAnimation { duration: hoverCheckBox.transitionDuration } }
    }

    contentItem: CheckLabel {
        text: control.text
        font: control.font
        color: control.palette.windowText

        
        
        
        
        
        
        leftPadding: {
            if (nativeIndicator)
                indicator.contentPadding.left
            else
                indicator && !mirrored ? indicator.width + spacing : 0
        }

        topPadding: nativeIndicator ? indicator.contentPadding.top : 0
        rightPadding: {
            if (nativeIndicator)
                indicator.contentPadding.right
            else
                indicator && mirrored ? indicator.width + spacing : 0
        }

        readonly property bool __ignoreNotCustomizable: true
    }
}
