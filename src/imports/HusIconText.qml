






















import QtQuick
import HuskarUI.Basic

HusText {
    id: control

    readonly property bool empty: iconSource === 0 || iconSource === ''
    property var iconSource: 0 ?? ''
    property alias iconSize: control.font.pixelSize
    property alias colorIcon: control.color
    property string contentDescription: text

    objectName: '__HusIconText__'
    width: __iconLoader.active ? (__iconLoader.implicitWidth + leftPadding + rightPadding) : implicitWidth
    height: __iconLoader.active ? (__iconLoader.implicitHeight + topPadding + bottomPadding) : implicitHeight
    text: __iconLoader.active ? '' : String.fromCharCode(iconSource)
    font {
        family: 'HuskarUI-Icons'
        pixelSize: parseInt(HusTheme.HusIconText.fontSize)
    }
    color: enabled ? HusTheme.HusIconText.colorText : HusTheme.HusIconText.colorTextDisabled

    Loader {
        id: __iconLoader
        anchors.centerIn: parent
        active: typeof iconSource == 'string' && iconSource !== ''
        sourceComponent: Image {

            source: {
                if (control.iconSource === 'qrc:/Gallery/images/monitor.svg') {
                    var c = HusTheme.isDark ? '#E8E8E8' : '#1F2937'
                    var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="' + c + '" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
                        + '<rect x="2.5" y="3.5" width="19" height="13" rx="2"/>'
                        + '<line x1="9" y1="21" x2="15" y2="21"/>'
                        + '<line x1="12" y1="16.5" x2="12" y2="21"/>'
                        + '</svg>'
                    return 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg)
                }
                return control.iconSource
            }
            width: control.iconSize
            height: control.iconSize
            sourceSize: Qt.size(width, height)
        }
    }

    Accessible.role: Accessible.Graphic
    Accessible.name: control.text
    Accessible.description: control.contentDescription
}
