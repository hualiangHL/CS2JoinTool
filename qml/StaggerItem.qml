import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int delay: 0
    property bool trigger: false
    property int animDuration: 350

    opacity: 0
    y: 12

    Layout.fillWidth: true
    Layout.preferredHeight: children.length > 0 && children[0].Layout !== undefined ? children[0].Layout.preferredHeight : 0
    implicitHeight: childrenRect.height

    onChildrenChanged: {
        if (children.length > 0) {
            try { children[0].anchors.fill = root } catch(e) {}
        }
    }

    onTriggerChanged: {
        if (trigger) {
            delayTimer.restart()
        } else {
            opacity = 0
            y = 12
        }
    }

    Timer {
        id: delayTimer
        interval: root.delay
        repeat: false
        onTriggered: {
            opacityAnim.restart()
            yAnim.restart()
        }
    }

    NumberAnimation on opacity {
        id: opacityAnim
        from: 0; to: 1
        duration: root.animDuration
        easing.type: Easing.OutCubic
    }

    NumberAnimation on y {
        id: yAnim
        from: 12; to: 0
        duration: root.animDuration
        easing.type: Easing.OutCubic
    }
}

