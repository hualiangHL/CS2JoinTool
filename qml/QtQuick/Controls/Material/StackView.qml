


import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.Material

T.StackView {
    id: control

    component LineAnimation: NumberAnimation {
        duration: 200
        easing.type: Easing.OutCubic
    }

    component FadeIn: LineAnimation {
        property: "opacity"
        from: 0.0
        to: 1.0
    }

    component FadeOut: LineAnimation {
        property: "opacity"
        from: 1.0
        to: 0.0
    }

    popEnter: Transition {
        
        LineAnimation { property: "x"; from: (control.mirrored ? -0.5 : 0.5) *  -control.width; to: 0 }
        FadeIn {}
    }

    popExit: Transition {
        
        LineAnimation { property: "x"; from: 0; to: (control.mirrored ? -0.5 : 0.5) * control.width }
        FadeOut {}
    }

    pushEnter: Transition {
        
        LineAnimation { property: "x"; from: (control.mirrored ? -0.5 : 0.5) * control.width; to: 0 }
        FadeIn {}
    }

    pushExit: Transition {
        
        LineAnimation { property: "x"; from: 0; to: (control.mirrored ? -0.5 : 0.5) * -control.width }
        FadeOut {}
    }

    replaceEnter: Transition {
        
        LineAnimation { property: "x"; from: (control.mirrored ? -0.5 : 0.5) * control.width; to: 0 }
        FadeIn {}
    }

    replaceExit: Transition {
        
        LineAnimation { property: "x"; from: 0; to: (control.mirrored ? -0.5 : 0.5) * -control.width }
        FadeOut {}
    }
}