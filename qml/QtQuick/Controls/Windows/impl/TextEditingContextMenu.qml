


import QtQuick.Controls.Windows
import QtQuick.Controls.Windows.impl as WindowsImpl

Menu {
    id: menu
    popupType: Popup.Window

    required property var editor

    WindowsImpl.UndoAction {
        editor: menu.editor
    }
    WindowsImpl.RedoAction {
        editor: menu.editor
    }

    MenuSeparator {}

    WindowsImpl.CutAction {
        editor: menu.editor
    }
    WindowsImpl.CopyAction {
        editor: menu.editor
    }
    WindowsImpl.PasteAction {
        editor: menu.editor
    }
    WindowsImpl.DeleteAction {
        editor: menu.editor
    }

    MenuSeparator {}

    WindowsImpl.SelectAllAction {
        editor: menu.editor
    }
}