


import QtQuick.NativeStyle as NativeStyle

NativeStyle.DefaultRadioDelegate {
    contentItem: NativeStyle.DefaultItemDelegateIconLabel {
        color: control.highlighted ? control.palette.button : control.palette.windowText

        readonly property bool __ignoreNotCustomizable: true
    }
}