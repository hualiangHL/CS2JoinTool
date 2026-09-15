import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "qrc:/qml" as App

Item {
    id: homePage
    width: parent.width
    height: parent.height
    property bool pageActive: false

    ParallelAnimation {
        id: staggerAnim
        SequentialAnimation {
            PauseAnimation { duration: 200 }
            NumberAnimation { target: pageTitle; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 450 }
            NumberAnimation { target: staggerChild1; property: "opacity"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 700 }
            NumberAnimation { target: staggerChild2; property: "opacity"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 950 }
            NumberAnimation { target: staggerChild3; property: "opacity"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1200 }
            NumberAnimation { target: staggerChild4; property: "opacity"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
    }

    onPageActiveChanged: {
        if (pageActive) {
            pageTitle.opacity = 0
            staggerChild1.opacity = 0
            staggerChild2.opacity = 0
            staggerChild3.opacity = 0
            staggerChild4.opacity = 0
            staggerAnim.restart()
            
            appController.connectProtocol = appController.defaultConnectProtocol
            
            appController.activeJoinCoreCount = appController.joinCoreCount
            homeCoreSlider.value = appController.activeJoinCoreCount
        } else if (protoDropdownOpen) {
            protoDropdownOpen = false
            protoDropdownAnim.to = 0
            protoDropdownAnim.start()
        }
    }

    Component.onCompleted: {
        initStaggerTimer.start()
    }

    Timer {
        id: initStaggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            pageTitle.opacity = 0
            staggerChild1.opacity = 0
            staggerChild2.opacity = 0
            staggerChild3.opacity = 0
            staggerChild4.opacity = 0
            staggerAnim.restart()
            
            appController.activeJoinCoreCount = appController.joinCoreCount
        }
    }

    Text {
        id: pageTitle
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        text: "挤服主页"
        font.family: App.Theme.fontFamily
        font.pixelSize: 22
        font.bold: true
        color: App.Theme.textPrimary
    }

    ScrollView {
        anchors.top: pageTitle.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: mainColumn
            width: homePage.width - 32
            spacing: 16

            
                Rectangle {
                id: staggerChild1
                opacity: 0
                
                    Layout.fillWidth: true
                    Layout.preferredHeight: 250
                radius: 12
                color: "#b01E1B2E"
                border.width: 1
                border.color: "#FF2D3245"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text { text: "连接配置"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    TextField {
                        id: ipField
                        Layout.fillWidth: true
                        implicitHeight: 36
                        placeholderText: "服务器IP，如 101.32.201.121"
                        text: appController.serverIp
                        onTextChanged: appController.serverIp = text
                        font.pixelSize: 13
                        color: App.Theme.textPrimary
                        padding: 10
                        background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                        placeholderTextColor: App.Theme.textSecondary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        TextField {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "端口"
                            text: appController.serverPort
                            onTextChanged: appController.serverPort = parseInt(text) || 0
                            font.pixelSize: 13
                            color: App.Theme.textPrimary
                            padding: 10
                            background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                            placeholderTextColor: App.Theme.textSecondary
                        }
                        TextField {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "密码(可选)"
                            echoMode: TextInput.Password
                            text: appController.serverPassword
                            onTextChanged: appController.serverPassword = text
                            font.pixelSize: 13
                            color: App.Theme.textPrimary
                            padding: 10
                            background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                            placeholderTextColor: App.Theme.textSecondary
                        }
                    }

                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "连接协议:"; color: App.Theme.textSecondary; font.pixelSize: 12 }

                        Rectangle {
                            id: protoDropBtn
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: protoDropMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: protoDropMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            readonly property var items: ["steam://connect「服务器浏览器协议」", "steam://run/730//+connect「游戏启动协议」"]

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: protoDropBtn.items[appController.connectProtocol]
                                color: App.Theme.textPrimary
                                font.pixelSize: 12
                            }

                            Canvas {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                width: 10; height: 6
                                onPaint: {
                                    var ctx = getContext("2d"); ctx.reset()
                                    ctx.fillStyle = App.Theme.textSecondary
                                    ctx.beginPath()
                                    ctx.moveTo(0, 0); ctx.lineTo(10, 0); ctx.lineTo(5, 6)
                                    ctx.closePath(); ctx.fill()
                                }
                            }

                            MouseArea { id: protoDropMouse; anchors.fill: parent; hoverEnabled: true; onClicked: homePage.toggleProtoDropdown() }

                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            color: queryBtnMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                            border.width: 1; border.color: queryBtnMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            MouseArea { id: queryBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.queryServer() }
                            Text { anchors.centerIn: parent; text: "查询状态"; color: App.Theme.textPrimary; font.pixelSize: 13 }
                        }

                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            color: connectBtnMouse.containsMouse ? "#e0A78BFA" : "#c0A78BFA"
                            border.width: 1; border.color: connectBtnMouse.containsMouse ? "#ffffff" : App.Theme.primary
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            MouseArea { id: connectBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.joinNow() }
                            Text { anchors.centerIn: parent; text: "连接服务器"; color: "#0a0a14"; font.pixelSize: 13; font.bold: true }
                        }
                    }
                }
                }

                
                Rectangle {
                id: staggerChild2
                opacity: 0
                
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                radius: 12
                color: "#b01E1B2E"
                border.width: 1
                border.color: "#FF2D3245"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text { text: "服务器状态"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }

                    Row {
                        spacing: 8
                        Rectangle {
                            width: 10; height: 10; radius: 5
                            color: appController.serverStatus === 1 ? App.Theme.success : (appController.serverStatus === 2 ? App.Theme.error : App.Theme.warning)
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: appController.serverStatus === 1 ? "在线" : (appController.serverStatus === 2 ? "离线" : "查询中")
                            color: appController.serverStatus === 1 ? App.Theme.success : (appController.serverStatus === 2 ? App.Theme.error : App.Theme.warning)
                            font.pixelSize: 13; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 20
                        Text { text: "服务器:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: appController.currentServerName; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "地图:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: appController.currentMap; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        Text { text: "玩家:"; color: App.Theme.textSecondary; font.pixelSize: 12 }
                        Text { text: appController.currentPlayers + "/" + appController.maxPlayers; color: App.Theme.primary; font.pixelSize: 12; font.bold: true }
                    }
                }
                }

                
                Rectangle {
                id: staggerChild3
                opacity: 0
                
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                radius: 12
                color: "#b01E1B2E"
                border.width: 1
                border.color: "#FF2D3245"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "自动挤服"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                    }

                    Text {
                        text: "启用后自动查询服务器，检测到空位时自动连接。间隔: " + appController.interval.toFixed(2) + "ms"
                        color: App.Theme.textSecondary; font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    
                    Slider {
                        id: intervalSlider
                        Layout.fillWidth: true
                        from: appController.proMode ? 0.01 : 50
                        to: 500
                        value: appController.interval
                        onValueChanged: appController.interval = value
                        implicitHeight: 24
                        background: Rectangle {
                            x: 0; y: parent.height / 2 - height / 2
                            width: parent.width
                            height: 4; radius: 2
                            color: "#40252040"
                            Rectangle {
                                width: intervalSlider.visualPosition * (intervalSlider.width - 16) + 8
                                height: parent.height; radius: 2
                                color: App.Theme.primary
                            }
                        }
                        handle: Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "white"
                            border.width: 2; border.color: App.Theme.primary
                            x: intervalSlider.visualPosition * (intervalSlider.width - width)
                            y: intervalSlider.height / 2 - height / 2
                        }
                    }

                    
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "挤服核心数"; color: App.Theme.textPrimary; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Text { text: "[非必要情况不用改动 拉满对服务器压力极大]"; color: "#607080"; font.pixelSize: 11; Layout.alignment: Qt.AlignVCenter }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: appController.activeJoinCoreCount + " / " + appController.cpuCoreCount + " 核"
                            color: appController.activeJoinCoreCount >= 6 ? "#FFE74C3C" : (appController.activeJoinCoreCount === 5 ? "#FFF1C40F" : App.Theme.primary)
                            font.pixelSize: 13; font.bold: true
                        }
                    }

                    Slider {
                        id: homeCoreSlider
                        Layout.fillWidth: true
                        from: 1
                        to: appController.cpuCoreCount
                        stepSize: 1
                        value: appController.activeJoinCoreCount
                        onValueChanged: appController.activeJoinCoreCount = Math.round(value)
                        implicitHeight: 24
                        background: Rectangle {
                            x: 0; y: parent.height / 2 - height / 2
                            width: parent.width
                            height: 4; radius: 2
                            color: "#40252040"
                            Rectangle {
                                width: homeCoreSlider.visualPosition * (homeCoreSlider.width - 16) + 8
                                height: parent.height; radius: 2
                                color: App.Theme.primary
                            }
                        }
                        handle: Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "white"
                            border.width: 2; border.color: App.Theme.primary
                            x: homeCoreSlider.visualPosition * (homeCoreSlider.width - width)
                            y: homeCoreSlider.height / 2 - height / 2
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            color: appController.autoJoining
                                ? (autoBtnMouse.containsMouse ? "#e0e74c3c" : "#c0e74c3c")
                                : (autoBtnMouse.containsMouse ? "#e0A78BFA" : "#c0A78BFA")
                            border.width: 1
                            border.color: appController.autoJoining
                                ? (autoBtnMouse.containsMouse ? "#ffffff" : "#e74c3c")
                                : (autoBtnMouse.containsMouse ? "#ffffff" : App.Theme.primary)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            MouseArea { id: autoBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.autoJoining ? appController.stopAutoJoin() : appController.startAutoJoin() }
                            Text { anchors.centerIn: parent; text: appController.autoJoining ? "停止挤服" : "开始挤服"; color: "#0a0a14"; font.pixelSize: 13; font.bold: true }
                        }

                        Text { text: "重试: " + appController.retryCount; color: App.Theme.textSecondary; font.pixelSize: 12 }
                    }
                }
                }

                
                Rectangle {
                id: staggerChild4
                opacity: 0
                
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                radius: 12
                color: "#b01E1B2E"
                border.width: 1
                border.color: "#FF2D3245"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "运行日志"; font.bold: true; color: App.Theme.textPrimary; font.pixelSize: 15 }
                        Item { Layout.fillWidth: true }

                        
                        Rectangle {
                            implicitWidth: 64; implicitHeight: 28
                            radius: 6
                            color: clearBtnMouse.containsMouse ? "#d0252040" : "#a01E1B2E"
                            border.width: 1; border.color: clearBtnMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            MouseArea { id: clearBtnMouse; anchors.fill: parent; hoverEnabled: true; onClicked: appController.clearLog() }
                            Text { anchors.centerIn: parent; text: "清空"; color: App.Theme.textPrimary; font.pixelSize: 12 }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        TextArea {
                            text: appController.logText
                            readOnly: true
                            font.family: "Consolas"
                            font.pixelSize: 11
                            color: App.Theme.textSecondary
                            background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                            selectByMouse: true
                        }
                    }
                }
            }
        }
    }

    
    property bool protoDropdownOpen: false
    property real protoDropdownMask: 0

    function toggleProtoDropdown() {
        protoDropdownOpen = !protoDropdownOpen
        if (protoDropdownOpen) {
            var pos = protoDropBtn.mapToItem(homePage, 0, protoDropBtn.height - 2)
            protoDropdown.x = pos.x
            protoDropdown.y = pos.y
            protoDropdown.width = protoDropBtn.width
            protoDropdownMask = 0
            protoDropdownAnim.to = 76
            protoDropdownAnim.start()
        } else {
            protoDropdownAnim.to = 0
            protoDropdownAnim.start()
        }
    }

    
    MouseArea {
        anchors.fill: parent
        z: 98
        visible: protoDropdownOpen
        onClicked: if (protoDropdownOpen) homePage.toggleProtoDropdown()
    }

    Rectangle {
        id: protoDropdown
        visible: protoDropdownOpen || protoDropdownMask > 0.5
        z: 99
        height: 76
        radius: 8
        color: "#f01E1B2E"
        border.width: 1; border.color: "#FF2D3245"
        clip: true
        opacity: protoDropdownOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Item {
            width: parent.width
            height: protoDropdownMask
            clip: true

            Column {
                width: parent.width
                spacing: 2
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 6

                Repeater {
                    model: protoDropBtn.items

                    Rectangle {
                        width: parent.width
                        height: 30
                        radius: 6
                        color: index === appController.connectProtocol ? "#35A78BFA" : (protoItemMouse2.containsMouse ? "#28252040" : "transparent")
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData
                            color: index === appController.connectProtocol ? App.Theme.primary : App.Theme.textPrimary
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: protoItemMouse2
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                appController.connectProtocol = index
                                homePage.toggleProtoDropdown()
                            }
                        }
                    }
                }
            }
        }
    }

    NumberAnimation {
        id: protoDropdownAnim
        target: homePage
        property: "protoDropdownMask"
        duration: 200
        easing.type: Easing.OutCubic
    }
}
