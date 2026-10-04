






















import QtQuick
import HuskarUI.Basic

HusIconButton {
    id: control

    property bool isError: false
    property bool noDisabledState: false

    themeSource: HusTheme.HusCaptionButton

    objectName: '__HusCaptionButton__'
    leftPadding: 12 * sizeRatio
    rightPadding: 12 * sizeRatio
    active: down
    radiusBg.all: 0
    hoverCursorShape: Qt.ArrowCursor
    type: HusButton.Type_Text
    iconSize: parseInt(themeSource.fontSize)
    effectEnabled: false
    colorIcon: {
        if (enabled || noDisabledState) {
            return checked ? themeSource.colorIconChecked :
                             themeSource.colorIcon;
        } else {
            return themeSource.colorIconDisabled;
        }
    }
    colorBg: {
        if (enabled || noDisabledState) {
            if (isError) {
                return active ? themeSource.colorErrorBgActive:
                                hovered ? themeSource.colorErrorBgHover :
                                          themeSource.colorErrorBg;
            } else {
                return active ? themeSource.colorBgActive:
                                hovered ? themeSource.colorBgHover :
                                          themeSource.colorBg;
            }
        } else {
            return themeSource.colorBgDisabled;
        }
    }
}
