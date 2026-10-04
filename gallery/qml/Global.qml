import QtQuick
import HuskarUI.Basic

QtObject {
    id: root

    property int themeIndex: 8
    property var primaryTokens: []
    property var componentTokens: new Object
    property var menus: []
    property var options: []
    property var updates: []
    property var galleryModel: [
        {
            key: 'HomeMain',
            label: Lang.tr('主页','Home'),
            iconSource: HusIcon.HomeOutlined,
            source: './Home/HomeMainPage.qml'
        },
        {
            type: 'divider'
        },
        {
            key: 'General',
            label: qsTr('通用'),
            iconSource: HusIcon.ProductOutlined,
            menuChildren: [
                {
                    key: 'HusWindow',
                    label: qsTr('HusWindow 无边框窗口'),
                    source: './Examples/General/ExpWindow.qml',
                    desc: qsTr('添加 setMacSystemButtonsVisible() 函数。\n更新 [SpecialEffect] 枚举值。')
                },
                {
                    key: 'HusButton',
                    label: qsTr('HusButton 按钮'),
                    source: './Examples/General/ExpButton.qml',
                    updateVersion: '0.7.0.0',
                    desc: qsTr('新增 borderBg 背景边框。')
                },
                {
                    key: 'HusIconButton',
                    label: qsTr('HusIconButton 图标按钮'),
                    source: './Examples/General/ExpIconButton.qml',
                    updateVersion: '0.5.2',
                    desc: qsTr('新增 iconFont 图标字体。\n新增 iconDelegate 图标代理。')
                },
                {
                    key: 'HusCaptionButton',
                    label: qsTr('HusCaptionButton 标题按钮'),
                    source: './Examples/General/ExpCaptionButton.qml',
                    desc: qsTr('一般用于窗口标题栏的按钮。')
                },
                {
                    key: 'HusIconText',
                    label: qsTr('HusIconText 图标文本'),
                    source: './Examples/General/ExpIconText.qml',
                    updateVersion: '0.4.6.0',
                    desc: qsTr('新增 empty 用于判断图标是否为空。\n新增 iconSource 支持内置图标和外部 url 链接。')
                },
                {
                    key: 'HusCopyableText',
                    label: qsTr('HusCopyableText 可复制文本'),
                    source: './Examples/General/ExpCopyableText.qml',
                    desc: qsTr('用于代替 Text 以提供可复制的文本。')
                },
                {
                    key: 'HusRectangle',
                    label: qsTr('HusRectangle 圆角矩形'),
                    source: './Examples/General/ExpRectangle.qml',
                    desc: qsTr('使用 HusRectangle 可以轻松实现任意四个对角方向上的圆角矩形。')
                },
                {
                    key: 'HusPopup',
                    label: qsTr('HusPopup 弹窗'),
                    source: './Examples/General/ExpPopup.qml',
                    desc: qsTr('代替内置 Popup 的弹出式窗口。')
                },
                {
                    key: 'HusText',
                    label: qsTr('HusText 文本'),
                    source: './Examples/General/ExpText.qml',
                    desc: qsTr('代替内置 Text 的来统一字体和文本。')
                },
                {
                    key: 'HusButtonBlock',
                    label: qsTr('HusButtonBlock 按钮块'),
                    source: './Examples/General/ExpButtonBlock.qml',
                    desc: qsTr('HusIconButton 的变体，用于将多个按钮组织成块，类似 HusRadioBlock。')
                },
                {
                    key: 'HusMoveMouseArea',
                    label: qsTr('HusMoveMouseArea 鼠标移动区域'),
                    source: './Examples/General/ExpMoveMouseArea.qml',
                    desc: qsTr('移动鼠标区域，提供对任意 Item 进行鼠标移动操作的区域。')
                },
                {
                    key: 'HusResizeMouseArea',
                    label: qsTr('HusResizeMouseArea 鼠标改变大小区域'),
                    source: './Examples/General/ExpResizeMouseArea.qml',
                    desc: qsTr('改变大小鼠标区域，提供对任意 Item 进行鼠标改变大小操作的区域。')
                },
                {
                    key: 'HusCaptionBar',
                    label: qsTr('HusCaptionBar 标题栏'),
                    source: './Examples/General/ExpCaptionBar.qml',
                    desc: qsTr('新增窗口额外按钮代理 winExtraButtonsDelegate。')
                },
                {
                    key: 'HusRadius',
                    label: qsTr('HusRadius 圆角半径'),
                    source: './Examples/General/ExpRadius.qml',
                    addVersion: '0.4.9.0',
                    desc: qsTr('提供四方向的圆角半径类型。')
                },
                {
                    key: 'HusLabel',
                    label: qsTr('HusLabel 文本标签'),
                    source: './Examples/General/ExpLabel.qml',
                    addVersion: '0.6.1.0',
                    desc: qsTr('新增 sizeHint 尺寸提示。')
                },
                {
                    key: 'HusFrame',
                    label: qsTr('HusFrame 框架'),
                    source: './Examples/General/ExpFrame.qml',
                    addVersion: '0.5.9.0',
                    desc: qsTr('逻辑控件组的视觉框架。')
                },
                {
                    key: 'HusPage',
                    label: qsTr('HusPage 页面'),
                    source: './Examples/General/ExpPage.qml',
                    addVersion: '0.5.9.0',
                    desc: qsTr('自导页眉和页脚项的基础页面。')
                },
                {
                    key: 'HusBorder',
                    label: qsTr('HusBorder 边框'),
                    source: './Examples/General/ExpBorder.qml',
                    addVersion: '0.7.0.0',
                    desc: qsTr('提供统一的边框类型。')
                },
            ]
        },
        {
            key: 'Server',
            label: Lang.tr('服务器','Servers'),
            iconSource: HusIcon.CloudServerOutlined,
            menuChildren: [
                {
                    key: 'exg',
                    label: Lang.tr('EXG社区','EXG'),
                    source: './Examples/Server/ExpServerList.qml'
                },
                {
                    key: 'zed',
                    label: Lang.tr('僵尸乐园','ZED'),
                    source: './Examples/Server/ExpServerListZed.qml'
                },
                {
                    key: 'ub',
                    label: Lang.tr('UB社区','moeUB'),
                    source: './Examples/Server/ExpServerListUb.qml'
                },
                {
                    key: 'fys',
                    label: Lang.tr('风云社','FYS'),
                    source: './Examples/Server/ExpServerListFys.qml'
                },
                {
                    key: 'upkk',
                    label: Lang.tr('UPKK/Zero','UPKK/Zero'),
                    source: './Examples/Server/ExpServerListUpkk.qml'
                },
                {
                    key: 'star',
                    label: Lang.tr('星社区','Star Community'),
                    source: './Examples/Server/ExpServerListStar.qml'
                },
                {
                    key: 'international',
                    label: Lang.tr('国际服','International'),
                    source: './Examples/Server/ExpServerListInternational.qml'
                },
                {
                    key: 'maprun',
                    label: Lang.tr('跑图服','Map Run'),
                    source: './Examples/Server/ExpServerListMapRun.qml'
                }
            ]
        },
        {
            key: 'Cooldown',
            label: Lang.tr('冷却查看','Cooldown'),
            shortLabel: Lang.isEn() ? 'Cool' : '',
            iconSource: HusIcon.ClockCircleOutlined,
            source: './Examples/Server/CooldownPage.qml'
        },
        {
            key: 'Subscription',
            label: Lang.tr('订阅列表','Subscriptions'),
            shortLabel: Lang.isEn() ? 'Subs' : '',
            iconSource: HusIcon.NotificationOutlined,
            source: './Examples/Server/SubscriptionPage.qml'
        },
        {
            key: 'Commands',
            label: Lang.tr('社区指令','Community Commands'),
            shortLabel: Lang.isEn() ? 'Cmds' : '',
            iconSource: HusIcon.CodeOutlined,
            menuChildren: [
                {
                    key: 'cmdlist',
                    label: Lang.tr('指令列表','Command List'),
                    source: './Examples/Server/CommandsListPage.qml'
                },
                {
                    key: 'cmdwheel',
                    label: Lang.tr('轮盘指令','Radial Wheel'),
                    source: './Examples/Server/RadialWheelPage.qml'
                }
            ]
        },
        {
            key: 'Workshop',
            label: Lang.tr('创意工坊','Workshop'),
            shortLabel: Lang.isEn() ? 'Works' : '',
            iconSource: HusIcon.GiftOutlined,
            source: './Examples/Server/WorkshopPage.qml'
        },
        {


            key: 'CommunityNav',
            label: Lang.tr('导航社区','Community Links'),
            shortLabel: Lang.isEn() ? 'Links' : '',
            iconSource: HusIcon.GlobalOutlined,
            keepOrder: true,
            menuChildren: [
                { key: 'navZed',  label: 'ZED',  externalUrl: 'https://zombieden.cn/' },
                { key: 'navExg',  label: 'EXG',  externalUrl: 'https://darkrp.cn/' },
                { key: 'navUb',   label: 'UB',   externalUrl: 'https://cs.moeub.cn/' },
                { key: 'navFys',  label: 'FYS',  externalUrl: 'https://fyscs.cn/' },
                { key: 'navStar', label: Lang.tr('星社区','Star Community'), externalUrl: 'https://www.starcs.cn/' },
                { key: 'navUpkk', label: 'UPKK', externalUrl: 'https://bbs.upkk.com/' },
                { key: 'navZero', label: 'ZERO', externalUrl: 'https://bbs.cszero.cn/' },
                { key: 'navGfl',  label: 'GFL',  externalUrl: 'https://gflclan.com/' }
            ]
        },
        {
            key: 'Browser',
            label: Lang.tr('网页菜单','Web Menu'),
            shortLabel: Lang.isEn() ? 'Web' : '',
            iconSource: 'qrc:/Gallery/images/monitor.svg',
            source: './Examples/Server/BrowserPage.qml'
        }
    ]

    function buildMenus() {
        
        for (const token in HusTheme.Primary) {
            primaryTokens.push({ label: `@${token}` });
        }
        
        const indexFile = `:/HuskarUI/resources/theme/Index.json`;
        const indexObject = JSON.parse(HusApi.readFileToString(indexFile));
        for (const source in indexObject.__component__) {
            const __style__ = {};
            const parseImport = (name) => {
                const path = `:/HuskarUI/resources/theme/${name}.json`;
                const fileContent = HusApi.readFileToString(path);
                if (!fileContent) {
                    console.warn("Failed to read file:", path);
                    return;
                }
                const object = JSON.parse(fileContent);
                const imports = object?.__init__?.__import__;
                const style = object.__style__;
                if (imports) {
                    imports.forEach(i => parseImport(i));
                }
                for (const token in style) {
                    __style__[token] = style[token];
                }
            }
            parseImport(source);

            const list = [];
            for (const token in __style__) {
                list.push({
                              'tokenName': token,
                              'tokenValue': {
                                  'token': token,
                                  'value': __style__[token],
                                  'rawValue': __style__[token],
                              },
                              'tokenCalcValue': token,
                          });
            }
            componentTokens[source] = list;
        }

        
        let __menus = [], __options = [], __updates = [];
        for (let item of galleryModel) {

            if (item.key === 'HomePage' || item.key === 'OverviewPage' || item.key === 'General')
                continue;
            if (item.type === 'divider') {

                if (__menus.length === 0)
                    continue;
                __menus.push(item);
                continue;
            }
            if (item && item.menuChildren) {
                let hasNew = false;
                let hasUpdate = false;



                if (item.key === 'Server') {
                    const order = (appSettings.serverOrder || '').split(',').filter(Boolean);
                    const hidden = (appSettings.serverHidden || '').split(',').filter(Boolean);
                    let children = item.menuChildren.slice();
                    if (order.length > 0) {
                        children = children.slice().sort((a, b) => {
                            const ia = order.indexOf(a.key);
                            const ib = order.indexOf(b.key);
                            if (ia < 0 && ib < 0) return 0;
                            if (ia < 0) return 1;
                            if (ib < 0) return -1;
                            return ia - ib;
                        });
                    }
                    children = children.filter(o => hidden.indexOf(o.key) < 0);
                    item = Object.assign({}, item, { menuChildren: children });
                } else if (!item.keepOrder) {

                    item.menuChildren.sort((a, b) => a.key.localeCompare(b.key));
                }
                item.menuChildren.forEach(
                            object => {
                                object.state = object.addVersion ? 'New' : object.updateVersion ? 'Update' : '';

                                if (object.externalUrl)
                                    object.keepCurrent = true;
                                if (object.state) {
                                    if (object.state === 'New') hasNew = true;
                                    if (object.state === 'Update') hasUpdate = true;
                                }


                                if (object.label && !object.externalUrl) {
                                    __options.push({
                                                       'key': object.key,
                                                       'value': object.key,
                                                       'label': object.label,
                                                       'state': object.state,
                                                   });
                                    __updates.push({
                                                       'name': object.key,
                                                       'desc': object.desc ?? '',
                                                       'tagState': object.state,
                                                       'version': object.addVersion || object.updateVersion || '',
                                                   });
                                }
                            });
                if (hasNew)
                    item.badgeState = 'New';
                else
                    item.badgeState = hasUpdate ? 'Update' : '';
            }
            __menus.push(item);
        }



        const navOrder = (appSettings.navOrder || '').split(',').filter(Boolean);
        if (navOrder.length > 0) {
            const pinned = [];
            const rest = [];
            for (const m of __menus) {
                if (m.key === 'HomeMain' || m.type === 'divider')
                    pinned.push(m);
                else
                    rest.push(m);
            }
            rest.sort((a, b) => {
                const ia = navOrder.indexOf(a.key);
                const ib = navOrder.indexOf(b.key);
                if (ia < 0 && ib < 0) return 0;
                if (ia < 0) return 1;
                if (ib < 0) return -1;
                return ia - ib;
            });
            __menus = pinned.concat(rest);
        }
        menus = __menus;
        options = __options.sort((a, b) => a.key.localeCompare(b.key));
        updates = __updates.sort(
                    (a, b) => {
                        const parts1 = a.version.split('.').map(Number);
                        const parts2 = b.version.split('.').map(Number);
                        for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
                            const num1 = parts1[i] || 0;
                            const num2 = parts2[i] || 0;

                            if (num1 > num2) return -1;
                            if (num1 < num2) return 1;
                        }
                        return 0;
                    });
    }

    Component.onCompleted: {
        buildMenus();
    }
}
