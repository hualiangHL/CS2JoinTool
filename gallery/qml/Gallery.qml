pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Window
import QtCore
import HuskarUI.Basic
import Gallery

import 'Home'
import 'Controls'

HusWindow {
    id: galleryWindow
    width: 1222
    height: 740
    opacity: 0
    minimumWidth: 800
    minimumHeight: 600
    title: Lang.tr('CS2挤服工具','CS2JoinTool')

    readonly property var __forceHusAppInit: HusApp
    followThemeSwitch: true

    property Item wifiBtnRef: null
    property var netWinObj: null
    function toggleNetPopup() {
        if (!netWinObj)
            netWinObj = netWinComp.createObject(galleryWindow)
        if (netWinObj.closing) {
            netWinObj.cancelClose()
        } else if (netWinObj.visible) {
            netWinObj.closePopup()
        } else {
            if (wifiBtnRef) {
                const g = wifiBtnRef.mapToGlobal(0, wifiBtnRef.height)
                netWinObj.x = Math.round(g.x + wifiBtnRef.width - netWinObj.width - 4)
                netWinObj.y = Math.round(g.y + 4)
            }
            netWinObj.openPopup()
            netWinObj.testLatency()
        }
    }

    property Item historyBtnRef: null
    property var historyWinObj: null
    function toggleHistoryPopup() {
        if (!historyWinObj)
            historyWinObj = historyWinComp.createObject(galleryWindow)
        if (historyWinObj.closing) {
            historyWinObj.cancelClose()
        } else if (historyWinObj.visible) {
            historyWinObj.closePopup()
        } else {
            if (historyBtnRef) {
                const g = historyBtnRef.mapToGlobal(0, historyBtnRef.height)
                historyWinObj.x = Math.round(g.x + historyBtnRef.width - historyWinObj.width - 4)
                historyWinObj.y = Math.round(g.y + 4)
            }
            historyWinObj.openPopup()
        }
    }

    onClosing: (close) => {
        if (appSettings.closeToTray) {
            close.accepted = false
            hide()
        }
    }

    onXChanged: dismissFloatWindows()
    onYChanged: dismissFloatWindows()
    onWidthChanged: dismissFloatWindows()
    onHeightChanged: dismissFloatWindows()
    onVisibilityChanged: dismissFloatWindows()

    function dismissFloatWindows() {
        if (netWinObj && netWinObj.visible)
            netWinObj.closePopup()
        if (historyWinObj && historyWinObj.visible)
            historyWinObj.closePopup()
    }

    onVisibleChanged: {
        if (!visible && container.genericIdx === 4) {
            BrowserControllerObj.hideBrowserWindow()
        } else if (visible) {
            if (container.genericIdx === 4) {

                if (!appSettings.webMenuExternal) {
                    BrowserControllerObj.showBrowserWindow()
                    BrowserControllerObj.updateBrowserGeometry()
                }
            } else {

                BrowserControllerObj.hideBrowserWindow()
            }
        }
    }
    captionBar.visible: Qt.platform.os === 'windows' || Qt.platform.os === 'linux' || Qt.platform.os === 'osx'
    captionBar.height: captionBar.visible ? 30 : 0
    captionBar.showThemeButton: true
    captionBar.showTopButton: true
    captionBar.showWinIcon: Qt.platform.os !== 'osx'

    Component {
        id: netWinComp
        Window {
            id: netWin
            width: 235
            height: netWinCol.height + 26
            flags: Qt.Tool | Qt.FramelessWindowHint
            color: 'transparent'
            visible: false

            transientParent: galleryWindow

            onActiveChanged: {
                if (!active && visible)
                    closePopup()
            }

            property string latencyText: '--'
            property int tick: 0
            property bool opening: false
            property bool closing: false
            property real baseY: 0

            Timer {
                interval: 1000
                running: netWin.visible
                repeat: true
                onTriggered: netWin.tick++
            }

            function testLatency() {
                latencyText = Lang.tr('测试中...','Testing...')
                var t0 = Date.now()
                var req = new XMLHttpRequest()
                req.open('GET', 'https://www.bluearchive.top/')
                req.onreadystatechange = function() {
                    if (req.readyState === XMLHttpRequest.DONE) {
                        if (req.status === 0)
                            latencyText = Lang.tr('失败','Failed')
                        else
                            latencyText = (Date.now() - t0) + ' ms'
                    }
                }
                req.send()
            }

            function freshConn() {
                tick
                return BaServerTime.isConnected() && (Date.now() - BaServerTime.lastPushMs()) <= 15000
            }

            function openPopup() {
                if (opening) return
                opening = true
                baseY = y
                netOpInY.from = baseY + 8
                netOpInY.to = baseY
                y = baseY + 8
                opacity = 0
                visible = true
                requestActivate()
                netOpIn.start()
            }

            function closePopup() {
                if (!visible || closing) return
                closing = true
                netOpOutO.from = opacity
                netOpOutY.from = y
                netOpOutY.to = y + 8
                netOpOut.start()
            }

            function cancelClose() {
                if (!closing) return
                closing = false
                netOpOut.stop()
                opacity = 1
            }


            ParallelAnimation {
                id: netOpIn
                NumberAnimation {
                    id: netOpInY
                    target: netWin
                    property: 'y'
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    id: netOpInO
                    target: netWin
                    property: 'opacity'
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                onFinished: netWin.opening = false
            }

            ParallelAnimation {
                id: netOpOut
                NumberAnimation {
                    id: netOpOutO
                    target: netWin
                    property: 'opacity'
                    to: 0
                    duration: 150
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    id: netOpOutY
                    target: netWin
                    property: 'y'
                    duration: 150
                    easing.type: Easing.InCubic
                }
                onFinished: {
                    netWin.closing = false
                    netWin.visible = false
                }
            }


            Rectangle {
                anchors.fill: parent
                radius: 8
                color: HusTheme.Primary.colorBgContainer
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
                border.width: 1
            }

            Column {
                id: netWinCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 13
                spacing: 8

                HusText {
                    text: Lang.tr('网络状态','Network Status')
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: HusTheme.Primary.colorTextBase
                }

                Text {
                    width: parent.width
                    textFormat: Text.RichText
                    text: {
                        netWin.tick
                        var ok = netWin.freshConn()
                        return Lang.tr('数据连接: ','Connection: ') + (ok ? Lang.tr('已连接','Connected') : '<font color="#F5222D"><b>' + Lang.tr('未连接','Disconnected') + '</b></font>')
                    }
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }

                HusText {
                    text: {
                        netWin.tick
                        var fresh = netWin.freshConn()
                        return Lang.tr('最近推送: ','Last update: ') + (fresh ? Math.max(0, Math.round((Date.now() - BaServerTime.lastPushMs()) / 10) / 100) + Lang.tr(' 秒前',' sec ago') : '--')
                    }
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }

                HusText {
                    text: {
                        netWin.tick
                        if (!netWin.freshConn()) return Lang.tr('时钟偏差: --','Clock offset: --')
                        var off = BaServerTime.offsetMs()
                        var offS = (off / 1000).toFixed(2)
                        return Lang.tr('时钟偏差: ','Clock offset: ') + (off >= 0 ? '+' : '') + offS + Lang.tr(' 秒',' sec')
                    }
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }

                Text {
                    width: parent.width
                    textFormat: Text.RichText
                    text: Lang.tr('网络延迟: ','Latency: ') + (netWin.latencyText === Lang.tr('失败','Failed') ? '<font color="#F5222D"><b>' + Lang.tr('失败','Failed') + '</b></font>' : netWin.latencyText)
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 12
                }

                Text {
                    width: parent.width
                    text: Lang.tr('1.延迟太高容易进不去服务器，尽量延迟低一点\n2.服务器运行时间会有暂时偏差，暂时无法解决','1. High latency may prevent joining servers, keep it low.\n2. Server uptime may deviate temporarily, unavoidable.')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 9
                    lineHeight: 1.5
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    Component {
        id: historyWinComp
        Window {
            id: historyWin
            width: 180
            height: Math.min(historyList.contentHeight, 300) + 10
            flags: Qt.Tool | Qt.FramelessWindowHint
            color: 'transparent'
            visible: false

            transientParent: galleryWindow

            onActiveChanged: {
                if (!active && visible)
                    closePopup()
            }

            property bool opening: false
            property bool closing: false
            property real baseY: 0

            function openPopup() {
                if (opening) return
                opening = true
                baseY = y
                hisOpInY.from = baseY + 8
                hisOpInY.to = baseY
                y = baseY + 8
                opacity = 0
                visible = true
                requestActivate()
                hisOpIn.start()
            }

            function closePopup() {
                if (!visible || closing) return
                closing = true
                hisOpOutO.from = opacity
                hisOpOutY.from = y
                hisOpOutY.to = y + 8
                hisOpOut.start()
            }

            function cancelClose() {
                if (!closing) return
                closing = false
                hisOpOut.stop()
                opacity = 1
            }


            ParallelAnimation {
                id: hisOpIn
                NumberAnimation {
                    id: hisOpInY
                    target: historyWin
                    property: 'y'
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    id: hisOpInO
                    target: historyWin
                    property: 'opacity'
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                onFinished: historyWin.opening = false
            }

            ParallelAnimation {
                id: hisOpOut
                NumberAnimation {
                    id: hisOpOutO
                    target: historyWin
                    property: 'opacity'
                    to: 0
                    duration: 150
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    id: hisOpOutY
                    target: historyWin
                    property: 'y'
                    duration: 150
                    easing.type: Easing.InCubic
                }
                onFinished: {
                    historyWin.closing = false
                    historyWin.visible = false
                }
            }


            Rectangle {
                anchors.fill: parent
                radius: 8
                color: HusTheme.Primary.colorBgContainer
                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.6)
                border.width: 1
            }

            ListView {
                id: historyList
                anchors.fill: parent
                anchors.margins: 5
                clip: true
                model: galleryRouter.history
                delegate: HusButton {
                    width: ListView.view.width
                    effectEnabled: false
                    text: urlData.label
                    borderBg.color: 'transparent'
                    radiusBg.all: 0
                    onClicked: {
                        galleryRouter.gotoUrl(modelData.location)
                        historyWin.closePopup()
                    }
                    required property var modelData
                    property var urlData: galleryRouter.urlDataMap.get(modelData.location)
                }
                ScrollBar.vertical: HusScrollBar { }
            }
        }
    }

    captionBar.closeCallback: () => {
        console.log('[Gallery] closeCallback fired, closeBehavior=' + appSettings.closeBehavior + ', squeezing=' + SqueezeEngineObj.running)

        if (SqueezeEngineObj.running) {
            closeChoiceWindow.openDialog(true)
            return
        }
        if (appSettings.closeBehavior === 2) {

            closeChoiceWindow.openDialog(false)
        } else if (appSettings.closeBehavior === 1) {
            Qt.quit()
        } else {
            galleryWindow.hide()
        }
    }
    captionBar.winIconDelegate: Item {
        Image {
            width: 16
            height: 16
            anchors.centerIn: parent
            source: 'qrc:/Gallery/images/app_icon.png'
            smooth: true
            mipmap: true
            asynchronous: true
        }
    }
    captionBar.themeCallback: () => {

        HusTheme.darkMode = HusTheme.isDark ? HusTheme.Light : HusTheme.Dark;
        themeSwitchLoader.active = true;
    }
    captionBar.topCallback: (checked) => {
        HusApi.setWindowStaysOnTopHint(galleryWindow, checked);
    }
    captionBar.winTitleDelegate: RowLayout {
        layoutDirection: captionBar.mirrored ? Qt.RightToLeft : Qt.LeftToRight
        spacing: 0

        Connections {
            target: captionBar
            function onWindowAgentChanged() {
                captionBar.addInteractionItem(goBackButton);
                captionBar.addInteractionItem(goForwardButton);
                captionBar.addInteractionItem(historyButton);
            }
        }

        HusText {
            text: captionBar.winTitle
            color: captionBar.winTitleColor
            font: captionBar.winTitleFont
        }

        HusCaptionButton {
            id: goBackButton
            Layout.leftMargin: 10
            Layout.fillHeight: true
            noDisabledState: true
            enabled: galleryRouter.canGoBack
            hoverCursorShape: Qt.PointingHandCursor
            iconSource: HusIcon.ArrowLeftOutlined
            iconSize: 14
            colorIcon: enabled ? themeSource.colorIcon :
                                 themeSource.colorIconDisabled
            colorBg: {
                if (enabled) {
                    return active ? themeSource.colorBgActive :
                                    hovered ? themeSource.colorBgHover : 'transparent';
                } else {
                    return 'transparent';
                }
            }
            contentDescription: Lang.tr('后退','Back')
            onClicked: galleryRouter.goBack();

            HusToolTip {
                visible: parent.hovered
                showArrow: true
                position: HusToolTip.Position_Bottom
                text: parent.contentDescription
            }
        }

        HusCaptionButton {
            id: goForwardButton
            Layout.fillHeight: true
            noDisabledState: true
            enabled: galleryRouter.canGoForward
            hoverCursorShape: Qt.PointingHandCursor
            iconSource: HusIcon.ArrowRightOutlined
            iconSize: 14
            colorIcon: enabled ? themeSource.colorIcon :
                                 themeSource.colorIconDisabled
            colorBg: {
                if (enabled) {
                    return active ? themeSource.colorBgActive :
                                    hovered ? themeSource.colorBgHover : 'transparent';
                } else {
                    return 'transparent';
                }
            }
            contentDescription: Lang.tr('前进','Forward')
            onClicked: galleryRouter.goForward();

            HusToolTip {
                visible: parent.hovered
                showArrow: true
                position: HusToolTip.Position_Bottom
                text: parent.contentDescription
            }
        }

        HusCaptionButton {
            id: historyButton
            Layout.fillHeight: true
            noDisabledState: true
            hoverCursorShape: Qt.PointingHandCursor
            iconSource: HusIcon.HistoryOutlined
            iconSize: 14
            contentDescription: Lang.tr('历史记录','History')
            onClicked: galleryWindow.toggleHistoryPopup()
            Component.onCompleted: galleryWindow.historyBtnRef = historyButton

            HusToolTip {
                visible: parent.hovered
                showArrow: true
                position: HusToolTip.Position_Bottom
                text: parent.contentDescription
            }
        }
    }
    captionBar.winPresetButtonsDelegate: RowLayout {
        layoutDirection: captionBar.mirrored ? Qt.RightToLeft : Qt.LeftToRight
        spacing: 0

        Connections {
            target: captionBar
            function onWindowAgentChanged() {
                captionBar.addInteractionItem(themeButton);
                captionBar.addInteractionItem(topButton);
            }
        }

        HusCaptionButton {
            id: wifiButton
            Layout.fillHeight: true
            Layout.preferredWidth: 38
            noDisabledState: true
            iconSource: HusIcon.WifiOutlined
            iconSize: 14
            contentDescription: Lang.tr('网络延迟','Network Latency')
            onClicked: galleryWindow.toggleNetPopup()
            Component.onCompleted: galleryWindow.wifiBtnRef = wifiButton
        }

        HusCaptionButton {
            id: themeButton
            Layout.fillHeight: true
            noDisabledState: true
            iconSource: HusTheme.isDark ? HusIcon.MoonOutlined : HusIcon.SunOutlined
            iconSize: 14
            contentDescription: Lang.tr('明暗主题切换','Toggle Theme')
            onClicked: captionBar.themeCallback();
        }

        HusCaptionButton {
            id: topButton
            Layout.fillHeight: true
            noDisabledState: true
            iconSource: HusIcon.PushpinOutlined
            iconSize: 14
            checkable: true
            checked: captionBar.topButtonChecked
            contentDescription: Lang.tr('置顶','Always on Top')
            onClicked: captionBar.topCallback(checked);
        }
    }

    Component.onCompleted: {

        console.log('[Gallery] applying themeMode=' + appSettings.themeMode);
        HusTheme.darkMode = appSettings.themeMode;


        if (Qt.platform.os === 'windows') {
            if (!galleryWindow.setSpecialEffect(appSettings.windowEffect)) {
                galleryWindow.setSpecialEffect(HusWindow.Win_DwmBlur);
                appSettings.windowEffect = HusWindow.Win_DwmBlur;
            }
        } else if (Qt.platform.os === 'osx') {
            galleryWindow.setSpecialEffect(HusWindow.Mac_BlurEffect);
        }


        if (appSettings.customBackground)
            galleryBackground.bgSource = appSettings.customBackground;


        galleryMenu.compactMode = appSettings.navMode;


        TrayController.init()

        CloseGuard.closeToTray = appSettings.closeToTray
    }

    Connections {
        target: appSettings
        function onCloseToTrayChanged() {
            CloseGuard.closeToTray = appSettings.closeToTray
        }
        function onCloseBehaviorChanged() {
            CloseGuard.closeToTray = appSettings.closeToTray
        }
    }

    property var galleryGlobal: Global { }

    Behavior on opacity { NumberAnimation { } }

    Timer {
        running: true
        interval: 200
        onTriggered: {

            HusTheme.darkMode = appSettings.themeMode;
            galleryWindow.opacity = 1;
        }
    }


    Settings {
        id: appSettings
        property int windowEffect: HusWindow.Win_DwmBlur
        property real bgOpacity: 0.7
        property string customBackground: ''
        property int squeezeProtocol: 1

        property bool intervalLimitEnabled: false

        property int defaultInterval: 100

        property int defaultThreshold: 63

        property int coreCount: 2

        property int defaultCoreCount: 2

        property bool joinToastEnabled: false

        property bool floatWindowEnabled: true

        property int closeBehavior: 2

        property int themeMode: 0

        property int navMode: 0

        property string serverOrder: ''

        property string serverHidden: ''

        property string navOrder: ''

        property bool hideOffline: false

        property bool sortByPlayers: false

        property string webMenuUrl: 'https://list.darkrp.cn:6514/'

        property bool webMenuExternal: false

        property bool closeToTray: closeBehavior !== 1
    }


    Connections {
        target: HusTheme
        function onDarkModeChanged() {
            var m = HusTheme.darkMode
            if (m === HusTheme.Dark) appSettings.themeMode = 1
            else if (m === HusTheme.Light) appSettings.themeMode = 0
            else appSettings.themeMode = 2
            console.log('[Gallery] theme saved, darkMode=' + m + ', themeMode=' + appSettings.themeMode)
        }
    }

    Rectangle {
        id: galleryBackground
        anchors.fill: content
        color: 'transparent'
        opacity: appSettings.bgOpacity

        property string bgSource: ''


        Image {
            anchors.fill: parent
            source: galleryBackground.bgSource !== '' ? galleryBackground.bgSource : AppBackground
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false

            sourceSize: Qt.size(1600, 900)
        }


        Rectangle {
            anchors.fill: parent
            color: HusTheme.isDark ? '#0f0f12' : '#f2f2f4'
            opacity: HusTheme.isDark ? 0.42 : 0.45
        }
    }


    Window {
        id: toastFloatWindow
        objectName: 'toastFloatWindow'
        width: 340
        height: 140
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        transientParent: null
        color: 'transparent'
        visible: false

        property bool toastExiting: false


        TextMetrics {
            id: toastBodyMetrics
            font: toastBody.font
        }


        function fitBody(text) {
            if (!text)
                return ''

            var maxW = toastFloatWindow.width - 38
            if (maxW <= 0)
                maxW = 300
            var lines = text.split('\n')
            var out = []
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                toastBodyMetrics.text = line
                if (toastBodyMetrics.advanceWidth <= maxW) {
                    out.push(line)
                    continue
                }
                var lo = 0, hi = line.length
                while (lo < hi) {
                    var mid = Math.ceil((lo + hi) / 2)
                    toastBodyMetrics.text = line.substring(0, mid) + '…'
                    if (toastBodyMetrics.advanceWidth > maxW)
                        hi = mid - 1
                    else
                        lo = mid
                }
                out.push(line.substring(0, lo) + '…')
            }
            return out.join('\n')
        }

        function positionAtBottomRight() {

            var scr = Qt.application.primaryScreen
            if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
            if (scr && scr.availableGeometry) {
                var g = scr.availableGeometry
                x = g.x + g.width - width - 16
                y = g.y + g.height - height - 16
                console.log('[toast] pos g=' + g.x + ',' + g.y + ' ' + g.width + 'x' + g.height
                    + ' win=' + width + 'x' + height + ' -> ' + x + ',' + y + ' scr=' + scr.name)
            }
        }

        function showToast(title, message, force) {

            if (!force && !appSettings.joinToastEnabled)
                return false
            positionAtBottomRight()
            if (visible && !toastExiting) {
                toastTitle.text = title
                toastBody.text = fitBody(message)
                toastBar.width = 316
                barAnim.restart()
                return true
            }
            if (toastExiting)
                exitAnim.stop()
            toastExiting = false
            toastTitle.text = title
            toastBody.text = fitBody(message)
            toastBar.width = 316
            toastBox.opacity = 0
            toastBox.scale = 0.9
            toastBox.x = 340
            visible = true
            show()
            raise()
            positionAtBottomRight()
            FloatWindowPos.positionAll()
            toastPosTimer.restart()
            toastPersistTimer.start()
            enterAnim.start()
            barAnim.start()
            return true
        }

        function startExit() {
            if (toastExiting) return
            toastExiting = true
            enterAnim.stop()
            barAnim.stop()
            toastPersistTimer.stop()
            toastBox.x = 1
            exitAnim.start()
        }

        ParallelAnimation {
            id: enterAnim
            NumberAnimation { target: toastBox; property: 'x'; from: 340; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: toastBox; property: 'opacity'; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: toastBox; property: 'scale'; from: 0.9; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: exitAnim
            NumberAnimation { target: toastBox; property: 'opacity'; from: 1; to: 0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: toastBox; property: 'scale'; from: 1.0; to: 0.95; duration: 250; easing.type: Easing.InCubic }
            onFinished: {
                toastFloatWindow.visible = false
                toastFloatWindow.toastExiting = false
            }
        }

        NumberAnimation {
            id: barAnim
            target: toastBar
            property: 'width'
            from: 316
            to: 0
            duration: 5000
            easing.type: Easing.Linear
            onFinished: toastFloatWindow.startExit()
        }


        Timer {
            id: toastPosTimer
            interval: 0
            repeat: false
            onTriggered: toastFloatWindow.positionAtBottomRight()
        }


        Timer {
            id: toastPersistTimer
            interval: 300
            repeat: true
            running: false
            onTriggered: toastFloatWindow.positionAtBottomRight()
        }

        Rectangle {
            id: toastBox
            width: parent.width - 2
            height: parent.height - 2
            x: 1
            y: 1
            radius: 14

            color: HusTheme.isDark ? '#E81E1B2E' : '#CCE0F7FA'
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)

            Column {
                anchors.fill: parent
                anchors.margins: 18
                anchors.bottomMargin: 30
                spacing: 8
                z: 1

                HusText {
                    id: toastTitle
                    text: ''
                    color: HusTheme.isDark ? '#FFFFFF' : '#1F2D36'
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width - 42
                }

                HusText {
                    id: toastBody
                    text: ''
                    color: HusTheme.isDark ? '#9BA1B5' : '#2E3B44'
                    font.pixelSize: 12

                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }


            Rectangle {
                id: toastBar
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.bottomMargin: 6
                width: 316
                height: 3
                radius: 2
                color: HusTheme.Primary.colorPrimary
            }


            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 6
                anchors.rightMargin: 6
                width: 34
                height: 34
                radius: 9
                color: toastCloseMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.30) : 'transparent'
                Behavior on color { ColorAnimation { duration: 120 } }

                HusText {
                    anchors.centerIn: parent
                    text: '\u00D7'
                    color: toastCloseMouse.containsMouse ? (HusTheme.isDark ? '#FFFFFF' : '#1F2D36') : (HusTheme.isDark ? '#8090A0' : '#2E3B44')
                    font.pixelSize: 24
                }

                MouseArea {
                    id: toastCloseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: toastFloatWindow.startExit()
                }
            }


            MouseArea {
                anchors.fill: parent
                onClicked: toastFloatWindow.startExit()
            }
        }
    }


    Window {
        id: updateFloatWindow
        objectName: 'updateFloatWindow'
        width: 340
        height: 140
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        transientParent: null
        color: 'transparent'
        visible: false

        property bool updateExiting: false

        TextMetrics {
            id: updateBodyMetrics
            font: updateBody.font
        }

        function fitUpdateBody(text) {
            if (!text)
                return ''
            var maxW = updateFloatWindow.width - 38
            if (maxW <= 0)
                maxW = 300
            var lines = text.split('\n')
            var out = []
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                updateBodyMetrics.text = line
                if (updateBodyMetrics.advanceWidth <= maxW) {
                    out.push(line)
                    continue
                }
                var lo = 0, hi = line.length
                while (lo < hi) {
                    var mid = Math.ceil((lo + hi) / 2)
                    updateBodyMetrics.text = line.substring(0, mid) + '…'
                    if (updateBodyMetrics.advanceWidth > maxW)
                        hi = mid - 1
                    else
                        lo = mid
                }
                out.push(line.substring(0, lo) + '…')
            }
            return out.join('\n')
        }

        function positionUpdateAtBottomRight() {

            var scr = Qt.application.primaryScreen
            if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
            if (scr && scr.availableGeometry) {
                var g = scr.availableGeometry
                x = g.x + g.width - width - 16
                y = g.y + g.height - height - 16
                console.log('[update] pos g=' + g.x + ',' + g.y + ' ' + g.width + 'x' + g.height
                    + ' win=' + width + 'x' + height + ' -> ' + x + ',' + y + ' scr=' + scr.name)
            }
        }

        function showUpdateToast(title, message, notes) {
            positionUpdateAtBottomRight()
            if (visible && !updateExiting) {
                updateTitle.text = title
                updateBody.text = message
                updateNotes.text = notes ? fitUpdateBody(notes) : ''
                updateBar.width = 316
                updateBarAnim.restart()
                return
            }
            if (updateExiting)
                updateExitAnim.stop()
            updateExiting = false
            updateTitle.text = title
            updateBody.text = message
            updateNotes.text = notes ? fitUpdateBody(notes) : ''
            updateBar.width = 316
            updateBox.opacity = 0
            updateBox.scale = 0.9
            updateBox.x = 340
            visible = true
            show()
            raise()
            positionUpdateAtBottomRight()
            FloatWindowPos.positionAll()
            updatePersistTimer.start()
            updateEnterAnim.start()
            updateBarAnim.start()
        }

        function startUpdateExit() {
            if (updateExiting) return
            updateExiting = true
            updateEnterAnim.stop()
            updateBarAnim.stop()
            updatePersistTimer.stop()
            updateBox.x = 1
            updateExitAnim.start()
        }

        ParallelAnimation {
            id: updateEnterAnim
            NumberAnimation { target: updateBox; property: 'x'; from: 340; to: 1; duration: 380; easing.type: Easing.OutCubic }
            NumberAnimation { target: updateBox; property: 'opacity'; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: updateBox; property: 'scale'; from: 0.9; to: 1.0; duration: 300; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: updateExitAnim
            NumberAnimation { target: updateBox; property: 'opacity'; from: 1; to: 0; duration: 250; easing.type: Easing.InCubic }
            NumberAnimation { target: updateBox; property: 'scale'; from: 1.0; to: 0.95; duration: 250; easing.type: Easing.InCubic }
            onFinished: {
                updateFloatWindow.visible = false
                updateFloatWindow.updateExiting = false
            }
        }

        NumberAnimation {
            id: updateBarAnim
            target: updateBar
            property: 'width'
            from: 316
            to: 0
            duration: 6000
            easing.type: Easing.Linear
            onFinished: updateFloatWindow.startUpdateExit()
        }


        Timer {
            id: updatePersistTimer
            interval: 300
            repeat: true
            running: false
            onTriggered: updateFloatWindow.positionUpdateAtBottomRight()
        }

        Rectangle {
            id: updateBox
            width: parent.width - 2
            height: parent.height - 2
            x: 1
            y: 1
            radius: 14
            color: HusTheme.isDark ? '#E81E1B2E' : '#CCE0F7FA'
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)

            Column {
                anchors.fill: parent
                anchors.margins: 18
                anchors.bottomMargin: 30
                spacing: 8
                z: 1

                HusText {
                    id: updateTitle
                    text: ''
                    color: HusTheme.isDark ? '#FFFFFF' : '#1F2D36'
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width - 42
                }

                HusText {
                    id: updateBody
                    text: ''

                    color: HusTheme.isDark ? '#FFFFFF' : '#111111'
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                HusText {
                    id: updateNotes
                    text: ''

                    color: HusTheme.isDark ? '#9BA1B5' : '#2E3B44'
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }

            Rectangle {
                id: updateBar
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.bottomMargin: 6
                width: 316
                height: 3
                radius: 2
                color: HusTheme.Primary.colorPrimary
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 6
                anchors.rightMargin: 6
                width: 34
                height: 34
                radius: 9
                color: updateCloseMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.30) : 'transparent'
                Behavior on color { ColorAnimation { duration: 120 } }

                HusText {
                    anchors.centerIn: parent
                    text: '\u00D7'
                    color: updateCloseMouse.containsMouse ? (HusTheme.isDark ? '#FFFFFF' : '#1F2D36') : (HusTheme.isDark ? '#8090A0' : '#2E3B44')
                    font.pixelSize: 24
                }

                MouseArea {
                    id: updateCloseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: updateFloatWindow.startUpdateExit()
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: updateFloatWindow.startUpdateExit()
            }
        }
    }


    Connections {
        target: UpdateChecker
        function onUpdateAvailable(version, notes) {
            updateFloatWindow.showUpdateToast(Lang.tr('发现新版本 v','New version v') + version, Lang.tr('软件有新版本可用，可去「设置 - 新版本查看」下载更新','A new version is available. Go to Settings > Check Updates to download.'), notes)
            SystemSound.playNotification()
        }
    }


    Timer {
        running: true
        interval: 10000
        onTriggered: UpdateChecker.checkForUpdate()
    }


    Connections {
        target: SqueezeEngineObj
        function onConnectSent() {
            console.log('[sound] onConnectSent fired, suppress=' + SqueezeEngineObj.suppressConnectToast + ', ip=' + SqueezeEngineObj.serverIp)

            if (SqueezeEngineObj.suppressConnectToast)
                toastFloatWindow.showToast(Lang.tr('正在加入服务器','Joining server'), Lang.tr('已发送连接请求，正在进入服务器...','Connection request sent, entering server...'))
            else
                toastFloatWindow.showToast(Lang.tr('挤服成功','Squeeze succeeded'), Lang.tr('已发送连接请求，正在进入服务器...','Connection request sent, entering server...'))

            SystemSound.playNotification()
            JoinHistoryManager.record(SqueezeEngineObj.mapName, SqueezeEngineObj.serverName, SqueezeEngineObj.serverIp)
        }
    }


    Connections {
        target: SubscriptionManagerObj
        function onNotificationRequested(title, message) {
            toastFloatWindow.showToast(title, message, true)
            SystemSound.playNotification()
        }
    }


    Window {
        id: floatStatusWindow
        objectName: 'floatStatusWindow'
        width: 260
        height: 150
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        transientParent: null
        color: 'transparent'
        visible: false

        function positionAtBottomRight() {

            var scr = galleryWindow.screen
            if (!scr) scr = Qt.application.primaryScreen
            if (!scr && Qt.application.screens.length > 0) scr = Qt.application.screens[0]
            if (scr && scr.availableGeometry) {
                var g = scr.availableGeometry
                x = g.x + g.width - width - 16
                y = g.y + g.height - height - 16
                console.log('[floatStatus] pos g=' + g.x + ',' + g.y + ' ' + g.width + 'x' + g.height
                    + ' win=' + width + 'x' + height + ' -> ' + x + ',' + y + ' scr=' + scr.name)
            }
        }

        function showFloat() {
            if (!appSettings.floatWindowEnabled)
                return
            if (visible && floatContent.opacity > 0.5) return
            floatCloseAnim.stop()
            positionAtBottomRight()
            floatStatusWindow.visible = true
            show()
            raise()
            positionAtBottomRight()
            FloatWindowPos.positionAll()
            floatContent.opacity = 0
            floatContent.scale = 0.85
            floatOpenAnim.start()
        }

        function hideFloat() {
            if (!visible) return
            floatOpenAnim.stop()
            floatCloseAnim.start()
        }


        ParallelAnimation {
            id: floatOpenAnim
            NumberAnimation { target: floatContent; property: 'opacity'; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { target: floatContent; property: 'scale'; from: 0.85; to: 1.0; duration: 320; easing.type: Easing.OutBack }
        }


        ParallelAnimation {
            id: floatCloseAnim
            NumberAnimation { target: floatContent; property: 'opacity'; from: 1; to: 0; duration: 200; easing.type: Easing.InCubic }
            NumberAnimation { target: floatContent; property: 'scale'; from: 1.0; to: 0.9; duration: 200; easing.type: Easing.InCubic }
            onFinished: floatStatusWindow.visible = false
        }

        Rectangle {
            id: floatContent
            anchors.fill: parent
            radius: 12

            color: HusTheme.isDark ? '#E81E1B2E' : '#CCE0F7FA'
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
            opacity: 0
            scale: 0.85


            Rectangle {
                id: floatTitle
                width: parent.width
                height: 32
                color: HusTheme.isDark ? '#C0121525' : '#D4E0F7FA'
                radius: 12
                clip: true


                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: SqueezeEngineObj.running ? (HusTheme.isDark ? '#FFD4AA00' : '#C77700') : (HusTheme.isDark ? '#708090' : '#8A9AA4')
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    HusText {
                        text: SqueezeEngineObj.running ? Lang.tr('正在挤服','Squeezing') : Lang.tr('挤服状态','Squeeze Status')
                        color: SqueezeEngineObj.running ? (HusTheme.isDark ? '#FFD4AA00' : '#C77700') : (HusTheme.isDark ? '#A0A8B8' : '#2E3B44')
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }


                Canvas {
                    id: floatCloseBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    onPaint: {
                        var ctx = getContext('2d')
                        ctx.reset()
                        ctx.strokeStyle = floatCloseMouse.containsMouse ? '#e74c3c' : (HusTheme.isDark ? '#8B7DB8' : '#2E3B44')
                        ctx.lineWidth = 2
                        ctx.lineCap = 'round'
                        ctx.beginPath()
                        ctx.moveTo(2, 2); ctx.lineTo(12, 12)
                        ctx.moveTo(12, 2); ctx.lineTo(2, 12)
                        ctx.stroke()
                    }

                    MouseArea {
                        id: floatCloseMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: floatStatusWindow.hideFloat()
                    }
                }


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
                    HusText { text: Lang.tr('服务器','Server'); color: HusTheme.isDark ? '#8B7DB8' : '#2E3B44'; font.pixelSize: 11; width: 50 }
                    HusText {
                        text: SqueezeEngineObj.running ? (SqueezeEngineObj.serverName || '—') : '—'
                        color: HusTheme.isDark ? '#FFFFFF' : '#1F2D36'
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width - 50
                    }
                }

                Row {
                    width: parent.width
                    HusText { text: Lang.tr('地图','Map'); color: HusTheme.isDark ? '#8B7DB8' : '#2E3B44'; font.pixelSize: 11; width: 50 }
                    HusText {
                        text: SqueezeEngineObj.running ? (SqueezeEngineObj.mapName || '—') : '—'
                        color: HusTheme.isDark ? '#FFFFFF' : '#1F2D36'
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width - 50
                    }
                }

                Row {
                    width: parent.width
                    HusText { text: Lang.tr('人数','Players'); color: HusTheme.isDark ? '#8B7DB8' : '#2E3B44'; font.pixelSize: 11; width: 50 }
                    HusText {
                        text: SqueezeEngineObj.running ? (SqueezeEngineObj.players + '/' + SqueezeEngineObj.maxPlayers) : '0/0'
                        color: HusTheme.Primary.colorPrimary
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                Row {
                    width: parent.width
                    HusText { text: Lang.tr('尝试','Attempts'); color: HusTheme.isDark ? '#8B7DB8' : '#2E3B44'; font.pixelSize: 11; width: 50 }
                    HusText {
                        text: SqueezeEngineObj.running ? Lang.tr('%1 次','%1 attempts').arg(Math.floor(SqueezeEngineObj.retryCount / 10) * 10) : Lang.tr('0 次','0 attempts')
                        color: HusTheme.isDark ? '#FFD4AA00' : '#C77700'
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }


            MouseArea {
                anchors.top: floatTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                onClicked: galleryWindow.requestActivate()
            }
        }
    }


    Connections {
        target: SqueezeEngineObj
        function onRunningChanged() {
            if (SqueezeEngineObj.running)
                floatStatusWindow.showFloat()
            else if (floatStatusWindow.visible)
                floatStatusWindow.hideFloat()
        }
    }

    HusRouter {
        id: galleryRouter
        property var urlDataMap: new Map
        function gotoUrl(url) {
            if (urlDataMap.has(url)) {
                const data = urlDataMap.get((url));
                gallerySwitchEffect.switchToSource(data.source);
            }
        }
        onCurrentUrlChanged: gotoUrl(currentUrl);
    }

    Loader {
        id: themeSwitchLoader
        z: 65536
        active: false
        anchors.fill: galleryWindow.contentItem
        sourceComponent: ThemeSwitchItem {
            opacity: galleryWindow.specialEffect == HusWindow.None ? 1.0 : galleryBackground.opacity
            target: galleryWindow.contentItem
            isDark: HusTheme.isDark
            onSwitchStarted: {

            }
            onAnimationFinished: {
                if (galleryWindow.specialEffect === HusWindow.None) {
                    galleryWindow.color = HusTheme.Primary.colorBgBase;
                }
                themeSwitchLoader.active = false;
            }
            Component.onCompleted: {
                colorBg = HusTheme.isDark ? '#f5f5f5' : '#181818';
                const distance = function(x1, y1, x2, y2) {
                    return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
                }
                const startX = content.width - 170;
                const startY = 0;
                const radius = Math.max(distance(startX, startY, 0, 0),
                                        distance(startX, startY, content.width, 0),
                                        distance(startX, startY, 0, content.height),
                                        distance(startX, startY, content.width, content.height));
                start(width, height, Qt.point(startX, startY), radius);
            }
        }

        function changeDark() {
            HusTheme.darkMode = HusTheme.isDark ? HusTheme.Light : HusTheme.Dark;
        }

        Connections {
            target: HusTheme
            function onIsDarkChanged() {
                if (HusTheme.darkMode === HusTheme.System) {
                    galleryWindow.setWindowMode(HusTheme.isDark);
                }
            }
        }
    }

    Item {
        id: content
        anchors.top: galleryWindow.captionBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        HusAutoComplete {
            id: searchComponent
            property bool expanded: false
            z: 10
            clip: true
            width: (galleryMenu.compactMode === HusMenu.Mode_Relaxed || expanded) ? (galleryMenu.defaultMenuWidth - 20) : 0
            anchors.top: parent.top
            anchors.topMargin: 5
            anchors.left: galleryMenu.compactMode === HusMenu.Mode_Relaxed ? galleryMenu.left : galleryMenu.right
            anchors.margins: 10
            topPadding: 6
            bottomPadding: 6
            rightPadding: 50
            showToolTip: true
            placeholderText: Lang.tr('搜索组件','Search Components')
            iconSource: HusIcon.SearchOutlined
            colorBg: !(galleryMenu.compactMode === HusMenu.Mode_Relaxed) ? HusTheme.HusInput.colorBg : 'transparent'
            options: galleryGlobal.options
            filterOption: (input, option) => option.label.toUpperCase().indexOf(input.toUpperCase()) !== -1
            onSelect: option => galleryMenu.gotoMenu(option.key)
            labelDelegate: HusText {
                height: implicitHeight + 4
                text: parent.textData
                color: HusTheme.HusAutoComplete.colorItemText
                font {
                    family: HusTheme.HusAutoComplete.fontFamily
                    pixelSize: HusTheme.HusAutoComplete.fontSize
                    weight: parent.highlighted ? Font.DemiBold : Font.Normal
                }
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter

                property var model: parent.modelData
                property string tagState: model.state ?? ''

                HusTag {
                    id: __tag
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.tagState
                    presetColor: parent.tagState === 'New' ? 'red' : 'green'
                    visible: parent.tagState !== ''
                }
            }

            Keys.onEscapePressed: {
                if (expanded) {
                    expanded = false;
                } else {
                    closePopup();
                }
            }

            Behavior on width {
                enabled: !(galleryMenu.compactMode === HusMenu.Mode_Relaxed) &&
                         galleryMenu.width === galleryMenu.compactWidth
                NumberAnimation { duration: HusTheme.Primary.durationFast }
            }
        }

        HusIconButton {
            id: searchCollapse
            visible: !(galleryMenu.compactMode === HusMenu.Mode_Relaxed)
            anchors.top: parent.top
            anchors.left: galleryMenu.left
            anchors.right: galleryMenu.right
            anchors.margins: 10
            type: HusButton.Type_Text
            colorText: HusTheme.Primary.colorTextBase
            iconSource: HusIcon.SearchOutlined
            iconSize: searchComponent.iconSize
            onClicked: {
                searchComponent.expanded = !searchComponent.expanded;
                if (searchComponent.expanded) {
                    searchComponent.forceActiveFocus();
                }
            }
            onVisibleChanged: {
                if (visible) {
                    searchComponent.closePopup();
                    searchComponent.expanded = false;
                }
            }
        }

        HusMenu {
            id: galleryMenu
            anchors.left: parent.left
            anchors.top: searchComponent.bottom
            anchors.bottom: menuDivider.top
            showEdge: true
            showToolTip: false
            defaultMenuWidth: 200
            defaultSelectedKeys: ['HomeMain']
            initModel: galleryGlobal.menus




            keepCurrentKeys: appSettings.webMenuExternal ? ['Browser'] : []

            popupTranslucent: appSettings.windowEffect === HusWindow.Win_DwmBlur

            popupAsWindow: container.genericIdx === 4
            menuLabelDelegate: HusText {
                text: menuButton.text
                font: menuButton.font
                color: menuButton.hovered ? HusTheme.Primary.colorPrimary : menuButton.colorText
                elide: Text.ElideRight

                property var model: parent.model
                property var menuButton: parent.menuButton
                property string tagState: model.state ?? ''


                Behavior on color { enabled: galleryMenu.animationEnabled; ColorAnimation { duration: 150 } }
                x: menuButton.hovered ? 4 : 0
                Behavior on x { enabled: galleryMenu.animationEnabled; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                HusTag {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.tagState
                    presetColor: parent.tagState === 'New' ? 'red' : 'green'
                    visible: parent.tagState !== ''
                }
            }
            menuBgDelegate: Rectangle {
                radius: menuButton.radiusBg.all
                color: menuButton.colorBg
                border.color: menuButton.borderBg.color
                border.width: 1

                property var model: parent.model
                property var menuButton: parent.menuButton
                property string badgeState: model.badgeState ?? ''

                Behavior on color { enabled: galleryMenu.animationEnabled; ColorAnimation { duration: HusTheme.Primary.durationMid } }
                Behavior on border.color { enabled: galleryMenu.animationEnabled; ColorAnimation { duration: HusTheme.Primary.durationMid } }

                HusBadge {
                    anchors.left: undefined
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: undefined
                    anchors.margins: 1
                    dot: true
                    presetColor: parent.badgeState == 'New' ? 'red' : 'green'
                    visible: parent.badgeState !== ''
                }
            }
            onClickMenu: function(deep, key, keyPath, data) {
                if (data) {
                    if (data.hasOwnProperty('menuChildren')) {
                        setDataProperty(key, 'badgeState', '');
                    } else {




                        if (data.externalUrl) {
                            Qt.openUrlExternally(data.externalUrl)
                            return
                        }

                        if (appSettings.webMenuExternal && container.genericSources.length > 4 && data.source === container.genericSources[4]) {
                            Qt.openUrlExternally(appSettings.webMenuUrl)


                            const curKey = container.currentMenuKey()
                            if (curKey !== '')
                                galleryMenu.selectKey(curKey)
                            return
                        }
                        galleryRouter.urlDataMap.set(Qt.url(data.source), data);
                        galleryRouter.push(data.source);
                        console.debug('onClickMenu', deep, key, keyPath, JSON.stringify(data));
                    }
                }
            }
        }


        component BottomNavItem: Rectangle {
            id: bottomNav
            property string labelText: ''
            property var navIcon: 0
            property bool navActive: false
            property alias hovered: navMouse.containsMouse
            signal navClicked()
            width: galleryMenu.width
            height: 40
            radius: 6
            color: navActive ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22)
                            : (navMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16) : 'transparent')
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 17
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5
                HusIconText {
                    iconSource: bottomNav.navIcon
                    iconSize: galleryMenu.defaultMenuIconSize
                    colorIcon: bottomNav.navActive ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase
                }
                HusText {
                    text: bottomNav.labelText

                    visible: galleryMenu.compactMode !== HusMenu.Mode_Compact
                    color: bottomNav.navActive ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextBase

                    width: Math.max(0, bottomNav.width - 45)
                    elide: Text.ElideRight
                    clip: true
                }
            }

            MouseArea {
                id: navMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: bottomNav.navClicked()
            }
        }

        HusDivider {
            id: menuDivider
            width: galleryMenu.width
            height: 5
            anchors.bottom: buttonsColumn.top
        }

        Loader {
            id: aboutLoader
            active: false
            visible: false
            sourceComponent: AboutPage { visible: aboutLoader.visible }
        }

        Loader {
            id: settingsLoader
            active: false
            visible: false
            sourceComponent: SettingsPage { visible: settingsLoader.visible }
        }

        Column {
            id: buttonsColumn
            width: galleryMenu.width
            anchors.bottom: parent.bottom

            BottomNavItem {
                width: parent.width
                labelText: Lang.tr('关于','About')
                navIcon: HusIcon.UserOutlined
                onNavClicked: {
                    if (!aboutLoader.active) aboutLoader.active = true;
                    aboutLoader.visible = !aboutLoader.visible;
                }

                HusToolTip {
                    visible: parent.hovered
                    showArrow: true
                    text: Lang.tr('关于','About')
                }
            }

            BottomNavItem {
                width: parent.width
                labelText: Lang.tr('设置','Settings')
                navIcon: HusIcon.SettingOutlined
                onNavClicked: {
                    if (!settingsLoader.active) settingsLoader.active = true;
                    settingsLoader.visible = !settingsLoader.visible;
                }

                HusToolTip {
                    visible: parent.hovered
                    showArrow: true
                    text: Lang.tr('设置','Settings')
                }
            }
        }

        Item {
            id: container
            anchors.left: galleryMenu.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 5
            clip: true

            property string source: './Home/HomeMainPage.qml'
            property int activeIdx: -1

            property bool serverCardMode: false

            property bool hideOffline: appSettings.hideOffline

            property bool sortByPlayers: appSettings.sortByPlayers

            property bool sortBySubs: AppConfig.sortBySubs

            onHideOfflineChanged: if (appSettings.hideOffline !== hideOffline) appSettings.hideOffline = hideOffline
            onSortByPlayersChanged: if (appSettings.sortByPlayers !== sortByPlayers) appSettings.sortByPlayers = sortByPlayers
            onSortBySubsChanged: if (AppConfig.sortBySubs !== sortBySubs) AppConfig.sortBySubs = sortBySubs


            property var serverSources: [
                './Examples/Server/ExpServerList.qml',
                './Examples/Server/ExpServerListZed.qml',
                './Examples/Server/ExpServerListUb.qml',
                './Examples/Server/ExpServerListFys.qml',
                './Examples/Server/ExpServerListUpkk.qml',
                './Examples/Server/ExpServerListStar.qml',
                './Examples/Server/ExpServerListInternational.qml',
                './Examples/Server/ExpServerListMapRun.qml'
            ]

            function allServerLoaders() {
                return [serverLoader0, serverLoader1, serverLoader2, serverLoader3,
                        serverLoader4, serverLoader5, serverLoader6, serverLoader7]
            }



            property var serverMenuKeys: ['exg', 'zed', 'ub', 'fys', 'upkk', 'star', 'international', 'maprun']
            property var genericMenuKeys: ['HomeMain', 'Cooldown', 'Subscription', 'Workshop', 'Browser', 'cmdlist', 'cmdwheel']
            function currentMenuKey() {
                if (activeIdx >= 0 && activeIdx < serverMenuKeys.length)
                    return serverMenuKeys[activeIdx]
                if (genericIdx >= 0 && genericIdx < genericMenuKeys.length)
                    return genericMenuKeys[genericIdx]
                return ''
            }



            property var genericSources: [
                './Home/HomeMainPage.qml',
                './Examples/Server/CooldownPage.qml',
                './Examples/Server/SubscriptionPage.qml',
                './Examples/Server/WorkshopPage.qml',
                './Examples/Server/BrowserPage.qml',
                './Examples/Server/CommandsListPage.qml',
                './Examples/Server/RadialWheelPage.qml'
            ]

            property int genericIdx: 0

            function switchToSource(source) {
                if (container.source === source) return

                if (galleryMenu) galleryMenu.closeAllPopups()

                const allLoaders = allServerLoaders()
                for (let li = 0; li < allLoaders.length; li++) {
                    const liItem = allLoaders[li].item
                    if (liItem && typeof liItem.closeFloatingPanels === 'function')
                        liItem.closeFloatingPanels()
                }
                const loaders = allServerLoaders()
                const idx = serverSources.indexOf(source)
                const oldIdx = serverSources.indexOf(container.source)

                container.source = source

                if (idx >= 0) {

                    container.activeIdx = idx
                    container.genericIdx = -1
                    if (!loaders[idx].active) loaders[idx].active = true
                    loaders[idx].visible = true
                } else {

                    const gi = genericSources.indexOf(source)
                    container.genericIdx = gi >= 0 ? gi : 0
                    container.activeIdx = -1

                    const genLoaders = [genLoader0, genLoader1, genLoader2, genLoader3, genLoader4, genLoader5, genLoader6]
                    if (container.genericIdx < genLoaders.length && !genLoaders[container.genericIdx].active)
                        genLoaders[container.genericIdx].active = true
                }


                hideOldTimer.targetIdx = oldIdx
                hideOldTimer.restart()
            }

            Timer {
                id: hideOldTimer
                interval: 250
                repeat: false
                property int targetIdx: -2
                onTriggered: {
                    if (targetIdx >= 0) {
                        const loaders = container.allServerLoaders()
                        if (targetIdx < loaders.length) loaders[targetIdx].visible = false
                    }
                }
            }


            Loader {
                id: serverLoader0
                active: false
                source: container.serverSources[0]
                visible: container.activeIdx === 0
                opacity: container.activeIdx === 0 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader1
                active: false
                source: container.serverSources[1]
                visible: container.activeIdx === 1
                opacity: container.activeIdx === 1 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader2
                active: false
                source: container.serverSources[2]
                visible: container.activeIdx === 2
                opacity: container.activeIdx === 2 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader3
                active: false
                source: container.serverSources[3]
                visible: container.activeIdx === 3
                opacity: container.activeIdx === 3 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader4
                active: false
                source: container.serverSources[4]
                visible: container.activeIdx === 4
                opacity: container.activeIdx === 4 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader5
                active: false
                source: container.serverSources[5]
                visible: container.activeIdx === 5
                opacity: container.activeIdx === 5 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader6
                active: false
                source: container.serverSources[6]
                visible: container.activeIdx === 6
                opacity: container.activeIdx === 6 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: serverLoader7
                active: false
                source: container.serverSources[7]
                visible: container.activeIdx === 7
                opacity: container.activeIdx === 7 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }


            Timer {
                id: serverPreloadTimer
                interval: 250
                repeat: true
                running: false
                property int step: 0
                onTriggered: {
                    const loaders = container.allServerLoaders()
                    if (step < loaders.length) {
                        loaders[step].active = true
                        step++
                    } else {
                        running = false
                        step = 0
                    }
                }
            }

            Timer {
                id: serverPreloadDelay
                interval: 3000
                repeat: false
                running: true
                onTriggered: serverPreloadTimer.start()
            }


            Loader {
                id: genLoader0
                active: true
                source: container.genericSources[0]
                visible: container.genericIdx === 0
                opacity: container.genericIdx === 0 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: genLoader1
                active: false
                source: container.genericSources[1]
                visible: container.genericIdx === 1
                opacity: container.genericIdx === 1 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: genLoader2
                active: false
                source: container.genericSources[2]
                visible: container.genericIdx === 2
                opacity: container.genericIdx === 2 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: genLoader3
                active: false
                source: container.genericSources[3]
                visible: container.genericIdx === 3
                opacity: container.genericIdx === 3 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            Loader {
                id: genLoader4

                active: true
                source: container.genericSources[4]
                visible: container.genericIdx === 4
                opacity: container.genericIdx === 4 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Loader {
                id: genLoader5
                active: false
                source: container.genericSources[5]
                visible: container.genericIdx === 5
                opacity: container.genericIdx === 5 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

            Loader {
                id: genLoader6

                active: true
                source: container.genericSources[6]
                visible: container.genericIdx === 6
                opacity: container.genericIdx === 6 ? 1 : 0
                anchors.fill: parent
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }

        }


        Rectangle {
            id: loadProgressBar
            anchors.left: container.left
            anchors.right: container.right
            anchors.bottom: content.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            anchors.bottomMargin: loadProgressBar.doneFading || !loadProgressBar.showReady ? -70 : 12
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
            height: 44
            radius: 10
            color: HusTheme.isDark ? '#E81E1B2E' : '#F5B8DCF8'
            border.color: HusTheme.isDark ? '#66455B7A' : '#B090B0C8'
            border.width: 2
            visible: opacity > 0.01 && container.genericIdx !== 4 && genLoader0.item && loadProgressBar.showReady
            opacity: (loadProgressBar.showReady && !loadProgressBar.doneFading) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
            z: 59

            property bool doneFading: false
            property bool showReady: false
            property real displayDone: 0
            property var homeItem: genLoader0.item


            Timer {
                id: showDelayTimer
                interval: 2000
                running: true
                onTriggered: {
                    loadProgressBar.showReady = true
                    loadProgressBar.displayDone = 0
                    catchUpTimer.start()
                }
            }


            Timer {
                id: catchUpTimer
                interval: 80
                repeat: true
                onTriggered: {
                    const real = genLoader0.item ? genLoader0.item.loadDone : 0
                    if (loadProgressBar.displayDone < real) {
                        loadProgressBar.displayDone = Math.min(real, loadProgressBar.displayDone + Math.max(1, real * 0.12))
                    }
                    if (genLoader0.item && genLoader0.item.allLoaded) {
                        loadProgressBar.displayDone = real
                        running = false
                    }
                }
            }


            Connections {
                target: genLoader0.item
                function onAllLoadedChanged() {
                    if (genLoader0.item && genLoader0.item.allLoaded)
                        fadeTimer.start()
                }
            }
            Timer {
                id: fadeTimer
                interval: 3000
                onTriggered: loadProgressBar.doneFading = true
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10


                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: '#2E7DB0'
                    Layout.alignment: Qt.AlignVCenter
                    SequentialAnimation on color {
                        loops: Animation.Infinite
                        running: !genLoader0.item || !genLoader0.item.allLoaded
                        ColorAnimation { to: '#2E7DB0'; duration: 500 }
                        ColorAnimation { to: '#6FB8E8'; duration: 500 }
                    }
                }


                HusText {
                    text: Lang.tr('加载服务器','Loading servers')
                    color: HusTheme.isDark ? '#FFFFFF' : '#1E3A5F'
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }


                Rectangle {
                    width: 1
                    height: 16
                    color: HusTheme.isDark ? '#408090B0' : '#50A0B8D8'
                    Layout.alignment: Qt.AlignVCenter
                }


                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    height: 16
                    radius: 8
                    color: HusTheme.isDark ? '#30FFFFFF' : '#50FFFFFF'
                    Layout.alignment: Qt.AlignVCenter
                    clip: true

                    Rectangle {
                        width: {
                            const total = genLoader0.item ? genLoader0.item.loadTotal : 0
                            return total > 0 ? (loadProgressBar.displayDone / total) * parent.width : 0
                        }
                        height: parent.height
                        color: '#4A7DB0'
                        radius: 8
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }

                    HusText {
                        anchors.centerIn: parent
                        text: {
                            const total = genLoader0.item ? genLoader0.item.loadTotal : 0
                            return Math.round(total > 0 ? (loadProgressBar.displayDone / total) * 100 : 0) + '%'
                        }
                        color: HusTheme.isDark ? '#F3F3F3' : '#1E2A3A'
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }


                HusText {
                    text: Lang.tr('正在加载 %1/%2 台服务器...','Loading %1/%2 servers...')
                          .arg(Math.round(loadProgressBar.displayDone))
                          .arg(genLoader0.item ? genLoader0.item.loadTotal : 0)
                    color: HusTheme.isDark ? '#F3F3F3' : '#1E2A3A'
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }


        Rectangle {
            id: squeezeStatusBar
            anchors.left: container.left
            anchors.right: container.right
            anchors.bottom: content.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16


            anchors.bottomMargin: SqueezeEngineObj.running ? 12 : -70
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            height: 44
            radius: 10
            color: '#C8B8DCF8'
            border.color: '#8090B0C8'
            border.width: 1
            visible: opacity > 0.01 && container.genericIdx !== 4
            opacity: SqueezeEngineObj.running ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            z: 60


            MouseArea {
                id: statusBarMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!SqueezeEngineObj.running)
                        return
                    const ip = String(SqueezeEngineObj.serverIp || '')
                    const port = SqueezeEngineObj.serverPort
                    if (!ip)
                        return
                    const loaders = container.allServerLoaders()
                    for (let i = 0; i < loaders.length; i++) {
                        const item = loaders[i].item
                        if (item && typeof item.serverHasIp === 'function' && item.serverHasIp(ip, port)) {
                            container.switchToSource(container.serverSources[i])
                            item.openSqueeze(ip + ':' + port, SqueezeEngineObj.serverName || '')
                            return
                        }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10


                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: '#D4A800'
                    Layout.alignment: Qt.AlignVCenter
                }


                HusText {
                    text: Lang.tr('正在挤服','Squeezing')
                    color: '#1E3A5F'
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignVCenter
                }


                Rectangle {
                    width: 1
                    height: 16
                    color: '#50A0B8D8'
                    Layout.alignment: Qt.AlignVCenter
                }


                HusText {
                    text: SqueezeEngineObj.serverName || '—'
                    color: '#1E2A3A'
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.minimumWidth: 60
                    Layout.alignment: Qt.AlignVCenter
                }


                HusText {
                    text: SqueezeEngineObj.mapName || '—'
                    color: '#3A4A60'
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.maximumWidth: 120
                    Layout.alignment: Qt.AlignVCenter
                }


                Rectangle {
                    width: 300
                    height: 16
                    radius: 8
                    color: '#50FFFFFF'
                    Layout.alignment: Qt.AlignVCenter
                    clip: true

                    Rectangle {
                        width: Math.min(1.0, SqueezeEngineObj.players / Math.max(1, SqueezeEngineObj.maxPlayers)) * parent.width
                        height: parent.height
                        color: '#4A7DB0'
                        radius: 8
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }

                    HusText {
                        anchors.centerIn: parent
                        text: SqueezeEngineObj.players + '/' + SqueezeEngineObj.maxPlayers
                        color: '#1E2A3A'
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }


                HusText {
                    text: Lang.tr('尝试 %1','Attempt %1').arg(Math.floor(SqueezeEngineObj.retryCount / 10) * 10)
                    color: '#3A4A6A'
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignVCenter
                }


                Rectangle {
                    width: 86
                    height: 32
                    radius: 7
                    color: cancelBtnMouse.containsMouse ? '#40CC0000' : '#25CC0000'
                    border.width: 1
                    border.color: cancelBtnMouse.containsMouse ? '#FFCC0000' : '#80CC0000'
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Layout.alignment: Qt.AlignVCenter

                    HusText {
                        anchors.centerIn: parent
                        text: Lang.tr('取消挤服','Stop')
                        color: '#FF8888'
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: cancelBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: SqueezeEngineObj.stop()
                    }
                }
            }
        }


        Window {
            id: squeezeBarFloatWindow
            objectName: 'squeezeBarFloatWindow'
            flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            transientParent: null
            color: 'transparent'

            x: galleryWindow.x + galleryMenu.width + 16
            y: galleryWindow.y + galleryWindow.height - 44 - 12
            width: Math.max(320, galleryWindow.width - galleryMenu.width - 32)
            height: 44
            visible: SqueezeEngineObj.running && container.genericIdx === 4
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            onVisibleChanged: {
                if (visible)
                    opacity = 1
                else
                    opacity = 0
            }

            Rectangle {
                anchors.fill: parent
                radius: 10

                color: HusTheme.isDark ? '#E81E1B2E' : '#C8B8DCF8'
                border.color: HusTheme.isDark ? '#66455B7A' : '#8090B0C8'
                border.width: 1


                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!SqueezeEngineObj.running)
                            return
                        const ip = String(SqueezeEngineObj.serverIp || '')
                        const port = SqueezeEngineObj.serverPort
                        if (!ip)
                            return
                        const loaders = container.allServerLoaders()
                        for (let i = 0; i < loaders.length; i++) {
                            const item = loaders[i].item
                            if (item && typeof item.serverHasIp === 'function' && item.serverHasIp(ip, port)) {
                                container.switchToSource(container.serverSources[i])
                                item.openSqueeze(ip + ':' + port, SqueezeEngineObj.serverName || '')
                                return
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10


                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: '#D4A800'
                        Layout.alignment: Qt.AlignVCenter
                    }


                    HusText {
                        text: Lang.tr('正在挤服','Squeezing')
                        color: HusTheme.isDark ? '#FFFFFF' : '#1E3A5F'
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                    }


                    Rectangle {
                        width: 1
                        height: 16
                        color: HusTheme.isDark ? '#408090B0' : '#50A0B8D8'
                        Layout.alignment: Qt.AlignVCenter
                    }


                    HusText {
                        text: SqueezeEngineObj.serverName || '—'
                        color: HusTheme.isDark ? '#F3F3F3' : '#1E2A3A'
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.minimumWidth: 60
                        Layout.alignment: Qt.AlignVCenter
                    }


                    HusText {
                        text: SqueezeEngineObj.mapName || '—'
                        color: HusTheme.isDark ? '#9BA1B5' : '#3A4A60'
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.maximumWidth: 120
                        Layout.alignment: Qt.AlignVCenter
                    }


                    Rectangle {
                        width: 300
                        height: 16
                        radius: 8
                        color: HusTheme.isDark ? '#30FFFFFF' : '#50FFFFFF'
                        Layout.alignment: Qt.AlignVCenter
                        clip: true

                        Rectangle {
                            width: Math.min(1.0, SqueezeEngineObj.players / Math.max(1, SqueezeEngineObj.maxPlayers)) * parent.width
                            height: parent.height
                            color: '#4A7DB0'
                            radius: 8
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }

                        HusText {
                            anchors.centerIn: parent
                            text: SqueezeEngineObj.players + '/' + SqueezeEngineObj.maxPlayers
                            color: HusTheme.isDark ? '#F3F3F3' : '#1E2A3A'
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }


                    HusText {
                        text: Lang.tr('尝试 %1','Attempt %1').arg(Math.floor(SqueezeEngineObj.retryCount / 10) * 10)
                        color: HusTheme.isDark ? '#9BA1B5' : '#3A4A6A'
                        font.pixelSize: 11
                        Layout.alignment: Qt.AlignVCenter
                    }


                    Rectangle {
                        width: 86
                        height: 32
                        radius: 7
                        color: cancelFloatBtnMouse.containsMouse ? '#40CC0000' : '#25CC0000'
                        border.width: 1
                        border.color: cancelFloatBtnMouse.containsMouse ? '#FFCC0000' : '#80CC0000'
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Layout.alignment: Qt.AlignVCenter

                        HusText {
                            anchors.centerIn: parent
                            text: Lang.tr('取消挤服','Stop')
                            color: '#FF8888'
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: cancelFloatBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: SqueezeEngineObj.stop()
                        }
                    }
                }
            }
        }
    }


    HusSwitchEffect {
        id: gallerySwitchEffect
        anchors.fill: container
        duration: 0
        type: HusSwitchEffect.Type_None
        maskScale: animationTime * 3
        maskRotation: (1.0 - animationTime) * 360

        function switchToSource(source) {
            if (container.source !== source)
                container.switchToSource(source)
        }
    }


    Window {
        id: closeChoiceWindow
        objectName: 'closeChoiceWindow'
        width: 360
        height: 214
        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        transientParent: null
        color: 'transparent'
        visible: false
        opacity: 0


        property bool squeezing: false

        property string pendingAction: ''

        function openDialog(sq) {
            squeezing = sq

            x = Math.round(galleryWindow.x + (galleryWindow.width - width) / 2)
            y = Math.round(galleryWindow.y + (galleryWindow.height - height) / 2)
            visible = true
            show()
            raise()
            maskFadeIn.start()
            cardPopIn.start()
        }

        function closeDialog(action) {
            pendingAction = action
            maskFadeOut.start()
            cardPopOut.start()
        }


        NumberAnimation {
            id: maskFadeIn
            target: closeChoiceWindow
            property: 'opacity'
            from: 0
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }


        NumberAnimation {
            id: maskFadeOut
            target: closeChoiceWindow
            property: 'opacity'
            from: 1
            to: 0
            duration: 160
            easing.type: Easing.InCubic
            onFinished: {
                closeChoiceWindow.visible = false
                if (closeChoiceWindow.pendingAction === 'tray')
                    galleryWindow.hide()
                else if (closeChoiceWindow.pendingAction === 'quit')
                    Qt.quit()
                closeChoiceWindow.pendingAction = ''
            }
        }

        Rectangle {
            id: closeChoiceCard
            width: parent.width
            height: parent.height
            radius: 14
            color: HusTheme.isDark ? '#E81E1B2E' : '#F2FFFFFF'
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)
            border.width: 1
            opacity: 0
            scale: 0.92


            ParallelAnimation {
                id: cardPopIn
                NumberAnimation {
                    target: closeChoiceCard
                    property: 'opacity'
                    from: 0
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: closeChoiceCard
                    property: 'scale'
                    from: 0.92
                    to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }


            ParallelAnimation {
                id: cardPopOut
                NumberAnimation {
                    target: closeChoiceCard
                    property: 'opacity'
                    from: 1
                    to: 0
                    duration: 150
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: closeChoiceCard
                    property: 'scale'
                    from: 1
                    to: 0.9
                    duration: 150
                    easing.type: Easing.InCubic
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                HusText {
                    width: parent.width
                    text: Lang.tr('关闭软件','Quit App')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }


                HusText {
                    width: parent.width
                    text: Lang.tr('你正在挤服确定关闭吗','Squeeze in progress. Close anyway?')
                    color: '#FF4D4F'
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    visible: closeChoiceWindow.squeezing
                }

                HusText {
                    width: parent.width
                    text: Lang.tr('请选择关闭方式：','Choose what to do on close:')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    visible: !closeChoiceWindow.squeezing
                }
            }


            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                width: 302
                spacing: 12

                HusButton {
                    width: 145
                    height: 35
                    text: Lang.tr('最小化到托盘','Minimize to Tray')

                    enabled: !closeChoiceWindow.squeezing
                    onClicked: closeChoiceWindow.closeDialog('tray')
                }

                HusButton {
                    width: 145
                    height: 35
                    text: Lang.tr('直接关闭','Exit App')
                    onClicked: closeChoiceWindow.closeDialog('quit')
                }
            }


            HusIconButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                iconSource: HusIcon.CloseOutlined
                iconSize: 14
                colorIcon: HusTheme.Primary.colorTextSecondary
                contentDescription: Lang.tr('关闭提示框','Close Dialog')
                onClicked: closeChoiceWindow.closeDialog('')
            }
        }
    }


    MouseArea {
        id: popupDismissLayer
        anchors.fill: parent
        z: 100000
        visible: (netWinObj && netWinObj.visible) || (historyWinObj && historyWinObj.visible)
        propagateComposedEvents: true
        onClicked: (mouse) => {
            if (netWinObj && netWinObj.visible)
                netWinObj.closePopup()
            if (historyWinObj && historyWinObj.visible)
                historyWinObj.closePopup()
            mouse.accepted = false
        }
    }
}
