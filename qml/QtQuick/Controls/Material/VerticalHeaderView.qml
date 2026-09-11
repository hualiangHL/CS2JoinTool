


pragma ComponentBehavior: Bound

import QtQuick.Templates as T
import QtQuick.Controls.Material

T.VerticalHeaderView {
    id: control

    
    
    
    
    
    implicitWidth: Math.max(1, contentWidth)
    implicitHeight: syncView ? syncView.height : 0

    delegate: VerticalHeaderViewDelegate { }
}
