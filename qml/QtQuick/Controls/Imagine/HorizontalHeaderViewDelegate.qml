


import QtQuick
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
        border.color: "#e4e4e4"
        color: "#f6f6f6"
    }

    contentItem: Label {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "#ff26282a"
        text: control.model[control.headerView.textRole]
    }
}
