# CS2 僵尸逃跑挤服工具 V4

Qt6 QML + C++ 开发的 CS2 僵尸逃跑模式挤服工具，深色紫色主题，流畅动画。


## 项目结构

### 根目录
| 文件 | 说明 |
|------|------|
| `main.cpp` | 程序入口：QML 引擎初始化、单实例锁、高 DPI 适配、OpenGL 后端设置 |
| `CMakeLists.txt` | CMake 编译配置：Qt 模块依赖、源文件列表、资源打包 |
| `resources.qrc` | Qt 资源文件：QML、图片、图标等资源的注册清单 |
| `app.rc` | Windows 资源脚本：EXE 图标、版本信息、公司名称 |
| `app.manifest` | Windows 应用清单：DPI 感知、兼容性声明 |
| `app.ico` | 程序图标（多尺寸 ICO 格式） |
| `.gitignore` | Git 忽略规则：排除编译产物、DLL、临时文件 |
| `map_db.json` | 地图翻译数据库：地图英文名 → 中文名映射 |
| `workshop_titles.json` | 创意工坊地图标题缓存：Workshop ID → 地图名称 |
| `strip_comments.py` | 辅助脚本：发布打包前删除代码中的注释 |

### src/ — C++ 核心源代码
| 文件 | 说明 |
|------|------|
| `appcontroller.h/.cpp` | 全局控制器：挤服逻辑、设置管理、配置持久化、信号调度中心 |
| `serverquery.h/.cpp` | A2S_INFO 协议：服务器状态查询、玩家数、地图名、服务器名称 |
| `servermanager.h/.cpp` | 服务器列表管理：74+ 服务器数据、分类、排序、自动刷新 |
| `mapsubscriptionmanager.h/.cpp` | 地图订阅管理：订阅列表、精确匹配检测、Windows 通知触发 |
| `mapcooldownmanager.h/.cpp` | ExG 地图冷却：冷却数据获取、倒计时、可用状态 |
| `maptranslations.h` | 地图翻译常量：内置地图中文名映射表 |
| `workshopmanager.h/.cpp` | 创意工坊管理：Steam 路径检测、地图扫描、预览图获取、文件操作 |
| `ubservermanager.h/.cpp` | UB 服务器特供：从 cs.moeub.cn 读取玩家列表、指挥标识、CT/T 阵营 |
| `playerquery.h/.cpp` | 玩家查询：A2S_PLAYER 协议获取普通服务器玩家列表 |
| `baservertime.h/.cpp` | 换图时间：bluearchive.top WebSocket 实时数据、游玩时间计算 |
| `roundedcornerrenderer.h/.cpp` | 圆角渲染器：OpenGL 抗锯齿圆角遮罩、窗口 20px 圆角绘制 |

### qml/ — QML 界面
| 文件 | 说明 |
|------|------|
| `Main.qml` | 主窗口：无边框窗口、顶部栏、左侧导航、页面切换、底部挤服状态栏 |
| `Theme.qml` | 主题配色：深色紫色主题色值、字体大小、圆角、动画时长统一管理 |
| `StaggerItem.qml` | 交错动画组件：页面切换时组件依次淡入的封装 |

### qml/components/ — 通用组件
| 文件 | 说明 |
|------|------|
| `EButton.qml` | 自定义按钮：半透明背景、悬停高亮、圆角、流畅过渡 |
| `ECard.qml` | 卡片容器：半透明面板、圆角、紫色描边 |
| `EDrawer.qml` | 下拉抽屉：流畅展开/收起动画、圆角列表、切换页面自动关闭 |
| `EInput.qml` | 输入框：半透明风格、搜索图标、实时过滤 |
| `ESlider.qml` | 滑动条：自定义样式、数值显示、范围限制 |
| `ESwitch.qml` | iPhone 样式开关：iOS 风格滑动切换动画 |
| `ETooltip.qml` | 工具提示：悬停弹出说明文字 |
| `ServerCard.qml` | 服务器卡片：服务器列表单项，名称/IP/地图/人数/状态/播放按钮 |
| `StatusBadge.qml` | 状态徽章：在线/离线/检测中三态指示灯 |

### qml/pages/ — 页面
| 文件 | 说明 |
|------|------|
| `HomePage.qml` | 挤服主页：IP 输入、协议选择、间隔/人数/次数设置、开始挤服、服务器详情 |
| `ServerListPage.qml` | 服务器列表：分类折叠、搜索、右键菜单、双击挤服面板、自动刷新 |
| `SubscriptionPage.qml` | 地图订阅：模糊搜索、难度显示、订阅管理、选中删除、通知测试 |
| `WorkshopPage.qml` | 创意工坊地图：连接/断开、路径管理、地图列表、详情面板、右键操作 |
| `CooldownPage.qml` | ExG 地图冷却：冷却列表、搜索、难度、双击详情、可用/冷却状态 |
| `SettingsPage.qml` | 设置：外观/窗口/挤服/调试四个分类、下拉选择、开关、极速模式密码 |
| `AboutPage.qml` | 关于：工具信息、版本历史、红色警示、作者 Steam 链接 |

### qml/QtQuick/ — Qt Quick Controls 样式
| 目录 | 说明 |
|------|------|
| `Controls/Basic/` | Qt Quick Controls 基础样式（按钮、输入框、下拉等系统组件） |
| `Controls/FluentWinUI3/` | Fluent WinUI3 风格样式（Windows 11 风格控件及贴图资源） |
| `QtQml/` | QML 模型和 WorkerScript 插件类型定义 |

### assets/ — 资源文件
| 文件 | 说明 |
|------|------|
| `app_icon.png` / `app_icon_64.png` / `app_icon_128.png` | 应用图标（不同尺寸 PNG） |
| `app_icon.ico` | 应用图标（ICO 格式，用于 EXE 和窗口） |
| `app_icon_new.png` | 新版应用图标（高清） |
| `icon.png` | 通用图标 |
| `notify_icon.png` | 系统通知/托盘图标 |
| `bg.jpg` / `bg1.jpg` / `bg2.jpg` | 三张背景图（随机显示，每 200 秒切换） |
| `bg1.webp` / `bg2.webp` | 背景图 WebP 版本 |

## 技术栈
- **框架**：Qt 6.11 MinGW 64-bit
- **语言**：C++17 + QML
- **渲染**：OpenGL 后端（QSG_RHI_BACKEND=opengl）
- **网络协议**：A2S_INFO（服务器查询）、WebSocket（bluearchive.top）、HTTPS（Steam API / ExG API / UB 数据）
- **窗口**：无边框 + DWM 圆角 + OpenGL 抗锯齿圆角遮罩
- **单实例**：QLocalServer + QLocalSocket

## 编译说明
需要 Qt 6.11+ MinGW 64-bit 环境。
```bash
mkdir build && cd build
cmake -G "MinGW Makefiles" ..
mingw32-make -j4
```

## 数据来源
- 服务器状态：A2S_INFO 协议实时查询
- 地图翻译：https://list.darkrp.cn:9000/ServerList/Cs2MapList
- 换图时间：https://www.bluearchive.top（WebSocket）
- 地图预览图：Steam Workshop API（通过 Workshop ID 获取 preview_url）
- UB 玩家列表：https://cs.moeub.cn/play
- 地图冷却：ExG API
