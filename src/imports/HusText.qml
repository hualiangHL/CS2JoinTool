






















import QtQuick
import HuskarUI.Basic

Text {
    id: control

    objectName: '__HusText__'
    renderType: HusTheme.textRenderType
    color: enabled ? HusTheme.Primary.colorTextBase :
                     HusTheme.Primary.colorTextDisabled
    font {
        family: HusTheme.Primary.fontPrimaryFamily
        pixelSize: parseInt(HusTheme.Primary.fontPrimarySize)
    }
}
