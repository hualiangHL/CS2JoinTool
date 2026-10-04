import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic


Rectangle {
    id: wheelPage
    anchors.fill: parent
    color: 'transparent'

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        HusText {
            text: Lang.tr('社区指令 · 轮盘指令','Community Commands · Radial Wheel')
            color: HusTheme.Primary.colorTextBase
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }


        Rectangle {
            id: wheelRoot
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            property var wheels: [
                { name: "Wheel 1", keybind: "", slots: [{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""}] },
                { name: "Wheel 2", keybind: "", slots: [{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""}] },
                { name: "Wheel 3", keybind: "", slots: [{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""},{cmd:"",text:""}] }
            ]
            property string slot0text: ""
            property string slot1text: ""
            property string slot2text: ""
            property string slot3text: ""
            property string slot4text: ""
            property string slot5text: ""
            property string slot6text: ""
            property string slot7text: ""
            property int activeWheel: 0
            property int forceUpdate: 0
            property int editingSlot: -1

            Rectangle {
                id: editBox
                visible: false
                z: 9999
                width: 150
                height: 38
                color: HusTheme.isDark ? '#1a1f2e' : '#FFFFFF'
                radius: 6
                border.width: 1
                border.color: HusTheme.Primary.colorPrimary
                TextField {
                    id: editTextField
                    anchors.fill: parent
                    anchors.margins: 6
                    background: Rectangle{color:"transparent"}
                    color: HusTheme.Primary.colorTextBase
                    placeholderTextColor: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.45)
                    font.pixelSize: 13
                    placeholderText: Lang.tr('请输入文本','Enter text')
                    onAccepted: {
                        if (wheelRoot.editingSlot === 0) { wheelRoot.slot0text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[0].text = text }
                        else if (wheelRoot.editingSlot === 1) { wheelRoot.slot1text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[1].text = text }
                        else if (wheelRoot.editingSlot === 2) { wheelRoot.slot2text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[2].text = text }
                        else if (wheelRoot.editingSlot === 3) { wheelRoot.slot3text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[3].text = text }
                        else if (wheelRoot.editingSlot === 4) { wheelRoot.slot4text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[4].text = text }
                        else if (wheelRoot.editingSlot === 5) { wheelRoot.slot5text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[5].text = text }
                        else if (wheelRoot.editingSlot === 6) { wheelRoot.slot6text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[6].text = text }
                        else if (wheelRoot.editingSlot === 7) { wheelRoot.slot7text = text; wheelRoot.wheels[wheelRoot.activeWheel].slots[7].text = text }
                        wheelRoot.forceUpdate++
                        editBox.visible = false
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 16


                Rectangle {
                    Layout.preferredWidth: 440
                    Layout.fillHeight: true
                    radius: 12
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            HusText { text: Lang.tr('轮盘预览','Wheel Preview'); color: HusTheme.Primary.colorTextBase; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            Repeater {
                                model: 3
                                Rectangle {
                                    width:72; height:28; radius:6
                                    color: wheelRoot.activeWheel===index ? HusTheme.Primary.colorPrimary : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                    scale: wheelRoot.activeWheel===index ? 1.06 : 1
                                    Behavior on scale { NumberAnimation { duration: 150 } }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    HusText { anchors.centerIn: parent; text:[Lang.tr('轮盘Ⅰ','Wheel I'),Lang.tr('轮盘Ⅱ','Wheel II'),Lang.tr('轮盘Ⅲ','Wheel III')][index]; color: wheelRoot.activeWheel===index ? (HusTheme.isDark ? '#000' : '#FFF') : HusTheme.Primary.colorTextSecondary; font.pixelSize:11; font.weight: wheelRoot.activeWheel===index ? Font.DemiBold : Font.Normal }
                                    MouseArea { anchors.fill: parent; hoverEnabled:true; onClicked: wheelRoot.activeWheel=index }
                                }
                            }
                        }

                        Item {
                            id: wa
                            Layout.fillWidth: true; Layout.fillHeight: true
                            readonly property real cx: width/2
                            readonly property real cy: height/2
                            readonly property real ro: Math.min(width,height)/2-20
                            readonly property real ri: ro*0.38

                            Rectangle {
                                width: wa.ro*2; height: width; radius: width/2
                                color: HusTheme.isDark ? Qt.rgba(0.09,0.11,0.15,0.6) : Qt.rgba(0.9,0.92,0.96,0.7)
                                border.width:2; border.color: "#7a828c"
                                anchors.centerIn: parent
                            }
                            Rectangle {
                                width: wa.ri*2; height: width; radius: width/2
                                color: HusTheme.isDark ? Qt.rgba(0.09,0.11,0.15,0.6) : Qt.rgba(0.9,0.92,0.96,0.7)
                                border.width:2; border.color: "#7a828c"
                                anchors.centerIn: parent
                                Item {
                                    anchors.centerIn: parent
                                    width: chatText.implicitWidth
                                    height: chatText.implicitHeight
                                    Text {
                                        id: chatText
                                        anchors.centerIn: parent
                                        text:"CHATWHEEL "+(wheelRoot.activeWheel+1)
                                        color: HusTheme.Primary.colorPrimary
                                        font.pixelSize:13
                                        font.bold:true
                                        font.family:"Consolas"
                                    }
                                }
                            }
                            Canvas {
                                id: paintCanvas
                                anchors.fill: parent
                                z: 10
                                property int hoverSlot: -1
                                onPaint: {
                                    wheelRoot.refreshCount
                                    var ctx = getContext("2d")
                                    ctx.reset()
                                    if (hoverSlot >= 0) {
                                        var sA = (hoverSlot*45 - 112.5) * Math.PI / 180
                                        var eA = (hoverSlot*45 - 67.5) * Math.PI / 180
                                        ctx.beginPath()
                                        ctx.arc(wa.cx, wa.cy, wa.ro, sA, eA)
                                        ctx.arc(wa.cx, wa.cy, wa.ri, eA, sA, true)
                                        ctx.closePath()
                                        ctx.fillStyle = "rgba("+Math.round(HusTheme.Primary.colorPrimary.r*255)+","+Math.round(HusTheme.Primary.colorPrimary.g*255)+","+Math.round(HusTheme.Primary.colorPrimary.b*255)+",0.25)"
                                        ctx.fill()
                                    }
                                    ctx.strokeStyle = "#7a828c"
                                    ctx.lineWidth = 1
                                    for (var i = 0; i < 8; i++) {
                                        var ang = (i*45 - 112.5) * Math.PI / 180
                                        var x1 = wa.cx + wa.ri * Math.cos(ang)
                                        var y1 = wa.cy + wa.ri * Math.sin(ang)
                                        var x2 = wa.cx + wa.ro * Math.cos(ang)
                                        var y2 = wa.cy + wa.ro * Math.sin(ang)
                                        ctx.beginPath()
                                        ctx.moveTo(x1, y1)
                                        ctx.lineTo(x2, y2)
                                        ctx.stroke()
                                    }
                                }
                            }
                            Repeater {
                                model: 8
                                Text {
                                    z: 20
                                    x: wa.cx + (wa.ri+wa.ro)/2*Math.cos((index*45-90)*Math.PI/180) - implicitWidth/2
                                    y: wa.cy + (wa.ri+wa.ro)/2*Math.sin((index*45-90)*Math.PI/180) - implicitHeight/2
                                    text: {
                                        wheelRoot.forceUpdate
                                        var t = wheelRoot.wheels[wheelRoot.activeWheel].slots[index].text
                                        return t === "" ? Lang.tr('请输入文本','Enter text') : t
                                    }
                                    color: HusTheme.Primary.colorTextBase
                                    font.pixelSize:12
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPositionChanged: {
                                    var dx = mouse.x - wa.cx
                                    var dy = mouse.y - wa.cy
                                    var d = Math.sqrt(dx*dx + dy*dy)
                                    if (d < wa.ri || d > wa.ro) {
                                        paintCanvas.hoverSlot = -1
                                        paintCanvas.requestPaint()
                                        return
                                    }
                                    var ang = Math.atan2(dy, dx) * 180 / Math.PI
                                    if (ang < -90) ang += 360
                                    var s = Math.floor((ang + 112.5)/45) % 8
                                    paintCanvas.hoverSlot = s
                                    paintCanvas.requestPaint()
                                }
                                onExited: {
                                    paintCanvas.hoverSlot = -1
                                    paintCanvas.requestPaint()
                                }
                                onClicked: {
                                    var dx = mouse.x - wa.cx
                                    var dy = mouse.y - wa.cy
                                    var d = Math.sqrt(dx*dx + dy*dy)
                                    if (d < wa.ri || d > wa.ro) return
                                    var ang = Math.atan2(dy, dx) * 180 / Math.PI
                                    if (ang < -90) ang += 360
                                    var s = Math.floor((ang + 112.5)/45) % 8
                                    var slotAng = (s*45-90) * Math.PI / 180
                                    var slotCx = wa.cx + (wa.ri+wa.ro)/2*Math.cos(slotAng)
                                    var slotCy = wa.cy + (wa.ri+wa.ro)/2*Math.sin(slotAng)
                                    editBox.x = slotCx - 65 + 10 - 3
                                    editBox.y = slotCy + 49 - 20 + 9
                                    editTextField.text = wheelRoot.wheels[wheelRoot.activeWheel].slots[s].text
                                    editBox.visible = true
                                    editTextField.forceActiveFocus()
                                    editTextField.selectAll()
                                    wheelRoot.editingSlot = s
                                }
                            }
                        }
                    }
                    HusText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        text: Lang.tr('点击"请输入文本"更改轮盘显示出来的文字\n默认"请输入文本"则为空白 回车键确定输入框内容','Click "Enter text" to change the wheel label; blank by default. Press Enter to confirm.')
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 11
                    }
                }


                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: 12
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.25)
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing:6

                        HusText { text: Lang.tr('槽位编辑 (%1)','Slot Editor (%1)').arg(wheelRoot.wheels[wheelRoot.activeWheel].name); color: HusTheme.Primary.colorTextBase; font.pixelSize: 15; font.weight: Font.DemiBold }

                        RowLayout {
                            Layout.fillWidth:true; spacing:8
                            HusText { text: Lang.tr('绑定打开的轮盘按键:','Bind key to open wheel:'); color: HusTheme.Primary.colorTextBase; font.pixelSize: 13; font.weight: Font.DemiBold }
                            TextField {
                                Layout.preferredWidth:100
                                background: Rectangle{color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6); radius:6; border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4); border.width:1}
                                color: HusTheme.Primary.colorTextBase; placeholderTextColor: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.45); font.pixelSize:12; placeholderText: Lang.tr('留空则不绑定','Leave empty to unbind')
                                text: wheelRoot.wheels[wheelRoot.activeWheel].keybind
                                onTextChanged: wheelRoot.wheels[wheelRoot.activeWheel].keybind=text
                            }
                        }

                        HusText {
                            text: Lang.tr('轮盘槽位1-8指令','Wheel slots 1-8 commands')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize:12
                            font.weight: Font.DemiBold
                            Layout.topMargin: 0
                        }

                        ColumnLayout {
                            id: slotList
                            Layout.fillWidth:true
                            spacing:3
                            Layout.topMargin: 0
                            Repeater {
                                model:8
                                Rectangle {
                                    Layout.preferredWidth:280; height:28; radius:4
                                    color: paintCanvas.hoverSlot === index ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.2) : "transparent"
                                    HusText {
                                        id: slotLabelText
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Lang.tr('%1号槽位指令:','Slot %1 command:').arg(index+1)
                                        color: HusTheme.Primary.colorTextBase; font.pixelSize:12; font.family:"Consolas"
                                    }
                                    TextField {
                                        anchors.left: slotLabelText.right
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 200
                                        background: Rectangle{color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6); radius:6; border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.4); border.width:1}
                                        color: HusTheme.Primary.colorTextBase; placeholderTextColor: HusThemeFunctions.alpha(HusTheme.Primary.colorTextBase, 0.45); font.pixelSize:12; font.family:"Consolas"; placeholderText:"he"
                                        text: wheelRoot.wheels[wheelRoot.activeWheel].slots[index].cmd
                                        onTextChanged: wheelRoot.wheels[wheelRoot.activeWheel].slots[index].cmd=text
                                    }
                                }
                            }
                        }

                        HusText { Layout.fillWidth:true; wrapMode:Text.WordWrap; text: Lang.tr('轮盘槽位执行的游戏指令[输入相对应的指令 例：he |buy mp7|say (๑╹っ╹๑)|ms_mp7|c_mp7]','Wheel slot game command [enter command, e.g. he |buy mp7|say (๑╹っ╹๑)|ms_mp7|c_mp7]'); color: HusTheme.Primary.colorTextSecondary; font.pixelSize:11 }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.fillWidth:true; height:455; radius:8
                            visible: wheelRoot.width > 1400
                            color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.1)
                            border.width:1; border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.2)
                            Text {
                                anchors.fill: parent
                                anchors.margins: 12
                                wrapMode: Text.WordWrap
                                text: Lang.tr('轮盘使用说明\n\n1.目前轮盘指令门槛有点高 暂时没有懒人解决办法 我做的只能帮助一键生成 文件需要你手动操作\n\n2.cfg 目录\n<盘符>:\\steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg\n在其下新建 exgtools 文件夹，用于放置 <servercommand.cfg> <servercommand2.cfg> <servercommand3.cfg> <text.cfg> <text2.cfg> <text3.cfg> 文件\n\n3.轮盘菜单显示文字\n<盘符>:\\steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\resource\n在此目录platform_schinese.txt 复制写入自定义内容,然后右键文件属性设置为只读\n\n4.一键生成的文件\n轮盘配置\n├── cfg\n│   ├── autoexec.cfg<粘贴指令代码>\n│   └── exgtools<文件夹直接复制过去>\n│       ├── servercommand.cfg<轮盘指令编辑>\n│       ├── servercommand2.cfg<Wheel 2指令编辑>\n│       ├── servercommand3.cfg<Wheel 3指令编辑>\n│       ├── text.cfg<不用更改>\n│       ├── text2.cfg<不用更改>\n│       └── text3.cfg<不用更改>\n└── resource\n    └── platform_schinese.txt<粘贴自定义轮盘显示自定义文字>\n\n5.启动项需要添加 -disable_workshop_command_filtering 启动轮盘','Wheel Usage Guide\n\n1. The wheel commands have a high entry barrier; no lazy solution for now. I only help generate files; manual steps are required.\n\n2. cfg directory\n<drive>:\\steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\cfg\nCreate an exgtools folder inside it to hold <servercommand.cfg> <servercommand2.cfg> <servercommand3.cfg> <text.cfg> <text2.cfg> <text3.cfg> files\n\n3. Wheel menu display text\n<drive>:\\steam\\steamapps\\common\\Counter-Strike Global Offensive\\game\\csgo\\resource\nCopy custom content into platform_schinese.txt, then set the file to read-only.\n\n4. Generated files\nWheel Config\n├── cfg\n│   ├── autoexec.cfg<paste command code>\n│   └── exgtools<copy the folder directly>\n│       ├── servercommand.cfg<wheel 1 command edit>\n│       ├── servercommand2.cfg<wheel 2 command edit>\n│       ├── servercommand3.cfg<wheel 3 command edit>\n│       ├── text.cfg<no changes>\n│       ├── text2.cfg<no changes>\n│       └── text3.cfg<no changes>\n└── resource\n    └── platform_schinese.txt<paste custom wheel display text>\n\n5. Add -disable_workshop_command_filtering to launch options to use the wheel')
                                color: HusTheme.Primary.colorTextSecondary; font.pixelSize:13
                            }
                        }

                        RowLayout {
                            Layout.fillWidth:true; spacing:8
                            Rectangle {
                                id: helpBtn
                                Layout.fillWidth:true; height:36; radius:8
                                color: helpHover.hovered ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.45) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
                                border.width: helpHover.hovered ? 2 : 0.5
                                border.color: helpHover.hovered ? HusTheme.Primary.colorTextBase : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                scale: helpHover.pressed ? 0.97 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.width { NumberAnimation { duration: 150 } }
                                HusText { anchors.centerIn:parent; text: Lang.tr('轮盘使用说明','Wheel Usage Guide'); color: '#FFFFFF'; font.pixelSize:13; font.weight: Font.DemiBold }
                                MouseArea {
                                    id: helpHover
                                    anchors.fill:parent; hoverEnabled: true
                                    onClicked: {
                                        wheelHelpDialog.visible = true
                                    }
                                }
                            }
                            Rectangle {
                                id: openCfgBtn
                                Layout.fillWidth:true; height:36; radius:8
                                color: hoverMouse.hovered ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.45) : HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.3)
                                border.width: hoverMouse.hovered ? 2 : 0.5
                                border.color: hoverMouse.hovered ? HusTheme.Primary.colorTextBase : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                scale: hoverMouse.pressed ? 0.97 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.width { NumberAnimation { duration: 150 } }
                                HusText { anchors.centerIn:parent; text: Lang.tr('打开CFG文件夹','Open CFG Folder'); color: '#FFFFFF'; font.pixelSize:13; font.weight: Font.DemiBold }
                                MouseArea {
                                    id: hoverMouse
                                    anchors.fill:parent; hoverEnabled: true
                                    onClicked: {
                                        WheelExporterObj.openFolder("E:/SteamLibrary/steamapps/common/Counter-Strike Global Offensive/game/csgo/cfg")
                                    }
                                }
                            }
                            Rectangle {
                                id: exportBtn
                                Layout.fillWidth:true; height:36; radius:8; color: exportHover.hovered ? HusTheme.Primary.colorPrimary.lighter(1.15) : HusTheme.Primary.colorPrimary
                                border.width: exportHover.hovered ? 2 : 0.5
                                border.color: exportHover.hovered ? HusTheme.Primary.colorTextBase : HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                scale: exportHover.pressed ? 0.97 : 1
                                Behavior on scale { NumberAnimation { duration: 100 } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.width { NumberAnimation { duration: 150 } }
                                HusText { anchors.centerIn:parent; text: Lang.tr('导出CFG配置文件','Export CFG File'); color: HusTheme.isDark ? '#000' : '#FFF'; font.pixelSize:13; font.weight: Font.DemiBold }
                                MouseArea {
                                    id: exportHover
                                    anchors.fill:parent; hoverEnabled: true
                                    onClicked: {
                                        function g(w){var l=[]; l.push("//"+["1","2","3"][w]+" wheel commands"); for(var s=0;s<8;s++){var c=wheelRoot.wheels[w].slots[s].cmd||"";var line='cl_radial_radio_tab_'+w+'_text_'+(s+1)+' cmd";'+c;if(c!=="")line+=";";l.push(line)} return l.join("\n")}
                                        var c1=g(0),c2=g(1),c3=g(2)
                                        var k1=wheelRoot.wheels[0].keybind||"",k2=wheelRoot.wheels[1].keybind||"",k3=wheelRoot.wheels[2].keybind||""
                                        var ae="//Wheel 1\nalias \"+radia\" \"exec exgtools/text.cfg;+radialradio\"\nalias \"-radia\" \"bind \""+k1+"\" +radia_loop\"\nalias \"+radia_loop\" \"exec exgtools/servercommand.cfg\"\nalias \"-radia_loop\" \"-radialradio;bind \""+k1+"\" +radia\"\nbind \""+k1+"\" \"+radia\"\n//Wheel 2\nalias \"+radia2\" \"exec exgtools/text2.cfg;+radialradio2\"\nalias \"-radia2\" \"bind \""+k2+"\" +radia2_loop\"\nalias \"+radia2_loop\" \"exec exgtools/servercommand2.cfg\"\nalias \"-radia2_loop\" \"-radialradio2;bind \""+k2+"\" +radia2\"\nbind \""+k2+"\" \"+radia2\"\n//Wheel 3\nalias \"+radia3\" \"exec exgtools/text3.cfg;+radialradio3\"\nalias \"-radia3\" \"bind \""+k3+"\" +radia3_loop\"\nalias \"+radia3_loop\" \"exec exgtools/servercommand3.cfg\"\nalias \"-radia3_loop\" \"-radialradio3;bind \""+k3+"\" +radia3\"\nbind \""+k3+"\" \"+radia3\""
                                        var tl=['"Tokens"','{']
                                        for(var w=0;w<3;w++){tl.push("//customize your "+["1","2","3"][w]+" wheel display text");for(var s=0;s<8;s++){var t=wheelRoot.wheels[w].slots[s].text||"";tl.push('    "SFUI_ze_lunpan'+(w+1)+'_'+(s+1)+'" "'+t+'"')}}
                                        tl.push('}')
                                        WheelExporterObj.exportFiles(c1,c2,c3,ae,tl.join("\n"))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    Rectangle {
        id: wheelHelpDialog
        visible: false
        anchors.fill: parent
        z: 10000
        color: '#8a000000'


        NumberAnimation on opacity {
            id: helpFadeIn
            from: 0; to: 1; duration: 180
            running: wheelHelpDialog.visible
        }
        Behavior on visible {
            enabled: false
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            id: helpDialogBox
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 860)
            height: Math.min(parent.height - 80, 720)
            radius: 14
            color: HusTheme.Primary.colorBgContainer
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.35)
            border.width: 1

            scale: 0.96
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10


                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    HusText {
                        text: Lang.tr('轮盘使用说明','Wheel Usage Guide')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true; height: 1 }

                    Rectangle {
                        width: 30; height: 30; radius: 6
                        color: closeHelpMouse.containsMouse ? HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.22) : 'transparent'
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: '\u2715'
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                        MouseArea {
                            id: closeHelpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wheelHelpDialog.visible = false
                        }
                    }
                }

                HusDivider { Layout.fillWidth: true }


                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.5)
                    border.width: 1
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                    clip: true

                    Flickable {
                        id: helpFlick
                        anchors.fill: parent
                        anchors.margins: 4
                        contentWidth: width
                        contentHeight: helpContent.height + 20
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: helpContent
                            width: helpFlick.width - 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            spacing: 14



                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                                lineHeight: 1.6
                                color: HusTheme.Primary.colorTextBase
                                textFormat: Text.PlainText
                                text: Lang.tr('教程没有太过于简单 这东西搞起来还是有点复杂的 如果觉得难可以不用搞

第一
将里面的autoexec.cfg 开启轮盘指令复制到 Counter-Strike Global Offensive\\game\\csgo\\cfg\\autoexec.cfg 里面放着
别直接拖autoexec过去覆盖了 要不然你在这个文件夹里面的绑过的键全部都被覆盖了','This tutorial is not too simple; it is quite involved. If it feels hard, you may skip it.

Step 1
Copy the autoexec.cfg wheel-enable commands into Counter-Strike Global Offensive\\game\\csgo\\cfg\\autoexec.cfg.
Do not drag autoexec over it, or all your existing keybinds in that folder will be overwritten.')
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.width * 506 / 900
                                radius: 8
                                clip: true
                                border.width: 1
                                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                color: '#FFFFFF'
                                Image {
                                    anchors.fill: parent
                                    source: 'qrc:/Gallery/images/wheel_help0.jpg'
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 900
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                                lineHeight: 1.6
                                color: HusTheme.Primary.colorTextBase
                                textFormat: Text.PlainText
                                text: Lang.tr('第二
将你生成的第二个文件exgtools文件解压塞进cfg文件夹中

exgtools里面的文件说明
servercommand.cfg 这个是轮盘里面的指令配置
cl_radial_radio_tab_0_text_1 cmd";<这里是写指令的地方可以编辑>;

text.cfg 用于引导显示面板的文字不用改动','Step 2
Unzip the generated exgtools folder into the cfg folder.

Files inside exgtools
servercommand.cfg is the wheel command config
cl_radial_radio_tab_0_text_1 cmd";<edit commands here>;

text.cfg guides the display panel text; no changes needed.')
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.width * 506 / 900
                                radius: 8
                                clip: true
                                border.width: 1
                                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                color: '#FFFFFF'
                                Image {
                                    anchors.fill: parent
                                    source: 'qrc:/Gallery/images/wheel_help1.jpg'
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 900
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                                lineHeight: 1.6
                                color: HusTheme.Primary.colorTextBase
                                textFormat: Text.PlainText
                                text: Lang.tr('第三
platform_schinese.txt 这个用于显示自定义的轮盘显示出来的文字
使用方式为 给生成出来的文件复制过去
游戏文件路径 Counter-Strike Global Offensive\\game\\csgo\\resource

修改完后保存，然后右键文件属性改回只读 不改的话那就可能会被二次刷掉','Step 3
platform_schinese.txt shows your custom wheel display text.
Usage: copy the generated file over.
Game file path: Counter-Strike Global Offensive\\game\\csgo\\resource

Save after editing, then set the file back to read-only, or it may be overwritten.')
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.width * 506 / 900
                                radius: 8
                                clip: true
                                border.width: 1
                                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                color: '#FFFFFF'
                                Image {
                                    anchors.fill: parent
                                    source: 'qrc:/Gallery/images/wheel_help2.jpg'
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 900
                                }
                            }

                            Text {
                                width: parent.width
                                wrapMode: Text.WordWrap
                                font.pixelSize: 14
                                lineHeight: 1.6
                                color: HusTheme.Primary.colorTextBase
                                textFormat: Text.PlainText
                                text: Lang.tr('第四
启动项添加 -disable_workshop_command_filtering
该启动项用来解除控制台部分指令限制

如果你还不会 建议逛逛论坛
https://bbs.darkrp.cn/forum-post/14334.html/
https://bbs.darkrp.cn/forum-post/26903.html/','Step 4
Add -disable_workshop_command_filtering to launch options.
It unlocks some console command restrictions.

If you still cannot figure it out, check the forums
https://bbs.darkrp.cn/forum-post/14334.html/
https://bbs.darkrp.cn/forum-post/26903.html/')
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.width * 506 / 900
                                radius: 8
                                clip: true
                                border.width: 1
                                border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.3)
                                color: '#FFFFFF'
                                Image {
                                    anchors.fill: parent
                                    source: 'qrc:/Gallery/images/wheel_help3.jpg'
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: 900
                                }
                            }
                        }
                    }


                    Rectangle {
                        id: helpScrollBar
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        width: 4
                        radius: 2
                        color: HusThemeFunctions.alpha(HusTheme.Primary.colorPrimary, 0.4)
                        visible: helpFlick.contentHeight > helpFlick.height
                        height: Math.max(20, helpFlick.height * (helpFlick.height / helpFlick.contentHeight))
                        y: helpFlick.visibleArea.yPosition * (helpFlick.height - height)
                        Behavior on y { NumberAnimation { duration: 60 } }
                    }
                }

                HusText {
                    Layout.fillWidth: true
                    text: Lang.tr('完成以上步骤后，轮盘即可正常使用。','Once these steps are done, the wheel is ready to use.')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}

