import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml" as App

Item {
    id: settingsPage
    width: parent.width
    height: parent.height
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false
    property bool showCard3: false

    onPageActiveChanged: {
        if (!pageActive) {
            showCard1 = false; showCard2 = false; showCard3 = false
            if (bgDropdownOpen) { bgDropdownOpen = false; bgDropdownAnim.to = 0; bgDropdownAnim.start() }
            if (cbDropdownOpen) { cbDropdownOpen = false; cbDropdownAnim.to = 0; cbDropdownAnim.start() }
            if (defaultProtoDropdownOpen) { defaultProtoDropdownOpen = false; defaultProtoDropdownAnim.to = 0; defaultProtoDropdownAnim.start() }
            if (webMenuDropdownOpen) { webMenuDropdownOpen = false; webMenuDropdownAnim.to = 0; webMenuDropdownAnim.start() }
            protoHelpVisible = false
        }
    }

    Timer { interval: 200; repeat: false; running: pageActive; onTriggered: showCard1 = true }
    Timer { interval: 400; repeat: false; running: pageActive; onTriggered: showCard2 = true }
    Timer { interval: 800; repeat: false; running: pageActive; onTriggered: showCard3 = true }

    Text {
        id: settingsTitle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        text: "设置"
        font.family: App.Theme.fontFamily
        font.bold: true
        color: App.Theme.textPrimary
        font.pixelSize: 22
    }

    ScrollView {
        anchors.top: settingsTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: settingsColumn
            width: settingsPage.width - 32 - 12
            spacing: 16

            
            Rectangle {
                width: parent.width
                height: appearanceCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: appearanceCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 18

                    Text { text: "外观"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "背景图"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        Rectangle {
                            id: bgDropBtn
                            width: 180; height: 32; radius: 8
                            color: bgDropMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: bgDropMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            readonly property var items: ["随机轮播", "图片一", "图片二", "图片三"]

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 12
                                text: bgDropBtn.items[appController.bgMode]
                                color: App.Theme.textPrimary; font.pixelSize: 12
                            }
                            Canvas {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 12
                                width: 10; height: 6
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.fillStyle = App.Theme.textSecondary
                                    ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,0); ctx.lineTo(5,6); ctx.closePath(); ctx.fill()
                                }
                            }
                            MouseArea { id: bgDropMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPage.toggleBgDropdown() }

                        }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "全透明窗口"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.transparentWindow; onToggled: appController.transparentWindow = !appController.transparentWindow }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "难度T级显示"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "[只是把难度更换一种显示方式 T0简单 T1普通 T2困难 T3极难 T4史诗 T5梦魇 T6绝境]"
                            color: "#808080"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.leftMargin: 8
                        }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.difficultyTierMode; onToggled: appController.difficultyTierMode = !appController.difficultyTierMode }
                    }
                }
            }

            
            Rectangle {
                id: staggerChild1
                opacity: showCard1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                width: parent.width
                height: windowCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: windowCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 18

                    Text { text: "窗口"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    RowLayout {
                        width: parent.width
                        Text { text: "启动时最小化到托盘"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.startMinimizedToTray; onToggled: appController.startMinimizedToTray = !appController.startMinimizedToTray }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "右下角挤服状态悬浮窗"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch {
                            id: floatWindowSwitch
                            checked: appController.floatWindowEnabled
                            onToggled: appController.floatWindowEnabled = !appController.floatWindowEnabled
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "加入服务器悬浮通知"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.joinNotificationEnabled; onToggled: appController.joinNotificationEnabled = !appController.joinNotificationEnabled }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "最小化托盘悬浮通知"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.minimizeNotificationEnabled; onToggled: appController.minimizeNotificationEnabled = !appController.minimizeNotificationEnabled }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "关闭按钮行为"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        Rectangle {
                            id: closeBehaviorBtn
                            width: 130; height: 32; radius: 8
                            color: cbMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: cbMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            readonly property var items: ["始终询问", "最小化托盘", "直接关闭"]

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 12
                                text: closeBehaviorBtn.items[appController.closeBehavior]
                                color: App.Theme.textPrimary; font.pixelSize: 12
                            }
                            Canvas {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 12
                                width: 10; height: 6
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.fillStyle = App.Theme.textSecondary
                                    ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,0); ctx.lineTo(5,6); ctx.closePath(); ctx.fill()
                                }
                            }
                            MouseArea { id: cbMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPage.toggleCbDropdown() }

                        }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "网页菜单社区切换"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        Rectangle {
                            id: webMenuBtn
                            width: 130; height: 32; radius: 8
                            color: wmMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: wmMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            readonly property var items: ["ExG网页菜单", "UB网页菜单", "X社网页菜单"]

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 12
                                text: webMenuBtn.items[appController.webMenuCommunity]
                                color: App.Theme.textPrimary; font.pixelSize: 12
                            }
                            Canvas {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 12
                                width: 10; height: 6
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.fillStyle = App.Theme.textSecondary
                                    ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,0); ctx.lineTo(5,6); ctx.closePath(); ctx.fill()
                                }
                            }
                            MouseArea { id: wmMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPage.toggleWebMenuDropdown() }

                        }
                    }
                }
            }

            
            Rectangle {
                id: staggerChild2
                opacity: showCard2 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                width: parent.width
                height: joinCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: joinCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 18

                    Text { text: "挤服"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    RowLayout {
                        width: parent.width
                        Text { text: "默认连接协议"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: "[不同连接协议说明]"
                            color: "#808080"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.leftMargin: 8
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: protoHelpVisible = true
                            }
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        Rectangle {
                            id: defaultProtoBtn
                            width: 280; height: 34; radius: 8
                            color: defaultProtoMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: defaultProtoMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            readonly property var items: ["steam://connect「服务器浏览器协议」", "steam://run/730//+connect「游戏启动协议」"]

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 12
                                text: defaultProtoBtn.items[appController.defaultConnectProtocol]
                                color: App.Theme.textPrimary; font.pixelSize: 12
                            }
                            Canvas {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 12
                                width: 10; height: 6
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.fillStyle = App.Theme.textSecondary
                                    ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(10,0); ctx.lineTo(5,6); ctx.closePath(); ctx.fill()
                                }
                            }
                            MouseArea { id: defaultProtoMouse; anchors.fill: parent; hoverEnabled: true; onClicked: settingsPage.toggleDefaultProtoDropdown() }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "连接成功后关闭程序"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: false }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "打开0.01ms-49.99ms间隔限制"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch {
                            id: proModeSwitch
                            checked: appController.proMode
                            onToggled: {
                                if (!appController.proMode) {
                                    proPasswordInput.text = ""
                                    proPasswordPopup.open()
                                } else {
                                    appController.proMode = false
                                }
                            }
                        }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "默认挤服间隔(ms)"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: "[该设置为每次打开挤服列表间隔ms 最低50最高500]"
                            color: "#808080"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.leftMargin: 8
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        TextField {
                            id: defaultIntervalInput
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 32
                            Layout.maximumWidth: 120
                            Layout.maximumHeight: 32
                            Layout.minimumWidth: 120
                            Layout.minimumHeight: 32
                            width: 120
                            height: 32
                            text: appController.defaultJoinInterval.toFixed(2)
                            background: Rectangle { color: App.Theme.bg; radius: 6; border.width: 1; border.color: "#30A78BFA" }
                            font.pixelSize: 13; color: App.Theme.textPrimary; padding: 6
                            horizontalAlignment: Text.AlignHCenter
                            validator: DoubleValidator { decimals: 2 }
                            onAccepted: {
                                appController.defaultJoinInterval = parseFloat(text) || 100
                                text = appController.defaultJoinInterval.toFixed(2)
                            }
                            onEditingFinished: {
                                appController.defaultJoinInterval = parseFloat(text) || 100
                                text = appController.defaultJoinInterval.toFixed(2)
                            }
                        }
                    }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "挤服CPU核心数"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: "[根据电脑性能和网络情况调整核心数 核心越多挤服越猛 对服务器承担的压力越大 默认2个核心]"
                            color: "#808080"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                            Layout.leftMargin: 8
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        TextField {
                            id: joinCoreInput
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 32
                            Layout.maximumWidth: 120
                            Layout.maximumHeight: 32
                            Layout.minimumWidth: 120
                            Layout.minimumHeight: 32
                            width: 120
                            height: 32
                            text: appController.joinCoreCount
                            background: Rectangle { color: App.Theme.bg; radius: 6; border.width: 1; border.color: "#30A78BFA" }
                            font.pixelSize: 13; color: App.Theme.textPrimary; padding: 6
                            horizontalAlignment: Text.AlignHCenter
                            validator: IntValidator { bottom: 1; top: appController.cpuCoreCount }
                            onAccepted: {
                                var c = parseInt(text) || 2
                                if (c < 1) c = 1
                                if (c > appController.cpuCoreCount) c = appController.cpuCoreCount
                                appController.joinCoreCount = c
                                text = appController.joinCoreCount
                            }
                            onEditingFinished: {
                                var c = parseInt(text) || 2
                                if (c < 1) c = 1
                                if (c > appController.cpuCoreCount) c = appController.cpuCoreCount
                                appController.joinCoreCount = c
                                text = appController.joinCoreCount
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        Text { text: "最大尝试次数(0=无限)"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        TextField {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 32
                            Layout.maximumWidth: 120
                            Layout.maximumHeight: 32
                            Layout.minimumWidth: 120
                            Layout.minimumHeight: 32
                            width: 120
                            height: 32
                            text: appController.maxRetryCount
                            background: Rectangle { color: App.Theme.bg; radius: 6; border.width: 1; border.color: "#30A78BFA" }
                            font.pixelSize: 13; color: App.Theme.textPrimary; padding: 6
                            horizontalAlignment: Text.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 999999 }
                            onAccepted: appController.maxRetryCount = parseInt(text) || 0
                            onEditingFinished: appController.maxRetryCount = parseInt(text) || 0
                        }
                    }

                    Text { text: "查询超时(ms): 3000"; color: App.Theme.textSecondary; font.pixelSize: 12 }

                    
                    RowLayout {
                        width: parent.width
                        Text { text: "默认配置文件夹"; color: App.Theme.textPrimary; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }

                        Text {
                            text: "[暂时无法修改位置因为修改会报错]"
                            color: "#808080"
                            font.pixelSize: 12
                            Layout.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 1; height: 1; Layout.fillWidth: true }

                        Rectangle {
                            id: configFolderBox
                            Layout.preferredWidth: 300
                            Layout.maximumWidth: 300
                            height: 30
                            radius: 6
                            color: configFolderMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: configFolderMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 10
                                anchors.right: parent.right; anchors.rightMargin: 10
                                text: appController.configFolderPath
                                color: App.Theme.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }

                            MouseArea {
                                id: configFolderMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appController.openConfigFolder()
                            }
                        }
                    }
                }
            }

            
            Rectangle {
                id: staggerChild3
                opacity: showCard3 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                width: parent.width
                height: debugCol.height + 32
                radius: 12
                color: "#b01E1B2E"
                border.width: 1; border.color: App.Theme.border

                Column {
                    id: debugCol
                    width: parent.width - 32
                    anchors.centerIn: parent
                    spacing: 18

                    Text { text: "调试"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    RowLayout {
                        width: parent.width
                        Text { text: "玩家列表数据"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        Item { width: 1; height: 1; Layout.fillWidth: true }
                        App.ESwitch { checked: appController.debugPlayerList; onToggled: appController.debugPlayerList = !appController.debugPlayerList }
                    }
                }
            }
        }
    }

    
    Popup {
        id: proPasswordPopup
        width: 320
        implicitHeight: 190
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        Overlay.modal: Rectangle { color: "#80CC0000" }
        x: Math.max(0, (parent.width - width) / 2)
        y: Math.max(0, (parent.height - height) / 2)
        background: Rectangle { color: "#601E1B2E"; radius: 12; border.width: 1; border.color: "#FF2D3245" }
        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 240; easing.type: Easing.OutBack }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.9; duration: 150; easing.type: Easing.InCubic }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            Text { text: "输入密码开启极速模式"; color: App.Theme.textPrimary; font.pixelSize: 15; font.bold: true }
            Text { text: "解锁后挤服间隔最低可调至0.01ms"; color: App.Theme.textSecondary; font.pixelSize: 12 }

            TextField {
                id: proPasswordInput
                width: parent.width
                implicitHeight: 36
                echoMode: TextInput.Password
                placeholderText: "请输入密码"
                color: App.Theme.textPrimary
                font.pixelSize: 13
                padding: 10
                background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                placeholderTextColor: App.Theme.textSecondary
                onAccepted: proConfirmBtn.clicked()
            }

            RowLayout {
                width: parent.width
                spacing: 10
                Rectangle {
                    id: proCancelBtn
                    width: (parent.width - 10) / 2; height: 34; radius: 8
                    color: "#b01E1B2E"; border.width: 1; border.color: "#FF2D3245"
                    Text { anchors.centerIn: parent; text: "取消"; color: App.Theme.textPrimary; font.pixelSize: 13 }
                    MouseArea { anchors.fill: parent; onClicked: { proModeSwitch.checked = false; proPasswordPopup.close() } }
                }
                Rectangle {
                    id: proConfirmBtn
                    width: (parent.width - 10) / 2; height: 34; radius: 8
                    color: "#35A78BFA"; border.width: 1; border.color: App.Theme.primary
                    Text { anchors.centerIn: parent; text: "确认"; color: App.Theme.primary; font.pixelSize: 13; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (proPasswordInput.text === "114514") {
                                appController.proMode = true
                                proPasswordPopup.close()
                            } else {
                                proPasswordInput.text = ""
                                proModeSwitch.checked = false
                                proPasswordPopup.close()
                            }
                        }
                    }
                }
            }
        }
    }

    
    property bool bgDropdownOpen: false
    property real bgDropdownMask: 0
    property bool cbDropdownOpen: false
    property real cbDropdownMask: 0
    property bool defaultProtoDropdownOpen: false
    property real defaultProtoDropdownMask: 0
    property bool webMenuDropdownOpen: false
    property real webMenuDropdownMask: 0

    function toggleBgDropdown() {
        bgDropdownOpen = !bgDropdownOpen
        if (bgDropdownOpen) {
            var pos = bgDropBtn.mapToItem(settingsPage, 0, bgDropBtn.height - 2)
            bgDropdown.x = pos.x; bgDropdown.y = pos.y; bgDropdown.width = bgDropBtn.width
            bgDropdownMask = 0; bgDropdownAnim.to = 136; bgDropdownAnim.start()
        } else {
            bgDropdownAnim.to = 0; bgDropdownAnim.start()
        }
    }

    function toggleCbDropdown() {
        cbDropdownOpen = !cbDropdownOpen
        if (cbDropdownOpen) {
            var pos = closeBehaviorBtn.mapToItem(settingsPage, 0, closeBehaviorBtn.height - 2)
            cbDropdown.x = pos.x; cbDropdown.y = pos.y; cbDropdown.width = closeBehaviorBtn.width
            cbDropdownMask = 0; cbDropdownAnim.to = 100; cbDropdownAnim.start()
        } else {
            cbDropdownAnim.to = 0; cbDropdownAnim.start()
        }
    }

    function toggleDefaultProtoDropdown() {
        defaultProtoDropdownOpen = !defaultProtoDropdownOpen
        if (defaultProtoDropdownOpen) {
            var pos = defaultProtoBtn.mapToItem(settingsPage, 0, defaultProtoBtn.height - 2)
            defaultProtoDropdown.x = pos.x; defaultProtoDropdown.y = pos.y; defaultProtoDropdown.width = defaultProtoBtn.width
            defaultProtoDropdownMask = 0; defaultProtoDropdownAnim.to = 76; defaultProtoDropdownAnim.start()
        } else {
            defaultProtoDropdownAnim.to = 0; defaultProtoDropdownAnim.start()
        }
    }

    function toggleWebMenuDropdown() {
        webMenuDropdownOpen = !webMenuDropdownOpen
        if (webMenuDropdownOpen) {
            var pos = webMenuBtn.mapToItem(settingsPage, 0, webMenuBtn.height - 2)
            webMenuDropdown.x = pos.x; webMenuDropdown.y = pos.y; webMenuDropdown.width = webMenuBtn.width
            webMenuDropdownMask = 0; webMenuDropdownAnim.to = 100; webMenuDropdownAnim.start()
        } else {
            webMenuDropdownAnim.to = 0; webMenuDropdownAnim.start()
        }
    }

    MouseArea {
        anchors.fill: parent; z: 98
        visible: bgDropdownOpen || cbDropdownOpen || defaultProtoDropdownOpen || webMenuDropdownOpen
        onClicked: {
            if (bgDropdownOpen) settingsPage.toggleBgDropdown()
            if (cbDropdownOpen) settingsPage.toggleCbDropdown()
            if (defaultProtoDropdownOpen) settingsPage.toggleDefaultProtoDropdown()
            if (webMenuDropdownOpen) settingsPage.toggleWebMenuDropdown()
        }
    }

    
    Rectangle {
        id: bgDropdown
        visible: bgDropdownOpen || bgDropdownMask > 0.5
        z: 99; height: 136; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: "#FF2D3245"; clip: true
        opacity: bgDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: settingsPage.bgDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: bgDropBtn.items
                    Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: index === appController.bgMode ? "#35A78BFA" : (bgDropItemMouse2.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: modelData; color: index === appController.bgMode ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 12 }
                        MouseArea { id: bgDropItemMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.bgMode = index; settingsPage.toggleBgDropdown() } }
                    }
                }
            }
        }
    }

    
    Rectangle {
        id: cbDropdown
        visible: cbDropdownOpen || cbDropdownMask > 0.5
        z: 99; height: 100; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: "#FF2D3245"; clip: true
        opacity: cbDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: settingsPage.cbDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: closeBehaviorBtn.items
                    Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: index === appController.closeBehavior ? "#35A78BFA" : (cbItemMouse2.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: modelData; color: index === appController.closeBehavior ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 12 }
                        MouseArea { id: cbItemMouse2; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.closeBehavior = index; settingsPage.toggleCbDropdown() } }
                    }
                }
            }
        }
    }

    NumberAnimation { id: bgDropdownAnim; target: settingsPage; property: "bgDropdownMask"; duration: 200; easing.type: Easing.OutCubic }
    NumberAnimation { id: cbDropdownAnim; target: settingsPage; property: "cbDropdownMask"; duration: 200; easing.type: Easing.OutCubic }

    
    Rectangle {
        id: defaultProtoDropdown
        visible: defaultProtoDropdownOpen || defaultProtoDropdownMask > 0.5
        z: 99; height: 76; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: "#FF2D3245"; clip: true
        opacity: defaultProtoDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: settingsPage.defaultProtoDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: defaultProtoBtn.items
                    Rectangle {
                        width: parent.width; height: 30; radius: 6
                        color: index === appController.defaultConnectProtocol ? "#35A78BFA" : (defaultProtoItemMouse.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: modelData; color: index === appController.defaultConnectProtocol ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 12 }
                        MouseArea { id: defaultProtoItemMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.defaultConnectProtocol = index; settingsPage.toggleDefaultProtoDropdown() } }
                    }
                }
            }
        }
    }

    NumberAnimation { id: defaultProtoDropdownAnim; target: settingsPage; property: "defaultProtoDropdownMask"; duration: 200; easing.type: Easing.OutCubic }

    
    Rectangle {
        id: webMenuDropdown
        visible: webMenuDropdownOpen || webMenuDropdownMask > 0.5
        z: 99; height: 100; radius: 8
        color: "#f01E1B2E"; border.width: 1; border.color: "#FF2D3245"; clip: true
        opacity: webMenuDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Item {
            width: parent.width; height: settingsPage.webMenuDropdownMask; clip: true
            Column {
                width: parent.width; spacing: 2; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                Repeater {
                    model: webMenuBtn.items
                    Rectangle {
                        width: parent.width; height: 28; radius: 6
                        color: index === appController.webMenuCommunity ? "#35A78BFA" : (wmItemMouse.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 10; text: modelData; color: index === appController.webMenuCommunity ? App.Theme.primary : App.Theme.textPrimary; font.pixelSize: 12 }
                        MouseArea { id: wmItemMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { appController.webMenuCommunity = index; settingsPage.toggleWebMenuDropdown() } }
                    }
                }
            }
        }
    }

    NumberAnimation { id: webMenuDropdownAnim; target: settingsPage; property: "webMenuDropdownMask"; duration: 200; easing.type: Easing.OutCubic }

    
    property bool protoHelpVisible: false

    Rectangle {
        anchors.fill: parent
        z: 200
        color: "#80000000"
        opacity: protoHelpVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: protoHelpVisible || protoHelpPanel.opacity > 0.05
        MouseArea { anchors.fill: parent; onClicked: protoHelpVisible = false }

        Rectangle {
            id: protoHelpPanel
            anchors.centerIn: parent
            width: Math.min(560, parent.width - 32)
            height: Math.min(520, parent.height - 32)
            radius: 14
            color: "#f01E1B2E"
            border.width: 1; border.color: "#FF2D3245"
            scale: protoHelpVisible ? 1.0 : 0.88
            opacity: protoHelpVisible ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: protoHelpVisible ? 280 : 150; easing.type: protoHelpVisible ? Easing.OutBack : Easing.InCubic } }
            Behavior on opacity { NumberAnimation { duration: protoHelpVisible ? 220 : 120 } }
            clip: true

            MouseArea { anchors.fill: parent; propagateComposedEvents: false }

            
            Rectangle {
                width: parent.width; height: 48
                color: "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 20
                    text: "连接协议说明"
                    color: App.Theme.textPrimary; font.pixelSize: 16; font.bold: true
                }
                
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right; anchors.rightMargin: 16
                    width: 28; height: 28; radius: 6
                    color: protoHelpCloseMouse.containsMouse ? "#40FFFFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.centerIn: parent
                        text: "✕"; color: App.Theme.textSecondary; font.pixelSize: 14
                    }
                    MouseArea {
                        id: protoHelpCloseMouse
                        anchors.fill: parent; hoverEnabled: true
                        onClicked: protoHelpVisible = false
                    }
                }
            }

            
            Column {
                anchors.top: parent.top; anchors.topMargin: 56
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                spacing: 14

                
                Rectangle {
                    width: parent.width
                    height: 168
                    radius: 10
                    color: "#401E1B2E"
                    border.width: 1; border.color: "#30A78BFA"

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 28
                        spacing: 7
                        Text { text: "[steam://connect]「服务器浏览器协议」"; color: App.Theme.primary; font.pixelSize: 13; font.bold: true; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 走 Steam 服务器浏览器协议"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 会先弹出 Steam 的服务器信息窗口，显示服务器名、地图、玩家数等"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 需要在那个窗口里点 \"连接\"，或者有些情况自动连"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 适合想先看服务器详情再决定连不连"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    }
                }

                
                Rectangle {
                    width: parent.width
                    height: 196
                    radius: 10
                    color: "#401E1B2E"
                    border.width: 1; border.color: "#30A78BFA"

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 28
                        spacing: 7
                        Text { text: "[steam://run/730//+connect]「游戏启动协议」"; color: App.Theme.primary; font.pixelSize: 13; font.bold: true; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 走 Steam 游戏启动协议"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 730 是 CS2 的 App ID，// 后面是传给游戏的启动参数"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- +connect IP:端口 是 CS2 控制台命令，游戏启动后自动执行"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 直接启动 CS2，游戏加载完自动进服务器，不会弹浏览器服务器窗口"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                        Text { text: "- 适合已经确定要连哪个服务器，快速进入"; color: App.Theme.textSecondary; font.pixelSize: 12; wrapMode: Text.WordWrap; width: parent.width }
                    }
                }
            }
        }
    }
}
