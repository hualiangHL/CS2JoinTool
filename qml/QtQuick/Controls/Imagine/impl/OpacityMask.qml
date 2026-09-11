


import QtQuick



Item {
    id: rootItem

    property variant source
    property variant maskSource
    property bool cached: false

    ShaderEffectSource {
        id: cacheItem
        anchors.fill: parent
        visible: rootItem.cached
        smooth: true
        sourceItem: shaderItem
        live: true
        hideSource: visible
    }

    ShaderEffect {
        id: shaderItem
        property variant source: rootItem.source
        property variant maskSource: rootItem.maskSource

        anchors.fill: parent

        fragmentShader: "qrc:/qt-project.org/imports/QtQuick/Controls/Imagine/impl/shaders/OpacityMask.frag.qsb"
    }
}