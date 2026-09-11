# CS2 僵尸逃跑挤服工具 

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
 
