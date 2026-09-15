import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: parent ? parent.width : 800
    height: header.height + (expanded ? contentHeight : 0)
    radius: 10
    color: "#401E1B2E"
    border.width: 1
    border.color: "#25A78BFA"
    clip: true
    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    property bool expanded: false
    property bool fillMode: false
    property int contentHeight: 320
    property string searchText: ""
    property bool copyFeedback: false

    
    property bool detailVisible: false
    property var detailCmd: null

    
    property var selectedCmd: null
    property string bindKey: ""

    readonly property var allCommands: [
        { cat: "枪械类", name: "mp9 [MP9]", cmd: "mp9;c_mp9;ms_mp9;sm_mp9" },
        { cat: "枪械类", name: "mp7 [MP7]", cmd: "mp7;c_mp7;ms_mp7;sm_mp7" },
        { cat: "枪械类", name: "mac10 [MAC-10]", cmd: "mac10;c_mac10;ms_mac10;sm_mac10" },
        { cat: "枪械类", name: "p90 [P90]", cmd: "p90;c_p90;ms_p90;sm_p90" },
        { cat: "枪械类", name: "mp5sd [MP5-SD]", cmd: "mp5sd;c_mp5sd;ms_mp5sd;sm_mp5sd" },
        { cat: "枪械类", name: "bizon [野牛]", cmd: "bizon;c_bizon;ms_bizon;sm_bizon" },
        { cat: "枪械类", name: "m249 [M249]", cmd: "m249;c_m249;ms_m249;sm_m249" },
        { cat: "枪械类", name: "negev [内格夫]", cmd: "negev;c_negev;ms_negev;sm_negev" },
        { cat: "枪械类", name: "ak47 [AK-47]", cmd: "ak47;c_ak47;ms_ak47;sm_ak47" },
        { cat: "枪械类", name: "m4a4 [M4A4]", cmd: "m4a4;c_m4a4;ms_m4a4;sm_m4a4" },
        { cat: "枪械类", name: "m4a1 [M4A1]", cmd: "m4a1;c_m4a1;ms_m4a1;sm_m4a1" },
        { cat: "枪械类", name: "famas [法玛斯]", cmd: "famas;c_famas;ms_famas;sm_famas" },
        { cat: "枪械类", name: "sg556 [SG556]", cmd: "sg556;c_sg556;ms_sg556;sm_sg556" },
        { cat: "枪械类", name: "aug [AUG]", cmd: "aug;c_aug;ms_aug;sm_aug" },
        { cat: "枪械类", name: "galilar [加利尔]", cmd: "galilar;c_galilar;ms_galilar;sm_galilar" },
        { cat: "枪械类", name: "nova [新星]", cmd: "nova;c_nova;ms_nova;sm_nova" },
        { cat: "枪械类", name: "xm1014 [XM1014]", cmd: "xm1014;c_xm1014;ms_xm1014;sm_xm1014" },
        { cat: "枪械类", name: "sawedoff [截短霰弹]", cmd: "sawedoff;c_sawedoff;ms_sawedoff;sm_sawedoff" },
        { cat: "枪械类", name: "mag7 [MAG-7]", cmd: "mag7;c_mag7;ms_mag7;sm_mag7" },
        { cat: "枪械类", name: "ssg08 [鸟狙]", cmd: "ssg08;c_ssg08;ms_ssg08;sm_ssg08" },
        { cat: "枪械类", name: "awp [大狙]", cmd: "awp;c_awp;ms_awp;sm_awp" },
        { cat: "枪械类", name: "g3sg1 [G3SG1]", cmd: "g3sg1;c_g3sg1;ms_g3sg1;sm_g3sg1" },
        { cat: "枪械类", name: "scar20 [SCAR-20]", cmd: "scar20;c_scar20;ms_scar20;sm_scar20" },
        { cat: "枪械类", name: "deagle [沙漠之鹰]", cmd: "deagle;c_deagle;ms_deagle;sm_deagle" },
        { cat: "枪械类", name: "revolver [左轮手枪]", cmd: "revolver;c_revolver;ms_revolver;sm_revolver" },
        { cat: "枪械类", name: "glock [格洛克]", cmd: "glock;c_glock;ms_glock;sm_glock" },
        { cat: "枪械类", name: "elite [双持贝瑞塔]", cmd: "elite;c_elite;ms_elite;sm_elite" },
        { cat: "枪械类", name: "usp_sliencer [USP-S]", cmd: "usp_sliencer;c_usp_sliencer;ms_usp_sliencer;sm_usp_sliencer" },
        { cat: "枪械类", name: "p250 [P250]", cmd: "p250;c_p250;ms_p250;sm_p250" },
        { cat: "枪械类", name: "cz75a [CZ75]", cmd: "cz75a;c_cz75a;ms_cz75a;sm_cz75a" },
        { cat: "道具类", name: "he [高爆手雷]", cmd: "!he;.he;sm_he | say !he" },
        { cat: "道具类", name: "smokegrenade [烟雾弹]", cmd: "!smokegrenade;ms_smokegrenade | buy !smokegrenade" },
        { cat: "道具类", name: "molotov [燃烧弹]", cmd: "!molotov;ms_molotov | say !molotov" },
        { cat: "道具类", name: "flashbang [闪光弹]", cmd: "!flashbang;ms_flashbang | buy !flashbang" },
        { cat: "道具类", name: "dec [EXG电圈雷]", cmd: "!dec;ms_dec;.dec | buy !dec" },
        { cat: "道具类", name: "ice [ZED冰冻雷]", cmd: "c_ice;!ice;ms_ice | c_ice" },
        { cat: "道具类", name: "kevlar [护甲]", cmd: "kevlar;c_kevlar;ms_kevlar;sm_kevlar" },
        { cat: "道具类", name: "xz [血针]", cmd: "!xz;c_xz;ms_health;sm_xz | xz;c_xz;ms_health;sm_xz" },
        { cat: "道具类", name: "hx25 [EXG榴弹发射器]", cmd: ".hx25;!hx25 | hx25" },
        { cat: "道具类", name: "m249xm [EXG霰弹机枪]", cmd: ".m249xm;!m249xm | m249xm" },
        { cat: "游戏其他", name: "bet [EXG装备切换]", cmd: "bet ct 1 2 3;bet t 1 2 3;bet ct <装备名字> | bet ct 1" },
        { cat: "游戏其他", name: "hidename [队友名字距离]", cmd: "!hidename | hidename 9999" },
        { cat: "游戏其他", name: "fullbright [夜视仪]", cmd: "ms_toggle mat_fullbright | toggle mat_fullbright" },
        { cat: "游戏其他", name: "enable [地图滤镜]", cmd: "ms_toggle r_csgo_postprocess_enable | toggle r_csgo_postprocess_enable" },
        { cat: "游戏其他", name: "drawparticles [地图特效]", cmd: "ms_toggle r_drawparticles | toggle r_drawparticles" },
        { cat: "游戏其他", name: "ztele [回到出生点]", cmd: "!ztele;ms_ztele;c_ztele | !ztele" },
        { cat: "游戏其他", name: "stop [停止晃动1秒]", cmd: "ms_shake_stop | +lookatweapon;shake_stop" },
        { cat: "游戏其他", name: "thirdperson [第三人称灵魂出窍]", cmd: "cl_allow_multi_input_binds true\nc_thirdpersonshoulder 0;cam_idealyaw 0;cam_idealpitch 0;cam_collision 1\nc_mindistance -999999;c_maxdistance 999999\nalias cam_settings \"cam_idealyaw 0;cam_idealpitch 0;c_thirdpersonshoulder 0;c_thirdpersonshoulderheight 6;c_thirdpersonshoulderoffset 0;c_thirdpersonshoulderaimdist 0;cam_idealdist 0;\"\nalias \"cs_aliasthird\" \"thirdperson;cam_settings;alias cs_chasecam cs_aliasfirst\"\nalias \"cs_aliasfirst\" \"firstperson;alias cs_chasecam cs_aliasthird\"\nalias \"cs_chasecam\" \"cs_aliasthird\"\nbind \"KEY\" \"+tp_magnifier\"\nalias +tp_magnifier \"cs_chasecam;bind_zoomin;bind_zoomout;cam_collision 0\"\nalias -tp_magnifier \"cs_chasecam;bind_normal1;bind_normal2\"\nalias bind_zoomin \"bind MWHEELUP incrementvar cam_idealdist -999999 999999 -100\"\nalias bind_zoomout \"bind MWHEELDOWN incrementvar cam_idealdist -999999 999999 100\"\nalias bind_normal1 \"bind MWHEELUP +jump\"\nalias bind_normal2 \"bind MWHEELDOWN +jump\"", inlineBind: true },
        { cat: "游戏其他", name: "mayamode [第三人称固定视角]", cmd: "ms_thirdperson_mayamode | thirdperson_mayamode" },
        { cat: "游戏其他", name: "absbox [标记实体]", cmd: "cl_ent_absbox" },
        { cat: "游戏其他", name: "hidew [EXG白名单开关]", cmd: "!hidew | hidew" },
        { cat: "游戏其他", name: "hide [隐藏距离]", cmd: "!hide | hide" },
        { cat: "游戏其他", name: "menu [HUD菜单]", cmd: ".menu;!menu;ms_menu;c_menu", noBind: true },
        { cat: "游戏其他", name: "white [添加白名单]", cmd: "!white <名字>;ms_white;c_white", noBind: true },
        { cat: "游戏其他", name: "showpos [显示速度坐标]", cmd: "cl_showpos 1" },
        { cat: "游戏其他", name: "musicvolume [背景音乐调节]", cmd: "snd_musicvolume 0.5" },
        { cat: "游戏其他", name: "voipvolume [语音音量调节]", cmd: "snd_voipvolume 1", noBind: true },
        { cat: "游戏其他", name: "hidebody[隐藏腿部模型]", cmd: "say !hidebody | !hidebody;c_hidebody;ms_hidebody;sm_hidebody" },
        { cat: "作弊指令", name: "cheats [开启作弊]", cmd: "sv_cheats 1" },
        { cat: "作弊指令", name: "noclip [穿墙飞行]", cmd: "noclip" },
        { cat: "作弊指令", name: "restartgame [重启回合]", cmd: "mp_restartgame 1" },
        { cat: "作弊指令", name: "win_conditions [禁用胜利]", cmd: "mp_ignore_round_win_conditions 1" },
        { cat: "作弊指令", name: "roundtime [回合60分钟]", cmd: "mp_roundtime 60" },
        { cat: "作弊指令", name: "roundtime_defuse [竞技60分钟]", cmd: "mp_roundtime_defuse 60" },
        { cat: "作弊指令", name: "warmup_end [结束热身]", cmd: "mp_warmup_end" },
        { cat: "作弊指令", name: "freezetime [冻结0秒]", cmd: "mp_freezetime 0" },
        { cat: "作弊指令", name: "maxrounds [总回合50]", cmd: "mp_maxrounds 50" },
        { cat: "作弊指令", name: "respawn_ct [CT复活]", cmd: "mp_respawn_on_death_ct 1" },
        { cat: "作弊指令", name: "respawn_t [T复活]", cmd: "mp_respawn_on_death_t 1" },
        { cat: "作弊指令", name: "respawnwavetime_ct [CT复活3秒]", cmd: "mp_respawnwavetime_ct 3" },
        { cat: "作弊指令", name: "respawnwavetime_t [T复活3秒]", cmd: "mp_respawnwavetime_t 3" },
        { cat: "作弊指令", name: "limitteams [阵营人数关闭]", cmd: "mp_limitteams 0" },
        { cat: "作弊指令", name: "autoteambalance [队伍平衡关闭]", cmd: "mp_autoteambalance 0" },
        { cat: "作弊指令", name: "autokick [防被踢]", cmd: "mp_autokick 0" },
        { cat: "作弊指令", name: "friendlyfire [友军伤害关闭]", cmd: "mp_friendlyfire 0" },
        { cat: "作弊指令", name: "solid_teammates [穿过队友]", cmd: "mp_solid_teammates 0" },
        { cat: "作弊指令", name: "buytime [购买时间无限]", cmd: "mp_buytime 99999" },
        { cat: "作弊指令", name: "buy_anywhere [任意地点购买]", cmd: "mp_buy_anywhere 1" },
        { cat: "作弊指令", name: "maxmoney [金钱上限99999]", cmd: "mp_maxmoney 99999" },
        { cat: "作弊指令", name: "startmoney [开局金钱99999]", cmd: "mp_startmoney 99999" },
        { cat: "作弊指令", name: "infinite_ammo [备弹无限]", cmd: "sv_infinite_ammo 2" },
        { cat: "作弊指令", name: "drop_knife [解锁丢刀]", cmd: "mp_drop_knife_enable 1" },
        { cat: "作弊指令", name: "death_drop_grenade [死亡不掉投掷物]", cmd: "mp_death_drop_grenade 0" },
        { cat: "作弊指令", name: "grenade_limit [投掷物上限5]", cmd: "ammo_grenade_limit_total 5" },
        { cat: "作弊指令", name: "weapons_glow [掉落武器高亮]", cmd: "mp_weapons_glow_on_ground 1" },
        { cat: "作弊指令", name: "nospread [跑跳无后坐力]", cmd: "weapon_accuracy_nospread 1" },
        { cat: "作弊指令", name: "t_default_grenades [T开局手雷火瓶]", cmd: "mp_t_default_grenades \"weapon_hegrenade weapon_molotov\"" },
        { cat: "作弊指令", name: "ct_default_grenades [CT开局手雷燃烧弹]", cmd: "mp_ct_default_grenades \"weapon_hegrenade weapon_incgrenade\"" },
        { cat: "作弊指令", name: "free_armor [出生自带全甲]", cmd: "mp_free_armor 2" },
        { cat: "作弊指令", name: "falldamage [免摔伤害]", cmd: "sv_falldamage_scale 0" },
        { cat: "作弊指令", name: "regeneration [自动回血]", cmd: "sv_regeneration_force_on 1" },
        { cat: "作弊指令", name: "buddha [锁血1血]", cmd: "buddha 1" },
        { cat: "作弊指令", name: "buddha_reset_hp [锁血回100000]", cmd: "buddha_reset_hp 100000" },
        { cat: "作弊指令", name: "endround [快速结束本局]", cmd: "endround" },
        { cat: "作弊指令", name: "getpos [获得坐标]", cmd: "getpos" },
        { cat: "作弊指令", name: "host_timescale [游戏加速]", cmd: "host_timescale 5" },
        { cat: "作弊指令", name: "sv_alltalk [语音互通]", cmd: "sv_alltalk 1" },
        { cat: "作弊指令", name: "airaccelerate [自动连跳]", cmd: "sv_autobunnyhopping 1;sv_enablebunnyhopping 1;sv_airaccelerate 500" },
        { cat: "作弊指令", name: "give [生成枪械]", cmd: "give weapon_ak47" },
        { cat: "作弊指令", name: "collisions[显示碰到的空气墙]", cmd: "sv_show_move_collisions 1" },
        { cat: "游戏启动项", name: "-novid [禁用开场动画]", cmd: "-novid" },
        { cat: "游戏启动项", name: "-high [进程优先运行]", cmd: "-high" },
        { cat: "游戏启动项", name: "-nojoy [禁用手柄]", cmd: "-nojoy" },
        { cat: "游戏启动项", name: "-fullscreen [全屏模式]", cmd: "-fullscreen" },
        { cat: "游戏启动项", name: "-windowed [窗口模式]", cmd: "-windowed" },
        { cat: "游戏启动项", name: "-w -h [指定分辨率]", cmd: "-w 1920 -h 1080" },
        { cat: "游戏启动项", name: "-freq [刷新率HZ]", cmd: "-freq 240" },
        { cat: "游戏启动项", name: "-language [界面语言]", cmd: "-language english" },
        { cat: "游戏启动项", name: "+fps_max [帧率限制]", cmd: "+fps_max 300" },
        { cat: "游戏启动项", name: "-perfectworld [国服启动]", cmd: "-perfectworld" },
        { cat: "游戏启动项", name: "-worldwide [国际服启动]", cmd: "-worldwide" },
        { cat: "游戏启动项", name: "+cl_forcepreload [强制预加载]", cmd: "+cl_forcepreload 1" },
        { cat: "游戏启动项", name: "-autoconfig [重置默认值启动]", cmd: "-autoconfig" },
        { cat: "游戏启动项", name: "+exec [启动指定CFG]", cmd: "+exec autoexec.cfg" },
        { cat: "游戏启动项", name: "-allow_third_party_software [允许OBS注入]", cmd: "-allow_third_party_software" },
        { cat: "游戏启动项", name: "-threads [手动CPU线程数]", cmd: "-threads 8" },
        { cat: "游戏启动项", name: "-vulkan [Vulkan图形API]", cmd: "-vulkan" },
        { cat: "游戏启动项", name: "-insecure [禁用VAC]", cmd: "-insecure" },
        { cat: "游戏启动项", name: "-console [启动自动开控制台]", cmd: "-console" },
        { cat: "游戏启动项", name: "-noreflex [禁用NVIDIA Reflex]", cmd: "-noreflex" },
        { cat: "游戏启动项", name: "+violence_hblood [删除暴力元素]", cmd: "+violence_hblood 0" },
        { cat: "游戏启动项", name: "-d3d9ex [启用Direct3D 9Ex]", cmd: "-d3d9ex" },
        { cat: "游戏启动项", name: "-no-browser [禁止加载浏览器]", cmd: "-no-browser" },
        { cat: "游戏启动项", name: "+mat_queue_mode 2 [多核处理]", cmd: "+mat_queue_mode 2" },
        { cat: "游戏启动项", name: "+cl_cmdrate [接收速率]", cmd: "+cl_cmdrate 128" },
        { cat: "游戏启动项", name: "+cl_updaterate [发送速率]", cmd: "+cl_updaterate 128" }
    ]

    readonly property var categories: ["枪械类", "道具类", "游戏其他", "作弊指令", "游戏启动项"]

    readonly property var filteredCommands: {
        if (searchText === "") return allCommands
        var s = searchText.toLowerCase()
        return allCommands.filter(function(c) {
            return c.name.toLowerCase().indexOf(s) >= 0 || c.cmd.toLowerCase().indexOf(s) >= 0 || c.cat.toLowerCase().indexOf(s) >= 0
        })
    }

    function copyCmd(text) {
        if (text && text.length > 0) appController.copyToClipboard(text)
    }

    function useBindFormat(cmdObj) {
        if (!cmdObj || cmdObj.noBind || cmdObj.inlineBind) return false
        return cmdObj.cat === "枪械类" || cmdObj.cat === "道具类" || cmdObj.cat === "游戏其他"
    }

    function formatDetailCmd(cmdObj) {
        if (!cmdObj) return ""
        if (!useBindFormat(cmdObj)) return cmdObj.cmd
        var variants = cmdObj.cmd.split("|")
        var lines = []
        for (var i = 0; i < variants.length; i++) {
            var v = variants[i].trim()
            if (v.length > 0) lines.push("bind \"xxx\" \"" + v + "\"")
        }
        return lines.join("\n")
    }

    function generateBindText(cmdObj, key) {
        if (!cmdObj || !key || key.trim().length === 0) return ""
        if (cmdObj.cat === "游戏启动项" || cmdObj.noBind) return ""
        if (cmdObj.inlineBind) {
            return cmdObj.cmd.replace(/\"KEY\"/g, "\"" + key + "\"")
        }
        var firstVariant = cmdObj.cmd.split("|")[0].trim()
        return "bind \"" + key + "\" \"" + firstVariant + "\""
    }

    function isBindable(cmdObj) {
        return cmdObj && cmdObj.cat !== "游戏启动项" && !cmdObj.noBind
    }

    
    Rectangle {
        id: header
        width: parent.width
        height: root.fillMode ? 0 : 40
        opacity: root.fillMode ? 0 : 1
        color: "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8
            Canvas {
                width: 10; height: 10
                anchors.verticalCenter: parent.verticalCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.fillStyle = "#A78BFA"
                    ctx.beginPath(); ctx.arc(5, 5, 3, 0, Math.PI * 2); ctx.fill()
                }
            }
            Text {
                text: "社区指令"
                color: "#E0D6F0"
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
            }
            Text {
                text: expanded ? "∧" : "∨"
                color: "#8B7BA8"
                font.pixelSize: 14
                Behavior on rotation { NumberAnimation { duration: 200 } }
                rotation: expanded ? 180 : 0
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: expanded = !expanded
        }
    }

    
    Item {
        id: contentArea
        width: parent.width
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        clip: true
        opacity: (root.fillMode || expanded) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        ColumnLayout {
            width: parent.width
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: 10
                color: "#501E1B2E"
                border.width: 1
                border.color: root.selectedCmd ? "#40A78BFA" : "#252D3245"
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    
                    ColumnLayout {
                        Layout.preferredWidth: 100
                        Layout.minimumWidth: 100
                        Layout.maximumWidth: 100
                        spacing: 2
                        Text {
                            text: "绑定按键"
                            color: "#8B9BA8"
                            font.pixelSize: 9
                        }
                        TextField {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 26
                            placeholderText: "如 F1"
                            placeholderTextColor: "#5A6A8A"
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.family: "Consolas"
                            font.bold: true
                            selectByMouse: true
                            text: root.bindKey
                            onTextChanged: root.bindKey = text
                            background: Rectangle {
                                color: "#30000000"
                                radius: 5
                                border.width: 1
                                border.color: root.bindKey.length > 0 ? "#50A78BFA" : "#303D4555"
                            }
                        }
                    }

                    
                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 1
                        Layout.maximumWidth: 1
                        Layout.preferredHeight: 28
                        color: "#20A78BFA"
                    }

                    
                    ColumnLayout {
                        Layout.preferredWidth: 150
                        Layout.minimumWidth: 150
                        Layout.maximumWidth: 150
                        spacing: 2
                        Text {
                            text: "选中指令"
                            color: "#8B9BA8"
                            font.pixelSize: 9
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.selectedCmd ? root.selectedCmd.name : "未选择"
                            color: root.selectedCmd ? "#E0D6F0" : "#4A5A7A"
                            font.pixelSize: 11
                            font.bold: root.selectedCmd ? true : false
                            elide: Text.ElideRight
                        }
                    }

                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "生成绑键"
                            color: "#8B9BA8"
                            font.pixelSize: 9
                        }
                        Text {
                            Layout.fillWidth: true
                            text: {
                                if (!root.selectedCmd) return "单击下方指令卡片选中"
                                if (!root.isBindable(root.selectedCmd)) return "该功能不可绑定按键"
                                var txt = root.generateBindText(root.selectedCmd, root.bindKey)
                                return txt || "请输入绑定按键"
                            }
                            color: {
                                if (!root.selectedCmd) return "#3A4A6A"
                                if (!root.isBindable(root.selectedCmd)) return "#FF6B6B"
                                return root.generateBindText(root.selectedCmd, root.bindKey) ? "#7AC8A0" : "#E0A040"
                            }
                            font.pixelSize: 11
                            font.family: "Consolas"
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            wrapMode: Text.NoWrap
                        }
                    }

                    
                    Rectangle {
                        id: bindCopyBtn
                        Layout.preferredWidth: 64
                        Layout.minimumWidth: 64
                        Layout.maximumWidth: 64
                        Layout.preferredHeight: 30
                        radius: 6
                        property bool canCopy: root.selectedCmd && root.isBindable(root.selectedCmd) && root.generateBindText(root.selectedCmd, root.bindKey).length > 0
                        color: root.copyFeedback ? "#4034D399" : (canCopy && bindCopyMouse.containsMouse ? "#60A78BFA" : (canCopy ? "#3AA78BFA" : "#252A3545"))
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: root.copyFeedback ? "已复制" : "复制"
                            color: (root.copyFeedback || bindCopyBtn.canCopy) ? "#FFFFFF" : "#8A9AAA"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            id: bindCopyMouse
                            anchors.fill: parent
                            hoverEnabled: bindCopyBtn.canCopy
                            cursorShape: bindCopyBtn.canCopy ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                var txt = root.generateBindText(root.selectedCmd, root.bindKey)
                                if (txt) {
                                    root.copyCmd(txt)
                                    root.copyFeedback = true
                                    copyFeedbackTimer.restart()
                                }
                            }
                        }
                    }
                }
            }

            
            TextField {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                placeholderText: "搜索指令名称或内容..."
                placeholderTextColor: "#6A7A9A"
                color: "#FFFFFF"
                font.pixelSize: 12
                selectByMouse: true
                background: Rectangle {
                    color: "#751E1B2E"
                    radius: 8
                    border.width: 1
                    border.color: parent.activeFocus ? "#60A78BFA" : "#353D4555"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }
                onTextChanged: searchText = text
            }

            
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: cmdColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle { radius: 2; color: "#60A78BFA" }
                }

                Column {
                    id: cmdColumn
                    width: parent.width - 20
                    x: 10
                    spacing: 2

                    Repeater {
                        model: root.categories
                        delegate: Item {
                            id: catDelegate
                            width: cmdColumn.width
                            height: catHeader.height + 8 + (catExpanded ? catItems.height : 0)
                            property bool catExpanded: root.expanded
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            
                            Rectangle {
                                id: catHeader
                                width: parent.width
                                height: 38
                                radius: 8
                                color: catHeaderMouse.containsMouse ? "#d0252040" : "#c01E1B2E"
                                border.width: 1
                                border.color: "#25A78BFA"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                MouseArea {
                                    id: catHeaderMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: catExpanded = !catExpanded
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10
                                    Canvas {
                                        width: 14; height: 14
                                        rotation: catExpanded ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                        onPaint: {
                                            var ctx = getContext("2d"); ctx.reset()
                                            ctx.strokeStyle = "#A78BFA"
                                            ctx.lineWidth = 2
                                            ctx.lineCap = "round"
                                            ctx.lineJoin = "round"
                                            ctx.beginPath()
                                            ctx.moveTo(4, 3)
                                            ctx.lineTo(10, 7)
                                            ctx.lineTo(4, 11)
                                            ctx.stroke()
                                        }
                                    }
                                    Text {
                                        text: modelData
                                        color: "#E0D6F0"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: root.filteredCommands.filter(function(c) { return c.cat === modelData }).length + " 条"
                                        color: "#6B7A9A"
                                        font.pixelSize: 11
                                    }
                                }
                            }
                            Flow {
                                id: catItems
                                width: parent.width
                                height: implicitHeight
                                anchors.top: catHeader.bottom
                                anchors.topMargin: 8
                                spacing: 8
                                opacity: catExpanded ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                                Repeater {
                                    model: root.filteredCommands.filter(function(c) { return c.cat === modelData })
                                    delegate: Rectangle {
                                        id: cmdCard
                                        width: (catItems.width - 3 * catItems.spacing) / 4
                                        height: 76
                                        radius: 10
                                        color: isSelected ? "#d0352855" : (cmdMouse.containsMouse ? "#e02D2548" : "#b81A1728")
                                        border.width: isSelected ? 2 : 1
                                        border.color: isSelected ? "#C4B5FD" : (cmdMouse.containsMouse ? "#70A78BFA" : "#252D3245")
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }
                                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                        scale: cmdMouse.containsMouse ? 1.02 : 1.0
                                        property bool isSelected: root.selectedCmd && root.selectedCmd.name === modelData.name && root.selectedCmd.cat === modelData.cat

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 4

                                            Text {
                                                text: modelData.name
                                                color: isSelected ? "#FFFFFF" : "#E8E0F5"
                                                font.pixelSize: 12
                                                font.bold: true
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: modelData.cmd
                                                color: isSelected ? "#B0C8D0" : "#6A8098"
                                                font.pixelSize: 9
                                                font.family: "Consolas"
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.Wrap
                                            }
                                            Item { Layout.fillHeight: true }
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text {
                                                    text: isSelected ? "✓ 已选中" : "单击选中・双击详情"
                                                    color: isSelected ? "#A78BFA" : (cmdMouse.containsMouse ? "#A78BFA" : "#5A6A8A")
                                                    font.pixelSize: 10
                                                }
                                                Item { Layout.fillWidth: true }
                                            }
                                        }

                                        MouseArea {
                                            id: cmdMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.selectedCmd = modelData
                                            }
                                            onDoubleClicked: {
                                                root.detailCmd = modelData
                                                root.detailVisible = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: copyFeedbackTimer
        interval: 1500
        onTriggered: root.copyFeedback = false
    }
}
