import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic



Rectangle {
    id: browserPage
    anchors.fill: parent
    color: 'transparent'

    property bool browserInitialized: false
    property bool needReset: false

    onVisibleChanged: {
        if (visible) {

            resetTimer.stop()
            if (!browserInitialized || needReset) {

                needReset = false
                browserInitTimer.start()
            } else {

                showTimer.start()
            }
        } else {

            browserInitTimer.stop()
            showTimer.stop()
            BrowserControllerObj.hideBrowserWindow()
            resetTimer.start()
        }
    }


    Timer {
        id: resetTimer
        interval: 80000
        repeat: false
        onTriggered: {
            needReset = true
            BrowserControllerObj.detachBrowser()
            browserInitialized = false
        }
    }


    Timer {
        id: browserInitTimer
        interval: 350
        repeat: false
        onTriggered: {

            if (appSettings.webMenuExternal) {
                Qt.openUrlExternally(appSettings.webMenuUrl)
                browserInitialized = true
                return
            }
            BrowserControllerObj.embedBrowser(browserPlaceholder)
            var url = appSettings.webMenuUrl
            if (BrowserControllerObj.webMenuCommunity === 1) url = 'https://cs.moeub.cn/inventory'
            if (BrowserControllerObj.webMenuCommunity === 2) url = 'https://bbs.upkk.com/plugin.php?id=xnet_steam_store_client_items:cs2_store_item_equip'
            BrowserControllerObj.browserNavigate(url)
            browserInitialized = true
            BrowserControllerObj.updateBrowserGeometry()
        }
    }


    Timer {
        id: showTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (appSettings.webMenuExternal) return
            BrowserControllerObj.showBrowserWindow()
            BrowserControllerObj.updateBrowserGeometry()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10


        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            HusText {
                text: Lang.tr('网页菜单','Web Menu')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true; height: 1 }
            HusText {
                text: Lang.tr('ctrl+滚轮调整缩放 | 离开菜单 80 秒恢复默认网页','Ctrl+scroll to zoom | Default page returns after 80s away')
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 11
            }
        }


        RowLayout {
            Layout.fillWidth: true
            spacing: 6


            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 30
                radius: 8
                color: backMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: backMouse.containsMouse ? HusTheme.Primary.colorPrimary : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: '\u2190'; color: HusTheme.Primary.colorTextBase; font.pixelSize: 14 }
                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BrowserControllerObj.browserGoBack() }
            }


            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 30
                radius: 8
                color: fwdMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: fwdMouse.containsMouse ? HusTheme.Primary.colorPrimary : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { anchors.centerIn: parent; text: '\u2192'; color: HusTheme.Primary.colorTextBase; font.pixelSize: 14 }
                MouseArea { id: fwdMouse; anchors.fill: parent; hoverEnabled: true; onClicked: BrowserControllerObj.browserGoForward() }
            }


            Rectangle {

                Layout.preferredWidth: Math.max(60, refreshText.implicitWidth + 24)
                Layout.minimumWidth: Layout.preferredWidth
                Layout.preferredHeight: 30
                radius: 8
                color: refreshMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: refreshMouse.containsMouse ? HusTheme.Primary.colorPrimary : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { id: refreshText; anchors.centerIn: parent; text: Lang.tr('刷新','Refresh'); color: HusTheme.Primary.colorTextBase; font.pixelSize: 12 }
                MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (appSettings.webMenuExternal) Qt.openUrlExternally(appSettings.webMenuUrl); else BrowserControllerObj.browserReload() } }
            }


            Rectangle {

                Layout.preferredWidth: Math.max(84, resetText.implicitWidth + 24)
                Layout.minimumWidth: Layout.preferredWidth
                Layout.preferredHeight: 30
                radius: 8
                color: resetMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22) : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: resetMouse.containsMouse ? HusTheme.Primary.colorPrimary : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { id: resetText; anchors.centerIn: parent; text: Lang.tr('恢复默认','Restore Default'); color: HusTheme.Primary.colorTextBase; font.pixelSize: 12 }
                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (appSettings.webMenuExternal)
                            Qt.openUrlExternally(appSettings.webMenuUrl)
                        else
                            BrowserControllerObj.browserNavigate(appSettings.webMenuUrl)
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 8
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: urlInput.activeFocus ? HusTheme.Primary.colorPrimary : Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.188)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id: urlInput
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 11
                    placeholderText: Lang.tr('输入网址后回车访问','Enter URL and press Enter')
                    placeholderTextColor: HusTheme.Primary.colorTextSecondary
                    background: Item {}
                    onAccepted: {
                        var t = urlInput.text.trim()
                        if (t.length === 0) return
                        if (!/^https?:\/\//i.test(t)) t = 'https://' + t
                        if (appSettings.webMenuExternal)
                            Qt.openUrlExternally(t)
                        else
                            BrowserControllerObj.browserNavigate(t)
                        urlInput.focus = false
                    }
                }


                Connections {
                    target: BrowserControllerObj
                    function onBrowserUrlChanged(url) {
                        if (!urlInput.activeFocus)
                            urlInput.text = url
                    }
                }
            }
        }


        Item {
            id: browserPlaceholder
            Layout.fillWidth: true
            Layout.fillHeight: true
            onXChanged: if (browserPage.visible) BrowserControllerObj.updateBrowserGeometry()
            onYChanged: if (browserPage.visible) BrowserControllerObj.updateBrowserGeometry()
            onWidthChanged: if (browserPage.visible) BrowserControllerObj.updateBrowserGeometry()
            onHeightChanged: if (browserPage.visible) BrowserControllerObj.updateBrowserGeometry()

            Rectangle {
                anchors.fill: parent
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                border.width: 1
                border.color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.30)

                visible: !appSettings.webMenuExternal && !BrowserControllerObj.browserEmbedded
                Text {
                    anchors.centerIn: parent
                    text: Lang.tr('浏览器加载中...','Browser loading...')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 14
                }
            }
            Rectangle {
                anchors.fill: parent
                color: 'transparent'
                border.width: 2
                border.color: Qt.rgba(HusTheme.Primary.colorPrimary.r, HusTheme.Primary.colorPrimary.g, HusTheme.Primary.colorPrimary.b, 0.55)
                z: 1
            }
        }
    }
}
