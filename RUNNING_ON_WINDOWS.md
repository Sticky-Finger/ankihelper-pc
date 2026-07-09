# Anki划词助手 — Windows 运行指南

本文档说明如何在 Windows 11 上安装环境并运行本项目（Flutter 桌面应用）。

> 适用平台：Windows 10 / 11（64 位）。
> 项目技术栈见 `README.md`：Flutter (Desktop) + Dart、Riverpod、SQLite、clipboard_watcher，与 Anki 通过 AnkiConnect 通信。

---

## 一、前置条件

| 依赖 | 用途 | 是否必需 |
|------|------|----------|
| Flutter SDK（stable 频道，≥ 3.11） | 框架与构建工具 | ✅ 必需 |
| Visual Studio 2022 + “使用 C++ 的桌面开发” 工作负载 | Windows 原生构建工具链 | ✅ 必需 |
| Git for Windows | 拉取依赖 | ✅ 必需（一般已装） |
| Android SDK / iOS 工具链 | 移动端构建 | ❌ 不需要（桌面应用用不到） |

---

## 二、安装 Flutter SDK

> 参考：https://docs.flutter.dev/install/manual

1. 下载 Stable 版本
2. 解压到**不含空格和中文**的路径，推荐：
   ```
   C:\flutter
   ```
3. 将 `flutter\bin` 加入系统环境变量 `Path`：
   - 开始菜单搜索“环境变量” → 编辑系统环境变量 → 环境变量 → 用户变量的 `Path` → 新建 → 填入 `C:\flutter\bin`
4. **重新打开终端**使 `Path` 生效。


> 安装好flutter SDK后，在项目根目录下命令行中使用`flutter doctor`可以发现缺少的依赖工具
---

## 三、安装 Visual Studio C++ 桌面工具链（关键步骤）

### case1：当前Windows未安装Visual Studio 2022

Flutter 编译 Windows 桌面程序需要 **Visual Studio 2022（非 VS Code）** 的 C++ 桌面组件。

1. 安装 Visual Studio 2022 社区版/专业版：`https://visualstudio.microsoft.com/zh-hans/downloads/`
2. 安装器中勾选工作负载：**使用 C++ 的桌面开发**（Desktop development with C++）。
3. 在右侧“安装详细信息 / 单个组件”中，确认包含以下三项（运行 `flutter doctor` 报缺的正是这些，建议手动再点一遍确保勾选）：
   - ☑ **MSVC v142 - VS 2019 C++ x64/x86 生成工具（Latest）**
   - ☑ **C++ CMake 工具 for Windows**
   - ☑ **Windows 10 SDK**（Windows 11 SDK 亦可）
4. 点击“修改”完成安装（体积较大，耐心等待）。
5. 安装完成后**重新打开终端**。

> ⚠️ 仅安装 VS Code 不够，必须有完整的 Visual Studio 2022 + C++ 桌面工作负载，否则 `flutter run -d windows` 会在原生构建阶段失败。

### case2：当前当前Windows安装了Visual Studio 2022，但组件不全

以我的电脑为例，项目根目录命令行下运行`flutter doctor`:

```powershell
(base) PS X:xxx\xxx\ankihelper-pc> flutter doctor
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.44.5, on Microsoft Windows [Version 10.0.22631.4249], locale zh-CN)
[✓] Windows Version (11 ????? 64 ?, 23H2, 2009)
[✗] Android toolchain - develop for Android devices
    ✗ Unable to locate Android SDK.
      Install Android Studio from: https://developer.android.com/studio/index.html
      On first launch it will assist you in installing the Android SDK components.
      (or visit https://flutter.dev/to/windows-android-setup for detailed instructions).
      If the Android SDK has been installed to a custom location, please use
      `flutter config --android-sdk` to update to that location.

[✓] Chrome - develop for the web
[!] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.14.6 (June 2025))
    ✗ Visual Studio is missing necessary components. Please re-run the Visual Studio installer for the "Desktop
      development with C++" workload, and include these components:
        MSVC v142 - VS 2019 C++ x64/x86 build tools
         - If there are multiple build tool versions available, install the latest
        C++ CMake tools for Windows
        Windows 10 SDK
[✓] Connected device (3 available)
[✓] Network resources

! Doctor found issues in 2 categories.
```

根据 `flutter doctor` 的输出，你的开发环境目前缺少两个关键部分：

1. **Android 工具链**（用于构建 Android 应用）—— 完全未安装。【**当前项目是个pc端跨平台项目，不考虑移动端，所以直接忽略**】
2. **Visual Studio 组件**（用于构建 Windows 桌面应用）—— 已安装 VS 但缺少必要的 C++ 工作负载。

以下是具体的解决办法：

---

#### 修复 Visual Studio 桌面开发组件

你的 Visual Studio Community 2022 已安装，但缺少 **“使用 C++ 的桌面开发”** 工作负载及其子组件。

操作步骤：

1. 打开 **Visual Studio Installer**（在开始菜单中可以找到）。
2. 在已安装的 Visual Studio Community 2022 旁边，点击 **“修改”**。
3. 在“工作负载”选项卡中，勾选 **“使用 C++ 的桌面开发”**（Desktop development with C++）。
4. 右侧“安装详细信息”中，确保以下**必选**组件被勾选（通常默认会带，但请确认）：
   - **MSVC v142 - VS 2019 C++ x64/x86 生成工具**（如果列出多个版本，选最新的）
   - **C++ CMake tools for Windows**
   - **Windows 10 SDK**（版本无所谓，选最新的即可）
5. 点击右下角的 **“修改”** 按钮，等待安装完成（可能需要几 GB 空间）。

安装完成后，重新打开终端，再次运行 `flutter doctor`，Visual Studio 项应该通过。

---

## 四、运行项目

打开终端，进入项目根目录：

```bash
cd D:\DOCS\Codes\ankihelper-pc

# 拉取 Dart/Flutter 依赖（对应 CI: .github/workflows/build.yml 中的 flutter pub get）
flutter pub get

# 启动调试版（带热重载）
flutter run -d windows
```

应用窗口会弹出，标题栏显示 **“Anki划词助手 - v0.1”**。

可选——构建可发布的 release 版本（对应 CI 的 `flutter build windows --release`）：

```bash
flutter build windows --release
# 产物位于 build\windows\x64\runner\Release\
```

---

### 安装依赖和运行项目时遇到Windows系统的权限和功能设置问题：

我这边安装依赖并运行遇到了问题，cmd显示的内容如下：

```powershell
(base) PS D:\DOCS\Codes\ankihelper-pc> flutter pub get
xxxxx
xxxxx
......
xxxxx
12 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
Building with plugins requires symlink support.

Please enable Developer Mode in your system settings. Run
  start ms-settings:developers
to open settings.


(base) PS D:\DOCS\Codes\ankihelper-pc> flutter run -d windows
Flutter assets will be downloaded from https://mirrors.tuna.tsinghua.edu.cn/flutter. Make sure you trust this source!
Launching lib\main.dart on Windows in debug mode...
Error: Building with plugins requires symlink support.

Please enable Developer Mode in your system settings. Run
  start ms-settings:developers
to open settings.
```

从提供的日志来看，**依赖包的下载和配置已经成功完成了**（`Changed 109 dependencies!`），现在遇到的核心问题与镜像源无关，而是Windows系统的一个**权限和功能设置**问题。

错误信息 `Building with plugins requires symlink support` 非常明确地指出了原因：Flutter在Windows上构建项目时，需要使用**符号链接（symlink）**功能，而系统当前没有启用对它的支持。

#### 解决方案：开启Windows开发者模式

这是唯一且必须的步骤。请按以下操作执行：

1.  **直接运行命令**：在刚才的CMD或PowerShell窗口中，直接运行提示中的命令：
    ```cmd
    start ms-settings:developers
    ```
    这会直接打开Windows设置的“开发者选项”页面。

2.  **或者手动打开**：
    *   打开Windows“设置” -> “更新和安全” -> “开发者选项”。
    *   （在Win11中，路径可能是“设置” -> “系统” -> “开发者选项”）。

3.  **开启开关**：在页面中，找到 **“开发人员模式”** 开关，并将其**打开**。系统可能会提示需要安装一些组件，请允许并等待完成。

4.  **重启终端**：完成设置后，**关闭并重新打开**你的PowerShell或CMD窗口，然后再次运行 `flutter run -d windows`。

---


## 五、验证运行成功

### 第 1 层：工具链（编译前）
```bash
flutter doctor
```
要求（针对 Windows 桌面）：
- ✅ Flutter、✅ Dart、✅ **Visual Studio**（显示 “Visual Studio 2022” 且为对勾）
- ⚠️ Android toolchain 的 ✗ 可**忽略**（桌面应用不需要 Android SDK）
- 其他如 Chrome / iOS 相关红叉也可忽略

若 Visual Studio 那项是红叉，回到**第三步**补装 C++ 桌面工作负载即可。

### 第 2 层：能跑起来（编译后）
- `flutter run -d windows` 能编译通过并弹出窗口，标题栏为 **“Anki划词助手”**。
- 窗口底部状态栏显示 **“状态：✅ 就绪”** —— 说明主流程启动成功、无崩溃。
- 状态栏 `AnkiConnect: 未连接` 是**正常现象**（未运行 Anki 时），不代表运行失败。

### 第 3 层（可选功能验证）
- 复制一句英文（如 `This is an example sentence`），回到应用：剪贴板区出现原文，单词块区域切分出 `This / is / an / example / sentence` 等可点击块 → 说明剪贴板监听 + 分词引擎工作正常。
- 点击「设置」填写翻译 API 的 appId/secret 并保存后，词典查询可返回释义（无密钥时仅显示“手动编辑卡片”空条目，属设计内兜底）。

---

## 六、配置说明（启动无硬依赖）

应用**启动没有任何外部依赖**，以下服务均为可选，未配置也能正常运行：

- **翻译 / 词典 API 凭证**：通过应用内「设置」对话框填写 appId / secret，使用 `shared_preferences` 持久化。**无需 `.env` 文件**（仓库 `.env` 已被 gitignore，且运行时并不读取它）。
- **AnkiConnect**：可选。需自行在 Anki 中安装 AnkiConnect 插件并运行 Anki，状态栏才会显示“已连接”；未连接时仅无法一键制卡。
- **本地词典**：可选。通过「设置」导入 AnkiHelper 格式 `.txt` 词典并自动建索引；不导入时词典查询走云端（需配置凭证）或仅手动编辑。

---

## 七、常见问题

| 现象 | 原因 / 解决 |
|------|-------------|
| `flutter doctor` 中 Visual Studio 为红叉 | 未装 C++ 桌面工作负载，回到第三步补装 |
| `flutter run` 卡在原生构建 / 报 MSVC / CMake 错误 | 同上，确认 MSVC v142、CMake、Windows 10 SDK 三项已勾选 |
| 状态栏 `AnkiConnect: 未连接` | 正常，未运行 Anki 或未装 AnkiConnect 插件 |
| 复制英文后无单词块 | 确认窗口已获得焦点、剪贴板监听正常；可点「刷新翻译」重试 |
| 词典查询仅显示空条目 | 未配置有道智云 API 凭证，去「设置」填写 |

---

## 参考来源

- `README.md` — 技术栈、核心功能与流程图（确认各项服务均为可启用/可选）。
- `.github/workflows/build.yml` — 官方 CI 命令：`flutter doctor` / `flutter pub get` / `flutter build windows --release`。
- `lib/main.dart`、`lib/app.dart` — 启动仅 `runApp(ProviderScope(...))`，无外部初始化阻塞。
- `lib/services/anki_connect_service.dart`、`lib/services/dictionary_service.dart` — 外部服务失败时仅返回错误提示而非崩溃。
- `lib/widgets/settings_dialog.dart` — API 凭证通过应用内设置 UI 配置，不依赖 `.env`。
- `windows/CMakeLists.txt` — 仅要求 `cxx_std_17`，未硬编码特定 MSVC 工具集版本。
