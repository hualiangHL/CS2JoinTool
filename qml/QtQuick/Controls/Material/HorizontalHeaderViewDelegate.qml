


import QtQuick
import QtQuick.Controls.Material
import QtQuick.Templates as T

T.HeaderViewDelegate {
    id: control

    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 8

    highlighted: selected

    background: Rectangle {
        color: control.Material.backgroundColor
    }

    contentItem: Label {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: enabled ? control.Material.foreground
                       : control.Material.hintTextColor
        text: control.model[control.headerView.textRole]
    }
}
