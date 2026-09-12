import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "qrc:/qml" as App

Rectangle {
    id: cooldownPage
    property bool pageActive: false
    property bool showCard1: false
    property bool showCard2: false
    property bool hasRefreshed: false
    color: "transparent"

    onPageActiveChanged: {
        if (!pageActive) { showCard1 = false; showCard2 = false }
        else if (!hasRefreshed) { hasRefreshed = true; cooldownManager.refresh() }
    }
    Timer { interval: 180; repeat: false; running: pageActive; onTriggered: showCard1 = true }
    Timer { interval: 360; repeat: false; running: pageActive; onTriggered: showCard2 = true }

    property var selectedMap: null
    property bool showMapDetail: false
    property bool panelVisible: false
    property string workshopPreviewUrl: ""
    property string currentPreviewMap: ""

    function openMapDetail(mapData) {
        selectedMap = mapData
        panelVisible = true
        showMapDetail = true
        if (mapData && mapData.enName) loadWorkshopMapPreview(mapData.enName)
    }

    // 从Steam创意工坊获取地图预览图
    function loadWorkshopMapPreview(mapName) {
        workshopPreviewUrl = ""
        currentPreviewMap = mapName
        if (!mapName) return
        var wsid = workshopManager.findWorkshopId(mapName)
        if (wsid) { fetchPreviewById(wsid, mapName); return }
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "https://steamcommunity.com/workshop/browse/?appid=730&searchtext=" + encodeURIComponent(mapName) + "&browsesort=textmatch&actualsearch=1", true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return
                try {
                    var m = xhr.responseText.match(/filedetails\/\?id=(\d+)/)
                    if (m && m[1]) fetchPreviewById(m[1], mapName)
                } catch(e) {}
            }
        }
        xhr.send()
    }

    function fetchPreviewById(wsid, mapName) {
        var xhr = new XMLHttpRequest()
        xhr.open("POST", "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/", true)
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (currentPreviewMap !== mapName) return
                try {
                    var data = JSON.parse(xhr.responseText)
                    if (data.response && data.response.publishedfiledetails && data.response.publishedfiledetails.length > 0) {
                        var url = data.response.publishedfiledetails[0].preview_url
                        if (url && url.length > 0) workshopPreviewUrl = url
                    }
                } catch(e) {}
            }
        }
        xhr.send("itemcount=1&publishedfileids[0]=" + wsid)
    }

    function closeMapDetail() {
        showMapDetail = false
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 280
        onTriggered: panelVisible = false
    }

    Component.onCompleted: {}

    Column {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // 标题
        Text {
            text: "ExG冷却时间"
            font.family: App.Theme.fontFamily
            color: App.Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }

        Text {
            text: "数据来源：darkrp.cn API · 仅供参考"
            color: "#D0D0D0"
            font.pixelSize: 12
        }

        // 工具栏（跟服务器列表同款：36px高，单层控件）
        RowLayout {
            id: staggerChild1
            opacity: showCard1 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: mainCol.width
            spacing: 8

            // 搜索框
            TextField {
                Layout.fillWidth: true
                implicitHeight: 36
                placeholderText: "搜索地图名/成就..."
                text: cooldownManager.searchText
                onTextChanged: cooldownManager.searchText = text
                background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 2; border.color: "#A78BFA" }
                font.pixelSize: 13; color: "#FFFFFF"; selectionColor: "#40A78BFA"; selectedTextColor: "#FFFFFF"
                leftPadding: 10; rightPadding: 10; topPadding: 0; bottomPadding: 0
                placeholderTextColor: "#607080"
            }

            // 只显示冷却中
            Rectangle {
                Layout.preferredWidth: 110
                implicitHeight: 36
                radius: 8
                color: coolMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 2; border.color: coolMouse.containsMouse ? App.Theme.primary : "#A78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }

                MouseArea { id: coolMouse; anchors.fill: parent; hoverEnabled: true; onClicked: cooldownManager.onlyCooling = !cooldownManager.onlyCooling }

                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    Rectangle {
                        width: 16; height: 16; radius: 4
                        color: cooldownManager.onlyCooling ? App.Theme.primary : "transparent"
                        border.width: 2; border.color: cooldownManager.onlyCooling ? App.Theme.primary : "#A0A0A0"
                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 12; visible: cooldownManager.onlyCooling }
                    }
                    Text { text: "冷却中"; color: "#FFFFFF"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
            }

            // 数量
            Text {
                Layout.preferredWidth: 100
                text: cooldownManager.error ? cooldownManager.error : (cooldownManager.loading ? "加载中..." : "共 " + cooldownManager.filteredMaps.length + " 张")
                color: cooldownManager.error ? "#ff6b6b" : "#D0D0D0"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            // 刷新按钮
            Rectangle {
                Layout.preferredWidth: 96
                implicitHeight: 36
                radius: 8
                color: refreshMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 2; border.color: refreshMouse.containsMouse ? App.Theme.primary : "#A78BFA"
                Behavior on color { ColorAnimation { duration: 150 } }
                opacity: cooldownManager.loading ? 0.5 : 1.0

                MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; enabled: !cooldownManager.loading; onClicked: cooldownManager.refresh() }

                Text {
                    anchors.centerIn: parent
                    text: cooldownManager.loading ? "刷新中..." : "刷新"
                    color: "#FFFFFF"
                    font.pixelSize: 13
                }
            }
        }

        // 地图列表
        Item {
            id: staggerChild2
            opacity: showCard2 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: mainCol.width
            height: mainCol.height - y - 10

            ListView {
                id: listView
                anchors.fill: parent
                anchors.rightMargin: 10
                model: cooldownManager.filteredMaps
                cacheBuffer: 800
                clip: true
                spacing: 3
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: "#60A78BFA"
                    }
                    background: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: "#201E1B2E"
                    }
                }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 56
                    radius: 8
                    color: index % 2 === 0 ? "#281E1B2E" : "#141E1B2E"
                    border.width: 1; border.color: "#182D3245"

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: 400

                        Text {
                            text: modelData.displayName
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: "成就: " + modelData.achievement
                            color: "#C8C0E0"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 425
                        anchors.verticalCenter: parent.verticalCenter
                        width: 56; height: 22
                        radius: 4
                        color: "#40A78BFA"
                        Text {
                            anchors.centerIn: parent
                            text: appController.difficultyTierMode ? appController.difficultyToTier(modelData.difficulty) : modelData.difficulty
                            color: "#FFFFFF"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.right: statusText.left
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: 110

                        Text {
                            text: modelData.cooldown
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                        Text {
                            text: modelData.cooldownEnd === "无" ? "随时可玩" : "截止 " + modelData.cooldownEnd
                            color: "#C8C0E0"
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            width: parent.width
                        }
                    }

                    Text {
                        id: statusText
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.isCooling ? "冷却中" : "可以预定"
                        color: modelData.isCooling ? "#ff6b6b" : "#4ADE80"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: cooldownPage.openMapDetail(modelData)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: cooldownManager.filteredMaps.length === 0 && !cooldownManager.loading
                    z: 10

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cooldownManager.error ? "加载失败" : "暂无数据"
                            color: "#FFFFFF"
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: cooldownManager.error ? cooldownManager.error : "点击右上角刷新按钮加载数据"
                            color: "#D0D0D0"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }

    // ===== 地图详情面板 =====
    Rectangle {
        id: detailMask
        anchors.fill: parent
        color: showMapDetail ? "#90000000" : "#00000000"
        visible: cooldownPage.panelVisible
        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
        z: 100

        MouseArea { anchors.fill: parent; onClicked: cooldownPage.closeMapDetail() }

        Rectangle {
            id: detailPanel
            width: 560
            height: 380
            radius: 12
            color: "#FF1E1B2E"
            border.width: 1; border.color: "#40A78BFA"
            anchors.centerIn: parent
            opacity: showMapDetail ? 1.0 : 0.0
            scale: showMapDetail ? 1.0 : 0.90
            Behavior on opacity { NumberAnimation { duration: showMapDetail ? 300 : 220; easing.type: showMapDetail ? Easing.OutCubic : Easing.InCubic } }
            Behavior on scale { NumberAnimation { duration: showMapDetail ? 320 : 220; easing.type: showMapDetail ? Easing.OutBack : Easing.InCubic } }

            // 关闭按钮
            Rectangle {
                id: closeBtn
                width: 28; height: 28; radius: 14
                anchors.top: parent.top; anchors.topMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                color: closeMouse.containsMouse ? "#40ff6b6b" : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: cooldownPage.closeMapDetail() }
                Text { anchors.centerIn: parent; text: "✕"; color: "#FFFFFF"; font.pixelSize: 14 }
            }

            // 地图预览图（左侧）
            Rectangle {
                id: previewContainer
                width: 280; height: 200
                radius: 8
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                color: "#0D1117"
                clip: true

                Image {
                    id: mapPreview
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    source: showMapDetail ? workshopPreviewUrl : ""
                    onStatusChanged: {
                        if (status === Image.Ready) mapPlaceholder.visible = false
                        else if (status === Image.Error) mapPlaceholder.visible = true
                    }
                }
                Rectangle {
                    id: mapPlaceholder
                    anchors.fill: parent
                    color: "#0D1117"
                    visible: true
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "暂无预览图"; color: "#FF6B7288"; font.pixelSize: 12 }
                    }
                }
            }

            // 详细信息（右侧）
            Column {
                anchors.left: previewContainer.right; anchors.leftMargin: 16
                anchors.top: previewContainer.top
                anchors.right: closeBtn.left; anchors.rightMargin: 12
                spacing: 10

                // 地图中文名
                Text {
                    text: cooldownPage.selectedMap ? cooldownPage.selectedMap.cnName : ""
                    color: "#FFFFFF"; font.pixelSize: 18; font.bold: true
                    elide: Text.ElideRight; width: parent.width
                }
                // 地图英文名
                Text {
                    text: cooldownPage.selectedMap ? cooldownPage.selectedMap.enName : ""
                    color: "#9BA1B5"; font.pixelSize: 12
                    elide: Text.ElideRight; width: parent.width; font.family: "Consolas"
                }

                // 分隔线
                Rectangle { width: parent.width; height: 1; color: "#20A78BFA" }

                // 成就
                Row { spacing: 8; width: parent.width
                    Text { text: "成就:"; color: "#9BA1B5"; font.pixelSize: 13; width: 50 }
                    Text { text: cooldownPage.selectedMap ? cooldownPage.selectedMap.achievement : ""; color: "#FFFFFF"; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width - 58 }
                }
                // 难度
                Row { spacing: 8; width: parent.width
                    Text { text: "难度:"; color: "#9BA1B5"; font.pixelSize: 13; width: 50 }
                    Rectangle {
                        width: 56; height: 22; radius: 4; color: "#40A78BFA"
                        Text { anchors.centerIn: parent; text: cooldownPage.selectedMap ? (appController.difficultyTierMode ? appController.difficultyToTier(cooldownPage.selectedMap.difficulty) : cooldownPage.selectedMap.difficulty) : ""; color: "#FFFFFF"; font.pixelSize: 11; font.bold: true }
                    }
                }
                // 冷却时长
                Row { spacing: 8; width: parent.width
                    Text { text: "冷却:"; color: "#9BA1B5"; font.pixelSize: 13; width: 50 }
                    Text { text: cooldownPage.selectedMap ? cooldownPage.selectedMap.cooldown : ""; color: "#FFFFFF"; font.pixelSize: 13; font.bold: true }
                }
                // 冷却截止
                Row { spacing: 8; width: parent.width
                    Text { text: "截止:"; color: "#9BA1B5"; font.pixelSize: 13; width: 50 }
                    Text { text: cooldownPage.selectedMap ? (cooldownPage.selectedMap.cooldownEnd === "无" ? "随时可玩" : cooldownPage.selectedMap.cooldownEnd) : ""; color: "#C8C0E0"; font.pixelSize: 12 }
                }
                // 状态
                Row { spacing: 8; width: parent.width
                    Text { text: "状态:"; color: "#9BA1B5"; font.pixelSize: 13; width: 50 }
                    Text {
                        text: cooldownPage.selectedMap ? (cooldownPage.selectedMap.isCooling ? "冷却中" : "可以预定") : ""
                        color: cooldownPage.selectedMap && cooldownPage.selectedMap.isCooling ? "#ff6b6b" : "#4ADE80"
                        font.pixelSize: 13; font.bold: true
                    }
                }
            }

            // 底部提示
            Text {
                anchors.bottom: parent.bottom; anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                text: "点击空白处或 ✕ 关闭"
                color: "#607080"; font.pixelSize: 11
            }
        }
    }
}
