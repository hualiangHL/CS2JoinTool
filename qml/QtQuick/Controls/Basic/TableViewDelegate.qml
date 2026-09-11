


import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T

T.TableViewDelegate {
    id: control

    
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    highlighted: control.selected

    required property int column
    required property int row
    required property var model

    background: Rectangle {
        border.width: control.current ? 2 : Qt.styleHints.accessibility.contrastPreference === Qt.HighContrast ? 1 : 0
        border.color: control.current ? control.palette.highlight : control.palette.windowText
        color: control.highlighted
               ? control.palette.highlight
               : (control.tableView.alternatingRows && control.row % 2 !== 0
               ? control.palette.alternateBase : control.palette.base)
    }

    contentItem: Label {
        clip: false
        text: control.model.display ?? ""
        elide: Text.ElideRight
        color: control.highlighted ? control.palette.highlightedText : control.palette.buttonText
        visible: !control.editing
    }

    
    
    
    
    
    TableView.editDelegate: FocusScope {
        width: parent.width
        height: parent.height

        TableView.onCommit: {
            let model = control.tableView.model
            if (!model)
                return
            const index = model.index(control.row, control.column)
            if (!model.setData(index, textField.text, Qt.EditRole))
                console.warn("The model does not allow setting the EditRole data.")
        }

        Component.onCompleted: textField.selectAll()

        TextField {
            id: textField
            anchors.fill: parent
            text: control.model.edit ?? control.model.display ?? ""
            focus: true
        }
    }
    
    
    
}