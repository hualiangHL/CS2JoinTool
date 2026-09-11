


import QtQuick
import QtQuick.NativeStyle as NativeStyle
import QtQuick.Controls.Windows.impl as WindowsImpl

NativeStyle.DefaultTextArea {
    id: control

    ContextMenu.menu: WindowsImpl.TextEditingContextMenu {
        editor: control
    }
}