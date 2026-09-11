


import QtQuick.NativeStyle as NativeStyle

NativeStyle.DefaultItemDelegate {
    contentItem: NativeStyle.DefaultItemDelegateIconLabel {
        color: control.highlighted ? control.palette.button : control.palette.windowText
    }
}