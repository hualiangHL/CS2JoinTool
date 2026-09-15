import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "qrc:/qml" as App

Rectangle {
    id: subscriptionPage
    property bool pageActive: false
    property bool showCard1: false

    onPageActiveChanged: { if (!pageActive) showCard1 = false }

    Timer { interval: 200; repeat: false; running: pageActive; onTriggered: showCard1 = true }

    color: "transparent"

    property var selectedIndexes: []
    property var selectedCommunities: ["全部社区"]
    property bool commDropdownOpen: false

    function isSelected(idx) { return selectedIndexes.indexOf(idx) >= 0 }
    function toggleSelect(idx) {
        var arr = selectedIndexes.slice()
        var i = arr.indexOf(idx)
        if (i >= 0) arr.splice(i, 1)
        else arr.push(idx)
        selectedIndexes = arr
    }
    function selectAll() {
        var arr = []
        for (var i = 0; i < subscriptionManager.subscribedMaps.length; i++) arr.push(i)
        selectedIndexes = arr
    }
    function clearSelection() { selectedIndexes = [] }
    function deleteSelected() {
        
        var sorted = selectedIndexes.slice().sort(function(a,b){return b-a})
        for (var i = 0; i < sorted.length; i++) {
            subscriptionManager.removeSubscription(sorted[i])
        }
        selectedIndexes = []
    }
    function doAddSubscription(mapName) {
        if (!mapName) return
        
        if (selectedCommunities.length === 0 || (selectedCommunities.length === 1 && selectedCommunities[0] === "全部社区")) {
            subscriptionManager.addSubscription(mapName, "")
            return
        }
        
        for (var i = 0; i < selectedCommunities.length; i++) {
            subscriptionManager.addSubscription(mapName, selectedCommunities[i])
        }
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        
        Text {
            Layout.fillWidth: true
            text: "地图订阅"
            font.family: App.Theme.fontFamily
            color: App.Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: "订阅的地图出现在任意服务器时 通过右下角悬浮窗窗口通知提醒你\n全部社区：所有社区都会提醒通知\n指定社区：仅该社区提醒通知"
            color: "#D0D0D0"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            lineHeight: 1.5
        }

        
        RowLayout {
                id: staggerChild0
                
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8

            
            Rectangle {
                id: commDropBtn
                Layout.preferredWidth: 130
                Layout.preferredHeight: 36
                radius: 8
                color: commDropMouse.containsMouse ? "#d0252040" : "#FF1E1B2E"
                border.width: 1; border.color: commDropdownOpen ? App.Theme.primary : "#FF2D3245"
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: commDropText
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: commArrow.left
                    anchors.rightMargin: 4
                    text: {
                        if (selectedCommunities.length === 0 || (selectedCommunities.length === 1 && selectedCommunities[0] === "全部社区")) return "全部社区"
                        if (selectedCommunities.length === 1) return selectedCommunities[0]
                        return "已选" + selectedCommunities.length + "个"
                    }
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Canvas {
                    id: commArrow
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12; height: 12
                    rotation: commDropdownOpen ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.strokeStyle = App.Theme.textSecondary
                        ctx.lineWidth = 2; ctx.lineCap = "round"; ctx.lineJoin = "round"
                        ctx.beginPath(); ctx.moveTo(3,2); ctx.lineTo(9,6); ctx.lineTo(3,10); ctx.stroke()
                    }
                }

                MouseArea {
                    id: commDropMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: commDropdownOpen = !commDropdownOpen
                }
            }

            TextField {
                id: mapInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: "输入地图名，如 ze_diddle"
                placeholderTextColor: "#609BA1B5"
                color: "#FFFFFF"
                selectionColor: "#40A78BFA"
                font.pixelSize: 12
                background: Rectangle { color: "#601E1B2E"; radius: 8; border.width: 1; border.color: "#FF2D3245" }
                onAccepted: {
                    if (text.trim()) {
                        doAddSubscription(text.trim())
                        text = ""
                    }
                }
                onTextChanged: searchTimer.restart()
                onFocusChanged: if (!focus) acPopup.closeAnimated()

                Timer {
                    id: searchTimer
                    interval: 120
                    repeat: false
                    onTriggered: {
                        var kw = mapInput.text.trim()
                        if (kw.length >= 1) {
                            var all = subscriptionManager.allMapNames
                            var kwLower = kw.toLowerCase()
                            var matched = []
                            for (var i = 0; i < all.length && matched.length < 50; i++) {
                                var name = all[i]
                                var trans = subscriptionManager.translateMap(name)
                                if (name.toLowerCase().indexOf(kwLower) >= 0 ||
                                    (trans && trans.indexOf(kw) >= 0)) {
                                    var diff = cooldownManager.getMapDifficulty(name)
                                    matched.push({name: name, trans: trans, diff: diff})
                                }
                            }
                            acPopup.showResults(matched)
                        } else {
                            acPopup.closeAnimated()
                        }
                    }
                }
            }

            
            Rectangle {
                id: addBtn
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                radius: 8
                color: addMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                border.width: 1; border.color: addMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: "添加"; color: "#FFFFFF"; font.pixelSize: 13 }
                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mapInput.text.trim()) {
                            doAddSubscription(mapInput.text.trim())
                            mapInput.text = ""
                        }
                    }
                }
            }

            
            Rectangle {
                Layout.preferredWidth: 100
                Layout.preferredHeight: 36
                radius: 8
                color: {
                    if (appController.toastCooldownRemaining > 0) return "#70383848"
                    return testMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                }
                border.width: 1
                border.color: {
                    if (appController.toastCooldownRemaining > 0) return "#40707080"
                    return testMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: appController.toastCooldownRemaining > 0 ? "冷却中 " + appController.toastCooldownRemaining + "s" : "通知测试"
                    color: appController.toastCooldownRemaining > 0 ? "#8090A0" : "#FFFFFF"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: testMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: appController.toastCooldownRemaining <= 0 && !appController.toastShowing
                    onClicked: subscriptionManager.testNotification()
                }
            }

            
            Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 36
                radius: 8
                color: {
                    if (selectedIndexes.length > 0) return delMouse.containsMouse ? "#d0353545" : "#b0252535"
                    return delMouse.containsMouse ? "#d0252040" : "#b01E1B2E"
                }
                border.width: 1
                border.color: {
                    if (selectedIndexes.length > 0) return delMouse.containsMouse ? "#e74c3c" : "#80353545"
                    return delMouse.containsMouse ? App.Theme.primary : "#FF2D3245"
                }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: selectedIndexes.length > 0 ? ("删除(" + selectedIndexes.length + ")") : "删除选中"
                    color: selectedIndexes.length > 0 ? "#ff8888" : "#FFFFFF"
                    font.pixelSize: 13
                }
                MouseArea {
                    id: delMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: if (selectedIndexes.length > 0) deleteSelected()
                }
            }
        }
        
        Row {
            Layout.fillWidth: true
            spacing: 8
            visible: subscriptionManager.subscribedMaps.length > 0

            Rectangle {
                width: 18; height: 18; radius: 4
                color: selectedIndexes.length === subscriptionManager.subscribedMaps.length && subscriptionManager.subscribedMaps.length > 0 ? App.Theme.primary : "transparent"
                border.width: 2
                border.color: selectedIndexes.length === subscriptionManager.subscribedMaps.length && subscriptionManager.subscribedMaps.length > 0 ? App.Theme.primary : App.Theme.textSecondary
                Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 12; visible: selectedIndexes.length === subscriptionManager.subscribedMaps.length && subscriptionManager.subscribedMaps.length > 0 }
                MouseArea { anchors.fill: parent; onClicked: { if (selectedIndexes.length === subscriptionManager.subscribedMaps.length) clearSelection(); else selectAll() } }
            }
            Text {
                text: selectedIndexes.length === subscriptionManager.subscribedMaps.length && subscriptionManager.subscribedMaps.length > 0 ? "取消全选" : "全选"
                color: App.Theme.textSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "已选 " + selectedIndexes.length + " / " + subscriptionManager.subscribedMaps.length
                color: App.Theme.textSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 20
            }
        }

        
        Rectangle {
                id: staggerChild1
                opacity: showCard1 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#20121525"
            radius: 10
            border.width: 1; border.color: "#20A78BFA"
            clip: true

            Flickable {
                id: subFlick
                anchors.fill: parent
                anchors.margins: 6
                contentHeight: subColumn.height + 8
                clip: true
                boundsBehavior: Flickable.DragOverBounds
                pressDelay: 8

                Column {
                    id: subColumn
                    width: parent.width
                    spacing: 5
                    topPadding: 4

                    Repeater {
                        model: subscriptionManager.subscribedMaps

                        MouseArea {
                            width: subColumn.width - 4
                            height: 40
                            onClicked: toggleSelect(index)

                            property string rawEntry: modelData
                            property string comm: {
                                var colonIdx = rawEntry.indexOf(":")
                                if (colonIdx <= 0) return "全部"
                                var prefix = rawEntry.substring(0, colonIdx).toLowerCase()
                                var valid = ["exg pve","exg","zed","ub","fys","upkk","zero","国际"]
                                return valid.indexOf(prefix) >= 0 ? rawEntry.substring(0, colonIdx) : "全部"
                            }
                            property string mapKw: {
                                var colonIdx = rawEntry.indexOf(":")
                                if (colonIdx <= 0) return rawEntry
                                var prefix = rawEntry.substring(0, colonIdx).toLowerCase()
                                var valid = ["exg pve","exg","zed","ub","fys","upkk","zero","国际"]
                                return valid.indexOf(prefix) >= 0 ? rawEntry.substring(colonIdx + 1) : rawEntry
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: isSelected(index) ? "#30A78BFA" : "#301E1B2E"
                                border.width: 1
                                border.color: isSelected(index) ? "#60A78BFA" : "#15A78BFA"
                                Behavior on color { ColorAnimation { duration: 120 } }

                                
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20; height: 20; radius: 5
                                    color: isSelected(index) ? App.Theme.primary : "transparent"
                                    border.width: 2
                                    border.color: isSelected(index) ? App.Theme.primary : App.Theme.textSecondary
                                    Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 12; font.bold: true; visible: isSelected(index) }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (parent.parent.comm === "全部" ? "全部社区" : parent.parent.comm) + "  ·  " + parent.parent.mapKw
                                    color: "#FFFFFF"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width - 50
                                }
                            }
                        }
                    }

                    
                    Text {
                        visible: subscriptionManager.subscribedMaps.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "暂无订阅，添加一个地图开始监控"
                        color: App.Theme.textSecondary
                        font.pixelSize: 13
                        topPadding: 30
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOn
                contentItem: Rectangle {
                    implicitWidth: 5
                    radius: 2.5
                    color: "#40A78BFA"
                }
            }
        }
    }
    
    MouseArea {
        id: acDismissArea
        anchors.fill: parent
        z: 98
        visible: acPopup.acOpen
        onClicked: {
            acPopup.closeAnimated()
            
            var pt = addBtn.mapToItem(subscriptionPage, 0, 0)
            if (mouse.x >= pt.x && mouse.x <= pt.x + addBtn.width &&
                mouse.y >= pt.y && mouse.y <= pt.y + addBtn.height) {
                if (mapInput.text.trim()) {
                    doAddSubscription(mapInput.text.trim())
                    mapInput.text = ""
                }
            }
        }
    }

    
    Rectangle {
        id: acPopup
        property var acResults: []
        property real acTargetHeight: 0
        property bool acOpen: false
        z: 99
        visible: acOpen || acAnim.running
        width: mapInput.width
        height: 0
        radius: 8
        color: "#f01E1B2E"
        border.width: 1; border.color: "#30A78BFA"
        clip: true

        Flickable {
            id: acFlick
            anchors.fill: parent
            anchors.margins: 4
            contentWidth: acCol.width
            contentHeight: acCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: acCol
                width: acFlick.width
                spacing: 1
                Repeater {
                    model: acPopup.acResults
                    delegate: Rectangle {
                        width: acCol.width
                        height: 32
                        radius: 5
                        color: acItemMouse.containsMouse ? "#25A78BFA" : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: modelData.name
                                color: "#FFFFFF"; font.pixelSize: 12
                                elide: Text.ElideRight; width: acCol.width - 80
                            }
                            Text {
                                text: modelData.trans ? modelData.trans : ""
                                color: "#FF9BA1B5"; font.pixelSize: 10
                                elide: Text.ElideRight; width: acCol.width - 80
                                visible: modelData.trans && modelData.trans.length > 0
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.diff ? (appController.difficultyTierMode ? appController.difficultyToTier(modelData.diff) : modelData.diff) : ""
                            color: "#FFA78BFA"; font.pixelSize: 11; font.bold: true
                            visible: modelData.diff && modelData.diff.length > 0
                        }
                        MouseArea {
                            id: acItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                mapInput.text = modelData.name
                                mapInput.focus = true
                                acPopup.closeAnimated()
                            }
                        }
                    }
                }
            }
        }

        
        Rectangle {
            id: acScrollbar
            anchors.right: parent.right; anchors.rightMargin: 1
            width: 3; radius: 1.5
            color: "#40A78BFA"
            visible: acFlick.contentHeight > acFlick.height + 1
            height: Math.min(acFlick.height - 8, Math.max(20, (acFlick.height - 8) * (acFlick.height - 8) / Math.max(1, acFlick.contentHeight)))
            y: {
                if (acFlick.contentHeight <= acFlick.height) return 4;
                var scrollRange = acFlick.contentHeight - acFlick.height;
                var thumbRange = (acFlick.height - 8) - acScrollbar.height;
                return 4 + (acFlick.contentY / scrollRange) * thumbRange;
            }
        }

        NumberAnimation {
            id: acAnim
            target: acPopup; property: "height"
            duration: 180; easing.type: Easing.OutCubic
        }

        function showResults(list) {
            acResults = list
            
            var pt = mapInput.mapToItem(subscriptionPage, 0, mapInput.height + 2)
            acPopup.x = pt.x
            acPopup.y = pt.y
            acTargetHeight = Math.min(list.length * 33 + 8, 360)
            if (list.length > 0) {
                acOpen = true
                acFlick.contentY = 0
                acAnim.from = acPopup.height; acAnim.to = acTargetHeight
                acAnim.start()
            } else {
                closeAnimated()
            }
        }
        function closeAnimated() {
            acOpen = false
            acAnim.from = acPopup.height; acAnim.to = 0
            acAnim.duration = 140; acAnim.easing.type = Easing.InCubic
            acAnim.start()
            acAnim.duration = 180; acAnim.easing.type = Easing.OutCubic
        }
    }

    
    MouseArea {
        anchors.fill: parent
        z: 998
        visible: commDropdownOpen
        onClicked: commDropdownOpen = false
    }

    
    Rectangle {
        id: commDropdown
        z: 999
        width: commDropBtn.width
        height: 294
        radius: 8
        color: "#f01E1B2E"
        border.width: 1; border.color: "#30A78BFA"
        clip: true
        visible: opacity > 0.01
        opacity: commDropdownOpen ? 1.0 : 0.0
        scale: commDropdownOpen ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        x: {
            var pt = commDropBtn.mapToItem(subscriptionPage, 0, 0)
            return pt.x
        }
        y: {
            var pt = commDropBtn.mapToItem(subscriptionPage, 0, commDropBtn.height + 4)
            return pt.y
        }

        Column {
            id: commCol
            x: 4; y: 4
            width: parent.width - 8
            spacing: 2

            Repeater {
                model: ["全部社区", "EXG", "EXG PVE", "ZED", "UB", "FYS", "UPKK", "Zero", "国际"]
                delegate: Rectangle {
                    width: commCol.width
                    height: 30
                    radius: 6
                    color: commItemMouse.containsMouse ? "#20A78BFA" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 4
                        color: selectedCommunities.indexOf(modelData) >= 0 ? App.Theme.primary : "transparent"
                        border.width: 2
                        border.color: selectedCommunities.indexOf(modelData) >= 0 ? App.Theme.primary : App.Theme.textSecondary
                        Text { anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 10; visible: selectedCommunities.indexOf(modelData) >= 0 }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: selectedCommunities.indexOf(modelData) >= 0 ? App.Theme.primary : "#FFFFFF"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: commItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            var name = modelData
                            var arr = selectedCommunities.slice()
                            var idx = arr.indexOf(name)
                            if (name === "全部社区") {
                                selectedCommunities = ["全部社区"]
                            } else {
                                var allIdx = arr.indexOf("全部社区")
                                if (allIdx >= 0) arr.splice(allIdx, 1)
                                if (idx >= 0) arr.splice(idx, 1)
                                else arr.push(name)
                                if (arr.length === 0) arr = ["全部社区"]
                                selectedCommunities = arr
                            }
                        }
                    }
                }
            }
        }
    }
}
