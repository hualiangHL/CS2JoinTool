import QtQuick
import QtQuick.Controls
import "qrc:/qml" as App

Item {
    id: sliderRoot
    property real value: 50
    property real from: 0
    property real to: 100
    signal valUpdated(real value)

    width: 240
    height: 40

    Slider {
        id: slider
        anchors.fill: parent
        from: sliderRoot.from
        to: sliderRoot.to
        value: sliderRoot.value
        onValueChanged: {
            sliderRoot.value = value
            sliderRoot.valUpdated(value)
        }
    }
}