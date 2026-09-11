


import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Controls.Fusion.impl as FusionImpl

Menu {
    id: menu
    popupType: Qt.platform.pluginName !== "wayland" ? Popup.Window : Popup.Item

    required property Item editor

    FusionImpl.UndoAction {
        editor: menu.editor
    }
    FusionImpl.RedoAction {
        editor: menu.editor
    }

    MenuSeparator {}

    FusionImpl.CutAction {
        editor: menu.editor
    }
    FusionImpl.CopyAction {
        editor: menu.editor
    }
    FusionImpl.PasteAction {
        editor: menu.editor
    }
    FusionImpl.DeleteAction {
        editor: menu.editor
    }

    MenuSeparator {}

    FusionImpl.SelectAllAction {
        editor: menu.editor
    }
}