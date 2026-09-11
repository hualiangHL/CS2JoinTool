


import QtQuick
import QtQuick.NativeStyle as NativeStyle
import QtQuick.Controls.Windows.impl

NativeStyle.DefaultTextField {
    id: control

    ContextMenu.menu: TextEditingContextMenu {
        editor: control
    }
}
