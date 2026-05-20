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

## 开发环境：WSL2 + Windows Android 模拟器

在 WSL2 中开发 Flutter，通过 Windows 侧的 Android 模拟器运行调试。

### 安装模拟器（Windows PowerShell）

1. 下载 Android Command Line Tools：
   - 打开 https://developer.android.com/studio#command-line-tools-only
   - 下载 Windows 版 zip

2. 解压并配置：
```powershell
$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
New-Item -ItemType Directory -Force -Path "$sdkRoot\cmdline-tools"
Expand-Archive -Path "$env:USERPROFILE\Downloads\commandlinetools-win-14742923_latest.zip" -DestinationPath "$sdkRoot\cmdline-tools" -Force
Rename-Item "$sdkRoot\cmdline-tools\cmdline-tools" "latest"

$env:ANDROID_HOME = $sdkRoot
$env:Path += ";$sdkRoot\cmdline-tools\latest\bin;$sdkRoot\platform-tools;$sdkRoot\emulator"
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkRoot, "User")
$oldPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$oldPath;$sdkRoot\cmdline-tools\latest\bin;$sdkRoot\platform-tools;$sdkRoot\emulator", "User")
```

3. 安装 Java（如果没有）：
```powershell
winget install EclipseAdoptium.Temurin.21.JDK
```

4. 安装 SDK 组件（重开 PowerShell 后执行）：
```powershell
sdkmanager.bat --licenses
sdkmanager.bat "platform-tools" "emulator" "platforms;android-34" "system-images;android-34;google_apis;x86_64"
```

5. 创建模拟器：
```powershell
avdmanager.bat create avd -n "Nautilus_Test" -k "system-images;android-34;google_apis;x86_64" -d "pixel_6" --force
```

### 日常开发流程

Windows 侧启动模拟器：
```powershell
emulator -avd Nautilus_Test
```

WSL2 侧连接并运行：
```bash
adb connect 127.0.0.1:5555
flutter run -d 127.0.0.1:5555
```

运行后按 `r` 热重载，按 `R` 热重启。

## 架构

```
lib/
├── main.dart                        # App 入口 + 路由 + Provider 配置
├── models/
│   ├── file_entry.dart              # 文件/目录模型
│   └── chat_message.dart            # 聊天消息模型
├── screens/
│   ├── connect_screen.dart          # 连接设置页
│   ├── home_screen.dart             # 底部 Tab 导航容器
│   ├── file_browser_screen.dart     # 文件浏览器
│   ├── chat_list_screen.dart        # 会话列表（类似聊天软件）
│   ├── chat_detail_screen.dart      # 对话详情（气泡式）
│   └── terminal_screen.dart         # 原始终端
├── services/
│   ├── connection_service.dart      # WebSocket 通信 + 状态管理
│   ├── file_service.dart            # 文件浏览状态
│   └── session_history_service.dart # 会话 I/O 历史
└── widgets/
    └── shortcut_bar.dart            # 虚拟快捷键栏
```
