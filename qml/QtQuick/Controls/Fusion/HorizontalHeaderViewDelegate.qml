


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Fusion as FusionControls

T.HeaderViewDelegate {
    id: control

    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 8

    highlighted: selected

    background: Rectangle {
        id: backgroundRect
        color: control.palette.button
        gradient: Gradient {
            GradientStop {
                position: 0
                color: FusionControls.Fusion.gradientStart(backgroundRect.color)
            }
            GradientStop {
                position: 1
                color: FusionControls.Fusion.gradientStop(backgroundRect.color)
            }
        }
    }

    contentItem: Label {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: control.model[control.headerView.textRole]
    }
}
