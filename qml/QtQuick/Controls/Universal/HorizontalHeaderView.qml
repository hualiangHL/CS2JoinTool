


pragma ComponentBehavior: Bound

import QtQuick.Templates as T
import QtQuick.Controls.Universal

T.HorizontalHeaderView {
    id: control

    implicitWidth: syncView ? syncView.width : 0
    
    
    
    
    
    implicitHeight: Math.max(1, contentHeight)

    delegate: HorizontalHeaderViewDelegate { }
}
