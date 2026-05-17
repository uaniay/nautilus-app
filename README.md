# Nautilus App

Flutter 客户端，通过 WebSocket 连接到 [nautilus](https://github.com/uaniay/nautilus) 服务，远程操控 CLI 终端。

## 功能

- 内网/外网连接到 nautilus 服务（支持 HTTP 和 HTTPS）
- 完整终端模拟（xterm.dart）
- 多会话管理（创建/切换/kill）
- 断线自动重连 + replay 恢复
- 服务器地址和 token 本地保存
- 虚拟快捷键栏（适配手机无物理键盘）

## 使用

### 1. 安装 Flutter

```bash
# https://docs.flutter.dev/get-started/install
```

### 2. 安装依赖

```bash
cd nautilus-app
flutter pub get
```

### 3. 运行

```bash
# Android
flutter run

# iOS
flutter run --device-id <ios-device>

# Web (调试用)
flutter run -d chrome

# 构建 APK
flutter build apk --release
```

### 4. 连接

1. 确保 nautilus 服务已在目标机器运行
2. 在 App 中输入服务器地址（如 `http://192.168.1.100:8080`）
3. 输入 JWT token（通过 `nautilus token --user X --role admin` 生成）
4. 点击 Connect
5. 选择命令，点击 + 创建会话

## 快捷键栏

终端底部提供可横向滚动的虚拟快捷键：

| 按钮 | 功能 |
|------|------|
| ESC | 退出 vim 等模式 |
| TAB | 自动补全 |
| CTRL | 切换 Ctrl 修饰键，点击后再按字母发送 Ctrl+字母 |
| Ctrl+C | 中断当前进程 |
| Ctrl+D | EOF / 退出 shell |
| Ctrl+Z | 挂起进程 |
| Ctrl+L | 清屏 |
| ↑↓←→ | 方向键 / 历史命令 |
| HOME/END | 光标到行首/行尾 |
| PGUP/PGDN | 翻页 |

## 架构

```
lib/
├── main.dart                    # App 入口 + 路由
├── screens/
│   ├── connect_screen.dart      # 连接设置页
│   └── terminal_screen.dart     # 终端页
└── services/
    └── connection_service.dart  # WebSocket 通信 + 状态管理
```
