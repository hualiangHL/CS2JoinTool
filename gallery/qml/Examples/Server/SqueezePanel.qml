import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery




Item {
    id: root
    visible: false
    z: 300

    property string targetIp: ''
    property int targetPort: 0
    property string targetName: ''
    property real panelBaseY: (root.height - 490) / 2
    property bool closing: false


    property string curMap: squeeze.mapName
    onCurMapChanged: {
        if (curMap === squeeze.mapName && previewBox)
            root.resetPreview()
    }


    function resetPreview() {
        if (!previewBox)
            return
        const raw = String(squeeze.mapName || '')
        if (!raw || raw.length === 0 || raw === 'undefined' || raw === 'null')
            return
        const m = previewBox.normMap(squeeze.mapName)

        previewBox.previewSrc = ''
        pvCanvas.imgReady = false
        if (previewBox.specialLocalMaps.indexOf(m) >= 0 || m.indexOf('ze_') === 0) {
            imgEl.stage = 'local'
            previewBox.previewSrc = previewBox.localImageSource(squeeze.mapName)
            pvCanvas.requestPaint()
            return
        }
        imgEl.stage = 'workshop'
        pvCanvas.requestPaint()
        WorkshopPreviewManager.requestPreview(squeeze.mapName)
        const cached = WorkshopPreviewManager.cachedUrl(squeeze.mapName)
        if (cached !== 'loading' && cached !== '') {
            previewBox.previewSrc = cached
        }
    }


    Component.onCompleted: {
        if (squeeze.mapName && squeeze.mapName.length > 0)
            root.resetPreview()
    }


    readonly property var squeeze: SqueezeEngineObj

    MapTranslator {
        id: mapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }

    function open(ip, port, name) {
        targetIp = ip;
        targetPort = port;
        targetName = name;
        squeeze.protocol = appSettings.squeezeProtocol;
        if (squeeze.running) {

            intervalSlider.intervalVal = squeeze.intervalMs;
        } else {

            squeeze.intervalMs = appSettings.defaultInterval;
            intervalSlider.intervalVal = appSettings.defaultInterval;
            squeeze.threshold = appSettings.defaultThreshold;
            squeeze.coreCount = appSettings.defaultCoreCount;
        }
        squeeze.probe(ip, port, name);
        closing = false;
        closeAnim.stop();
        visible = true;
        root.resetPreview();


        overlayRect.opacity = 0;
        panel.opacity = 0;
        panel.scale = 0.92;
        panel.y = panelBaseY + 8;
        openAnim.start();
    }


    function joinServer(ip, port, name) {
        targetIp = ip;
        targetPort = port;
        targetName = name;

        squeeze.protocol = appSettings.squeezeProtocol;

        squeeze.suppressConnectToast = true;
        squeeze.probe(ip, port, name);
        squeeze.joinNow();

        Qt.callLater(function() { squeeze.suppressConnectToast = false; });
    }

    function close() {
        if (!visible || closing)
            return;
        closing = true;
        openAnim.stop();

        if (!squeeze.running)
            squeeze.stop();

        closeAnim.start();
    }


    function forceHide() {
        openAnim.stop();
        closeAnim.stop();
        closing = false;
        visible = false;
        overlayRect.opacity = 0;
        panel.opacity = 0;
        panel.scale = 0.94;
        panel.y = root.panelBaseY + 8;
    }


    Rectangle {
        id: overlayRect
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }


    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: overlayRect
            property: 'opacity'
            from: 0
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: panel
            property: 'opacity'
            from: 0
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: panel
            property: 'scale'
            from: 0.92
            to: 1
            duration: 260
            easing.type: Easing.OutBack
        }
        NumberAnimation {
            target: panel
            property: 'y'
            from: root.panelBaseY + 8
            to: root.panelBaseY
            duration: 220
            easing.type: Easing.OutCubic
        }
    }


    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: overlayRect
            property: 'opacity'
            from: 1
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: panel
            property: 'opacity'
            from: 1
            to: 0
            duration: 180
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: panel
            property: 'scale'
            from: 1
            to: 0.94
            duration: 180
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: panel
            property: 'y'
            from: root.panelBaseY
            to: root.panelBaseY + 8
            duration: 180
            easing.type: Easing.InCubic
        }
        onFinished: {
            root.visible = false
            root.closing = false
        }
    }


    Rectangle {
        id: panel
        width: 720
        height: 490
        radius: 12
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.8)
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
        border.width: 1


        MouseArea {
            anchors.fill: parent
        }


        RowLayout {
            id: titleRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.rightMargin: 10
            anchors.topMargin: 14
            spacing: 8

            HusText {
                Layout.fillWidth: true
                text: Lang.tr('挤服 - %1','Squeeze - %1').arg(targetName)
                color: HusTheme.Primary.colorTextBase
                wrapMode: Text.Wrap
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }


            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                radius: 6
                color: 'transparent'

                HusIconText {
                    anchors.centerIn: parent
                    font.pixelSize: 14
                    color: HusTheme.Primary.colorTextSecondary
                    iconSource: HusIcon.CloseOutlined
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }


        Rectangle {
            id: titleSep
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleRow.bottom
            anchors.topMargin: 10
            height: 1
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
        }


        Column {
            id: previewCol
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 18
            anchors.leftMargin: 16
            width: 300
            spacing: 10


            Rectangle {
                id: previewBox
                width: parent.width
                height: 168
                radius: 12
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
                border.width: 1


                property var specialLocalMaps: ['rp_downtown', 'ze_obf_npst_v2_legacy', 'fys_lobby_liyue']


                function localImageSource(mapName) {
                    const m = String(mapName).split('.')[0].trim().toLowerCase();
                    return MapImagesDir + '/' + m + '.jpg';
                }


                function normMap(mapName) {
                    return String(mapName || '').split('.')[0].trim().toLowerCase();
                }


                property string previewSrc: ''

                Image {
                    id: imgEl
                    anchors.fill: parent
                    source: previewBox.previewSrc
                    asynchronous: true
                    sourceSize: Qt.size(480, 270)
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                    property string stage: 'local'
                    onStatusChanged: {
                        if (status === Image.Ready) {
                            pvCanvas.imgReady = true
                            pvCanvas.requestPaint()
                            repaintTimer.start()
                        } else if (status === Image.Error) {
                            if (stage === 'workshop' || stage === 'local') {

                                stage = 'fallback'
                                previewBox.previewSrc = MapImagesDir + '/no_map_image.jpg'
                            } else {
                                pvCanvas.imgReady = false
                                pvCanvas.requestPaint()
                            }
                        }
                    }
                }

                Connections {
                    target: WorkshopPreviewManager
                    function onPreviewReady(mapName, url) {
                        if (previewBox.normMap(mapName) === previewBox.normMap(squeeze.mapName) && imgEl.stage !== 'fallback') {
                            imgEl.stage = 'workshop'
                            previewBox.previewSrc = url
                        }
                    }
                    function onPreviewFailed(mapName) {
                        if (previewBox.normMap(mapName) === previewBox.normMap(squeeze.mapName) && imgEl.stage === 'workshop') {

                            imgEl.stage = 'fallback'
                            previewBox.previewSrc = MapImagesDir + '/no_map_image.jpg'
                        }
                    }
                }

                Timer {
                    id: repaintTimer
                    interval: 150
                    repeat: true
                    property int n: 0
                    onTriggered: {
                        pvCanvas.requestPaint()
                        n++
                        if (n >= 6)
                            stop()
                    }
                }

                Canvas {
                    id: pvCanvas
                    anchors.fill: parent
                    property bool imgReady: false
                    smooth: true
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        if (width <= 1 || height <= 1)
                            return
                        try {
                            const ctx = getContext('2d')
                            if (!ctx)
                                return
                            ctx.save()
                            ctx.clearRect(0, 0, width, height)
                            const r = 12
                            const w = width, h = height
                            ctx.beginPath()
                            ctx.moveTo(r, 0)
                            ctx.lineTo(w - r, 0)
                            ctx.quadraticCurveTo(w, 0, w, r)
                            ctx.lineTo(w, h - r)
                            ctx.quadraticCurveTo(w, h, w - r, h)
                            ctx.lineTo(r, h)
                            ctx.quadraticCurveTo(0, h, 0, h - r)
                            ctx.lineTo(0, r)
                            ctx.quadraticCurveTo(0, 0, r, 0)
                            ctx.closePath()
                            ctx.clip()
                            if (imgReady && imgEl.status === Image.Ready) {
                                ctx.drawImage(imgEl, 0, 0, w, h)
                            } else {
                                ctx.fillStyle = '#26263A'
                                ctx.fillRect(0, 0, w, h)
                            }
                            ctx.restore()
                        } catch (e) {}
                    }
                }


                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: 'transparent'
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                }


                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 62
                    radius: 12
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: HusThemeFunctions.alpha('#000000', 0.0) }
                        GradientStop { position: 1.0; color: HusThemeFunctions.alpha('#000000', 0.78) }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 10
                    anchors.bottomMargin: 8
                    spacing: 2

                    HusText {
                        width: parent.width
                        text: squeeze.mapName.length > 0 ? squeeze.mapName : '--'
                        color: '#FFFFFF'
                        font.pixelSize: 12
                        font.family: 'Consolas'
                        elide: Text.ElideRight
                    }

                    HusText {
                        width: parent.width
                        text: squeeze.mapName.length > 0 ? (Lang.isEn() ? squeeze.mapName : mapTrans.zhName(squeeze.mapName)) : ''
                        color: '#00B4D8'
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }


            Rectangle {
                id: infoCard
                width: parent.width
                height: 222
                radius: 10
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                border.width: 1
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: width
                    contentHeight: infoCol.height
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 3; }

                    Column {
                        id: infoCol
                        width: parent.width
                        spacing: 5


                        HusText {
                            text: Lang.tr('[挤服间隔]','[Squeeze Interval]')
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('用来控制你挤服务器的速度','Controls how fast squeeze requests are sent.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('默认为 100','Default: 100')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }

                        Item { width: 1; height: 4 }


                        HusText {
                            text: Lang.tr('[核心数量]','[Core Count]')
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('核心同一时刻发出的查询请求越多，核心越高连接指令发得最快，对服务器压力就越大','More cores fire more simultaneous queries: higher counts send joins faster, but put more load on the server.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('负面效果：核心越多 CPU 占用和网络包量越大，太高反而可能查询超时或拖慢系统','Drawbacks: higher CPU usage and network traffic; too high may cause timeouts or slow your PC.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('默认为 2 个，谨慎调整，一般不用调整','Default: 2. Adjust with care; usually leave as is.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }

                        Item { width: 1; height: 4 }


                        HusText {
                            text: Lang.tr('[人数阈值]','[Player Threshold]')
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('调整多少人的时候加入服务器','Join automatically once players reach this number.')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                        HusText {
                            width: parent.width
                            text: Lang.tr('默认为 63 人','Default: 63 players')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }


        ColumnLayout {
            id: rightCol
            anchors.top: titleSep.bottom
            anchors.left: previewCol.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: 12
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 14
            spacing: 8


            Column {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    width: parent.width
                    spacing: 10
                    HusText {
                        Layout.preferredWidth: 56
                        text: Lang.tr('服务器','Server')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                    }
                    HusText {
                        Layout.fillWidth: true
                        text: targetName.length > 0 ? targetName : '--'
                        color: HusTheme.Primary.colorTextBase
                        elide: Text.ElideRight
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10
                    HusText {
                        Layout.preferredWidth: 56
                        text: Lang.tr('IP 地址','IP Address')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                    }
                    HusText {
                        Layout.fillWidth: true
                        text: (targetIp.length > 0 ? targetIp + ' : ' + targetPort : '--')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 13
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 10
                    HusText {
                        Layout.preferredWidth: 56
                        text: Lang.tr('状态','Status')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                    }
                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5
                        anchors.verticalCenter: parent.verticalCenter
                        color: !squeeze.running
                               ? HusTheme.Primary.colorTextDisabled
                               : (squeeze.statusText.indexOf(Lang.tr('空位','Free Slot'), Qt.CaseInsensitive) >= 0
                                  ? '#4CAF50'
                                  : (squeeze.statusText.indexOf(Lang.tr('等待','Waiting'), Qt.CaseInsensitive) >= 0 ? '#FF9800' : '#2196F3'))
                    }
                    HusText {
                        Layout.fillWidth: true
                        text: squeeze.running ? squeeze.statusText
                              : (squeeze.statusText.length > 0
                                 ? squeeze.statusText
                                 : Lang.tr('未开始，点击下方按钮开始挤服','Not started yet. Click the button below to begin.'))
                        color: HusTheme.Primary.colorTextBase
                        elide: Text.ElideRight
                        font.pixelSize: 12
                    }
                    HusText {
                        text: Lang.tr('重试 %1 次','Retries: %1').arg(squeeze.retryCount)
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 11
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: 8
                color: squeeze.running
                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.12)
                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.85)
                border.color: squeeze.running
                              ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.28)
                              : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
                border.width: 1
                Behavior on color { ColorAnimation { duration: 200 } }


                MouseArea {
                    anchors.fill: parent
                    enabled: squeeze.running
                }

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 12
                    spacing: 12


                    RowLayout {
                        width: parent.width
                        spacing: 10

                        HusText {
                            id: intervalLabel
                            Layout.preferredWidth: intervalLabel.implicitWidth
                            text: Lang.tr('挤服间隔','Squeeze Interval')
                            color: squeeze.running ? HusTheme.Primary.colorTextDisabled : HusTheme.Primary.colorTextBase
                            font.pixelSize: 12
                        }

                        Item {
                            id: intervalSlider
                            Layout.fillWidth: true
                            height: 22


                            property real minV: appSettings.intervalLimitEnabled ? 0.01 : 50
                            property real maxV: 500
                            property real stepV: appSettings.intervalLimitEnabled ? 0.01 : 10

                            property real intervalVal: 50

                            property color lockColor: squeeze.running ? HusTheme.Primary.colorTextDisabled : HusTheme.Primary.colorPrimary

                            Component.onCompleted: intervalVal = squeeze.intervalMs

                            function posToValue(x) {
                                const r = Math.max(0, Math.min(1, x / width));
                                const raw = minV + r * (maxV - minV);
                                const stepped = Math.round(raw / stepV) * stepV;
                                intervalVal = Math.min(maxV, Math.max(minV, stepped));
                                squeeze.intervalMs = Math.round(intervalVal);
                                return intervalVal;
                            }

                            function setValue(x) {
                                posToValue(x);
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !squeeze.running
                                onPressed: intervalSlider.setValue(mouse.x)
                                onPositionChanged: {
                                    if (pressed)
                                        intervalSlider.setValue(mouse.x);
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: squeeze.running
                                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.4)
                                       : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
                            }

                            Rectangle {
                                id: ivFill
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: 2
                                color: intervalSlider.lockColor
                                width: Math.max(0, ivHandle.x + ivHandle.width / 2)
                            }

                            Rectangle {
                                id: ivHandle
                                y: (parent.height - 14) / 2
                                width: 14
                                height: 14
                                radius: 7
                                color: '#FFFFFF'
                                border.color: intervalSlider.lockColor
                                border.width: 2
                                x: (intervalSlider.intervalVal - intervalSlider.minV) / (intervalSlider.maxV - intervalSlider.minV) * (parent.width - width)
                            }
                        }

                        HusText {
                            id: intervalValText
                            Layout.preferredWidth: Math.max(64, intervalValText.implicitWidth)
                            horizontalAlignment: Text.AlignRight
                            text: qsTr('%1 ms').arg(intervalSlider.intervalVal.toFixed(appSettings.intervalLimitEnabled ? 2 : 0))
                            color: intervalSlider.lockColor
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }


                RowLayout {
                    width: parent.width
                    spacing: 10

                    HusText {
                        id: coreLabel
                        Layout.preferredWidth: coreLabel.implicitWidth
                        text: Lang.tr('核心数量','Core Count')
                        color: squeeze.running ? HusTheme.Primary.colorTextDisabled : HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                    }

                    Item {
                        id: coreSlider
                        Layout.fillWidth: true
                        height: 22

                        property real minV: 1
                        property real maxV: squeeze.maxCores
                        property real stepV: 1

                        property color coreColor: squeeze.running
                                                  ? HusTheme.Primary.colorTextDisabled
                                                  : (squeeze.coreCount >= 6 ? '#E5484D' : (squeeze.coreCount >= 5 ? '#F5B400' : (squeeze.coreCount >= 4 ? '#2EB872' : HusTheme.Primary.colorPrimary)))

                        function posToValue(x) {
                            const r = Math.max(0, Math.min(1, x / width));
                            const raw = minV + r * (maxV - minV);
                            return Math.round(raw / stepV) * stepV;
                        }

                        function setValue(x) {
                            squeeze.coreCount = posToValue(x);
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !squeeze.running
                            onPressed: coreSlider.setValue(mouse.x)
                            onPositionChanged: {
                                if (pressed)
                                    coreSlider.setValue(mouse.x);
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: squeeze.running
                                   ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.4)
                                   : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
                        }

                        Rectangle {
                            id: coreFill
                            anchors.verticalCenter: parent.verticalCenter
                            height: 4
                            radius: 2
                            color: coreSlider.coreColor
                            width: Math.max(0, coreHandle.x + coreHandle.width / 2)
                        }

                        Rectangle {
                            id: coreHandle
                            y: (parent.height - 14) / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: '#FFFFFF'
                            border.color: coreSlider.coreColor
                            border.width: 2
                            x: (squeeze.coreCount - coreSlider.minV) / (coreSlider.maxV - coreSlider.minV) * (parent.width - width)
                        }
                    }

                    HusText {
                        id: coreValText
                        Layout.preferredWidth: Math.max(64, coreValText.implicitWidth)
                        horizontalAlignment: Text.AlignRight
                        text: Lang.tr('%1 核','%1 cores').arg(squeeze.coreCount)
                        color: coreSlider.coreColor
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }


                    RowLayout {
                        width: parent.width
                        spacing: 10

                        HusText {
                            id: thLabel
                            Layout.preferredWidth: thLabel.implicitWidth
                            text: Lang.tr('人数阈值','Player Threshold')
                            color: squeeze.running ? HusTheme.Primary.colorTextDisabled : HusTheme.Primary.colorTextBase
                            font.pixelSize: 12
                        }

                        Item {
                            id: thresholdSlider
                            Layout.fillWidth: true
                            height: 22

                            property real minV: 20
                            property real maxV: 63
                            property real stepV: 1

                            property color lockColor: squeeze.running ? HusTheme.Primary.colorTextDisabled : HusTheme.Primary.colorPrimary

                            function posToValue(x) {
                                const r = Math.max(0, Math.min(1, x / width));
                                const raw = minV + r * (maxV - minV);
                                return Math.round(raw / stepV) * stepV;
                            }

                            function setValue(x) {
                                squeeze.threshold = posToValue(x);
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !squeeze.running
                                onPressed: thresholdSlider.setValue(mouse.x)
                                onPositionChanged: {
                                    if (pressed)
                                        thresholdSlider.setValue(mouse.x);
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 4
                                radius: 2
                                color: squeeze.running
                                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorTextDisabled, 0.4)
                                       : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
                            }

                            Rectangle {
                                id: thFill
                                anchors.verticalCenter: parent.verticalCenter
                                height: 4
                                radius: 2
                                color: thresholdSlider.lockColor
                                width: Math.max(0, thHandle.x + thHandle.width / 2)
                            }

                            Rectangle {
                                id: thHandle
                                y: (parent.height - 14) / 2
                                width: 14
                                height: 14
                                radius: 7
                                color: '#FFFFFF'
                                border.color: thresholdSlider.lockColor
                                border.width: 2
                                x: (squeeze.threshold - thresholdSlider.minV) / (thresholdSlider.maxV - thresholdSlider.minV) * (parent.width - width)
                            }
                        }

                        HusText {
                            id: thValText
                            Layout.preferredWidth: Math.max(64, thValText.implicitWidth)
                            horizontalAlignment: Text.AlignRight
                            text: Lang.tr('%1 人','%1 players').arg(squeeze.threshold)
                            color: thresholdSlider.lockColor
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                }
            }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.85)
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
                border.width: 1

                HusText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 10
                    anchors.topMargin: 8
                    text: Lang.tr('日志','Log')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 11
                }

                Flickable {
                    id: logFlick
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 26
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.bottomMargin: 8
                    clip: true
                    contentHeight: logText.height

                    Text {
                        id: logText
                        width: logFlick.width
                        text: squeeze.logText
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 11
                        font.family: 'Consolas'
                        wrapMode: Text.WrapAnywhere
                    }

                    onContentHeightChanged: {
                        if (contentHeight > height)
                            contentY = contentHeight - height;
                    }
                }
            }


            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: joinBtn
                    Layout.fillWidth: true
                    height: 34
                    radius: 6
                    color: joinMa.containsMouse
                           ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16)
                           : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.7)
                    border.color: joinMa.containsMouse
                                  ? HusTheme.Primary.colorPrimary
                                  : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    scale: joinMa.containsMouse ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }


                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: '#22FFFFFF'
                        opacity: joinMa.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    HusText {
                        anchors.centerIn: parent
                        text: Lang.tr('立即连接','Connect Now')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: joinMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {

                            squeeze.suppressConnectToast = true
                            squeeze.joinNow()

                            Qt.callLater(function() { squeeze.suppressConnectToast = false; })

                            serverMessage.success(Lang.tr('正在加入服务器...','Joining server...'), 3000)
                        }
                    }
                }

                Rectangle {
                    id: startBtn
                    Layout.fillWidth: true
                    height: 34
                    radius: 6
                    color: squeeze.running
                           ? (startMa.containsMouse
                              ? HusThemeFunctions.alpha(HusTheme.Primary.colorError, 0.5)
                              : HusThemeFunctions.alpha(HusTheme.Primary.colorError, 0.3))
                           : HusTheme.Primary.colorPrimary
                    border.color: squeeze.running
                                  ? HusThemeFunctions.alpha(HusTheme.Primary.colorError, 0.6)
                                  : 'transparent'
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }
                    scale: startMa.containsMouse ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }


                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: '#22FFFFFF'
                        opacity: startMa.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    HusText {
                        anchors.centerIn: parent
                        text: squeeze.running ? Lang.tr('停止挤服','Stop Squeeze') : Lang.tr('开始挤服','Start Squeeze')
                        color: '#FFFFFF'
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: startMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (squeeze.running)
                                squeeze.stop();
                            else
                                squeeze.start(root.targetIp, root.targetPort, root.targetName);
                        }
                    }
                }
            }
        }
    }
}
