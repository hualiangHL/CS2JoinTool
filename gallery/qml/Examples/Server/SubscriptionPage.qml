import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic


Rectangle {
    id: subscriptionPage
    anchors.fill: parent
    color: 'transparent'

    property var selectedIndexes: []
    property var selectedCommunities: [Lang.tr('全部社区','All Communities')]
    property bool commDropdownOpen: false

    MapTranslator {
        id: mapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }


    function commKey(name) {
        switch (name) {
        case Lang.tr('EXG社区','EXG Community'): return 'exg';
        case Lang.tr('僵尸乐园','Zombie Eden'): return 'zed';
        case Lang.tr('UB社区','UB Community'): return 'ub';
        case Lang.tr('风云社','FYS'): return 'fys';
        case 'UPKK/Zero': return 'upkk';
        case Lang.tr('星社区','Star Community'): return 'star';
        case Lang.tr('国际服','International'): return 'international';
        case Lang.tr('跑图服','Map Run'): return 'maprun';
        }
        return '';
    }
    function commLabel(key) {
        switch (key) {
        case 'exg': return Lang.tr('EXG社区','EXG Community');
        case 'zed': return Lang.tr('僵尸乐园','Zombie Eden');
        case 'ub': return Lang.tr('UB社区','UB Community');
        case 'fys': return Lang.tr('风云社','FYS');
        case 'upkk': return 'UPKK/Zero';
        case 'star': return Lang.tr('星社区','Star Community');
        case 'international': return Lang.tr('国际服','International');
        case 'maprun': return Lang.tr('跑图服','Map Run');
        }
        return Lang.tr('全部社区','All Communities');
    }

    function entryComm(raw) {
        var colonIdx = raw.indexOf(':')
        if (colonIdx <= 0) return ''
        var prefix = raw.substring(0, colonIdx).toLowerCase()
        var valid = ['exg','zed','ub','fys','upkk','star','international','maprun']
        return valid.indexOf(prefix) >= 0 ? prefix : ''
    }
    function entryMap(raw) {
        var colonIdx = raw.indexOf(':')
        if (colonIdx <= 0) return raw
        var prefix = raw.substring(0, colonIdx).toLowerCase()
        var valid = ['exg','zed','ub','fys','upkk','star','international','maprun']
        return valid.indexOf(prefix) >= 0 ? raw.substring(colonIdx + 1) : raw
    }

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
        for (var i = 0; i < SubscriptionManagerObj.subscribedMaps.length; i++) arr.push(i)
        selectedIndexes = arr
    }
    function clearSelection() { selectedIndexes = [] }
    function deleteSelected() {
        var sorted = selectedIndexes.slice().sort(function(a, b) { return b - a })
        for (var i = 0; i < sorted.length; i++) {
            SubscriptionManagerObj.removeSubscription(sorted[i])
        }
        selectedIndexes = []
    }
    function doAddSubscription(mapName) {
        if (!mapName) return
        if (selectedCommunities.length === 0 || (selectedCommunities.length === 1 && selectedCommunities[0] === Lang.tr('全部社区','All Communities'))) {
            SubscriptionManagerObj.addSubscription(mapName, '')
            return
        }
        for (var i = 0; i < selectedCommunities.length; i++) {
            SubscriptionManagerObj.addSubscription(mapName, commKey(selectedCommunities[i]))
        }
    }

    function openCommDropdown() {
        var pt = commDropBtn.mapToItem(subscriptionPage, 0, commDropBtn.height + 4)
        commDropdown.x = pt.x
        commDropdown.y = pt.y
        commDropdownOpen = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12


        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            HusText {
                text: Lang.tr('地图订阅','Map Subscriptions')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true; height: 1 }
        }

        HusText {
            Layout.fillWidth: true
            text: Lang.tr('订阅的地图出现在任意服务器时，通过右下角悬浮窗通知提醒你','When a subscribed map appears on any server, a bottom-right toast notifies you.')
            color: HusTheme.Primary.colorTextSecondary
            font.pixelSize: 11
        }

        HusText {
            Layout.fillWidth: true
            text: Lang.tr('全部社区：所有社区都会提醒通知　　指定社区：仅该社区提醒通知','All communities: get notified for every community. Selected: only the ones you pick.')
            color: HusTheme.Primary.colorTextSecondary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            spacing: 8


            Rectangle {
                id: commDropBtn
                Layout.preferredWidth: 130
                Layout.preferredHeight: 36
                radius: 8
                color: commDropMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: commDropdownOpen ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: commDropText
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: commArrow.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (selectedCommunities.length === 0 || (selectedCommunities.length === 1 && selectedCommunities[0] === Lang.tr('全部社区','All Communities'))) return Lang.tr('全部社区','All Communities')
                        if (selectedCommunities.length === 1) return selectedCommunities[0]
                        if (Lang.isEn()) return Lang.tr('已选','Selected') + ' ' + selectedCommunities.length
                        return Lang.tr('已选','Selected') + selectedCommunities.length + '个'
                    }
                    color: HusTheme.Primary.colorTextBase
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
                        var ctx = getContext('2d'); ctx.reset()
                        ctx.strokeStyle = HusTheme.Primary.colorTextSecondary
                        ctx.lineWidth = 2; ctx.lineCap = 'round'; ctx.lineJoin = 'round'
                        ctx.beginPath(); ctx.moveTo(3, 2); ctx.lineTo(9, 6); ctx.lineTo(3, 10); ctx.stroke()
                    }
                }

                MouseArea {
                    id: commDropMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (commDropdownOpen) commDropdownOpen = false
                        else openCommDropdown()
                    }
                }
            }


            TextField {
                id: mapInput
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                placeholderText: Lang.tr('输入地图名，如 ze_diddle','Enter map name, e.g. ze_diddle')
                placeholderTextColor: HusTheme.Primary.colorTextSecondary
                color: HusTheme.Primary.colorTextBase
                selectionColor: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.25)
                font.pixelSize: 12
                background: Rectangle {
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                    radius: 8
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                }
                onAccepted: {
                    if (text.trim()) {
                        doAddSubscription(text.trim())
                        text = ''
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
                            var all = SubscriptionManagerObj.allMapNames
                            var kwLower = kw.toLowerCase()
                            var matched = []
                            for (var i = 0; i < all.length && matched.length < 50; i++) {
                                var name = all[i]
                                var trans = mapTrans.formatMap(name)
                                var transOnly = ''
                                var idx = trans.indexOf('\u300c')
                                if (idx > 0) transOnly = trans.substring(idx + 1, trans.length - 1)
                                if (name.toLowerCase().indexOf(kwLower) >= 0 || (transOnly && transOnly.indexOf(kw) >= 0)) {
                                    matched.push({name: name, trans: transOnly, diff: mapTrans.difficulty(name)})
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
                Layout.preferredWidth: addText.implicitWidth + 32
                Layout.preferredHeight: 36
                radius: 8
                color: addMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: addMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    id: addText
                    anchors.centerIn: parent
                    text: Lang.tr('添加','Add')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 13
                }
                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mapInput.text.trim()) {
                            doAddSubscription(mapInput.text.trim())
                            mapInput.text = ''
                        }
                    }
                }
            }


            Rectangle {
                Layout.preferredWidth: testText.implicitWidth + 32
                Layout.preferredHeight: 36
                radius: 8
                color: testMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: testMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    id: testText
                    anchors.centerIn: parent
                    text: Lang.tr('通知测试','Test Notification')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 13
                }
                MouseArea {
                    id: testMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: SubscriptionManagerObj.testNotification()
                }
            }


            Rectangle {
                Layout.preferredWidth: delText.implicitWidth + 32
                Layout.preferredHeight: 36
                radius: 8
                color: {
                    if (selectedIndexes.length > 0) return delMouse.containsMouse ? '#F5E8EB' : '#E8F2F5'
                    return delMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                }
                border.width: 1
                border.color: {
                    if (selectedIndexes.length > 0) return delMouse.containsMouse ? '#e74c3c' : '#C8E74C3C'
                    return delMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                }
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    id: delText
                    anchors.centerIn: parent
                    text: selectedIndexes.length > 0 ? (Lang.tr('删除(','Delete(') + selectedIndexes.length + ')') : Lang.tr('删除选中','Delete Selected')
                    color: selectedIndexes.length > 0 ? '#ff8888' : HusTheme.Primary.colorTextBase
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
            visible: SubscriptionManagerObj.subscribedMaps.length > 0
            Rectangle {
                width: 18; height: 18; radius: 4
                color: selectedIndexes.length === SubscriptionManagerObj.subscribedMaps.length && SubscriptionManagerObj.subscribedMaps.length > 0 ? HusTheme.Primary.colorPrimary : 'transparent'
                border.width: 2
                border.color: selectedIndexes.length === SubscriptionManagerObj.subscribedMaps.length && SubscriptionManagerObj.subscribedMaps.length > 0 ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                Text {
                    anchors.centerIn: parent
                    text: '\u2713'; color: 'white'; font.pixelSize: 12
                    visible: selectedIndexes.length === SubscriptionManagerObj.subscribedMaps.length && SubscriptionManagerObj.subscribedMaps.length > 0
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (selectedIndexes.length === SubscriptionManagerObj.subscribedMaps.length) clearSelection()
                        else selectAll()
                    }
                }
            }
            Text {
                text: selectedIndexes.length === SubscriptionManagerObj.subscribedMaps.length && SubscriptionManagerObj.subscribedMaps.length > 0 ? Lang.tr('取消全选','Deselect All') : Lang.tr('全选','Select All')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: Lang.tr('已选 ','Selected ') + selectedIndexes.length + ' / ' + SubscriptionManagerObj.subscribedMaps.length
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 20
            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
            radius: 10
            border.width: 1
            border.color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.125)
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
                        model: SubscriptionManagerObj.subscribedMaps

                        MouseArea {
                            width: subColumn.width - 4
                            height: 40
                            onClicked: toggleSelect(index)

                            property string rawEntry: modelData

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: subscriptionPage.isSelected(index) ? Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                border.width: 1
                                border.color: subscriptionPage.isSelected(index) ? Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.375) : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.082)
                                Behavior on color { ColorAnimation { duration: 120 } }


                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 20; height: 20; radius: 5
                                    color: subscriptionPage.isSelected(index) ? HusTheme.Primary.colorPrimary : 'transparent'
                                    border.width: 2
                                    border.color: subscriptionPage.isSelected(index) ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                                    Text {
                                        anchors.centerIn: parent
                                        text: '\u2713'; color: 'white'; font.pixelSize: 12; font.bold: true
                                        visible: subscriptionPage.isSelected(index)
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 40
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (entryComm(parent.parent.rawEntry) === '' ? Lang.tr('全部社区','All Communities') : commLabel(entryComm(parent.parent.rawEntry))) + '  \u00b7  ' + entryMap(parent.parent.rawEntry)
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }


                    Text {
                        visible: SubscriptionManagerObj.subscribedMaps.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: Lang.tr('暂无订阅，添加一个地图开始监控','No subscriptions; add a map to start monitoring.')
                        color: HusTheme.Primary.colorTextSecondary
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
                    color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.25)
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
                    mapInput.text = ''
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
        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.85)
        border.width: 1
        border.color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
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
                        color: acItemMouse.containsMouse ? Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.145) : 'transparent'
                        Behavior on color { ColorAnimation { duration: 80 } }
                        Column {
                            anchors.left: parent.left; anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: modelData.name
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: acCol.width - 80
                            }
                            Text {
                                text: modelData.trans ? modelData.trans : ''
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: acCol.width - 80
                                visible: modelData.trans && modelData.trans.length > 0
                            }
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.diff ? modelData.diff : ''
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 11
                            font.bold: true
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
            color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.25)
            visible: acFlick.contentHeight > acFlick.height + 1
            height: Math.min(acFlick.height - 8, Math.max(20, (acFlick.height - 8) * (acFlick.height - 8) / Math.max(1, acFlick.contentHeight)))
            y: {
                if (acFlick.contentHeight <= acFlick.height) return 4
                var scrollRange = acFlick.contentHeight - acFlick.height
                var thumbRange = (acFlick.height - 8) - acScrollbar.height
                return 4 + (acFlick.contentY / scrollRange) * thumbRange
            }
        }

        NumberAnimation {
            id: acAnim
            target: acPopup; property: 'height'
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
        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.85)
        border.width: 1
        border.color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
        clip: true
        visible: opacity > 0.01
        opacity: commDropdownOpen ? 1.0 : 0.0
        scale: commDropdownOpen ? 1.0 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
        x: 0
        y: 0

        Column {
            id: commCol
            x: 4; y: 4
            width: parent.width - 8
            spacing: 2

            Repeater {
                model: [Lang.tr('全部社区','All Communities'), Lang.tr('EXG社区','EXG Community'), Lang.tr('僵尸乐园','Zombie Eden'), Lang.tr('UB社区','UB Community'), Lang.tr('风云社','FYS'), 'UPKK/Zero', Lang.tr('星社区','Star Community'), Lang.tr('国际服','International'), Lang.tr('跑图服','Map Run')]
                delegate: Rectangle {
                    width: commCol.width
                    height: 30
                    radius: 6
                    color: commItemMouse.containsMouse ? Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.125) : 'transparent'
                    Behavior on color { ColorAnimation { duration: 100 } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 4
                        color: selectedCommunities.indexOf(modelData) >= 0 ? HusTheme.Primary.colorPrimary : 'transparent'
                        border.width: 2
                        border.color: selectedCommunities.indexOf(modelData) >= 0 ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextSecondary
                        Text {
                            anchors.centerIn: parent
                            text: '\u2713'; color: 'white'; font.pixelSize: 10
                            visible: selectedCommunities.indexOf(modelData) >= 0
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 30
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: selectedCommunities.indexOf(modelData) >= 0 ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
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
                            if (name === Lang.tr('全部社区','All Communities')) {
                                selectedCommunities = [Lang.tr('全部社区','All Communities')]
                            } else {
                                var allIdx = arr.indexOf(Lang.tr('全部社区','All Communities'))
                                if (allIdx >= 0) arr.splice(allIdx, 1)
                                if (idx >= 0) arr.splice(idx, 1)
                                else arr.push(name)
                                if (arr.length === 0) arr = [Lang.tr('全部社区','All Communities')]
                                selectedCommunities = arr
                            }
                        }
                    }
                }
            }
        }
    }
}
