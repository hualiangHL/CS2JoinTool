import QtQuick
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import "qrc:/qml" as App

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1100
    height: 720
    minimumWidth: 900
    minimumHeight: 600
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "cs2挤服工具V4_1"
    property bool joinDetailVisible: false
    property int currentPage: 0

    Connections {
        target: appController
        function onActivateRequested() {
            if (mainWindow.visibility === Window.Minimized)
                mainWindow.visibility = Window.Windowed
            mainWindow.show()
            mainWindow.raise()
            mainWindow.requestActivate()
        }
    }

    // 背景图轮播（新图先100%底层显示，旧图上层淡出，全程不透明）
    property var bgSources: ["qrc:/assets/bg1.jpg", "qrc:/assets/bg2.jpg", "qrc:/assets/bg.jpg"]
    property int bgIndex: 0
    property bool bgSwap: false
    property bool bgPending: false

    function switchBg(newIdx) {
        bgIndex = newIdx
        var nextImg = bgSwap ? bgA : bgB
        bgPending = true
        nextImg.source = bgSources[bgIndex]
    }

    // 主界面内容
    Item {
        id: rootContent
        anchors.fill: parent

    // 背景图层（transparentWindow=true 时整体隐藏，窗口全透明）
    Item {
        id: bgLayer
        anchors.fill: parent
        opacity: appController.transparentWindow ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        // 实色底色（防止交叉淡入淡出时透出窗口透明）
        Rectangle { anchors.fill: parent; color: "#0F1117" }

        Image {
            id: bgA
            anchors.fill: parent
            source: bgSources[bgIndex]
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            asynchronous: true
            opacity: !bgSwap ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 1800; easing.type: Easing.InOutCubic } }
            onStatusChanged: {
                if (status === Image.Ready && bgPending && bgSwap) {
                    bgPending = false
                    bgSwap = false
                }
            }
        }

        Image {
            id: bgB
            anchors.fill: parent
            source: bgSources[bgIndex]
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            asynchronous: true
            opacity: bgSwap ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 1800; easing.type: Easing.InOutCubic } }
            onStatusChanged: {
                if (status === Image.Ready && bgPending && !bgSwap) {
                    bgPending = false
                    bgSwap = true
                }
            }
        }
    }

    Timer {
        interval: 200000
        repeat: true
        running: appController.bgMode === 0
        onTriggered: switchBg((bgIndex + 1) % bgSources.length)
    }

    Connections {
        target: appController
        function onBgModeChanged(mode) {
            if (mode > 0) switchBg(mode - 1)
        }
    }

    Component.onCompleted: {
        // DPI 适配：根据屏幕可用尺寸调整窗口大小并居中
        var scr = mainWindow.screen
        if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
        if (scr && scr.availableGeometry) {
            var avail = scr.availableGeometry
            var targetW = 1100
            var targetH = 720
            if (avail.width > 0 && avail.height > 0) {
                if (avail.width < targetW + 40 || avail.height < targetH + 40) {
                    var scale = Math.min((avail.width - 40) / targetW, (avail.height - 40) / targetH)
                    targetW = Math.max(800, Math.floor(targetW * scale))
                    targetH = Math.max(550, Math.floor(targetH * scale))
                }
                mainWindow.width = targetW
                mainWindow.height = targetH
                mainWindow.x = avail.x + Math.floor((avail.width - targetW) / 2)
                mainWindow.y = avail.y + Math.floor((avail.height - targetH) / 2)
            }
        }

        if (appController.bgMode === 0) {
            bgIndex = Math.floor(Math.random() * bgSources.length)
        } else {
            bgIndex = appController.bgMode - 1
        }
        bgA.source = bgSources[bgIndex]
        bgB.source = bgSources[bgIndex]
        if (appController.startMinimizedToTray) {
            appController.minimizeToTray()
        }
        appController.setupRoundedCorners(mainWindow)
        appController.toastRequested.connect(function(title, message) {
            inAppToast.showToast(title, message)
        })
    }

    // 暗色遮罩
    Rectangle {
        anchors.fill: parent
        color: "#700a0e27"
    }

    // 主体：导航栏 + 内容区
    Row {
        anchors.fill: parent
        spacing: 0

        // 左侧导航栏
        Rectangle {
            id: navRect
            width: 210
            height: parent.height
            color: "#90121628"

            // 选中背景（流畅移动动画）
            Rectangle {
                id: navHighlight
                z: 0
                radius: 10
                color: App.Theme.primaryLight
                visible: false
                property bool animateReady: false
                property Item targetItem: mainWindow.currentPage < 5 ? navRepeater.itemAt(mainWindow.currentPage) : (mainWindow.currentPage === 5 ? settingsItem : aboutItem)

                onTargetItemChanged: {
                    if (!targetItem) return
                    visible = true
                    var tx = navColumn.x + targetItem.x
                    var ty = navColumn.y + targetItem.y
                    if (!animateReady) {
                        // 第一次直接定位，不播动画
                        xBehavior.enabled = false; yBehavior.enabled = false
                        wBehavior.enabled = false; hBehavior.enabled = false
                        x = tx; y = ty; width = targetItem.width; height = targetItem.height
                        animateReady = true
                        Qt.callLater(function() {
                            xBehavior.enabled = true; yBehavior.enabled = true
                            wBehavior.enabled = true; hBehavior.enabled = true
                        })
                    } else {
                        x = tx; y = ty; width = targetItem.width; height = targetItem.height
                    }
                }

                Behavior on x { id: xBehavior; NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                Behavior on y { id: yBehavior; NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                Behavior on width { id: wBehavior; NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
                Behavior on height { id: hBehavior; NumberAnimation { duration: 280; easing.type: Easing.InOutCubic } }
            }

            ColumnLayout {
                id: navColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                // 应用标题
                Row {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 10
                    opacity: 0
                    property real slideX: -20
                    transform: Translate { x: slideX }
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Behavior on slideX { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Timer { running: true; interval: 0; repeat: false; onTriggered: { parent.opacity = 1; parent.slideX = 0 } }

                    Image {
                        width: 34; height: 34
                        source: "qrc:/assets/app_icon_128.png"
                        sourceSize: Qt.size(64, 64)
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        smooth: true
                    }
                    Text { text: "cs2挤服工具V4_1"; color: App.Theme.textPrimary; font.pixelSize: 15; font.bold: true; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight }
                }

                // 分隔线
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    height: 1
                    color: App.Theme.border
                    opacity: 0
                    Timer { running: true; interval: 75; repeat: false; onTriggered: parent.opacity = 1 }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                // 导航菜单项
                Repeater {
                    id: navRepeater
                    model: [
                        { name: "挤服主页", icon: "⌂" },
                        { name: "服务器列表", icon: "≡" },
                        { name: "ExG冷却时间", icon: "⏱" },
                        { name: "地图订阅", icon: "★" },
                        { name: "创意工坊", icon: "🗺" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 10
                        color: navMouse.containsMouse ? "#15A78BFA" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        opacity: 0
                        property real slideX: -20
                        transform: Translate { x: slideX }
                        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                        Behavior on slideX { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                        Timer { running: true; interval: 150 + index * 75; repeat: false; onTriggered: { parent.opacity = 1; parent.slideX = 0 } }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            Item {
                                width: 18; height: 18
                                Canvas {
                                    id: houseCanvas
                                    width: 18; height: 18
                                    visible: index === 0
                                    property bool selected: mainWindow.currentPage === 0
                                    onSelectedChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        var c = mainWindow.currentPage === 0 ? "#FFA78BFA" : "#FF9BA1B5"
                                        ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // roof
                                        ctx.beginPath()
                                        ctx.moveTo(3, 9.5); ctx.lineTo(9, 3.5); ctx.lineTo(15, 9.5)
                                        ctx.stroke()
                                        // left wall
                                        ctx.beginPath()
                                        ctx.moveTo(4, 9.5); ctx.lineTo(4, 16)
                                        ctx.stroke()
                                        // right wall
                                        ctx.beginPath()
                                        ctx.moveTo(14, 9.5); ctx.lineTo(14, 16)
                                        ctx.stroke()
                                        // bottom
                                        ctx.beginPath()
                                        ctx.moveTo(4, 16); ctx.lineTo(14, 16)
                                        ctx.stroke()
                                        // door
                                        ctx.beginPath()
                                        ctx.moveTo(7.5, 16); ctx.lineTo(7.5, 12); ctx.lineTo(10.5, 12); ctx.lineTo(10.5, 16)
                                        ctx.stroke()
                                    }
                                }
                                Canvas {
                                    id: serverCanvas
                                    width: 18; height: 18
                                    visible: index === 1
                                    property bool selected: mainWindow.currentPage === 1
                                    onSelectedChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        var c = mainWindow.currentPage === 1 ? "#FFA78BFA" : "#FF9BA1B5"
                                        ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // top box
                                        ctx.beginPath()
                                        ctx.moveTo(4, 2); ctx.lineTo(14, 2); ctx.quadraticCurveTo(15.5, 2, 15.5, 3.5); ctx.lineTo(15.5, 6.5)
                                        ctx.quadraticCurveTo(15.5, 8, 14, 8); ctx.lineTo(4, 8); ctx.quadraticCurveTo(2.5, 8, 2.5, 6.5)
                                        ctx.lineTo(2.5, 3.5); ctx.quadraticCurveTo(2.5, 2, 4, 2)
                                        ctx.stroke()
                                        // bottom box
                                        ctx.beginPath()
                                        ctx.moveTo(4, 10); ctx.lineTo(14, 10); ctx.quadraticCurveTo(15.5, 10, 15.5, 11.5); ctx.lineTo(15.5, 14.5)
                                        ctx.quadraticCurveTo(15.5, 16, 14, 16); ctx.lineTo(4, 16); ctx.quadraticCurveTo(2.5, 16, 2.5, 14.5)
                                        ctx.lineTo(2.5, 11.5); ctx.quadraticCurveTo(2.5, 10, 4, 10)
                                        ctx.stroke()
                                        // dots
                                        ctx.fillStyle = c
                                        ctx.beginPath(); ctx.arc(5.5, 5, 0.9, 0, Math.PI * 2); ctx.fill()
                                        ctx.beginPath(); ctx.arc(5.5, 13, 0.9, 0, Math.PI * 2); ctx.fill()
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: index !== 0 && index !== 1 && index !== 2 && index !== 3 && index !== 4
                                    text: modelData.icon; font.pixelSize: 16; color: mainWindow.currentPage === index ? App.Theme.primary : App.Theme.textSecondary
                                }
                                Canvas {
                                    id: fileCanvas
                                    width: 18; height: 18
                                    visible: index === 4
                                    property bool selected: mainWindow.currentPage === 4
                                    onSelectedChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        var c = mainWindow.currentPage === 4 ? "#FFA78BFA" : "#FF9BA1B5"
                                        ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // file body with folded corner
                                        ctx.beginPath()
                                        ctx.moveTo(5, 2.5)
                                        ctx.lineTo(11.5, 2.5)
                                        ctx.lineTo(15.5, 6.5)
                                        ctx.lineTo(15.5, 15.5)
                                        ctx.quadraticCurveTo(15.5, 16.5, 14.5, 16.5)
                                        ctx.lineTo(5, 16.5)
                                        ctx.quadraticCurveTo(4, 16.5, 4, 15.5)
                                        ctx.lineTo(4, 3.5)
                                        ctx.quadraticCurveTo(4, 2.5, 5, 2.5)
                                        ctx.stroke()
                                        // fold line
                                        ctx.beginPath()
                                        ctx.moveTo(11.5, 2.5)
                                        ctx.lineTo(11.5, 6.5)
                                        ctx.lineTo(15.5, 6.5)
                                        ctx.stroke()
                                    }
                                }
                                Canvas {
                                    id: clockCanvas
                                    width: 18; height: 18
                                    visible: index === 2
                                    property bool selected: mainWindow.currentPage === 2
                                    onSelectedChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        var c = mainWindow.currentPage === 2 ? "#FFA78BFA" : "#FF9BA1B5"
                                        ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // circle
                                        ctx.beginPath()
                                        ctx.arc(9, 9, 6.5, 0, Math.PI * 2)
                                        ctx.stroke()
                                        // hour hand (12)
                                        ctx.beginPath()
                                        ctx.moveTo(9, 9); ctx.lineTo(9, 5)
                                        ctx.stroke()
                                        // minute hand (~4)
                                        ctx.beginPath()
                                        ctx.moveTo(9, 9); ctx.lineTo(12, 11)
                                        ctx.stroke()
                                    }
                                }
                                Canvas {
                                    id: bellCanvas
                                    width: 18; height: 18
                                    visible: index === 3
                                    property bool selected: mainWindow.currentPage === 3
                                    onSelectedChanged: requestPaint()
                                    Component.onCompleted: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d"); ctx.reset()
                                        var c = mainWindow.currentPage === 3 ? "#FFA78BFA" : "#FF9BA1B5"
                                        ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                        // bell body
                                        ctx.beginPath()
                                        ctx.moveTo(5.5, 8.5)
                                        ctx.bezierCurveTo(5.5, 5.5, 7.5, 3.5, 9, 3.5)
                                        ctx.bezierCurveTo(10.5, 3.5, 12.5, 5.5, 12.5, 8.5)
                                        ctx.lineTo(12.5, 11)
                                        ctx.lineTo(14.5, 13.5)
                                        ctx.lineTo(3.5, 13.5)
                                        ctx.lineTo(5.5, 11)
                                        ctx.closePath()
                                        ctx.stroke()
                                        // bell bottom knob
                                        ctx.beginPath()
                                        ctx.moveTo(7.8, 15.5)
                                        ctx.quadraticCurveTo(9, 16.8, 10.2, 15.5)
                                        ctx.stroke()
                                    }
                                }
                            }
                            Text { text: modelData.name; font.pixelSize: 14; color: mainWindow.currentPage === index ? App.Theme.primary : App.Theme.textPrimary }
                        }

                        Rectangle {
                            width: 3; height: 20; radius: 1.5
                            color: App.Theme.primary
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: mainWindow.currentPage === index
                        }

                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mainWindow.currentPage = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // 网页菜单（点击打开浏览器，不切换页面，社区可在设置切换）
                Rectangle {
                    id: webMenuItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: exgWebMouse.containsMouse ? "#15A78BFA" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    opacity: 0
                    property real slideX: -20
                    transform: Translate { x: slideX }
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Behavior on slideX { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Timer { running: true; interval: 525; repeat: false; onTriggered: { parent.opacity = 1; parent.slideX = 0 } }
                    property string webMenuName: {
                        if (appController.webMenuCommunity === 1) return "UB网页菜单"
                        if (appController.webMenuCommunity === 2) return "X社网页菜单"
                        return "ExG网页菜单"
                    }
                    property string webMenuUrl: {
                        if (appController.webMenuCommunity === 1) return "https://cs.moeub.cn/inventory"
                        if (appController.webMenuCommunity === 2) return "https://bbs.upkk.com/plugin.php?id=xnet_steam_store_client_items:cs2_store_item_equip"
                        return "https://list.darkrp.cn:6514/"
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        Canvas {
                            width: 18; height: 18
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                var c = "#FF9BA1B5"
                                ctx.strokeStyle = c; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                // screen
                                ctx.beginPath()
                                ctx.moveTo(4.5, 3); ctx.lineTo(13.5, 3); ctx.quadraticCurveTo(15, 3, 15, 4.5); ctx.lineTo(15, 11.5)
                                ctx.quadraticCurveTo(15, 13, 13.5, 13); ctx.lineTo(4.5, 13); ctx.quadraticCurveTo(3, 13, 3, 11.5)
                                ctx.lineTo(3, 4.5); ctx.quadraticCurveTo(3, 3, 4.5, 3)
                                ctx.stroke()
                                // stand
                                ctx.beginPath()
                                ctx.moveTo(9, 13); ctx.lineTo(9, 15.5)
                                ctx.stroke()
                                // base
                                ctx.beginPath()
                                ctx.moveTo(6, 15.5); ctx.lineTo(12, 15.5)
                                ctx.stroke()
                            }
                        }
                        Text { text: webMenuItem.webMenuName; font.pixelSize: 14; color: App.Theme.textPrimary }
                    }
                    MouseArea {
                        id: exgWebMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: appController.openUrlDefaultBrowser(webMenuItem.webMenuUrl)
                    }
                }

                // 设置
                Rectangle {
                    id: settingsItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: setMouse.containsMouse ? "#15A78BFA" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    opacity: 0
                    property real slideX: -20
                    transform: Translate { x: slideX }
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Behavior on slideX { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Timer { running: true; interval: 600; repeat: false; onTriggered: { parent.opacity = 1; parent.slideX = 0 } }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        Canvas {
                            width: 18; height: 18
                            property bool selected: mainWindow.currentPage === 5
                            onSelectedChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                var c = selected ? "#FFA78BFA" : "#FF9BA1B5"
                                ctx.strokeStyle = c; ctx.lineWidth = 1.3; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                var cx = 9, cy = 9, teeth = 8
                                var rOut = 6.8, rIn = 5.2, rHole = 2.4
                                ctx.beginPath()
                                for (var i = 0; i <= teeth * 2; i++) {
                                    var ang = (i * Math.PI) / teeth - Math.PI / 2
                                    var r = (i % 2 === 0) ? rOut : rIn
                                    var x = cx + r * Math.cos(ang), y = cy + r * Math.sin(ang)
                                    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                                }
                                ctx.stroke()
                                ctx.beginPath()
                                ctx.arc(cx, cy, rHole, 0, Math.PI * 2)
                                ctx.stroke()
                            }
                        }
                        Text { text: "设置"; font.pixelSize: 14; color: mainWindow.currentPage === 5 ? App.Theme.primary : App.Theme.textPrimary }
                    }
                    Rectangle {
                        width: 3; height: 20; radius: 1.5
                        color: App.Theme.primary
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: mainWindow.currentPage === 5
                    }
                    MouseArea { id: setMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mainWindow.currentPage = 5 }
                }

                // 关于
                Rectangle {
                    id: aboutItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 10
                    color: aboutMouse.containsMouse ? "#15A78BFA" : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    opacity: 0
                    property real slideX: -20
                    transform: Translate { x: slideX }
                    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Behavior on slideX { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    Timer { running: true; interval: 675; repeat: false; onTriggered: { parent.opacity = 1; parent.slideX = 0 } }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        Canvas {
                            width: 18; height: 18
                            property bool selected: mainWindow.currentPage === 6
                            onSelectedChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                var c = selected ? "#FFA78BFA" : "#FF9BA1B5"
                                ctx.strokeStyle = c; ctx.fillStyle = c; ctx.lineWidth = 1.3; ctx.lineCap = "round"; ctx.lineJoin = "round"
                                function drawStar(cx, cy, rOut, rIn) {
                                    ctx.beginPath()
                                    for (var i = 0; i <= 8; i++) {
                                        var ang = (i * Math.PI) / 4 - Math.PI / 2
                                        var r = (i % 2 === 0) ? rOut : rIn
                                        var x = cx + r * Math.cos(ang), y = cy + r * Math.sin(ang)
                                        if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                                    }
                                    ctx.stroke()
                                }
                                // big sparkle
                                drawStar(11, 9.5, 5.5, 2)
                                // small sparkle top-left
                                drawStar(4.5, 4.5, 2, 0.8)
                                // small sparkle bottom-left
                                drawStar(5, 14.5, 1.8, 0.7)
                            }
                        }
                        Text { text: "关于"; font.pixelSize: 14; color: mainWindow.currentPage === 6 ? App.Theme.primary : App.Theme.textPrimary }
                    }
                    Rectangle {
                        width: 3; height: 20; radius: 1.5
                        color: App.Theme.primary
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: mainWindow.currentPage === 6
                    }
                    MouseArea { id: aboutMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: mainWindow.currentPage = 6 }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                    text: "EvolveUI Edition"
                    color: App.Theme.textDisabled
                    font.pixelSize: 10
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    Timer { running: true; interval: 750; repeat: false; onTriggered: parent.opacity = 1 }
                }
            }
        }

        // 右侧内容区
        Rectangle {
            width: parent.width - 210
            height: parent.height
            color: "transparent"
            clip: true

            Item {
                id: pageContainer
                anchors.fill: parent
                property int active: mainWindow.currentPage

                // 页面切换动画公共行为
                function pageOpacity(idx) { return pageContainer.active === idx ? 1 : 0 }
                function pageScale(idx) { return pageContainer.active === idx ? 1 : 0.96 }
                function pageZ(idx) { return pageContainer.active === idx ? 2 : 1 }

                App.HomePage {
                    id: homePageRef
                    anchors.fill: parent
                    pageActive: pageContainer.active === 0
                    opacity: pageContainer.active === 0 ? 1 : 0
                    scale: pageContainer.active === 0 ? 1 : 0.96
                    z: pageContainer.active === 0 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.ServerListPage {
                    id: serverListPageRef
                    pageActive: pageContainer.active === 1
                    anchors.fill: parent
                    opacity: pageContainer.active === 1 ? 1 : 0
                    scale: pageContainer.active === 1 ? 1 : 0.96
                    z: pageContainer.active === 1 ? 2 : 1
                    onRequestHomePage: mainWindow.currentPage = 0
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.CooldownPage {
                    id: cooldownRef
                    pageActive: pageContainer.active === 2
                    anchors.fill: parent
                    opacity: pageContainer.active === 2 ? 1 : 0
                    scale: pageContainer.active === 2 ? 1 : 0.96
                    z: pageContainer.active === 2 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.SubscriptionPage {
                    id: subscriptionRef
                    pageActive: pageContainer.active === 3
                    anchors.fill: parent
                    opacity: pageContainer.active === 3 ? 1 : 0
                    scale: pageContainer.active === 3 ? 1 : 0.96
                    z: pageContainer.active === 3 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.WorkshopPage {
                    id: workshopRef
                    pageActive: pageContainer.active === 4
                    anchors.fill: parent
                    opacity: pageContainer.active === 4 ? 1 : 0
                    scale: pageContainer.active === 4 ? 1 : 0.96
                    z: pageContainer.active === 4 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.SettingsPage {
                    id: settingsRef
                    pageActive: pageContainer.active === 5
                    anchors.fill: parent
                    opacity: pageContainer.active === 5 ? 1 : 0
                    scale: pageContainer.active === 5 ? 1 : 0.96
                    z: pageContainer.active === 5 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                App.AboutPage {
                    id: aboutRef
                    pageActive: pageContainer.active === 6
                    anchors.fill: parent
                    opacity: pageContainer.active === 6 ? 1 : 0
                    scale: pageContainer.active === 6 ? 1 : 0.96
                    z: pageContainer.active === 6 ? 2 : 1
                    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    // 右上角窗口控制按钮
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.rightMargin: 12
        spacing: 8
        z: 10

        // 最小化
        Rectangle {
            width: 34; height: 34; radius: 9
            color: minMouse.containsMouse ? "#c02a2f45" : "#801E1B2E"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea { id: minMouse; anchors.fill: parent; hoverEnabled: true; onClicked: mainWindow.showMinimized() }
            Rectangle { width: 12; height: 2; radius: 1; color: App.Theme.textPrimary; anchors.centerIn: parent }
        }

        // 最大化/还原
        Rectangle {
            width: 34; height: 34; radius: 9
            color: maxMouse.containsMouse ? "#c02a2f45" : "#801E1B2E"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea { id: maxMouse; anchors.fill: parent; hoverEnabled: true; onClicked: mainWindow.visibility === Window.Maximized ? mainWindow.showNormal() : mainWindow.showMaximized() }
            Rectangle { width: 12; height: 12; radius: 2; color: "transparent"; border.width: 1.5; border.color: App.Theme.textPrimary; anchors.centerIn: parent }
        }

        // 关闭
        Rectangle {
            width: 34; height: 34; radius: 9
            color: closeMouse.containsMouse ? "#e0e85050" : "#801E1B2E"
            Behavior on color { ColorAnimation { duration: 150 } }
            MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.tryClose() }
            Canvas {
                anchors.centerIn: parent; width: 14; height: 14
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = closeMouse.containsMouse ? "#ffffff" : App.Theme.textPrimary
                    ctx.lineWidth = 1.8; ctx.lineCap = "round"
                    ctx.beginPath(); ctx.moveTo(3, 3); ctx.lineTo(11, 11)
                    ctx.moveTo(11, 3); ctx.lineTo(3, 11); ctx.stroke()
                }
            }
        }
    }

    // 拖拽区域
    MouseArea {
        id: dragArea
        anchors.left: parent.left
        anchors.leftMargin: 210
        anchors.right: parent.right
        anchors.rightMargin: 140
        anchors.top: parent.top
        anchors.topMargin: 0
        height: 50
        onPressed: mainWindow.startSystemMove()
    }

    // 全局底部挤服状态栏
    Rectangle {
        id: bottomStatusBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 48
        color: "#d0121628"
        visible: opacity > 0.01
        opacity: appController.autoJoining ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        z: 50

        MouseArea {
            anchors.fill: parent
            onClicked: joinDetailVisible = true
            cursorShape: Qt.PointingHandCursor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 14

            // 状态指示灯
            Rectangle {
                width: 8; height: 8; radius: 4
                color: "#FFD4AA00"
                Layout.alignment: Qt.AlignVCenter
            }

            // 状态文字
            Text {
                text: "正在挤服"
                color: "#FFD4AA00"
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            // 分隔
            Rectangle { width: 1; height: 16; color: "#20A78BFA"; Layout.alignment: Qt.AlignVCenter }

            // 服务器名（自适应占满中间空间）
            Text {
                text: appController.currentServerName || "—"
                color: "#FFFFFF"
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 80
                Layout.alignment: Qt.AlignVCenter
            }

            // 地图
            Text {
                text: appController.currentMap || "—"
                color: "#A0A8B8"
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 140
                Layout.alignment: Qt.AlignVCenter
            }

            // 人数进度条
            Rectangle {
                width: 140; height: 18; radius: 9
                color: "#300a0e27"
                Layout.alignment: Qt.AlignVCenter
                clip: true

                Rectangle {
                    width: Math.min(1.0, appController.currentPlayers / Math.max(1, appController.maxPlayers)) * parent.width
                    height: parent.height
                    color: "#FFA78BFA"
                    radius: 9
                    Behavior on width { NumberAnimation { duration: 300 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: appController.currentPlayers + "/" + appController.maxPlayers
                    color: "#FFFFFF"
                    font.pixelSize: 10
                    font.bold: true
                }
            }

            // 尝试次数
            Text {
                text: appController.maxRetryCount > 0 ? ("尝试 " + Math.floor(appController.retryCount / 10) * 10 + "/" + appController.maxRetryCount) : ("尝试 " + Math.floor(appController.retryCount / 10) * 10)
                color: "#8B7DB8"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignVCenter
            }

            // 取消挤服按钮
            Rectangle {
                width: 72; height: 28; radius: 6
                color: cancelBtnMouse.containsMouse ? "#40CC0000" : "#25CC0000"
                border.width: 1; border.color: cancelBtnMouse.containsMouse ? "#FFCC0000" : "#80CC0000"
                Behavior on color { ColorAnimation { duration: 120 } }
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "取消挤服"
                    color: "#FF8888"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: cancelBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: appController.cancelJoin()
                }
            }
        }
    }

    } // rootContent 结束

    // 窗口紫色描边（最高层级，不被任何弹窗遮罩盖住）
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 20
        border.width: 2
        border.color: "#FFA78BFA"
        z: 2000
    }

    // 全局挤服详情面板遮罩
    Rectangle {
        id: joinDetailMask
        anchors.fill: parent
        z: 60
        color: "#90000000"
        visible: opacity > 0.01
        opacity: joinDetailVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent; onClicked: joinDetailVisible = false }
    }

    // 全局挤服详情面板
    Rectangle {
        id: joinDetailPanel
        width: 520
        height: 380
        radius: 12
        color: "#FF1E1B2E"
        border.width: 1
        border.color: "#40A78BFA"
        anchors.centerIn: parent
        visible: opacity > 0.01
        opacity: joinDetailVisible ? 1.0 : 0.0
        scale: joinDetailVisible ? 1.0 : 0.85
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        z: 61

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Text {
                text: "挤服详情"
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
            }

            Rectangle { width: parent.width; height: 1; color: "#15A78BFA" }

            // 地图信息
            Row {
                spacing: 12
                Text { text: "当前地图:"; color: "#FF9BA1B5"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: appController.currentMap || "未知"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; width: 280 }
            }

            Row {
                spacing: 12
                Text { text: "进入阈值:"; color: "#FF9BA1B5"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: appController.joinThreshold + " 人"; color: "#FFA78BFA"; font.pixelSize: 13; font.bold: true }
            }

            Row {
                spacing: 12
                Text { text: "已尝试:"; color: "#FF9BA1B5"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text { text: (appController.maxRetryCount > 0 ? (Math.floor(appController.retryCount / 10) * 10 + "/" + appController.maxRetryCount) : Math.floor(appController.retryCount / 10) * 10) + " 次"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
            }

            Row {
                spacing: 12
                Text { text: "服务器状态:"; color: "#FF9BA1B5"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: appController.serverStatus === 1 ? "在线" : (appController.serverStatus === 0 ? "查询中" : "离线")
                    color: appController.serverStatus === 1 ? "#FFA78BFA" : "#FF888888"
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            Item { Layout.fillHeight: true }

            // 按钮行
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                Rectangle {
                    width: 140; height: 40; radius: 8
                    color: cancelJoinMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                    border.width: 1; border.color: cancelJoinMouse.containsMouse ? App.Theme.primary : App.Theme.border
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea { id: cancelJoinMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.cancelJoin(); joinDetailVisible = false } }
                    Text { anchors.centerIn: parent; text: "取消挤服"; color: cancelJoinMouse.containsMouse ? App.Theme.primary : App.Theme.textSecondary; font.pixelSize: 13; font.bold: true }
                }

                Rectangle {
                    width: 140; height: 40; radius: 8
                    color: confirmJoinMouse.containsMouse ? "#30A78BFA" : "#20A78BFA"
                    border.width: 1; border.color: "#40A78BFA"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea { id: confirmJoinMouse; anchors.fill: parent; hoverEnabled: true; onClicked: joinDetailVisible = false }
                    Text { anchors.centerIn: parent; text: "确定"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                }
            }
        }
    }

    // 挤服成功窗口遮罩
    Rectangle {
        anchors.fill: parent
        z: 998
        color: "#90000000"
        visible: opacity > 0.01
        opacity: appController.connected ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea { anchors.fill: parent }
    }

    // 全局挤服成功窗口
    Rectangle {
        id: joinSuccessWindow
        width: 480
        height: 280
        radius: 12
        color: "#FF1E1B2E"
        border.width: 1
        border.color: "#40A78BFA"
        anchors.centerIn: parent
        visible: opacity > 0.01
        opacity: appController.connected ? 1.0 : 0.0
        scale: appController.connected ? 1.0 : 0.8
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
        z: 999

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "正在连接服务器"
                color: "#FFA78BFA"
                font.pixelSize: 24
                font.bold: true
            }

            Rectangle { width: parent.width; height: 1; color: "#15A78BFA" }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "已连接服务器 如果你没有进去说明有人比你快"
                color: "#FFFFFF"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Item { Layout.fillHeight: true }

            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Rectangle {
                    width: 140; height: 40; radius: 8
                    color: successRetryMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                    border.width: 1; border.color: successRetryMouse.containsMouse ? "#FFA78BFA" : "#40A78BFA"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea {
                        id: successRetryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            appController.connected = false
                            appController.startAutoJoin()
                        }
                    }
                    Text { anchors.centerIn: parent; text: "重新挤服"; color: successRetryMouse.containsMouse ? "#FFA78BFA" : "#A0A8B8"; font.pixelSize: 13; font.bold: true }
                }

                Rectangle {
                    width: 140; height: 40; radius: 8
                    color: successOkMouse.containsMouse ? "#30A78BFA" : "#20A78BFA"
                    border.width: 1; border.color: "#40A78BFA"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    MouseArea { id: successOkMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.connected = false }
                    Text { anchors.centerIn: parent; text: "确定"; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                }
            }
        }
    }

    // 系统桌面右下角挤服状态悬浮窗（独立置顶窗口）
    Window {
        id: floatStatusWindow
        width: 260
        height: 150
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        visible: false
        x: {
            var scr = mainWindow.screen
            if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
            if (scr && scr.availableGeometry) return scr.availableGeometry.x + scr.availableGeometry.width - width - 16
            return Screen.width - width - 16
        }
        y: {
            var scr = mainWindow.screen
            if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
            if (scr && scr.availableGeometry) return scr.availableGeometry.y + scr.availableGeometry.height - height - 48
            return Screen.height - height - 48
        }

        property bool floatStatusShow: true

        function showFloat() {
            floatStatusWindow.visible = true
            floatStatusWindow.requestActivate()
            floatContent.opacity = 0
            floatContent.scale = 0.85
            floatOpenAnim.start()
        }

        function hideFloat() {
            floatCloseAnim.start()
        }

        // 打开动画
        ParallelAnimation {
            id: floatOpenAnim
            NumberAnimation { target: floatContent; property: "opacity"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { target: floatContent; property: "scale"; from: 0.85; to: 1.0; duration: 320; easing.type: Easing.OutBack }
        }

        // 关闭动画
        ParallelAnimation {
            id: floatCloseAnim
            NumberAnimation { target: floatContent; property: "opacity"; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: floatContent; property: "scale"; from: 1.0; to: 0.9; duration: 200; easing.type: Easing.InCubic }
            onFinished: floatStatusWindow.visible = false
        }

        Rectangle {
            id: floatContent
            anchors.fill: parent
            radius: 12
            color: "#e81E1B2E"
            border.width: 1; border.color: "#40A78BFA"
            opacity: 0
            scale: 0.85

            // 顶部标题栏（可拖动）
            Rectangle {
                id: floatTitle
                width: parent.width; height: 32
                color: "#c0121525"
                radius: 12
                clip: true

                // 指示灯 + 标题
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle { width: 8; height: 8; radius: 4; color: "#FFD4AA00"; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "正在挤服"; color: "#FFD4AA00"; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                }

                // 关闭按钮（右上角，独立层级）
                Canvas {
                    id: floatCloseBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14; height: 14
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = floatCloseMouse.containsMouse ? "#e74c3c" : "#8B7DB8"
                        ctx.lineWidth = 2; ctx.lineCap = "round"
                        ctx.beginPath(); ctx.moveTo(2,2); ctx.lineTo(12,12); ctx.moveTo(12,2); ctx.lineTo(2,12); ctx.stroke()
                    }
                    MouseArea { id: floatCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: floatStatusWindow.floatStatusShow = false }
                }

                // 拖动区域（排除关闭按钮区域）
                MouseArea {
                    id: floatDragArea
                    property real pressX: 0
                    property real pressY: 0
                    anchors.left: parent.left
                    anchors.right: floatCloseBtn.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    onPressed: {
                        pressX = mouseX
                        pressY = mouseY
                    }
                    onPositionChanged: {
                        floatStatusWindow.x += mouseX - pressX
                        floatStatusWindow.y += mouseY - pressY
                    }
                }
            }

            // 内容
            Column {
                anchors.top: parent.top
                anchors.topMargin: 40
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                spacing: 8

                Row {
                    width: parent.width
                    Text { text: "服务器"; color: "#8B7DB8"; font.pixelSize: 11; width: 50 }
                    Text { text: appController.currentServerName || "—"; color: "#FFFFFF"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight; width: parent.width - 50 }
                }
                Row {
                    width: parent.width
                    Text { text: "地图"; color: "#8B7DB8"; font.pixelSize: 11; width: 50 }
                    Text { text: appController.currentMap || "—"; color: "#FFFFFF"; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width - 50 }
                }
                Row {
                    width: parent.width
                    Text { text: "人数"; color: "#8B7DB8"; font.pixelSize: 11; width: 50 }
                    Text { text: appController.currentPlayers + "/" + appController.maxPlayers; color: "#FFA78BFA"; font.pixelSize: 12; font.bold: true }
                }
                Row {
                    width: parent.width
                    Text { text: "尝试"; color: "#8B7DB8"; font.pixelSize: 11; width: 50 }
                    Text { text: (appController.maxRetryCount > 0 ? (Math.floor(appController.retryCount / 10) * 10 + "/" + appController.maxRetryCount) : Math.floor(appController.retryCount / 10) * 10) + " 次"; color: "#FFD4AA00"; font.pixelSize: 12; font.bold: true }
                }
            }

            // 点击内容区域激活主窗口（不覆盖标题栏）
            MouseArea {
                anchors.top: floatTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                onClicked: mainWindow.requestActivate()
            }
        }
    }

    Connections {
        target: appController
        function onAutoJoiningChanged(joining) {
            if (joining) {
                if (appController.floatWindowEnabled) {
                    floatStatusWindow.floatStatusShow = true
                    floatStatusWindow.showFloat()
                }
            } else if (floatStatusWindow.visible) {
                floatStatusWindow.hideFloat()
            }
        }
    }

    Connections {
        target: floatStatusWindow
        function onFloatStatusShowChanged(show) {
            if (!show && floatStatusWindow.visible) {
                floatStatusWindow.hideFloat()
            }
        }
    }

    // 关闭选择对话框
    Connections {
        target: appController
        function onCloseDialogRequested() {
            closeDlg.showDlg()
        }
    }

    Rectangle {
        id: closeDlgMask
        anchors.fill: parent
        color: "#80000000"
        z: 1000
        visible: opacity > 0.01
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent; onClicked: closeDlg.hideDlg() }
    }

    Rectangle {
        id: closeDlg
        width: 340; height: 180
        radius: 12
        color: "#f01E1B2E"
        border.width: 1; border.color: "#40A78BFA"
        z: 1001
        visible: opacity > 0.01
        opacity: 0
        scale: 0.9
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        anchors.centerIn: parent

        function showDlg() { opacity = 1; scale = 1; closeDlgMask.opacity = 1 }
        function hideDlg() { opacity = 0; scale = 0.9; closeDlgMask.opacity = 0 }

        Rectangle {
            id: closeDlgX
            width: 28; height: 28; radius: 7
            anchors.top: parent.top; anchors.topMargin: 10
            anchors.right: parent.right; anchors.rightMargin: 10
            color: closeDlgXMouse.containsMouse ? "#40ff6b6b" : "#20FFFFFF"
            Behavior on color { ColorAnimation { duration: 120 } }
            z: 10
            MouseArea { id: closeDlgXMouse; anchors.fill: parent; hoverEnabled: true; onClicked: closeDlg.hideDlg() }
            Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 14; font.bold: true }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Text {
                text: "关闭提示"
                color: "#FFFFFF"
                font.pixelSize: 16
                font.bold: true
            }
            Text {
                text: "你想怎么处理？"
                color: "#B8A9D9"
                font.pixelSize: 13
            }

            Item { width: parent.width; height: 1 }

            Row {
                spacing: 12
                anchors.right: parent.right

                Rectangle {
                    width: 120; height: 36; radius: 8
                    color: trayBtnMouse.containsMouse ? "#20A78BFA" : "#1E1B2E"
                    border.width: 1; border.color: "#40A78BFA"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "最小化托盘"; color: "#A78BFA"; font.pixelSize: 13 }
                    MouseArea {
                        id: trayBtnMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: { closeDlg.hideDlg(); appController.minimizeToTray() }
                    }
                }

                Rectangle {
                    width: 120; height: 36; radius: 8
                    color: quitBtnMouse.containsMouse ? "#e0e85050" : "#1E1B2E"
                    border.width: 1; border.color: "#40e85050"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text { anchors.centerIn: parent; text: "直接关闭"; color: quitBtnMouse.containsMouse ? "#FFFFFF" : "#e85050"; font.pixelSize: 13 }
                    MouseArea {
                        id: quitBtnMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: appController.quitApp()
                    }
                }
            }
        }
    }

    // 程序内右下角通知（纯文字无图标，替代 Windows 系统通知）
    Rectangle {
        id: inAppToast
        width: 320; height: 72
        radius: 12
        color: "#f01E1B2E"
        border.width: 1; border.color: "#40A78BFA"
        z: 3000
        opacity: 0
        visible: opacity > 0.01
        x: mainWindow.width - width - 20
        y: mainWindow.height - height - 20
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Text {
                id: toastTitle
                text: ""
                color: "#FFFFFF"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                id: toastMessage
                text: ""
                color: "#9BA1B5"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width
            }
        }

        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: {
                inAppToast.opacity = 0
                inAppToast.y = mainWindow.height - inAppToast.height - 20 + 20
            }
        }

        function showToast(title, message) {
            toastTitle.text = title
            toastMessage.text = message
            inAppToast.opacity = 1
            inAppToast.y = mainWindow.height - inAppToast.height - 20
            toastTimer.restart()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                inAppToast.opacity = 0
                toastTimer.stop()
            }
        }
    }
}
