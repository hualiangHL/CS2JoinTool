import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic


Rectangle {
    id: root
    anchors.fill: parent
    color: 'transparent'

    property var selectedMap: null
    property bool showDetail: false
    property bool detailVisible: false
    property string previewSrc: ''
    property string previewMap: ''



    function diffColor(d) {
        switch (d) {
        case '简单': case 'Easy': return '#43A047';
        case '普通': case 'Normal': return '#F9A825';
        case '困难': case 'Hard': return '#EF5350';
        case '极难': case 'Extreme': return '#C62828';
        case '史诗': case 'Epic': return '#AB47BC';
        case '梦魇': case 'Nightmare': return '#6A1B9A';
        case '绝境': case 'Deadly': return '#E040FB';
        }
        return '#BDBDBD';
    }


    function fmtCooldown(s) {
        if (!Lang.isEn()) return s;
        return String(s).replace('小时','h').replace('分钟','min').replace('天','d').replace('无','None');
    }


    function diffText(d) {
        const m = {
            '简单': 'Easy', '普通': 'Normal', '困难': 'Hard', '极难': 'Extreme',
            '史诗': 'Epic', '梦魇': 'Nightmare', '绝境': 'Deadly'
        };
        if (Lang.isEn()) return m[d] || d;
        return d;
    }


    function loadPreview(mapName) {
        const m = String(mapName).split('.')[0].trim().toLowerCase();
        previewMap = m
        if (m.indexOf('ze_') === 0) {
            previewSrc = MapImagesDir + '/' + m + '.jpg'
            return
        }
        previewSrc = ''
        WorkshopPreviewManager.requestPreview(mapName)
        const cached = WorkshopPreviewManager.cachedUrl(mapName)
        if (cached !== 'loading' && cached !== '') {
            previewSrc = cached
        }
    }

    Connections {
        target: WorkshopPreviewManager
        function onPreviewReady(mapName, url) {
            const k1 = String(mapName).split('.')[0].trim().toLowerCase()
            if (k1 === previewMap && k1.indexOf('ze_') !== 0)
                previewSrc = url
        }
    }

    Component.onCompleted: {
        console.log('COOLDOWN_REFRESH_CALL')
        CooldownManager.refresh()
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10


        RowLayout {
            width: parent.width
            spacing: 10

            HusText {
                text: Lang.tr('EXG 冷却时间','EXG Cooldown')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            HusText {
                text: Lang.tr('数据来源：darkrp.cn API · 仅供参考','Source: darkrp.cn API · for reference only')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }


            Item {
                Layout.fillWidth: true
                height: 1
            }

            HusText {
                Layout.alignment: Qt.AlignRight
                text: CooldownManager.error ? CooldownManager.error
                      : (CooldownManager.loading ? Lang.tr('加载中…','Loading...')
                         : Lang.tr('共 %1 张','%1 total').arg(CooldownManager.filteredMaps.length))
                color: CooldownManager.error ? '#C62828' : HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }
        }


        RowLayout {
            width: parent.width
            spacing: 8


            HusInput {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                height: 30
                iconSource: HusIcon.SearchOutlined
                iconPosition: HusInput.Position_Left
                placeholderText: Lang.tr('搜索地图名 / 成就…','Search map / achievement...')
                font.pixelSize: 12
                background: Rectangle {
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                    radius: 6
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
                    border.width: 1
                }
                onTextEdited: CooldownManager.searchText = text
            }


            Rectangle {
                height: 30
                width: 104
                radius: 6
                color: cm.containsMouse
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.18)
                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35)
                border.color: CooldownManager.onlyCooling
                              ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.7)
                              : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: cm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CooldownManager.onlyCooling = !CooldownManager.onlyCooling
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 3
                        color: CooldownManager.onlyCooling ? HusTheme.Primary.colorPrimary : 'transparent'
                        border.width: 2
                        border.color: CooldownManager.onlyCooling ? HusTheme.Primary.colorPrimary : '#A0A0A0'

                        HusText {
                            anchors.centerIn: parent
                            text: '✓'
                            color: '#FFFFFF'
                            font.pixelSize: 9
                            visible: CooldownManager.onlyCooling
                        }
                    }

                    HusText {
                        text: Lang.tr('冷却中','On cooldown')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }
                }
            }


            Rectangle {
                height: 30
                width: 84
                radius: 6
                color: rb.containsMouse || rb.pressed
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.35)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                border.width: 1
                opacity: CooldownManager.loading ? 0.5 : 1.0

                MouseArea {
                    id: rb
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !CooldownManager.loading
                    onClicked: CooldownManager.refresh()
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    HusIconText {
                        iconSource: HusIcon.ReloadOutlined
                        iconSize: 12
                        colorIcon: HusTheme.Primary.colorTextBase
                    }

                    HusText {
                        text: CooldownManager.loading ? Lang.tr('刷新中…','Refreshing...') : Lang.tr('刷新','Refresh')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }
                }
            }
        }


        Rectangle {
            width: parent.width
            height: parent.height - 92
            radius: 10
            color: 'transparent'
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
            border.width: 1

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                spacing: 4
                model: CooldownManager.filteredMaps
                ScrollBar.vertical: HusScrollBar {}

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 54
                    radius: 8
                    color: hovered ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.10)
                                   : (index % 2 === 0
                                      ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.25)
                                      : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.12))
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    property bool hovered: false
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onDoubleClicked: root.openDetail(modelData)
                    }


                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: Math.min(parent.width * 0.5, 360)

                        HusText {
                            width: parent.width
                            text: Lang.isEn() ? modelData.enName : modelData.displayName
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                    }


                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 480
                        anchors.verticalCenter: parent.verticalCenter
                        width: 62
                        height: 22
                        radius: 4
                        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)

                        HusText {
                            anchors.centerIn: parent
                            text: String(modelData.difficulty || '').length > 0 ? root.diffText(String(modelData.difficulty)) : '--'
                            color: root.diffColor(String(modelData.difficulty || ''))
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }


                    HusText {
                        anchors.left: parent.left
                        anchors.leftMargin: 640
                        anchors.right: rightCol.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: Lang.tr('成就: %1','Achievement: %1').arg(modelData.achievement)
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }


                    Column {
                        id: rightCol
                        anchors.right: statusText.left
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        width: 120

                        HusText {
                            width: parent.width
                            text: root.fmtCooldown(modelData.cooldown)
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }

                        HusText {
                            width: parent.width
                            text: modelData.cooldownEnd === '无' ? Lang.tr('随时可玩','Playable anytime')
                                  : Lang.tr('截止 %1','Until %1').arg(root.fmtCooldown(modelData.cooldownEnd))
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }


                    HusText {
                        id: statusText
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.isCooling ? Lang.tr('冷却中','On cooldown') : Lang.tr('可以预定','Bookable')
                        color: modelData.isCooling ? '#C62828' : '#2E7D32'
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }


                Rectangle {
                    anchors.fill: parent
                    color: 'transparent'
                    visible: CooldownManager.filteredMaps.length === 0 && !CooldownManager.loading
                    z: 10

                    Column {
                        anchors.centerIn: parent
                        spacing: 6

                        HusText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: CooldownManager.error ? Lang.tr('加载失败','Failed to load') : Lang.tr('暂无数据','No Data')
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 14
                        }

                        HusText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: CooldownManager.error ? CooldownManager.error : Lang.tr('点击右上角刷新按钮加载数据','Click the refresh button in the top-right to load data.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }


    Rectangle {
        anchors.fill: parent
        color: showDetail ? '#90000000' : '#00000000'
        visible: detailVisible
        Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
        z: 100

        MouseArea { anchors.fill: parent; onClicked: root.closeDetail() }

        Rectangle {
            width: 520
            height: 340
            radius: 12
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.92)
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
            border.width: 1
            anchors.centerIn: parent
            opacity: showDetail ? 1.0 : 0.0
            scale: showDetail ? 1.0 : 0.9
            Behavior on opacity { NumberAnimation { duration: showDetail ? 260 : 200; easing.type: showDetail ? Easing.OutCubic : Easing.InCubic } }
            Behavior on scale { NumberAnimation { duration: showDetail ? 280 : 200; easing.type: showDetail ? Easing.OutBack : Easing.InCubic } }


            Rectangle {
                width: 26
                height: 26
                radius: 13
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                color: closeM.containsMouse ? '#40ff6b6b' : 'transparent'
                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: closeM
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.closeDetail()
                }

                HusText {
                    anchors.centerIn: parent
                    text: '✕'
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 13
                }
            }


            Rectangle {
                id: pvBox
                width: 280
                height: 190
                radius: 8
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.top: parent.top
                anchors.topMargin: 18
                color: HusThemeFunctions.alpha('#000000', 0.3)
                clip: true

                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(480, 270)
                    source: root.previewSrc
                    onStatusChanged: {
                        if (status === Image.Ready) phText.visible = false
                        else if (status === Image.Error) phText.visible = true
                    }
                }

                HusText {
                    id: phText
                    anchors.centerIn: parent
                    text: Lang.tr('暂无预览图','No preview')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 11
                }
            }


            Column {
                anchors.left: pvBox.right
                anchors.leftMargin: 16
                anchors.top: pvBox.top
                anchors.right: parent.right
                anchors.rightMargin: 14
                spacing: 8

                HusText {
                    width: parent.width

                    text: root.selectedMap
                          ? (Lang.isEn() ? root.selectedMap.enName
                                         : (String(root.selectedMap.cnName || '').length > 0 ? root.selectedMap.cnName : root.selectedMap.enName))
                          : ''
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                HusText {
                    width: parent.width
                    visible: !Lang.isEn()
                    text: root.selectedMap ? root.selectedMap.enName : ''
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 11
                    font.family: 'Consolas'
                    elide: Text.ElideRight
                }

                Rectangle { width: parent.width; height: 1; color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4) }

                Row {
                    spacing: 8
                    width: parent.width
                    HusText { text: Lang.tr('成就:','Achievement:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; width: 48 }
                    HusText { text: root.selectedMap ? root.selectedMap.achievement : ''; color: HusTheme.Primary.colorTextBase; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width - 56 }
                }

                Row {
                    spacing: 8
                    width: parent.width
                    HusText { text: Lang.tr('难度:','Difficulty:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; width: 48 }
                    HusText { text: root.selectedMap ? (String(root.selectedMap.difficulty || '').length > 0 ? root.diffText(String(root.selectedMap.difficulty)) : '--') : ''; color: root.diffColor(String(root.selectedMap ? root.selectedMap.difficulty || '' : '')); font.pixelSize: 12; font.weight: Font.DemiBold }
                }

                Row {
                    spacing: 8
                    width: parent.width
                    HusText { text: Lang.tr('冷却:','Cooldown:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; width: 48 }
                    HusText { text: root.selectedMap ? root.fmtCooldown(root.selectedMap.cooldown) : ''; color: HusTheme.Primary.colorTextBase; font.pixelSize: 12; font.weight: Font.DemiBold }
                }

                Row {
                    spacing: 8
                    width: parent.width
                    HusText { text: Lang.tr('截止:','Until:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; width: 48 }
                    HusText { text: root.selectedMap ? (root.selectedMap.cooldownEnd === '无' ? Lang.tr('随时可玩','Playable anytime') : root.fmtCooldown(root.selectedMap.cooldownEnd)) : ''; color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12 }
                }

                Row {
                    spacing: 8
                    width: parent.width
                    HusText { text: Lang.tr('状态:','Status:'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize: 12; width: 48 }
                    HusText { text: root.selectedMap ? (root.selectedMap.isCooling ? Lang.tr('冷却中','On cooldown') : Lang.tr('可以预定','Bookable')) : ''; color: root.selectedMap && root.selectedMap.isCooling ? '#C62828' : '#2E7D32'; font.pixelSize: 12; font.weight: Font.DemiBold }
                }
            }


            HusText {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lang.tr('点击空白处或 ✕ 关闭','Click empty area or ✕ to close')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 10
            }
        }
    }


    function openDetail(mapData) {
        selectedMap = mapData
        previewSrc = ''
        previewMap = ''
        detailVisible = true
        showDetail = true
        if (mapData && mapData.enName)
            loadPreview(mapData.enName)
    }

    function closeDetail() {
        showDetail = false
        hideDetailTimer.restart()
    }

    Timer {
        id: hideDetailTimer
        interval: 240
        onTriggered: detailVisible = false
    }
}
