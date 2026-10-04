import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import HuskarUI.Basic

import '../Controls'

HusWindow {
    id: root

    width: 620
    height: 600
    minimumWidth: 620
    minimumHeight: 600
    captionBar.showMinimizeButton: false
    captionBar.showMaximizeButton: false
    captionBar.winTitle: Lang.tr('设置','Settings')
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
    captionBar.closeCallback: () => settingsLoader.visible = false;


    property bool updateAvailable: UpdateChecker.hasUpdate
    property string latestVersion: UpdateChecker.latestVersion
    property bool downloadFailed: false
    property string downloadError: ""
    property int updateCooldown: 0


    Component.onCompleted: {
        if (UpdateChecker.hasUpdate) {
            updateAvailable = true
            latestVersion = UpdateChecker.latestVersion
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: updateCooldown > 0
        onTriggered: updateCooldown--
    }

    Connections {
        target: UpdateChecker
        function onUpdateAvailable(version, notes) {
            updateAvailable = true
            latestVersion = version
            downloadFailed = false
        }
        function onUpToDate() {
            updateAvailable = false
            downloadFailed = false
        }
        function onCheckFailed(error) {
            downloadFailed = true
            downloadError = error
        }
    }

    Item {
        anchors.fill: parent

        HusShadow {
            anchors.fill: backRect
            source: backRect
        }

        Rectangle {
            id: backRect
            anchors.fill: parent
            radius: 6
            color: HusTheme.Primary.colorBgBase
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.2)
        }

        Item {
            anchors.fill: parent

            GradientFlowEffect {
                anchors.fill: parent
                opacity: 0.5
            }
        }

        component MySlider: RowLayout {
            height: 30
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 20

            property alias label: __label
            property alias slider: __slider
            property bool showScale: false

            HusText {
                id: __label

                Layout.preferredWidth: Math.max(HusTheme.Primary.fontPrimarySize * 6, __label.implicitWidth)
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Loader {
                    width: parent.width
                    active: showScale
                    sourceComponent: Item {
                        Row {
                            anchors.top: parent.top
                            anchors.topMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: (parent.width - 14 - ((__repeater.count - 1) * 4)) / (__repeater.count - 1)

                            Repeater {
                                id: __repeater
                                model: Math.round((__slider.max - __slider.min) / __slider.stepSize) + 1
                                delegate: Rectangle {
                                    width: 4
                                    height: 6
                                    radius: 2
                                    color: __slider.colorBg

                                    HusText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.bottom
                                        anchors.topMargin: 8
                                        text: (__slider.stepSize) * index + __slider.min
                                    }
                                }
                            }
                        }
                    }
                }

                HusSlider {
                    id: __slider
                    anchors.fill: parent
                    min: 0.0
                    max: 1.0
                    stepSize: 0.1
                }
            }
        }

        component SettingsItem: Item {
            id: settingsItem
            width: parent.width
            height: column.height

            property string title: value
            property Component itemDelegate: Item { }

            Column {
                id: column
                width: parent.width
                spacing: 10

                HusText {
                    text: settingsItem.title
                }

                Rectangle {
                    width: parent.width
                    height: itemLoader.height + 40
                    radius: 6
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgBase, 0.6)
                    border.color: HusTheme.Primary.colorFillPrimary

                    Loader {
                        id: itemLoader
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 20
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: settingsItem.itemDelegate
                    }
                }
            }
        }


        FileDialog {
            id: bgFileDialog
            title: Lang.tr('选择背景图片','Choose Background Image')
            nameFilters: [ Lang.tr('图片文件 (*.jpg *.jpeg *.png *.webp *.bmp)','Image files (*.jpg *.jpeg *.png *.webp *.bmp)') ]
            onAccepted: {
                var url = BackgroundFileManager.importBackground(selectedFile);
                if (url) {
                    appSettings.customBackground = url;
                    galleryBackground.bgSource = url;
                }
            }
        }

        Flickable {
            anchors.fill: parent
            anchors.topMargin: root.captionBar.height
            anchors.bottomMargin: 20
            clip: true
            contentHeight: contentColumn.height
            ScrollBar.vertical: HusScrollBar {
                anchors.right: parent.right
                anchors.rightMargin: 5
            }

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.right: parent.right
                anchors.rightMargin: 20
                spacing: 20

                SettingsItem {
                    title: Lang.tr('常规设置','General Settings')
                    itemDelegate: Column {
                        spacing: 10

                        MySlider {
                            id: bgOpacitySlider
                            label.text: Lang.tr('背景透明度','Background Opacity')
                            slider.value: galleryBackground.opacity
                            slider.snapMode: HusSlider.SnapOnRelease
                            slider.onFirstMoved: {
                                galleryBackground.opacity = slider.currentValue;
                                appSettings.bgOpacity = slider.currentValue;
                            }
                            slider.handleToolTipDelegate: HusToolTip {
                                showArrow: true
                                delay: 100
                                text: bgOpacitySlider.slider.currentValue.toFixed(1)
                                visible: handlePressed || handleHovered
                            }
                        }

                        MySlider {
                            label.text: Lang.tr('圆角大小','Corner Radius')
                            slider.min: 0
                            slider.max: 24
                            slider.stepSize: 2
                            slider.value: HusTheme.Primary.radiusPrimary
                            slider.snapMode: HusSlider.SnapAlways
                            slider.onFirstReleased: {
                                HusTheme.installThemePrimaryRadiusBase(slider.currentValue);
                            }
                            showScale: true
                        }


                        RowLayout {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: bgPathField
                                Layout.fillWidth: true
                                height: 28
                                readOnly: true
                                selectByMouse: true
                                text: appSettings.customBackground !== ''
                                      ? appSettings.customBackground
                                      : Lang.tr('使用默认背景','Use Default Background')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                            }

                            HusButton {
                                text: Lang.tr('自定义背景','Custom Background')
                                onClicked: bgFileDialog.open()
                            }

                            HusButton {
                                text: Lang.tr('恢复','Restore')
                                onClicked: {
                                    BackgroundFileManager.resetDefault();
                                    appSettings.customBackground = '';
                                    galleryBackground.bgSource = '';
                                }
                            }
                        }

                        HusText {
                            width: parent.width
                            text: Lang.tr('自定义背景图将保存到配置文件夹，重启后仍然生效','Custom background is saved to the config folder and still applies after restart.')
                            color: HusTheme.Primary.colorTextTertiary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                    }
                }


                SettingsItem {
                    title: Lang.tr('窗口效果','Window Effects')
                    itemDelegate: Column {
                        spacing: 10

                        ButtonGroup { id: specialEffectGroup }

                        Repeater {
                            delegate: HusRadio {
                                property int effectValue: modelData.value
                                text: modelData.label
                                ButtonGroup.group: specialEffectGroup
                                onClicked: {
                                    if (galleryWindow.setSpecialEffect(modelData.value)) {
                                        appSettings.windowEffect = modelData.value;
                                    } else {
                                        for (let i = 0; i < specialEffectGroup.buttons.length; i++) {
                                            specialEffectGroup.buttons[i].checked =
                                                specialEffectGroup.buttons[i].effectValue === galleryWindow.specialEffect;
                                        }
                                    }
                                }
                                Component.onCompleted: {
                                    checked = galleryWindow.specialEffect === modelData.value;
                                }
                            }
                            Component.onCompleted: {
                                if (Qt.platform.os === 'windows'){
                                    model = [
                                                { 'label': Lang.tr('无','None'), 'value': HusWindow.None },
                                                { 'label': Lang.tr('模糊','Blur'), 'value': HusWindow.Win_DwmBlur }
                                            ];
                                } else if (Qt.platform.os === 'osx') {
                                    model = [
                                                { 'label': Lang.tr('无','None'), 'value': HusWindow.None },
                                                { 'label': Lang.tr('模糊','Blur'), 'value': HusWindow.Mac_BlurEffect },
                                            ];
                                }
                            }
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('应用主题','App Theme')
                    itemDelegate: Column {
                        spacing: 10

                        ButtonGroup { id: themeGroup }

                        Repeater {
                            model: [
                                { 'label': Lang.tr('浅色','Light'), 'value': HusTheme.Light },
                                { 'label': Lang.tr('深色','Dark'), 'value': HusTheme.Dark },
                                { 'label': Lang.tr('跟随系统','Match System'), 'value': HusTheme.System }
                            ]
                            delegate: HusRadio {
                                id: darkModeRadio
                                text: modelData.label
                                ButtonGroup.group: themeGroup
                                onClicked: {
                                    appSettings.themeMode = modelData.value;
                                    HusTheme.darkMode = modelData.value;
                                }
                                Component.onCompleted: {
                                    checked = HusTheme.darkMode === modelData.value;
                                }

                                Connections {
                                    target: HusTheme
                                    function onDarkModeChanged() {
                                        darkModeRadio.checked = HusTheme.darkMode === modelData.value;
                                    }
                                }
                            }
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('导航模式','Navigation Mode')
                    itemDelegate: HusRadioBlock {
                        id: navMode
                        model: [
                            { label: Lang.tr('宽松','Comfortable'), value: HusMenu.Mode_Relaxed },
                            { label: Lang.tr('标准','Standard'), value: HusMenu.Mode_Standard },
                            { label: Lang.tr('紧凑','Compact'), value: HusMenu.Mode_Compact }
                        ]
                        onClicked:
                            (index, radioData) => {
                                galleryMenu.compactMode = radioData.value;
                                appSettings.navMode = radioData.value;
                            }
                        Component.onCompleted: {
                            currentCheckedIndex = galleryMenu.compactMode;
                        }

                        Connections {
                            target: galleryMenu
                            function onCompactModeChanged() {
                                navMode.currentCheckedIndex = galleryMenu.compactMode;
                            }
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('关闭选择','Close Behavior')
                    itemDelegate: Column {
                        spacing: 10

                        ButtonGroup { id: closeBehaviorGroup }

                        Repeater {
                            model: [
                                { label: Lang.tr('最小化到托盘','Minimize to Tray'), value: 0 },
                                { label: Lang.tr('直接关闭','Exit App'), value: 1 },
                                { label: Lang.tr('始终询问','Always Ask'), value: 2 }
                            ]
                            delegate: HusRadio {
                                text: modelData.label
                                ButtonGroup.group: closeBehaviorGroup
                                onClicked: appSettings.closeBehavior = modelData.value
                                Component.onCompleted: {
                                    checked = appSettings.closeBehavior === modelData.value;
                                }
                            }
                        }

                        HusText {
                            width: parent.width
                            text: Lang.tr('始终询问：每次点击关闭按钮时弹窗选择关闭方式','Always ask: a dialog appears each time you click Close to choose how to close.')
                            color: HusTheme.Primary.colorTextTertiary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('挤服设置','Squeeze Settings')
                    itemDelegate: Column {
                        spacing: 10

                        ButtonGroup { id: squeezeProtocolGroup }

                        Repeater {
                            model: [
                                { label: Lang.tr('steam://connect/IP:端口','steam://connect/IP:Port'), value: 0 },
                                { label: Lang.tr('steam://run/730//+connect IP:端口','steam://run/730//+connect IP:Port'), value: 1 }
                            ]
                            delegate: HusRadio {
                                text: modelData.label
                                ButtonGroup.group: squeezeProtocolGroup
                                onClicked: {
                                    appSettings.squeezeProtocol = modelData.value;
                                }
                                Component.onCompleted: {
                                    checked = appSettings.squeezeProtocol === modelData.value;
                                }
                            }
                        }

                        HusText {
                            width: parent.width
                            text: Lang.tr('选择连接方式：前者直接进入服务器，后者附带启动参数连接','Connection type: the first joins directly; the second adds launch parameters.')
                            color: HusTheme.Primary.colorTextTertiary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }


                        Rectangle {
                            width: parent.width
                            height: 28
                            color: joinToastRowMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.08) : 'transparent'
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    id: joinToastCheck
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: appSettings.joinToastEnabled ? HusTheme.Primary.colorPrimary : 'transparent'
                                    border.width: 1
                                    border.color: appSettings.joinToastEnabled ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorBorder
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: '\u2713'
                                        color: '#FFFFFF'
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        visible: appSettings.joinToastEnabled
                                    }
                                }

                                HusText {
                                    text: Lang.tr('右下角加入服务器悬浮框','Bottom-right join-server popup')
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: joinToastRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appSettings.joinToastEnabled = !appSettings.joinToastEnabled
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 28
                            color: floatWindowRowMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.08) : 'transparent'
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    id: floatWindowCheck
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: appSettings.floatWindowEnabled ? HusTheme.Primary.colorPrimary : 'transparent'
                                    border.width: 1
                                    border.color: appSettings.floatWindowEnabled ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorBorder
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: '\u2713'
                                        color: '#FFFFFF'
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        visible: appSettings.floatWindowEnabled
                                    }
                                }

                                HusText {
                                    text: Lang.tr('右下角挤服状态悬浮框','Bottom-right squeeze status popup')
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: floatWindowRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appSettings.floatWindowEnabled = !appSettings.floatWindowEnabled
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 28
                            color: intervalLimitRowMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.08) : 'transparent'
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8


                                Rectangle {
                                    id: intervalLimitCheck
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: appSettings.intervalLimitEnabled ? HusTheme.Primary.colorPrimary : 'transparent'
                                    border.width: 1
                                    border.color: appSettings.intervalLimitEnabled ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorBorder
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: '\u2713'
                                        color: '#FFFFFF'
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        visible: appSettings.intervalLimitEnabled
                                    }
                                }

                                HusText {
                                    text: Lang.tr('开启0.01-49.00间隔限制','Enable 0.01-49.00 interval limit')
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: intervalLimitRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appSettings.intervalLimitEnabled) {

                                        appSettings.intervalLimitEnabled = false
                                    } else {

                                        squeezePwdField.text = ''
                                        squeezePwdError.visible = false
                                        squeezeLimitDialog.visible = true
                                        squeezePwdField.forceActiveFocus()
                                    }
                                }
                            }
                        }


                        Row {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: defaultIntervalField
                                width: 90
                                height: 28
                                text: appSettings.defaultInterval
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                validator: IntValidator { bottom: 1; top: 9999 }
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    let v = parseInt(text) || 100;

                                    v = Math.max(50, Math.min(500, v));
                                    text = v;
                                    appSettings.defaultInterval = v;
                                }
                            }

                            HusText {
                                text: Lang.tr('默认间隔(ms)','Default Interval (ms)')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }


                        Row {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: defaultThresholdField
                                width: 90
                                height: 28
                                text: appSettings.defaultThreshold
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                validator: IntValidator { bottom: 1; top: 9999 }
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    let v = parseInt(text) || 63;

                                    v = Math.max(20, Math.min(63, v));
                                    text = v;
                                    appSettings.defaultThreshold = v;
                                }
                            }

                            HusText {
                                text: Lang.tr('默认人数','Default Players')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }


                        Row {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: defaultCoreField
                                width: 90
                                height: 28
                                text: appSettings.defaultCoreCount
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                validator: IntValidator { bottom: 1; top: 9999 }
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    let v = parseInt(text) || 2;

                                    v = Math.max(1, Math.min(4, v));
                                    text = v;
                                    appSettings.defaultCoreCount = v;
                                }
                            }

                            HusText {
                                text: Lang.tr('默认核心','Default Cores')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }



                        RowLayout {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: configDirField
                                Layout.fillWidth: true
                                readOnly: true
                                height: 28
                                text: ConfigDir
                                color: HusTheme.Primary.colorPrimary
                                font.pixelSize: 12
                                font.family: 'Consolas'
                                background: Rectangle {
                                    radius: 6
                                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)
                                    border.width: 1
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally('file:///' + ConfigDir)
                                }
                            }

                            HusText {
                                text: Lang.tr('配置文件夹','Config Folder')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('通知音效','Notification Sound')
                    itemDelegate: Column {
                        spacing: 10

                        FileDialog {
                            id: soundFileDialog
                            title: Lang.tr('选择通知音效文件','Choose Notification Sound File')
                            currentFolder: SystemSound.yinpinDirUrl
                            nameFilters: [
                                Lang.tr('音频文件 (*.wav *.mp3 *.ogg *.m4a *.flac *.aac)','Audio files (*.wav *.mp3 *.ogg *.m4a *.flac *.aac)'),
                                Lang.tr('所有文件 (*.*)','All files (*.*)')
                            ]
                            onAccepted: {
                                var p = SystemSound.importCustomSound(selectedFile);
                                if (p) {
                                    SystemSound.playCustom();
                                }
                            }
                        }


                        RowLayout {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: soundPathField
                                Layout.fillWidth: true
                                height: 28
                                readOnly: true
                                selectByMouse: true
                                text: SystemSound.customSoundPath !== ''
                                      ? SystemSound.customSoundPath
                                      : Lang.tr('使用 Windows 系统通知音效','Use Windows system notification sound')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                            }

                            HusButton {
                                text: Lang.tr('选择','Browse')
                                onClicked: soundFileDialog.open()
                            }

                            HusButton {
                                text: Lang.tr('试听','Preview')
                                enabled: SystemSound.customSoundPath !== ''
                                onClicked: SystemSound.playCustom()
                            }

                            HusButton {
                                text: Lang.tr('恢复','Restore')
                                onClicked: SystemSound.resetCustomSound()
                            }
                        }


                        RowLayout {
                            height: 30
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: 12

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                HusSlider {
                                    id: soundVolumeSlider
                                    anchors.fill: parent
                                    min: 0
                                    max: 100
                                    stepSize: 5
                                    value: SystemSound.volume
                                    snapMode: HusSlider.SnapOnRelease
                                    onFirstMoved: {
                                        SystemSound.volume = currentValue;
                                    }
                                    handleToolTipDelegate: HusToolTip {
                                        showArrow: true
                                        delay: 100
                                        text: soundVolumeSlider.currentValue.toFixed(0)
                                        visible: handlePressed || handleHovered
                                    }
                                }
                            }

                            HusText {
                                text: soundVolumeSlider.currentValue.toFixed(0) + '%'
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                            }

                            HusText {
                                text: Lang.tr('音量大小','Volume')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                            }
                        }

                        HusText {
                            width: parent.width
                            text: Lang.tr('自定义音效将复制保存到配置文件夹，订阅地图/更新提醒/挤服成功等通知均使用该音效','Custom sounds are copied to the config folder; subscription, update and squeeze-success notifications all use them.')
                            color: HusTheme.Primary.colorTextTertiary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                    }
                }


                SettingsItem {
                    title: Lang.tr('网页设置','Web Settings')
                    itemDelegate: Column {
                        spacing: 10


                        RowLayout {
                            width: parent.width
                            spacing: 8

                            TextField {
                                id: webMenuUrlField
                                Layout.fillWidth: true
                                height: 28
                                text: appSettings.webMenuUrl
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                background: Rectangle {
                                    radius: 6
                                    color: HusTheme.Primary.colorBgContainer
                                    border.color: HusTheme.Primary.colorBorder
                                    border.width: 1
                                }
                                onEditingFinished: {
                                    var t = text.trim()

                                    if (t.length === 0) {
                                        appSettings.webMenuUrl = 'https://list.darkrp.cn:6514/'
                                        text = appSettings.webMenuUrl
                                        return
                                    }
                                    if (!/^https?:\/\//i.test(t))
                                        t = 'https://' + t
                                    text = t
                                    appSettings.webMenuUrl = t
                                }
                            }

                            HusText {
                                text: Lang.tr('打开时网址','Default URL')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }


                        Rectangle {
                            width: parent.width
                            height: 28
                            color: webExtRowMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.08) : 'transparent'
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    id: webExtCheck
                                    width: 16
                                    height: 16
                                    radius: 4
                                    color: appSettings.webMenuExternal ? HusTheme.Primary.colorPrimary : 'transparent'
                                    border.width: 1
                                    border.color: appSettings.webMenuExternal ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorBorder
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: '\u2713'
                                        color: '#FFFFFF'
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        visible: appSettings.webMenuExternal
                                    }
                                }

                                HusText {
                                    text: Lang.tr('用外部浏览器打开','Open in external browser')
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: webExtRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: appSettings.webMenuExternal = !appSettings.webMenuExternal
                            }
                        }
                    }
                }

                SettingsItem {
                    title: Lang.tr('排版设置','Layout Settings')
                    itemDelegate: Row {
                        width: parent.width
                        spacing: 24


                        Column {
                            id: navLayoutCol
                            width: 224
                            spacing: 8

                            HusText {
                                width: parent.width
                                text: Lang.tr('导航栏排序','Navigation Order')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            HusText {
                                width: parent.width
                                text: Lang.tr('主页固定在最前，不可调整；点击即时生效','Home is pinned first; changes apply instantly.')
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }

                            ListModel {
                                id: navLayoutModel
                            }

                            function initNavLayout() {
                                navLayoutModel.clear()
                                var order = (appSettings.navOrder || '').split(',').filter(Boolean)
                                var defs = [
                                    { key: 'HomeMain',     label: Lang.tr('主页','Home'),                 locked: true },
                                    { key: 'Server',       label: Lang.tr('服务器','Servers') },
                                    { key: 'Cooldown',     label: Lang.tr('冷却查看','Cooldown') },
                                    { key: 'Subscription', label: Lang.tr('订阅列表','Subscriptions') },
                                    { key: 'Commands',     label: Lang.tr('社区指令','Community Commands') },
                                    { key: 'Workshop',     label: Lang.tr('创意工坊','Workshop') },
                                    { key: 'CommunityNav', label: Lang.tr('导航社区','Community Links') },
                                    { key: 'Browser',      label: Lang.tr('网页菜单','Web Menu') }
                                ]
                                var sorted = defs.slice()
                                if (order.length > 0) {
                                    sorted.sort(function(a, b) {
                                        if (a.locked) return -1
                                        if (b.locked) return 1
                                        var ia = order.indexOf(a.key)
                                        var ib = order.indexOf(b.key)
                                        if (ia < 0 && ib < 0) return 0
                                        if (ia < 0) return 1
                                        if (ib < 0) return -1
                                        return ia - ib
                                    })
                                }
                                for (var j = 0; j < sorted.length; j++) {
                                    navLayoutModel.append({
                                        key: sorted[j].key,
                                        label: sorted[j].label,
                                        locked: sorted[j].locked === true
                                    })
                                }
                            }

                            function saveNavLayout() {
                                var order = []
                                for (var i = 0; i < navLayoutModel.count; i++) {
                                    if (!navLayoutModel.get(i).locked)
                                        order.push(navLayoutModel.get(i).key)
                                }
                                appSettings.navOrder = order.join(',')
                                galleryGlobal.buildMenus()
                                console.log('[NavLayout] saved order=' + appSettings.navOrder)
                            }

                            Component.onCompleted: initNavLayout()

                            Repeater {
                                model: navLayoutModel
                                delegate: Row {
                                    width: parent.width
                                    spacing: 8

                                    Rectangle {
                                        width: 150
                                        height: 28
                                        radius: 6
                                        color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, model.locked ? 0.06 : 0.14)
                                        border.width: 1
                                        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, model.locked ? 0.14 : 0.3)

                                        HusText {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: model.label
                                            color: model.locked ? HusTheme.Primary.colorTextTertiary : HusTheme.Primary.colorTextBase
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    HusText {
                                        width: 52
                                        height: 28
                                        visible: model.locked
                                        text: Lang.tr('固定','Fixed')
                                        color: HusTheme.Primary.colorTextTertiary
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 6
                                        visible: !model.locked
                                        color: navUpMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                        HusText {
                                            anchors.centerIn: parent
                                            text: '\u25B2'
                                            color: HusTheme.Primary.colorPrimary
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: navUpMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (index > 1) {
                                                    navLayoutModel.move(index, index - 1, 1)
                                                    navLayoutCol.saveNavLayout()
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 6
                                        visible: !model.locked
                                        color: navDownMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                        HusText {
                                            anchors.centerIn: parent
                                            text: '\u25BC'
                                            color: HusTheme.Primary.colorPrimary
                                            font.pixelSize: 11
                                        }
                                        MouseArea {
                                            id: navDownMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (index < navLayoutModel.count - 1) {
                                                    navLayoutModel.move(index, index + 1, 1)
                                                    navLayoutCol.saveNavLayout()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }


                        Column {
                            id: serverLayoutCol
                            width: 300
                            spacing: 8

                            HusText {
                                width: parent.width
                                text: Lang.tr('服务器排序','Server Order')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            HusText {
                                width: parent.width
                                text: Lang.tr('8 个社区的显示顺序与显隐','Order and visibility of the 8 communities.')
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 11
                                wrapMode: Text.Wrap
                            }

                        ListModel {
                            id: layoutModel
                        }

                        function initLayout() {
                            layoutModel.clear()
                            var order = (appSettings.serverOrder || '').split(',').filter(Boolean)
                            var hidden = (appSettings.serverHidden || '').split(',').filter(Boolean)
                            var defs = [
                                { key: 'exg', label: Lang.tr('EXG社区','EXG Community') },
                                { key: 'zed', label: Lang.tr('僵尸乐园','Zombie Eden') },
                                { key: 'ub', label: Lang.tr('UB社区','UB Community') },
                                { key: 'fys', label: Lang.tr('风云社','FYS') },
                                { key: 'upkk', label: 'UPKK/Zero' },
                                { key: 'star', label: Lang.tr('星社区','Star Community') },
                                { key: 'international', label: Lang.tr('国际服','International') },
                                { key: 'maprun', label: Lang.tr('跑图服','Map Run') }
                            ]
                            var sorted = []
                            for (var i = 0; i < defs.length; i++) sorted.push(defs[i])
                            if (order.length > 0) {
                                sorted.sort(function(a, b) {
                                    var ia = order.indexOf(a.key)
                                    var ib = order.indexOf(b.key)
                                    if (ia < 0 && ib < 0) return 0
                                    if (ia < 0) return 1
                                    if (ib < 0) return -1
                                    return ia - ib
                                })
                            }
                            for (var j = 0; j < sorted.length; j++) {
                                layoutModel.append({ key: sorted[j].key, label: sorted[j].label, visible: hidden.indexOf(sorted[j].key) < 0 })
                            }
                        }

                        function saveLayout() {
                            var order = []
                            var hidden = []
                            for (var i = 0; i < layoutModel.count; i++) {
                                order.push(layoutModel.get(i).key)
                                if (!layoutModel.get(i).visible) hidden.push(layoutModel.get(i).key)
                            }
                            appSettings.serverOrder = order.join(',')
                            appSettings.serverHidden = hidden.join(',')
                            galleryGlobal.buildMenus()
                        }

                        Component.onCompleted: initLayout()

                        Repeater {
                            model: layoutModel
                            delegate: Row {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    width: 140
                                    height: 28
                                    radius: 6
                                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, model.visible ? 0.14 : 0.05)
                                    border.width: 1
                                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, model.visible ? 0.3 : 0.12)

                                    HusText {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.label
                                        color: model.visible ? HusTheme.Primary.colorTextBase : HusTheme.Primary.colorTextTertiary
                                        font.pixelSize: 12
                                        font.weight: model.visible ? Font.DemiBold : Font.Normal
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: upMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                    HusText {
                                        anchors.centerIn: parent
                                        text: '\u25B2'
                                        color: HusTheme.Primary.colorPrimary
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: upMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (index > 0) {
                                                layoutModel.move(index, index - 1, 1)
                                                serverLayoutCol.saveLayout()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 6
                                    color: downMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                    HusText {
                                        anchors.centerIn: parent
                                        text: '\u25BC'
                                        color: HusTheme.Primary.colorPrimary
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        id: downMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (index < layoutModel.count - 1) {
                                                layoutModel.move(index, index + 1, 1)
                                                serverLayoutCol.saveLayout()
                                            }
                                        }
                                    }
                                }

                                Item { width: 6; height: 1 }

                                Rectangle {
                                    width: 66
                                    height: 28
                                    radius: 6
                                    color: visMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.12)
                                    HusText {
                                        anchors.centerIn: parent
                                        text: model.visible ? Lang.tr('显示','Show') : Lang.tr('隐藏','Hide')
                                        color: model.visible ? HusTheme.Primary.colorPrimary : HusTheme.Primary.colorTextTertiary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        id: visMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            layoutModel.setProperty(index, 'visible', !model.visible)
                                            serverLayoutCol.saveLayout()
                                        }
                                    }
                                }
                            }
                        }
                        }
                    }
                }


                SettingsItem {
                    title: Lang.tr('语言设置','Language Settings')
                    itemDelegate: Column {
                        spacing: 10

                        ButtonGroup { id: langGroup }

                        HusRadio {

                            text: '中文'
                            ButtonGroup.group: langGroup
                            checked: Lang.language === 'zh'
                            onClicked: Lang.language = 'zh'
                        }
                        Row {
                            spacing: 6
                            HusRadio {
                                text: 'English'
                                ButtonGroup.group: langGroup
                                checked: Lang.language === 'en'
                                onClicked: Lang.language = 'en'
                            }
                            HusText {
                                text: Lang.tr('[Ai翻译可能出现翻译不准问题]','[AI translation may be inaccurate]')
                                color: HusTheme.Primary.colorTextTertiary
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }


                SettingsItem {
                    title: Lang.tr('新版本查看','Check Updates')
                    itemDelegate: Column {
                        spacing: 10

                        RowLayout {
                            width: parent.width
                            spacing: 8
                            HusText {
                                text: Lang.tr('检查更新','Check Updates')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                id: checkUpdateBtn
                                width: 110
                                height: 32
                                radius: 8
                                color: (UpdateChecker.checking || updateCooldown > 0) ? '#40606070' : (checkUpdateMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.5) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25))
                                border.width: 1
                                border.color: (UpdateChecker.checking || updateCooldown > 0) ? '#606070' : (checkUpdateMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.375))
                                scale: checkUpdateMouse.pressed ? 0.95 : 1.0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                MouseArea {
                                    id: checkUpdateMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!UpdateChecker.checking && updateCooldown <= 0) {
                                            UpdateChecker.checkForUpdate()
                                            updateCooldown = 20
                                        }
                                    }
                                }
                                HusText {
                                    anchors.centerIn: parent
                                    text: UpdateChecker.checking ? Lang.tr('检查中...','Checking...') : (updateCooldown > 0 ? Lang.tr('冷却中','On cooldown ') + updateCooldown + Lang.tr('秒','s') : Lang.tr('检查更新','Check Updates'))
                                    color: '#FFFFFF'
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        HusText {
                            text: Lang.tr('当前版本: v','Current version: v') + UpdateChecker.displayVersion
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 12
                        }

                        RowLayout {
                            width: parent.width
                            visible: updateAvailable
                            spacing: 8
                            HusText {
                                text: Lang.tr('发现新版本: v','New version found: v') + latestVersion
                                color: HusTheme.Primary.colorPrimary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                id: downloadBtn
                                width: 100
                                height: 32
                                radius: 8
                                color: downloadBtnMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.5) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
                                border.width: 1
                                border.color: downloadBtnMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.375)
                                scale: downloadBtnMouse.pressed ? 0.95 : 1.0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                MouseArea {
                                    id: downloadBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: UpdateChecker.downloadUpdate(UpdateChecker.downloadUrl)
                                }
                                HusText {
                                    anchors.centerIn: parent
                                    text: Lang.tr('下载更新','Download Update')
                                    color: '#FFFFFF'
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        HusText {
                            visible: downloadFailed
                            width: parent.width
                            text: Lang.tr('检查/下载失败: ','Check/Download failed: ') + downloadError
                            color: '#ff4757'
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        HusText {
                            visible: updateAvailable
                            width: parent.width
                            text: Lang.tr('发现新版本，点击按钮打开浏览器下载。下载完手动替换旧版 exe 即可，所有配置保存在配置文件夹。','New version found; click the button to download via browser. Replace the old exe manually; all settings stay in the config folder.')
                            color: HusTheme.Primary.colorPrimary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }


    Rectangle {
        id: squeezeLimitDialog
        visible: false
        anchors.fill: parent
        z: 1000
        color: '#66000000'

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 190
            radius: 12
            color: HusTheme.Primary.colorBgContainer
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
            border.width: 1

            Column {
                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 12

                HusText {
                    width: parent.width
                    text: Lang.tr('开启 0.01-49.00 间隔限制','Enable 0.01-49.00 interval limit')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: squeezePwdField
                    width: parent.width
                    height: 32
                    echoMode: TextInput.Password
                    placeholderText: Lang.tr('请输入密码','Enter Password')
                    placeholderTextColor: HusTheme.Primary.colorTextTertiary
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 13
                    background: Rectangle {
                        radius: 6
                        color: HusTheme.Primary.colorBgContainer
                        border.color: HusTheme.Primary.colorBorder
                        border.width: 1
                    }
                    onAccepted: squeezeLimitConfirm.clicked()
                }

                HusText {
                    id: squeezePwdError
                    visible: false
                    width: parent.width
                    text: Lang.tr('密码错误','Wrong Password')
                    color: '#e74c3c'
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    width: parent.width
                    spacing: 10

                    HusButton {
                        id: squeezeLimitConfirm
                        width: (parent.width - 10) / 2
                        text: Lang.tr('确认','Confirm')
                        onClicked: {
                            if (squeezePwdField.text === '114514') {
                                appSettings.intervalLimitEnabled = true
                                squeezeLimitDialog.visible = false
                            } else {
                                squeezePwdError.visible = true
                            }
                        }
                    }

                    HusButton {
                        width: (parent.width - 10) / 2
                        text: Lang.tr('取消','Cancel')
                        onClicked: {
                            squeezeLimitDialog.visible = false

                        }
                    }
                }
            }
        }
    }
}
