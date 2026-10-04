






















import QtQuick
import QtQuick.Layouts
import HuskarUI.Basic

            HusButton {
    id: control

    enum IconPosition {
        Position_Start = 0,
        Position_End = 1
    }

    property bool loading: false
    property var iconSource: 0 ?? ''
    property int iconSize: parseInt(themeSource.fontSize) * sizeRatio
    property int iconSpacing: 5 * sizeRatio
    property int iconPosition: HusIconButton.Position_Start
    property int orientation: Qt.Horizontal
    property alias textFont: control.font
    property font iconFont: Qt.font({
                                        family: 'HuskarUI-Icons',
                                        pixelSize: iconSize
                                    })
    property color colorIcon: colorText

    property Component iconDelegate: HusIconText {
        id: __icon
        font: control.iconFont
        color: control.colorIcon
        iconSource: control.loading ? HusIcon.LoadingOutlined : control.iconSource
        verticalAlignment: Text.AlignVCenter
        visible: !empty

        Behavior on color { enabled: control.animationEnabled; ColorAnimation { duration: HusTheme.Primary.durationFast } }

        NumberAnimation on rotation {
            running: control.loading
            from: 0
            to: 360
            loops: Animation.Infinite
            duration: 1000
            onRunningChanged: {
                if (!running) {
                    __icon.rotation = 0;
                }
            }
        }
    }

    objectName: '__HusIconButton__'
    contentItem: Item {
        implicitWidth: control.orientation === Qt.Horizontal ? __horLoader.implicitWidth : __verLoader.implicitWidth
        implicitHeight: control.orientation === Qt.Horizontal ? __horLoader.implicitHeight : __verLoader.implicitHeight

        Behavior on implicitWidth { enabled: control.animationEnabled; NumberAnimation { duration: HusTheme.Primary.durationMid } }
        Behavior on implicitHeight { enabled: control.animationEnabled; NumberAnimation { duration: HusTheme.Primary.durationMid } }

        Loader {
            id: __horLoader
            anchors.centerIn: parent
            active: control.orientation === Qt.Horizontal
            sourceComponent: Row {
                spacing: control.iconSpacing
                layoutDirection: control.iconPosition === HusIconButton.Position_Start ? Qt.LeftToRight : Qt.RightToLeft

                Loader {
                    id: __hIcon
                    height: Math.max(__hIcon.implicitHeight, __hText.implicitHeight)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: control.iconDelegate
                }

                HusText {
                    id: __hText
                    anchors.verticalCenter: parent.verticalCenter
                    text: control.text
                    font: control.font
                    lineHeight: control.themeSource.fontLineHeight
                    color: control.colorText
                    elide: Text.ElideRight
                    visible: text !== ''

                    Behavior on color { enabled: control.animationEnabled; ColorAnimation { duration: HusTheme.Primary.durationFast } }
                }
            }
        }

        Loader {
            id: __verLoader
            active: control.orientation === Qt.Vertical
            anchors.centerIn: parent
            sourceComponent: Column {
                spacing: control.iconSpacing
                Component.onCompleted: relayout();

                function relayout() {
                    if (control.iconPosition === HusIconButton.Position_Start) {
                        children = [__vIcon, __vText];
                    } else {
                        children = [__vText, __vIcon];
                    }
                }

                Loader {
                    id: __vIcon
                    height: Math.max(__vIcon.implicitHeight, __vText.implicitHeight)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: control.iconDelegate
                }

                HusText {
                    id: __vText
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: control.text
                    font: control.font
                    lineHeight: control.themeSource.fontLineHeight
                    color: control.colorText
                    elide: Text.ElideRight
                    visible: text !== ''

                    Behavior on color { enabled: control.animationEnabled; ColorAnimation { duration: HusTheme.Primary.durationFast } }
                }
            }
        }
    }
}
