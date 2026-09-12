# CS2 僵尸逃跑挤服工具 V4

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
