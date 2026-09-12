import QtQuick
import QtQuick.Controls
import "qrc:/qml" as App

Rectangle {
    id: buttonRoot
    property string text: ""
    property string iconText: ""
    property bool primary: true
    property bool danger: false
    property bool ghost: false
    property bool loading: false
    property bool enabled: true
    signal clicked()

    width: implicitWidth
    implicitWidth: textLabel.implicitWidth + (iconText ? 36 : 0) + App.Theme.paddingLg * 2
    height: 40
    radius: App.Theme.radiusMd
    color: {
        if (!enabled) return App.Theme.surface
        if (ghost) return "transparent"
        if (danger) return mouseArea.containsMouse ? App.Theme.error : App.Theme.withOpacity(App.Theme.error, 0.85)
        if (primary) return mouseArea.pressed ? App.Theme.primaryPressed : (mouseArea.containsMouse ? App.Theme.primaryHover : App.Theme.primary)
        return mouseArea.containsMouse ? App.Theme.surfaceHover : App.Theme.surface
    }
    border.width: ghost ? 1 : 0
    border.color: ghost ? App.Theme.border : "transparent"
    opacity: enabled ? 1 : 0.5

    Behavior on color { ColorAnimation { duration: App.Theme.durationFast } }

    // 发光效果

    Row {
        anchors.centerIn: parent
        spacing: App.Theme.spacingSm

        Text {
            id: iconLabel
            text: buttonRoot.iconText
            font.family: "FontAwesome"
            font.pixelSize: 14
            color: primary && !ghost ? "#FFFFFF" : (danger ? "#FFFFFF" : App.Theme.textPrimary)
            visible: buttonRoot.iconText !== ""
        }

        Text {
            id: textLabel
            text: buttonRoot.loading ? "处理中..." : buttonRoot.text
            font.family: App.Theme.fontFamily
            font.pixelSize: App.Theme.fontMd
            font.weight: Font.Medium
            color: primary && !ghost ? "#FFFFFF" : (danger ? "#FFFFFF" : App.Theme.textPrimary)
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (buttonRoot.enabled && !buttonRoot.loading) buttonRoot.clicked()
    }
}
