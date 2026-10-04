import QtQuick
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery


Item {
    id: cardRoot
    required property var srv
    required property var groupName

    property var onOpenSqueeze: function(ip, name) {}
    property var onContextMenu: function(ip, name, mapText, online, x, y) {}
    property var onJoin: function(ip, name) {}

    MapTranslator {
        id: mapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }


    property var specialLocalMaps: ['rp_downtown', 'ze_obf_npst_v2_legacy', 'fys_lobby_liyue']


    function localImageSource(mapName) {
        const m = String(mapName).split('.')[0].trim().toLowerCase();
        return MapImagesDir + '/' + m + '.jpg';
    }


    function normMap(mapName) {
        return String(mapName || '').split('.')[0].trim().toLowerCase();
    }


    property string previewSrc: ''
    property string curMap: srv.map



    function startPreview() {
        const raw = String(srv.map || '')
        if (!raw || raw.length === 0 || raw === 'undefined' || raw === 'null')
            return
        const m = normMap(srv.map)

        cardRoot.previewSrc = ''
        if (specialLocalMaps.indexOf(m) >= 0 || m.indexOf('ze_') === 0) {
            imgEl.stage = 'local'
            mapCanvas.imgReady = false
            cardRoot.previewSrc = cardRoot.localImageSource(srv.map)
            return
        }
        imgEl.stage = 'workshop'
        mapCanvas.imgReady = false
        WorkshopPreviewManager.requestPreview(srv.map)
        const cached = WorkshopPreviewManager.cachedUrl(srv.map)
        if (cached !== 'loading' && cached !== '') {
            cardRoot.previewSrc = cached
        }
    }

    onCurMapChanged: cardRoot.startPreview()
    Component.onCompleted: cardRoot.startPreview()


    function mapZh(mapName) {
        const f = mapTrans.formatMap(mapName);
        const m = f.match(/「(.+?)」/);
        return m ? m[1] : '';
    }



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
        return '#FFFFFF';
    }


    function diffText() {
        if (srv.checking || String(srv.map).indexOf('ze_') !== 0)
            return '';
        const d = mapTrans.difficulty(srv.map);
        if (!d || d.length === 0)
            return Lang.tr('暂无','None');
        const en = {'简单':'Easy','普通':'Normal','困难':'Hard','极难':'Extreme','史诗':'Epic','梦魇':'Nightmare','绝境':'Deadly'};
        return Lang.isEn() ? (en[d] || d) : d;
    }

    height: 150
    width: 330


    scale: cardMouse.containsMouse ? 1.02 : 1.0
    z: cardMouse.containsMouse ? 3 : 0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 12
        color: cardMouse.containsMouse
               ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgBase, 1)
               : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 1)
        border.color: cardMouse.containsMouse
                      ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.95)
                      : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
        border.width: cardMouse.containsMouse ? 3 : 2

        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on border.width { NumberAnimation { duration: 120 } }



        Image {
            id: imgEl
            anchors.fill: parent
            source: cardRoot.previewSrc
            asynchronous: true

            sourceSize: Qt.size(480, 270)
            visible: false
            fillMode: Image.PreserveAspectCrop

            property string stage: 'local'
            onStatusChanged: {
                if (status === Image.Ready) {
                    mapCanvas.imgReady = true
                    mapCanvas.requestPaint()

                    repaintTimer.start()
                } else if (status === Image.Error) {
                    if (stage === 'workshop' || stage === 'local') {

                        stage = 'fallback'
                        cardRoot.previewSrc = mapCanvas.noMapSrc
                    } else {

                        mapCanvas.imgReady = false
                        mapCanvas.requestPaint()
                    }
                }
            }
        }


        HusText {
            visible: imgEl.stage === 'workshop' && !mapCanvas.imgReady
            anchors.centerIn: parent
            text: Lang.tr('获取预览图中…','Fetching preview image...')
            color: HusTheme.Primary.colorTextSecondary
            font.pixelSize: 11
            z: 2
        }


        Connections {
            target: WorkshopPreviewManager
            function onPreviewReady(mapName, url) {
                if (cardRoot.normMap(mapName) === cardRoot.normMap(cardRoot.srv.map) && imgEl.stage !== 'fallback') {
                    imgEl.stage = 'workshop'
                    cardRoot.previewSrc = url
                }
            }
            function onPreviewFailed(mapName) {
                if (cardRoot.normMap(mapName) === cardRoot.normMap(cardRoot.srv.map) && imgEl.stage === 'workshop') {

                    imgEl.stage = 'fallback'
                    cardRoot.previewSrc = mapCanvas.noMapSrc
                }
            }
        }


        Timer {
            id: repaintTimer
            interval: 150
            repeat: true
            property int n: 0
            onTriggered: {
                mapCanvas.requestPaint()
                n++
                if (n >= 6)
                    stop()
            }
        }

        Canvas {
            id: mapCanvas
            anchors.fill: parent
            property string noMapSrc: MapImagesDir + '/no_map_image.jpg'
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
            color: srv.online ? 'transparent'
                   : (srv.checking ? HusThemeFunctions.alpha('#000000', 0.45)
                                   : HusThemeFunctions.alpha('#000000', 0.62))
        }


        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: HusThemeFunctions.alpha('#000000', 0.72) }
                GradientStop { position: 1.0; color: HusThemeFunctions.alpha('#000000', 0.0) }
            }
        }

        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.topMargin: 6
            spacing: 6


            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: srv.online ? '#4ADE80'
                       : (srv.checking ? '#FACC15' : '#FF4D4F')
            }

            HusText {
                id: srvNameText
                text: srv.checking ? Lang.tr('检测中...','Checking...')
                      : (srv.online ? srv.name : Lang.tr('离线','Offline'))
                color: '#FFFFFF'
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
                width: parent.width - 14
            }
        }


        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 72
            radius: 12
            gradient: Gradient {
                GradientStop { position: 0.0; color: HusThemeFunctions.alpha('#000000', 0.0) }
                GradientStop { position: 1.0; color: HusThemeFunctions.alpha('#000000', 0.78) }
            }
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            anchors.bottomMargin: 6
            spacing: 2


            HusText {
                width: parent.width - 8
                text: cardRoot.diffText()
                visible: text.length > 0
                color: cardRoot.diffColor(text)
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            HusText {
                width: parent.width - 8
                text: srv.map.length > 0 ? srv.map : '--'
                color: '#FFFFFF'
                font.pixelSize: 10
                font.family: 'Consolas'
                elide: Text.ElideRight
            }

            HusText {
                width: parent.width - 8
                text: cardRoot.mapZh(srv.map)
                color: HusTheme.Primary.colorPrimary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }


        HusButton {
            id: joinBtn
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 8
            anchors.bottomMargin: 6
            width: 50
            height: 22
            z: 10
            type: HusButton.Type_Primary
            radiusBg.all: 5
            text: Lang.tr('加入','Join')
            enabled: srv.online
            font.pixelSize: 10

            scale: hovered ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            opacity: hovered ? 1.0 : (enabled ? 0.92 : 0.5)
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            onClicked: cardRoot.onJoin(srv.ip, srv.name, srv.map)
        }


        HusText {
            anchors.right: parent.right
            anchors.bottom: joinBtn.top
            anchors.rightMargin: 8
            anchors.bottomMargin: 4
            width: 100
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: srv.checking ? Lang.tr('检测中','Checking')
                  : (srv.online ? srv.players : '--')
            color: srv.online ? '#4ADE80' : '#B0B0B0'
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }


        Rectangle {
            anchors.fill: parent
            radius: 12
            color: 'transparent'
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
        }
    }


    MouseArea {
        id: cardMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onDoubleClicked: {
            if (srv.online)
                cardRoot.onOpenSqueeze(srv.ip, srv.name);
        }
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {

                const pos = cardRoot.mapToGlobal(mouse.x, mouse.y);
                cardRoot.onContextMenu(srv.ip, srv.name, mapTrans.formatMap(srv.map),
                                       srv.online, pos.x, pos.y);
            }
        }
    }
}
