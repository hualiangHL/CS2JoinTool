


import QtQuick
import QtQuick.Controls.impl
import QtQuick.Controls.Basic.impl
import QtQuick.Templates as T

T.TextField {
    id: control

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
                   || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 6
    leftPadding: padding + 4

    color: control.palette.text
    selectionColor: control.palette.highlight
    selectedTextColor: control.palette.highlightedText
    placeholderTextColor: control.palette.placeholderText
    verticalAlignment: TextInput.AlignVCenter

    ContextMenu.menu: TextEditingContextMenu {
        editor: control
    }

    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        border.width: control.activeFocus ? 2 : 1
        color: control.palette.base
        border.color: {
            if (control.activeFocus)
                return control.palette.highlight
            else if (Qt.styleHints.accessibility.contrastPreference !== Qt.HighContrast)
                return control.palette.mid
            else
                return Color.blend(control.palette.text, control.palette.base,
                                   control.enabled ? 0.0 : 0.5)
        }
    }
}