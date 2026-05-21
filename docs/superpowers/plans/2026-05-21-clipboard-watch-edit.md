# 剪贴板监听与原文编辑 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现剪贴板自动监听（clipboard_watcher + 300ms 防抖）、原文区域可编辑（TextField + on blur 确认）、编辑期间暂停剪贴板监听、文本变化后自动触发分词。

**架构:** 新建 `ClipboardNotifier`（Riverpod Notifier）管理剪贴板原文和编辑状态，集成 `clipboard_watcher` 包监听系统剪贴板。`ClipboardSection` 从纯展示改为可编辑 `TextField`。`WordBlocksSection` 监听剪贴板 Provider 自动分词，替换硬编码示例数据。

**技术栈:** Flutter, Riverpod 3.x, clipboard_watcher, dart:async

**核心文件结构:**
```
lib/
├── providers/
│   └── clipboard_provider.dart        # [新建] 剪贴板状态 + clipboard_watcher 监听 + 防抖
├── widgets/
│   ├── clipboard_section.dart         # [修改] 原文改为可编辑 TextField，on blur 触发更新
│   └── word_blocks_section.dart       # [修改] 监听剪贴板 Provider 自动分词，移除硬编码
└── app.dart                           # [修改] ClipboardSection 改为无参调用
```

---

## Tasks

### Task 1: 添加 clipboard_watcher 依赖

**修改文件:**
- `pubspec.yaml`

**实现内容:**
- 在 `dependencies` 中添加 `clipboard_watcher: ^3.0.0`
- 运行 `flutter pub get`

**验证:**
```bash
flutter pub get
```
依赖安装成功。

---

### Task 2: 创建剪贴板 Provider

**创建文件:**
- `lib/providers/clipboard_provider.dart`

**实现内容:**
- `ClipboardState` — 持有 `originalText`（String）和 `isEditing`（bool）
- `ClipboardNotifier` — `Notifier<ClipboardState>`，实现 `ClipboardListener` 接口
  - `build()` 时注册 clipboard_watcher 监听，`ref.onDispose` 时清理
  - `onClipboardChanged()` — 编辑期间跳过；否则 300ms 防抖后读取剪贴板文本，仅内容变化时更新 state
  - `setText(String)` — 手动设置原文（编辑完成时调用）
  - `setEditing(bool)` — 设置编辑状态
- `clipboardProvider` — 对应的 `NotifierProvider`

**验证:**
```bash
flutter analyze lib/providers/clipboard_provider.dart
```
无报错。

---

### Task 3: 改造 ClipboardSection 为可编辑

**修改文件:**
- `lib/widgets/clipboard_section.dart`

**实现内容:**
- 从 `ConsumerWidget` 改为 `ConsumerStatefulWidget`，移除构造函数参数（`originalText`、`translationText`、`onRefreshTranslation`）
- 原文展示框：非编辑状态显示静态 `Text`（占位文案改为"点击输入或等待剪贴板内容..."），点击进入编辑模式
- 编辑模式：显示 `TextField`（`maxLines: null`，`autofocus: true`），边框变为 `strokeFocus` 高亮
- `FocusNode` 监听 `onFocusChange`：光标离开时结束编辑 → `setEditing(false)` → `setText(controller.text.trim())`
- 翻译行暂时保留静态展示（翻译服务未实现）

**验证:**
```bash
flutter analyze lib/widgets/clipboard_section.dart
```
无报错。

---

### Task 4: 连接 app.dart 并更新 WordBlocksSection

**修改文件:**
- `lib/app.dart`
- `lib/widgets/word_blocks_section.dart`

**实现内容:**
- `app.dart` 第 84-87 行：`ClipboardSection` 改为无参调用 `const ClipboardSection()`
- `word_blocks_section.dart` `initState`：移除硬编码示例数据，改为 `ref.listen(clipboardProvider, ...)` 监听文本变化，文本非空时调用 `tokenize()` 更新 `wordSelectionProvider`；初始化时若已有文本则立即分词

**验证:**
```bash
flutter run -d macos
```
1. 启动后剪贴板区域显示占位文案
2. 复制英文文本 → 原文自动更新，单词块自动分词
3. 点击原文区域 → 进入编辑模式，输入文本 → 点击外部（on blur）→ 单词块自动更新
4. 编辑期间复制新内容不会覆盖编辑中的文本

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| （待填写） | | | |
