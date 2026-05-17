# Anki划词助手 Phase 1 — UI 组件层 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 基于 Fluent 2 Design 设计原型（`docs/anki-word-helper.html`），使用 Flutter Desktop 完整实现 Anki划词助手的所有 UI 组件，包括主题系统、标题栏、剪贴板区域、单词块区域、结果列表、预览弹窗、状态栏、Toast 通知、设置/关于/手动输入弹窗。

**架构:** 组件化架构，每个 UI 区域封装为独立 Widget。主题通过 `FluentTokens` 类 + Riverpod `StateNotifier` 管理亮色/暗色切换。单词选中状态通过 Provider 管理。所有组件在 `MainScreen` 中组装。

**技术栈:** Flutter Desktop (macOS), Dart, Riverpod (状态管理)

**核心文件结构:**
```
lib/
├── main.dart                           # 应用入口
├── app.dart                            # MaterialApp + MainScreen
├── theme/
│   ├── fluent_tokens.dart              # Fluent 2 设计令牌（所有色值/尺寸常量）
│   └── theme_provider.dart             # 亮色/暗色主题切换
├── widgets/
│   ├── fluent_buttons.dart             # Fluent 按钮合集
│   ├── title_bar.dart                  # 标题栏
│   ├── clipboard_section.dart          # 剪贴板区域
│   ├── word_blocks_section.dart        # 单词块区域（含选中逻辑）
│   ├── word_token.dart                 # 单个单词块组件
│   ├── results_list.dart               # 结果列表容器
│   ├── result_entry.dart               # 单个结果条目
│   ├── preview_modal.dart              # 卡片预览弹窗
│   ├── status_bar.dart                 # 状态栏
│   └── toast_notification.dart         # Toast 通知
├── models/
│   ├── word_token_model.dart           # 单词块数据模型
│   └── card_entry_model.dart           # 卡片条目数据模型
└── providers/
    ├── word_selection_provider.dart     # 单词选中状态
    ├── card_data_provider.dart          # 卡片条目数据
    └── toast_provider.dart              # Toast 状态
```

---

## Tasks

### Task 1: 初始化 Flutter Desktop 项目 ✅

**前置条件:**
- 通过 `brew install --cask flutter` 安装 Flutter SDK
- 运行 `flutter doctor` 确认环境正常，按提示安装 Xcode 及命令行工具
- 启用 macOS Desktop 支持: `flutter config --enable-macos-desktop`

**步骤:**

1. **创建 Git feature 分支**:
   ```bash
   git checkout -b feature/phase1-ui
   ```

2. **创建项目骨架**（在 `ankihelper-pc` 根目录直接初始化）:
   ```bash
   flutter create . --project-name ankihelper
   ```

3. **添加依赖** – 运行 `flutter pub add flutter_riverpod` 自动安装最新稳定版

4. **修改文件:**
   - `lib/main.dart` — 应用入口，`ProviderScope` 包裹
   - `lib/app.dart` — `MainScreen` 骨架（`Column` 布局，各组件用 `TODO` 占位）
   - 目录结构（`lib/theme/` 等）在各 Task 实现时按需创建

**验证:**
```bash
flutter pub get && flutter analyze
```
无报错，并且 `flutter run -d macos` 能正常启动空白窗口。

---

### Task 2: 实现 Fluent 2 主题系统 ✅

**创建文件:**
- `lib/theme/fluent_tokens.dart` — FluentTokens 类，包含亮色/暗色共 42 个色值变量（bg/fg/stroke/status 四类）、字体字号字重、间距、圆角、阴影常量
- `lib/theme/theme_provider.dart` — ThemeState + ThemeNotifier (Notifier)，提供 `themeProvider` 和 `fluentTokensProvider`

**验证:** `flutter analyze` 无报错 ✅

---

### Task 3: 实现 Fluent 按钮合集 ✅

**创建文件:**
- `lib/widgets/fluent_buttons.dart` — 四种样式按钮：`SubtleButton`（透明背景+hover灰）、`OutlineButton`（边框）、`PrimaryButton`（品牌色填充）、`IconSubtleButton`（图标按钮）

---

### Task 4: 实现标题栏 ✅

**创建文件:**
- `lib/widgets/title_bar.dart` — 左侧：应用图标+标题"Anki划词助手"+版本号"v0.1"；右侧：主题切换/设置/关于/手动输入按钮

**修改文件:**
- `lib/app.dart` — 将 TitleBar 接入 MainScreen

---

### Task 5: 实现剪贴板区域 ✅

**创建文件:**
- `lib/widgets/clipboard_section.dart` — 区域标题"剪贴板原文"、原文展示框、翻译展示框、刷新翻译按钮

**修改文件:**
- `lib/app.dart` — 接入 ClipboardSection

---

### Task 6: 实现单词块数据模型与选中状态管理 ✅

**创建文件:**
- `lib/models/word_token_model.dart` — WordTokenModel（text/index/type）+ tokenize() 分词函数
- `lib/providers/word_selection_provider.dart` — WordSelectionState（tokens/selectedIndices/lastClickedIndex），支持单击单选/Shift+连续多选/Cmd+切换选中

---

### Task 7: 实现单词块组件与单词块区域 ✅

**创建文件:**
- `lib/widgets/word_token.dart` — 单个单词块（圆角边框+hover高亮+选中态品牌色，标点符号灰色）
- `lib/widgets/word_blocks_section.dart` — 标题行、Wrap 网格展示单词块、选中词组展示区域。通过 `HardwareKeyboard` 检测 Shift/Meta 修饰键实现多选

**修改文件:**
- `lib/app.dart` — 接入 WordBlocksSection

---

### Task 8: 实现卡片条目模型与结果列表 ✅

**创建文件:**
- `lib/models/card_entry_model.dart` — CardEntryModel（id/word/phonetic/pos/meaning/example）
- `lib/providers/card_data_provider.dart` — CardDataNotifier 管理条目列表
- `lib/widgets/result_entry.dart` — 支持空条目（虚线边框+▶+空标签）和释义条目（序号/单词/音标/词性/释义/添加+预览按钮）
- `lib/widgets/results_list.dart` — 区域标题+词典标签（牛津高阶）、ListView（首条固定空条目+释义条目列表）、底部提示文字

**修改文件:**
- `lib/app.dart` — 接入 ResultsList（Expanded 包裹）

---

### Task 9: 实现预览弹窗 ✅

**创建文件:**
- `lib/widgets/preview_modal.dart` — PreviewCardData 数据类；弹窗包含遮罩层、标题"卡片预览"+关闭按钮、四字段展示（正面/音标/背面/例句）、底部取消+添加到 Anki 按钮。支持点击遮罩层关闭

---

### Task 10: 实现状态栏 ✅

**创建文件:**
- `lib/widgets/status_bar.dart` — StatusItem 数据类；三组状态指示（就绪/AnkiConnect/词典查询），每组含圆点指示器（绿/黄/红）+ 标签文字，分隔线隔开

**修改文件:**
- `lib/app.dart` — 接入 StatusBar

---

### Task 11: 实现 Toast 通知系统 ✅

**创建文件:**
- `lib/providers/toast_provider.dart` — ToastState（message/isVisible）+ ToastNotifier
- `lib/widgets/toast_notification.dart` — ToastOverlay 包裹子组件，底部居中显示，含入场滑入+淡入动画，2秒自动消失

**修改文件:**
- `lib/app.dart` — MainScreen 用 ToastOverlay 包裹

---

### Task 12: 实现设置/关于/手动输入弹窗 ✅

**创建文件:**
- `lib/widgets/about_dialog.dart` — 简易 Dialog，展示应用名称+版本+描述
- `lib/widgets/settings_dialog.dart` — 骨架（后续填充词典管理/牌组选择/API配置）
- `lib/widgets/manual_input_dialog.dart` — 骨架（后续填充文本输入框）

**修改文件:**
- `lib/widgets/title_bar.dart` — 连接设置/关于/手动输入按钮的 onPressed 事件

---

### Task 13: 组装主界面 + 整体验证 ✅

**修改文件:**
- `lib/app.dart` — 最终完整布局：TitleBar → SingleChildScrollView(ClipboardSection + WordBlocksSection + Divider + ResultsList) → StatusBar，ToastOverlay 包裹

**验证:** `flutter pub get && flutter analyze` 无报错 ✅

---

### Task 14: UI 样式验证与修复 ✅

**目标:** 运行应用，对照设计原型逐项校验 UI 样式，修复发现的样式偏差。

**步骤:**

1. **启动应用:** `flutter run -d macos`
2. **对照设计原型逐项检查**（通过 OpenDesign MCP 查看 `anki-word-helper.html`）:
   - [x] **主题系统:** 亮色/暗色切换是否正常，背景色是否正确
   - [x] **标题栏:** 图标、标题、版本号位置；按钮组间距；主题切换图标是否正确切换
   - [x] **剪贴板区域:** 卡片圆角、内边距、原文/翻译展示框样式
   - [x] **单词块区域:** Wrap 网格间距、单词块圆角边框/hover 色/选中品牌色、标点灰色
   - [x] **选中词组展示:** 标签+词组文字颜色、底框样式
   - [x] **分隔线:** 颜色、边距
   - [x] **结果列表:** 标题+词典标签、空条目虚线边框、条目 hover 高亮、操作按钮组
   - [x] **预览弹窗:** 遮罩层、弹窗圆角阴影、字段标签/值样式、底部按钮
   - [x] **状态栏:** 圆点颜色、分隔线、文字间距
   - [x] **Toast 通知:** 入场动画、位置、自动消失
   - [x] **设置/关于/手动输入弹窗:** 布局正确性

3. **记录所有样式偏差**，逐项修复对应 Widget 文件

**验证:** 所有 UI 元素样式与设计原型一致，无视觉偏差后标记完成。
