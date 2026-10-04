import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic


Rectangle {
    id: commandsPage
    anchors.fill: parent
    color: 'transparent'


    Rectangle {
        id: cmdRoot
        anchors.fill: parent
        radius: 10
        color: "transparent"
        clip: true

        property bool fillMode: true
        property bool expanded: true
        property string searchText: ""
        property bool copyFeedback: false


        property bool detailVisible: false
        property var detailCmd: null


        property var selectedCmd: null
        property string bindKey: ""

        readonly property var allCommands: [
            { cat: "Weapons", name: "mp9 [MP9]", cmd: "mp9;c_mp9;ms_mp9;sm_mp9" },
            { cat: "Weapons", name: "mp7 [MP7]", cmd: "mp7;c_mp7;ms_mp7;sm_mp7" },
            { cat: "Weapons", name: "mac10 [MAC-10]", cmd: "mac10;c_mac10;ms_mac10;sm_mac10" },
            { cat: "Weapons", name: "p90 [P90]", cmd: "p90;c_p90;ms_p90;sm_p90" },
            { cat: "Weapons", name: "mp5sd [MP5-SD]", cmd: "mp5sd;c_mp5sd;ms_mp5sd;sm_mp5sd" },
            { cat: "Weapons", name: "bizon [Bizon]", cmd: "bizon;c_bizon;ms_bizon;sm_bizon" },
            { cat: "Weapons", name: "m249 [M249]", cmd: "m249;c_m249;ms_m249;sm_m249" },
            { cat: "Weapons", name: "negev [Negev]", cmd: "negev;c_negev;ms_negev;sm_negev" },
            { cat: "Weapons", name: "ak47 [AK-47]", cmd: "ak47;c_ak47;ms_ak47;sm_ak47" },
            { cat: "Weapons", name: "m4a4 [M4A4]", cmd: "m4a4;c_m4a4;ms_m4a4;sm_m4a4" },
            { cat: "Weapons", name: "m4a1 [M4A1]", cmd: "m4a1;c_m4a1;ms_m4a1;sm_m4a1" },
            { cat: "Weapons", name: "famas [FAMAS]", cmd: "famas;c_famas;ms_famas;sm_famas" },
            { cat: "Weapons", name: "sg556 [SG556]", cmd: "sg556;c_sg556;ms_sg556;sm_sg556" },
            { cat: "Weapons", name: "aug [AUG]", cmd: "aug;c_aug;ms_aug;sm_aug" },
            { cat: "Weapons", name: "galilar [Galil]", cmd: "galilar;c_galilar;ms_galilar;sm_galilar" },
            { cat: "Weapons", name: "nova [Nova]", cmd: "nova;c_nova;ms_nova;sm_nova" },
            { cat: "Weapons", name: "xm1014 [XM1014]", cmd: "xm1014;c_xm1014;ms_xm1014;sm_xm1014" },
            { cat: "Weapons", name: "sawedoff [Sawed-Off]", cmd: "sawedoff;c_sawedoff;ms_sawedoff;sm_sawedoff" },
            { cat: "Weapons", name: "mag7 [MAG-7]", cmd: "mag7;c_mag7;ms_mag7;sm_mag7" },
            { cat: "Weapons", name: "ssg08 [SSG-08]", cmd: "ssg08;c_ssg08;ms_ssg08;sm_ssg08" },
            { cat: "Weapons", name: "awp [AWP]", cmd: "awp;c_awp;ms_awp;sm_awp" },
            { cat: "Weapons", name: "g3sg1 [G3SG1]", cmd: "g3sg1;c_g3sg1;ms_g3sg1;sm_g3sg1" },
            { cat: "Weapons", name: "scar20 [SCAR-20]", cmd: "scar20;c_scar20;ms_scar20;sm_scar20" },
            { cat: "Weapons", name: "deagle [Desert Eagle]", cmd: "deagle;c_deagle;ms_deagle;sm_deagle" },
            { cat: "Weapons", name: "revolver [Revolver]", cmd: "revolver;c_revolver;ms_revolver;sm_revolver" },
            { cat: "Weapons", name: "glock [Glock]", cmd: "glock;c_glock;ms_glock;sm_glock" },
            { cat: "Weapons", name: "elite [Dual Berettas]", cmd: "elite;c_elite;ms_elite;sm_elite" },
            { cat: "Weapons", name: "usp_sliencer [USP-S]", cmd: "usp_sliencer;c_usp_sliencer;ms_usp_sliencer;sm_usp_sliencer" },
            { cat: "Weapons", name: "p250 [P250]", cmd: "p250;c_p250;ms_p250;sm_p250" },
            { cat: "Weapons", name: "cz75a [CZ75]", cmd: "cz75a;c_cz75a;ms_cz75a;sm_cz75a" },
            { cat: "Equipment", name: "he [HE Grenade]", cmd: "!he;.he;sm_he | say !he" },
            { cat: "Equipment", name: "smokegrenade [Smoke]", cmd: "!smokegrenade;ms_smokegrenade | buy !smokegrenade" },
            { cat: "Equipment", name: "molotov [Molotov]", cmd: "!molotov;ms_molotov | say !molotov" },
            { cat: "Equipment", name: "flashbang [Flashbang]", cmd: "!flashbang;ms_flashbang | buy !flashbang" },
            { cat: "Equipment", name: "dec [EXG Decoy]", cmd: "!dec;ms_dec;.dec | buy !dec" },
            { cat: "Equipment", name: "ice [ZED Ice]", cmd: "c_ice;!ice;ms_ice | c_ice" },
            { cat: "Equipment", name: "kevlar [Armor]", cmd: "kevlar;c_kevlar;ms_kevlar;sm_kevlar" },
            { cat: "Equipment", name: "xz [Health Needle]", cmd: "!xz;c_xz;ms_health;sm_xz | xz;c_xz;ms_health;sm_xz" },
            { cat: "Equipment", name: "hx25 [EXG Grenade Launcher]", cmd: ".hx25;!hx25 | hx25" },
            { cat: "Equipment", name: "m249xm [EXG Shotgun MG]", cmd: ".m249xm;!m249xm | m249xm" },
            { cat: "Misc", name: "bet [EXG Loadout]", cmd: "bet ct 1 2 3;bet t 1 2 3;bet ct <equipment name> | bet ct 1" },
            { cat: "Misc", name: "hidename [Name Distance]", cmd: "!hidename | hidename 9999" },
            { cat: "Misc", name: "fullbright [Night Vision]", cmd: "ms_toggle mat_fullbright | toggle mat_fullbright" },
            { cat: "Misc", name: "enable [Map Filter]", cmd: "ms_toggle r_csgo_postprocess_enable | toggle r_csgo_postprocess_enable" },
            { cat: "Misc", name: "drawparticles [Map Effects]", cmd: "ms_toggle r_drawparticles | toggle r_drawparticles" },
            { cat: "Misc", name: "ztele [Back to Spawn]", cmd: "!ztele;ms_ztele;c_ztele | !ztele" },
            { cat: "Misc", name: "stop [Stop Shake 1s]", cmd: "ms_shake_stop | +lookatweapon;shake_stop" },
            { cat: "Misc", name: "thirdperson [Third Person]", cmd: "cl_allow_multi_input_binds true\nc_thirdpersonshoulder 0;cam_idealyaw 0;cam_idealpitch 0;cam_collision 1\nc_mindistance -999999;c_maxdistance 999999\nalias cam_settings \"cam_idealyaw 0;cam_idealpitch 0;c_thirdpersonshoulder 0;c_thirdpersonshoulderheight 6;c_thirdpersonshoulderoffset 0;c_thirdpersonshoulderaimdist 0;cam_idealdist 0;\"\nalias \"cs_aliasthird\" \"thirdperson;cam_settings;alias cs_chasecam cs_aliasfirst\"\nalias \"cs_aliasfirst\" \"firstperson;alias cs_chasecam cs_aliasthird\"\nalias \"cs_chasecam\" \"cs_aliasthird\"\nbind \"KEY\" \"+tp_magnifier\"\nalias +tp_magnifier \"cs_chasecam;bind_zoomin;bind_zoomout;cam_collision 0\"\nalias -tp_magnifier \"cs_chasecam;bind_normal1;bind_normal2\"\nalias bind_zoomin \"bind MWHEELUP incrementvar cam_idealdist -999999 999999 -100\"\nalias bind_zoomout \"bind MWHEELDOWN incrementvar cam_idealdist -999999 999999 100\"\nalias bind_normal1 \"bind MWHEELUP +jump\"\nalias bind_normal2 \"bind MWHEELDOWN +jump\"", inlineBind: true },
            { cat: "Misc", name: "mayamode [Third Person Fixed]", cmd: "ms_thirdperson_mayamode | thirdperson_mayamode" },
            { cat: "Misc", name: "absbox [Mark Entity]", cmd: "cl_ent_absbox" },
            { cat: "Misc", name: "hidew [EXG Whitelist]", cmd: "!hidew | hidew" },
            { cat: "Misc", name: "hide [Hide Distance]", cmd: "!hide | hide" },
            { cat: "Misc", name: "menu [HUD Menu]", cmd: ".menu;!menu;ms_menu;c_menu", noBind: true },
            { cat: "Misc", name: "white [Add Whitelist]", cmd: "!white <name>;ms_white;c_white", noBind: true },
            { cat: "Misc", name: "showpos [Show Speed/Pos]", cmd: "cl_showpos 1" },
            { cat: "Misc", name: "musicvolume [Music Volume]", cmd: "snd_musicvolume 0.5" },
            { cat: "Misc", name: "voipvolume [Voice Volume]", cmd: "snd_voipvolume 1", noBind: true },
            { cat: "Misc", name: "hidebody[Hide Legs]", cmd: "say !hidebody | !hidebody;c_hidebody;ms_hidebody;sm_hidebody" },
            { cat: "Misc", name: "say [Send Chat]", cmd: "say <message>", noBind: true },
            { cat: "Cheats", name: "cheats [Enable Cheats]", cmd: "sv_cheats 1" },
            { cat: "Cheats", name: "noclip [Noclip]", cmd: "noclip" },
            { cat: "Cheats", name: "restartgame [Restart Round]", cmd: "mp_restartgame 1" },
            { cat: "Cheats", name: "win_conditions [Disable Win]", cmd: "mp_ignore_round_win_conditions 1" },
            { cat: "Cheats", name: "roundtime [Round 60min]", cmd: "mp_roundtime 60" },
            { cat: "Cheats", name: "roundtime_defuse [Comp 60min]", cmd: "mp_roundtime_defuse 60" },
            { cat: "Cheats", name: "warmup_end [End Warmup]", cmd: "mp_warmup_end" },
            { cat: "Cheats", name: "freezetime [Freeze 0s]", cmd: "mp_freezetime 0" },
            { cat: "Cheats", name: "maxrounds [Max Rounds 50]", cmd: "mp_maxrounds 50" },
            { cat: "Cheats", name: "respawn_ct [CT Respawn]", cmd: "mp_respawn_on_death_ct 1" },
            { cat: "Cheats", name: "respawn_t [T Respawn]", cmd: "mp_respawn_on_death_t 1" },
            { cat: "Cheats", name: "respawnwavetime_ct [CT Respawn 3s]", cmd: "mp_respawnwavetime_ct 3" },
            { cat: "Cheats", name: "respawnwavetime_t [T Respawn 3s]", cmd: "mp_respawnwavetime_t 3" },
            { cat: "Cheats", name: "limitteams [Team Limit Off]", cmd: "mp_limitteams 0" },
            { cat: "Cheats", name: "autoteambalance [Team Balance Off]", cmd: "mp_autoteambalance 0" },
            { cat: "Cheats", name: "autokick [No AutoKick]", cmd: "mp_autokick 0" },
            { cat: "Cheats", name: "friendlyfire [FF Off]", cmd: "mp_friendlyfire 0" },
            { cat: "Cheats", name: "solid_teammates [Solid Teammates Off]", cmd: "mp_solid_teammates 0" },
            { cat: "Cheats", name: "buytime [Buy Time Infinite]", cmd: "mp_buytime 99999" },
            { cat: "Cheats", name: "buy_anywhere [Buy Anywhere]", cmd: "mp_buy_anywhere 1" },
            { cat: "Cheats", name: "maxmoney [Max Money 99999]", cmd: "mp_maxmoney 99999" },
            { cat: "Cheats", name: "startmoney [Start Money 99999]", cmd: "mp_startmoney 99999" },
            { cat: "Cheats", name: "infinite_ammo [Infinite Ammo]", cmd: "sv_infinite_ammo 2" },
            { cat: "Cheats", name: "drop_knife [Drop Knife]", cmd: "mp_drop_knife_enable 1" },
            { cat: "Cheats", name: "death_drop_grenade [No Grenade Drop]", cmd: "mp_death_drop_grenade 0" },
            { cat: "Cheats", name: "grenade_limit [Grenade Limit 5]", cmd: "ammo_grenade_limit_total 5" },
            { cat: "Cheats", name: "weapons_glow [Weapon Glow]", cmd: "mp_weapons_glow_on_ground 1" },
            { cat: "Cheats", name: "nospread [No Spread]", cmd: "weapon_accuracy_nospread 1" },
            { cat: "Cheats", name: "t_default_grenades [T Start Grenades]", cmd: "mp_t_default_grenades \"weapon_hegrenade weapon_molotov\"" },
            { cat: "Cheats", name: "ct_default_grenades [CT Start Grenades]", cmd: "mp_ct_default_grenades \"weapon_hegrenade weapon_incgrenade\"" },
            { cat: "Cheats", name: "free_armor [Free Armor]", cmd: "mp_free_armor 2" },
            { cat: "Cheats", name: "falldamage [No Fall Damage]", cmd: "sv_falldamage_scale 0" },
            { cat: "Cheats", name: "regeneration [Auto Heal]", cmd: "sv_regeneration_force_on 1" },
            { cat: "Cheats", name: "buddha [Buddha 1 HP]", cmd: "buddha 1" },
            { cat: "Cheats", name: "buddha_reset_hp [Buddha 100000 HP]", cmd: "buddha_reset_hp 100000" },
            { cat: "Cheats", name: "endround [End Round]", cmd: "endround" },
            { cat: "Cheats", name: "getpos [Get Position]", cmd: "getpos" },
            { cat: "Cheats", name: "host_timescale [Game Speed]", cmd: "host_timescale 5" },
            { cat: "Cheats", name: "sv_alltalk [AllTalk]", cmd: "sv_alltalk 1" },
            { cat: "Cheats", name: "airaccelerate [Auto Bhop]", cmd: "sv_autobunnyhopping 1;sv_enablebunnyhopping 1;sv_airaccelerate 500" },
            { cat: "Cheats", name: "give [Give Weapon]", cmd: "give weapon_ak47" },
            { cat: "Cheats", name: "collisions[Show Collisions]", cmd: "sv_show_move_collisions 1" },
            { cat: "Launch Options", name: "-novid [No Intro]", cmd: "-novid" },
            { cat: "Launch Options", name: "-high [High Priority]", cmd: "-high" },
            { cat: "Launch Options", name: "-nojoy [No Joystick]", cmd: "-nojoy" },
            { cat: "Launch Options", name: "-fullscreen [Fullscreen]", cmd: "-fullscreen" },
            { cat: "Launch Options", name: "-windowed [Windowed]", cmd: "-windowed" },
            { cat: "Launch Options", name: "-w -h [Resolution]", cmd: "-w 1920 -h 1080" },
            { cat: "Launch Options", name: "-freq [Refresh Rate]", cmd: "-freq 240" },
            { cat: "Launch Options", name: "-language [Language]", cmd: "-language english" },
            { cat: "Launch Options", name: "+fps_max [FPS Limit]", cmd: "+fps_max 300" },
            { cat: "Launch Options", name: "-perfectworld [Perfect World]", cmd: "-perfectworld" },
            { cat: "Launch Options", name: "-worldwide [Worldwide]", cmd: "-worldwide" },
            { cat: "Launch Options", name: "+cl_forcepreload [Force Preload]", cmd: "+cl_forcepreload 1" },
            { cat: "Launch Options", name: "-autoconfig [Autoconfig]", cmd: "-autoconfig" },
            { cat: "Launch Options", name: "+exec [Exec CFG]", cmd: "+exec autoexec.cfg" },
            { cat: "Launch Options", name: "-allow_third_party_software [Allow 3rd Party SW]", cmd: "-allow_third_party_software" },
            { cat: "Launch Options", name: "-threads [CPU Threads]", cmd: "-threads 8" },
            { cat: "Launch Options", name: "-vulkan [Vulkan]", cmd: "-vulkan" },
            { cat: "Launch Options", name: "-insecure [Insecure]", cmd: "-insecure" },
            { cat: "Launch Options", name: "-console [Console]", cmd: "-console" },
            { cat: "Launch Options", name: "-noreflex [No Reflex]", cmd: "-noreflex" },
            { cat: "Launch Options", name: "+violence_hblood [No Blood]", cmd: "+violence_hblood 0" },
            { cat: "Launch Options", name: "-d3d9ex [D3D9Ex]", cmd: "-d3d9ex" },
            { cat: "Launch Options", name: "-no-browser [No Browser]", cmd: "-no-browser" },
            { cat: "Launch Options", name: "+mat_queue_mode 2 [Multi-core]", cmd: "+mat_queue_mode 2" },
            { cat: "Launch Options", name: "+cl_cmdrate [Cmdrate]", cmd: "+cl_cmdrate 128" },
            { cat: "Launch Options", name: "+cl_updaterate [Updaterate]", cmd: "+cl_updaterate 128" }
        ]

        readonly property var categories: ["Weapons", "Equipment", "Misc", "Cheats", "Launch Options"]



        function categoryLabel(cat) {
            switch (cat) {
            case "Weapons": return Lang.tr('武器', 'Weapons')
            case "Equipment": return Lang.tr('装备', 'Equipment')
            case "Misc": return Lang.tr('杂项', 'Misc')
            case "Cheats": return Lang.tr('作弊指令', 'Cheats')
            case "Launch Options": return Lang.tr('启动项', 'Launch Options')
            }
            return cat
        }




        readonly property var cmdDescZh: ({

            "Desert Eagle": "沙鹰",
            "Dual Berettas": "双持贝瑞塔",
            "Revolver": "左轮",
            "Negev": "内格夫",
            "Nova": "新星",
            "Sawed-Off": "截短霰弹枪",
            "Galil": "加利尔",
            "FAMAS": "法玛斯",
            "Glock": "格洛克",
            "Bizon": "野牛",

            "HE Grenade": "高爆手雷",
            "Smoke": "烟雾弹",
            "Molotov": "燃烧瓶",
            "Flashbang": "闪光弹",
            "EXG Decoy": "EXG 诱饵弹",
            "ZED Ice": "ZED 冰冻弹",
            "Armor": "护甲",
            "Health Needle": "医疗针",
            "EXG Grenade Launcher": "EXG 榴弹发射器",
            "EXG Shotgun MG": "EXG 霰弹机枪",

            "EXG Loadout": "EXG 装备配置",
            "Name Distance": "名字显示距离",
            "Night Vision": "夜视",
            "Map Filter": "地图滤镜",
            "Map Effects": "地图特效",
            "Back to Spawn": "返回出生点",
            "Stop Shake 1s": "停止抖动 1 秒",
            "Third Person": "第三人称",
            "Third Person Fixed": "第三人称（固定）",
            "Mark Entity": "标记实体",
            "EXG Whitelist": "EXG 白名单",
            "Hide Distance": "隐藏距离",
            "HUD Menu": "HUD 菜单",
            "Add Whitelist": "添加白名单",
            "Show Speed/Pos": "显示速度/坐标",
            "Music Volume": "音乐音量",
            "Voice Volume": "语音音量",
            "Hide Legs": "隐藏腿部",
            "Send Chat": "发送聊天",

            "Enable Cheats": "开启作弊",
            "Noclip": "穿墙",
            "Restart Round": "重开回合",
            "Disable Win": "禁用胜负判定",
            "Round 60min": "回合时长 60 分钟",
            "Comp 60min": "竞技时长 60 分钟",
            "End Warmup": "结束热身",
            "Freeze 0s": "冻结 0 秒",
            "Max Rounds 50": "最大回合数 50",
            "CT Respawn": "CT 重生",
            "T Respawn": "T 重生",
            "CT Respawn 3s": "CT 重生 3 秒",
            "T Respawn 3s": "T 重生 3 秒",
            "Team Limit Off": "关闭队伍人数限制",
            "Team Balance Off": "关闭自动平衡",
            "No AutoKick": "关闭自动踢出",
            "FF Off": "关闭友军伤害",
            "Solid Teammates Off": "关闭队友碰撞",
            "Buy Time Infinite": "购买时间无限",
            "Buy Anywhere": "随地购买",
            "Max Money 99999": "最大金钱 99999",
            "Start Money 99999": "初始金钱 99999",
            "Infinite Ammo": "无限弹药",
            "Drop Knife": "允许丢刀",
            "No Grenade Drop": "死亡不掉雷",
            "Grenade Limit 5": "手雷上限 5",
            "Weapon Glow": "武器发光",
            "No Spread": "无弹道扩散",
            "T Start Grenades": "T 初始投掷物",
            "CT Start Grenades": "CT 初始投掷物",
            "Free Armor": "免费护甲",
            "No Fall Damage": "无跌落伤害",
            "Auto Heal": "自动回血",
            "Buddha 1 HP": "不死模式 1 HP",
            "Buddha 100000 HP": "不死模式 100000 HP",
            "End Round": "结束回合",
            "Get Position": "获取坐标",
            "Game Speed": "游戏速度",
            "AllTalk": "全体语音",
            "Auto Bhop": "自动连跳",
            "Give Weapon": "给予武器",
            "Show Collisions": "显示碰撞",

            "No Intro": "跳过开场动画",
            "High Priority": "高优先级",
            "No Joystick": "禁用手柄",
            "Fullscreen": "全屏",
            "Windowed": "窗口化",
            "Resolution": "分辨率",
            "Refresh Rate": "刷新率",
            "Language": "语言",
            "FPS Limit": "FPS 上限",
            "Perfect World": "完美世界",
            "Worldwide": "国际服",
            "Force Preload": "强制预加载",
            "Autoconfig": "自动配置",
            "Exec CFG": "执行 CFG",
            "Allow 3rd Party SW": "允许第三方软件",
            "CPU Threads": "CPU 线程数",
            "Insecure": "不安全模式",
            "Console": "控制台",
            "No Reflex": "禁用 Reflex",
            "No Blood": "关闭血液",
            "No Browser": "禁用内置浏览器",
            "Multi-core": "多核渲染",
            "Cmdrate": "命令速率",
            "Updaterate": "更新速率"
        })



        function cmdLabel(name) {
            const i = name.lastIndexOf('[')
            if (i < 0 || name.charAt(name.length - 1) !== ']')
                return name
            const head = name.substring(0, i).trim()
            const desc = name.substring(i + 1, name.length - 1)
            return head + ' [' + (Lang.isEn() ? desc : (cmdDescZh[desc] || desc)) + ']'
        }

        readonly property var filteredCommands: {
            if (searchText === "") return allCommands
            var s = searchText.toLowerCase()
            return allCommands.filter(function(c) {
                return c.name.toLowerCase().indexOf(s) >= 0 || c.cmd.toLowerCase().indexOf(s) >= 0
                    || c.cat.toLowerCase().indexOf(s) >= 0 || categoryLabel(c.cat).toLowerCase().indexOf(s) >= 0
                    || cmdLabel(c.name).toLowerCase().indexOf(s) >= 0
            })
        }

        function copyCmd(text) {
            if (text && text.length > 0) HusApi.setClipboardText(text)
        }

        function useBindFormat(cmdObj) {
            if (!cmdObj || cmdObj.noBind || cmdObj.inlineBind) return false
            return cmdObj.cat === "Weapons" || cmdObj.cat === "Equipment" || cmdObj.cat === "Misc"
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
            if (cmdObj.cat === "Launch Options" || cmdObj.noBind) return ""
            if (cmdObj.inlineBind) {
                return cmdObj.cmd.replace(/\"KEY\"/g, "\"" + key + "\"")
            }
            var firstVariant = cmdObj.cmd.split("|")[0].trim()
            return "bind \"" + key + "\" \"" + firstVariant + "\""
        }

        function isBindable(cmdObj) {
            return cmdObj && cmdObj.cat !== "Launch Options" && !cmdObj.noBind
        }


        RowLayout {
            id: cmdTitleRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8
            HusText {
                text: Lang.tr('社区指令 · 指令列表','Community Commands · Command List')
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            HusText {
                text: Lang.tr('%1 条指令 · 单击选中 · 双击查看详情','%1 commands · click to select · double-click for details')
                .arg(cmdRoot.allCommands.length)
                color: HusTheme.Primary.colorTextSecondary
                font.pixelSize: 12
            }
        }


        Rectangle {
            id: cmdBindRow
            anchors.top: cmdTitleRow.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            height: 46
            radius: 10
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
            border.width: 1
            border.color: cmdRoot.selectedCmd ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)
                                              : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
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
                    HusText {
                        text: Lang.tr('绑定按键','Bind Key')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 9
                    }
                    TextField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        placeholderText: Lang.tr('如 F1','e.g. F1')
                        placeholderTextColor: HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.55)
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 12
                        font.family: "Consolas"
                        font.bold: true
                        selectByMouse: true
                        text: cmdRoot.bindKey
                        onTextChanged: cmdRoot.bindKey = text
                        background: Rectangle {
                            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                            radius: 5
                            border.width: 1
                            border.color: cmdRoot.bindKey.length > 0
                                           ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.45)
                                           : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.minimumWidth: 1
                    Layout.maximumWidth: 1
                    Layout.preferredHeight: 28
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.15)
                }

                ColumnLayout {
                    Layout.preferredWidth: 150
                    Layout.minimumWidth: 150
                    Layout.maximumWidth: 150
                    spacing: 2
                    HusText {
                        text: Lang.tr('选中指令','Selected Command')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 9
                    }
                    HusText {
                        Layout.fillWidth: true
                        text: cmdRoot.selectedCmd ? cmdRoot.cmdLabel(cmdRoot.selectedCmd.name) : Lang.tr('未选择','Not Selected')
                        color: cmdRoot.selectedCmd ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.55)
                        font.pixelSize: 11
                        font.weight: cmdRoot.selectedCmd ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    HusText {
                        text: Lang.tr('生成绑键','Generate Bind')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 9
                    }
                    HusText {
                        Layout.fillWidth: true
                        text: {
                            if (!cmdRoot.selectedCmd) return Lang.tr('单击下方指令卡片选中','Click a command card below to select it')
                            if (!cmdRoot.isBindable(cmdRoot.selectedCmd)) return Lang.tr('该功能不可绑定按键','This feature cannot be bound')
                            var txt = cmdRoot.generateBindText(cmdRoot.selectedCmd, cmdRoot.bindKey)
                            return txt || Lang.tr('请输入绑定按键','Enter a key to bind')
                        }
                        color: {
                            if (!cmdRoot.selectedCmd) return HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.55)
                            if (!cmdRoot.isBindable(cmdRoot.selectedCmd)) return '#E5484D'
                            return cmdRoot.generateBindText(cmdRoot.selectedCmd, cmdRoot.bindKey) ? '#34C89A' : '#E0A040'
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
                    property bool canCopy: cmdRoot.selectedCmd && cmdRoot.isBindable(cmdRoot.selectedCmd)
                                           && cmdRoot.generateBindText(cmdRoot.selectedCmd, cmdRoot.bindKey).length > 0
                    color: cmdRoot.copyFeedback ? '#4034D399'
                            : (canCopy && bindCopyMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.45)
                                                                     : (canCopy ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.28)
                                                                                : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.16)))
                    Behavior on color { ColorAnimation { duration: 120 } }
                    HusText {
                        anchors.centerIn: parent
                        text: cmdRoot.copyFeedback ? Lang.tr('已复制','Copied') : Lang.tr('复制','Copy')
                        color: (cmdRoot.copyFeedback || bindCopyBtn.canCopy) ? '#FFFFFF' : HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.72)
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    MouseArea {
                        id: bindCopyMouse
                        anchors.fill: parent
                        hoverEnabled: bindCopyBtn.canCopy
                        cursorShape: bindCopyBtn.canCopy ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            var txt = cmdRoot.generateBindText(cmdRoot.selectedCmd, cmdRoot.bindKey)
                            if (txt) {
                                cmdRoot.copyCmd(txt)
                                cmdRoot.copyFeedback = true
                                copyFeedbackTimer.restart()
                            }
                        }
                    }
                }
            }
        }


        TextField {
            id: cmdSearchField
            anchors.top: cmdBindRow.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            height: 34
            placeholderText: Lang.tr('搜索指令名称或内容...','Search command name or content...')
            placeholderTextColor: HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.55)
            color: HusTheme.Primary.colorTextBase
            font.pixelSize: 12
            selectByMouse: true
            background: Rectangle {
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                radius: 8
                border.width: 1
                border.color: parent.activeFocus ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.45)
                                                 : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4)
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }
            onTextChanged: cmdRoot.searchText = text
        }


        Flickable {
            id: cmdFlick
            anchors.top: cmdSearchField.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            contentHeight: cmdColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                width: 4
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle { radius: 2; color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.4) }
            }

            Column {
                id: cmdColumn
                width: parent.width - 20
                x: 10
                spacing: 2

                Repeater {
                    model: cmdRoot.categories
                    delegate: Item {
                        id: catDelegate
                        width: cmdColumn.width
                        height: catHeader.height + 8 + (catExpanded ? catItems.height : 0)
                        property bool catExpanded: false
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: catHeader
                            width: parent.width
                            height: 38
                            radius: 8
                            color: catHeaderMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.2)
                                                                : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.55)
                            border.width: 1
                            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.18)
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
                                HusText {
                                    text: cmdRoot.categoryLabel(modelData)
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                HusText {
                                    text: cmdRoot.filteredCommands.filter(function(c) { return c.cat === modelData }).length + Lang.tr(' 条',' items')
                                    color: HusTheme.Primary.colorTextSecondary
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
                            visible: catExpanded
                            opacity: catExpanded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            Repeater {
                                model: cmdRoot.filteredCommands.filter(function(c) { return c.cat === modelData })
                                delegate: Rectangle {
                                    id: cmdCard
                                    width: (catItems.width - 3 * catItems.spacing) / 4
                                    height: 76
                                    radius: 10
                                    color: isSelected ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)
                                           : (cmdMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22)
                                                                     : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5))
                                    border.width: isSelected ? 2 : 1
                                    border.color: isSelected ? HusTheme.Primary.colorPrimary
                                           : (cmdMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.6)
                                                                     : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35))
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    scale: cmdMouse.containsMouse ? 1.02 : 1.0
                                    property bool isSelected: cmdRoot.selectedCmd && cmdRoot.selectedCmd.name === modelData.name && cmdRoot.selectedCmd.cat === modelData.cat

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4

                                        HusText {
                                            text: cmdRoot.cmdLabel(modelData.name)
                                            color: isSelected ? '#FFFFFF' : HusTheme.Primary.colorTextBase
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        HusText {
                                            text: modelData.cmd
                                            color: isSelected ? '#B0C8D0' : HusTheme.Primary.colorTextSecondary
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
                                            HusText {
                                                text: isSelected ? Lang.tr('✓ 已选中','✓ Selected') : Lang.tr('单击选中・双击详情','Click to select · double-click for details')
                                                color: isSelected ? HusTheme.Primary.colorPrimary
                                                       : (cmdMouse.containsMouse ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.72))
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
                                            cmdRoot.selectedCmd = modelData
                                        }
                                        onDoubleClicked: {
                                            cmdRoot.detailCmd = modelData
                                            cmdRoot.detailVisible = true
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
            onTriggered: cmdRoot.copyFeedback = false
        }
    }


    Rectangle {
        id: detailMask
        anchors.fill: parent
        color: cmdRoot.detailVisible ? '#90000000' : '#00000000'
        visible: false
        Behavior on color { ColorAnimation { duration: 280; easing.type: Easing.OutCubic } }
        z: 100

        Timer {
            id: detailHideTimer
            interval: 280
            running: !cmdRoot.detailVisible && detailMask.visible
            onTriggered: detailMask.visible = false
        }

        Connections {
            target: cmdRoot
            function onDetailVisibleChanged() {
                if (cmdRoot.detailVisible) detailMask.visible = true
            }
        }

        MouseArea { anchors.fill: parent; onClicked: cmdRoot.detailVisible = false }

        Rectangle {
            id: detailPanel
            width: 520
            height: 280
            radius: 12
            color: HusTheme.isDark ? '#F21E1B2E' : '#FAFFFFFF'
            border.width: 1
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
            anchors.centerIn: parent
            opacity: cmdRoot.detailVisible ? 1.0 : 0.0
            scale: cmdRoot.detailVisible ? 1.0 : 0.90
            Behavior on opacity { NumberAnimation { duration: cmdRoot.detailVisible ? 300 : 220; easing.type: cmdRoot.detailVisible ? Easing.OutCubic : Easing.InCubic } }
            Behavior on scale { NumberAnimation { duration: cmdRoot.detailVisible ? 320 : 220; easing.type: cmdRoot.detailVisible ? Easing.OutBack : Easing.InCubic } }

            Rectangle {
                id: detailCloseBtn
                width: 28; height: 28; radius: 14
                anchors.top: parent.top; anchors.topMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 12
                color: detailCloseMouse.containsMouse ? '#40ff6b6b' : 'transparent'
                Behavior on color { ColorAnimation { duration: 150 } }
                MouseArea { id: detailCloseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: cmdRoot.detailVisible = false }
                HusText { anchors.centerIn: parent; text: '✕'; color: HusTheme.Primary.colorTextBase; font.pixelSize: 14 }
            }

            HusText {
                id: detailName
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: parent.top; anchors.topMargin: 20
                anchors.right: detailCloseBtn.left; anchors.rightMargin: 12
                text: cmdRoot.detailCmd ? cmdRoot.cmdLabel(cmdRoot.detailCmd.name) : ''
                color: HusTheme.Primary.colorTextBase
                font.pixelSize: 18
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Rectangle {
                id: detailCatTag
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.top: detailName.bottom; anchors.topMargin: 10
                width: detailCatText.implicitWidth + 16
                height: 22
                radius: 4
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
                HusText {
                    id: detailCatText
                    anchors.centerIn: parent
                    text: cmdRoot.detailCmd ? cmdRoot.categoryLabel(cmdRoot.detailCmd.cat) : ''
                    color: HusTheme.Primary.colorPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                id: detailDivider
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.top: detailCatTag.bottom; anchors.topMargin: 14
                height: 1
                color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.15)
            }

            Rectangle {
                id: detailCmdBox
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.top: detailDivider.bottom; anchors.topMargin: 14
                anchors.bottom: detailHint.top; anchors.bottomMargin: 12
                radius: 8
                color: detailCmdMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.7)
                                                    : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                border.width: 1
                border.color: detailCmdMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.4)
                                                           : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.15)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                clip: true
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 12
                    contentWidth: width
                    contentHeight: detailCmdFullText.implicitHeight
                    clip: true
                    Text {
                        id: detailCmdFullText
                        text: cmdRoot.detailCmd ? cmdRoot.formatDetailCmd(cmdRoot.detailCmd) : ''
                        color: '#34C89A'
                        font.pixelSize: 13
                        font.family: "Consolas"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                }
                MouseArea {
                    id: detailCmdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (cmdRoot.detailCmd) {
                            var txt = cmdRoot.formatDetailCmd(cmdRoot.detailCmd)
                            HusApi.setClipboardText(txt)
                            detailCopyFeedback = true
                            detailCopyTimer.restart()
                        }
                    }
                }
            }

            HusText {
                id: detailHint
                anchors.bottom: parent.bottom; anchors.bottomMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                text: detailCopyFeedback ? Lang.tr('✓ 已复制到剪贴板','✓ Copied to clipboard') : Lang.tr('点击指令复制 · 点击空白处或 ✕ 关闭','Click a command to copy · click empty area or ✕ to close')
                color: detailCopyFeedback ? '#34D399' : HusThemeFunctions.alpha(HusTheme.Primary.colorTextSecondary, 0.72)
                font.pixelSize: 11
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }
    }

    property bool detailCopyFeedback: false
    Timer {
        id: detailCopyTimer
        interval: 1500
        onTriggered: commandsPage.detailCopyFeedback = false
    }
}
