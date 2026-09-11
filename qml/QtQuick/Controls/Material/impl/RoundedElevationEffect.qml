


import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

ElevationEffect {
    required property int roundedScale

    _shadows: roundedScale === Material.NotRounded ? _defaultShadows : roundedShadows()

    function roundedShadows() {
        
        let shadows = [..._defaultShadows]
        for (let i = 0, strength = 0.95; i < shadows.length; ++i) {
            
            shadows[i].strength = strength
            
            
            
            
            strength = Math.max(0.05, strength - (roundedScale > Material.ExtraSmallScale ? 0.1 : 0.3))

            
            if (i > 0) {
                
                for (let angularShadowIndex = 0; angularShadowIndex < shadows[i].angularValues.length; ++angularShadowIndex) {
                    shadows[i].angularValues[angularShadowIndex].blur =
                        Math.max(1, Math.floor(shadows[i].angularValues[angularShadowIndex].blur / 4))
                }
            }
        }
        return shadows
    }
}