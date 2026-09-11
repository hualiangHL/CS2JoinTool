pragma Singleton
import QtQuick

QtObject {
    id: theme

    
    property bool isDark: true

    
    readonly property color darkBg: "#FF0F1117"
    readonly property color darkSurface: "#FF1A1D27"
    readonly property color darkSurfaceHover: "#FF242836"
    readonly property color darkCard: "#FF1E2230"
    readonly property color darkBorder: "#FFA78BFA"
    readonly property color darkTextPrimary: "#FFE8EAF0"
    readonly property color darkTextSecondary: "#FF9BA1B5"
    readonly property color darkTextDisabled: "#FF5A5F73"

    readonly property color lightBg: "#FFF5F6FA"
    readonly property color lightSurface: "#FFFFFFFF"
    readonly property color lightSurfaceHover: "#FFF0F2F7"
    readonly property color lightCard: "#FFFFFFFF"
    readonly property color lightBorder: "#FFE2E5ED"
    readonly property color lightTextPrimary: "#FF1A1D27"
    readonly property color lightTextSecondary: "#FF5A5F73"
    readonly property color lightTextDisabled: "#FFB0B5C5"

    readonly property color primary: "#FFA78BFA"
    readonly property color primaryHover: "#FF00E8BC"
    readonly property color primaryPressed: "#FF00B894"
    readonly property color primaryLight: "#1AA78BFA"
    readonly property color primaryGlow: "#40A78BFA"

    readonly property color accent: "#FF5B8DEF"
    readonly property color accentHover: "#FF7AA3F5"

    readonly property color success: "#FF4ADE80"
    readonly property color warning: "#FFFBBF24"
    readonly property color error: "#FFF87171"
    readonly property color info: "#FF60A5FA"

    property color bg: isDark ? darkBg : lightBg
    property color surface: isDark ? darkSurface : lightSurface
    property color surfaceHover: isDark ? darkSurfaceHover : lightSurfaceHover
    property color card: isDark ? darkCard : lightCard
    property color border: isDark ? darkBorder : lightBorder
    property color textPrimary: isDark ? darkTextPrimary : lightTextPrimary
    property color textSecondary: isDark ? darkTextSecondary : lightTextSecondary
    property color textDisabled: isDark ? darkTextDisabled : lightTextDisabled

    
    readonly property real radiusSm: 8
    readonly property real radiusMd: 12
    readonly property real radiusLg: 16
    readonly property real radiusXl: 24
    readonly property real radiusFull: 999

    readonly property real spacingXs: 4
    readonly property real spacingSm: 8
    readonly property real spacingMd: 12
    readonly property real spacingLg: 16
    readonly property real spacingXl: 24
    readonly property real spacing2xl: 32

    readonly property real paddingSm: 10
    readonly property real paddingMd: 16
    readonly property real paddingLg: 20
    readonly property real paddingXl: 28

    
    readonly property string fontFamily: "Segoe UI, Microsoft YaHei, sans-serif"
    readonly property real fontXs: 11
    readonly property real fontSm: 12
    readonly property real fontMd: 14
    readonly property real fontLg: 16
    readonly property real fontXl: 20
    readonly property real font2xl: 24
    readonly property real font3xl: 32

    
    readonly property color shadowColor: isDark ? "#000000" : "#1A1A2E"
    readonly property real shadowOpacity: isDark ? 0.4 : 0.08
    readonly property real shadowBlur: 20
    readonly property real shadowY: 4

    
    readonly property int durationFast: 150
    readonly property int durationNormal: 250
    readonly property int durationSlow: 400
    readonly property real springDamping: 0.7
    readonly property real springEpsilon: 0.01

    
    readonly property real navWidth: 220
    readonly property real titleBarHeight: 48
    readonly property real windowMinWidth: 960
    readonly property real windowMinHeight: 640

    function toggleTheme() {
        isDark = !isDark
    }

    function withOpacity(color, opacity) {
        return Qt.rgba(color.r, color.g, color.b, opacity)
    }
}