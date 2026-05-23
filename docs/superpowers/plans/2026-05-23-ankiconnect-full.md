# AnkiConnect 完整功能 + 手动添加 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现自定义卡片模板注册与字段映射（替代硬编码 Basic 模型）、预览确认后添加、例句高亮，以及空条目手动编辑添加功能。

**架构:** 先实现模板基础（模型注册、字段映射、Provider），再集成到添加流程，最后实现空条目编辑。模板配置在设置面板中选择，启动时自动应用默认模板并注册到 Anki。

**技术栈:** Flutter, Riverpod, AnkiConnect JSON-RPC, SharedPreferences

**核心文件结构:**
```
lib/
├── models/
│   ├── card_template_model.dart    # [新建] 模板配置数据模型
│   └── card_entry_model.dart       # [修改] 新增 exampleTranslation 字段
├── services/
│   ├── anki_connect_service.dart   # [修改] 新增 modelNames / createModel / modelFieldNames
│   └── template_manager.dart       # [新建] 模板注册、字段映射、HTML 解析
├── providers/
│   └── template_provider.dart      # [新建] 模板选择状态 + 持久化
├── widgets/
│   ├── settings_dialog.dart        # [修改] 新增卡片模板选择入口 + 字段映射展示
│   ├── results_list.dart           # [修改] 使用自定义模板 + 例句高亮 + 空条目编辑
│   ├── result_entry.dart           # [修改] 支持编辑模式
│   └── preview_modal.dart          # [修改] 确认后触发添加
```

---

## 第一部分：AnkiConnect 完整功能

### Task 1: AnkiConnect 服务扩展 — 模板管理 API

**修改文件:**
- `lib/services/anki_connect_service.dart`

**实现内容:**
- 新增 `getModelNames()` → 调用 `modelNames` action，返回 `List<String>`
- 新增 `createModel({name, css, frontTemplate, backTemplate, fieldNames})` → 调用 `createModel` action
- 新增 `getModelFieldNames(modelName)` → 调用 `modelFieldNames` action，返回 `List<String>`

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 2: 模板数据模型 + 管理服务

**创建文件:**
- `lib/models/card_template_model.dart`
- `lib/services/template_manager.dart`

**实现内容:**
- `CardTemplateModel` 数据类：`id`、`name`、`fields`（字段名列表）、`fieldMapping`（`Map<String, String>` 应用字段→模板字段）
- 预设两个配置：`vocabulary`（词汇卡片，7 字段）和 `basic`（基础卡片，Front/Back）
- `TemplateManager`：
  - `ensureModelExists(service, template)` — 检查模型是否存在，不存在则从 `assets/template01/vocabulary_card_model.html` 读取 HTML 并调用 `createModel` 注册
  - `buildFields(template, entry)` — 根据字段映射将 `CardEntryModel` 转为 `Map<String, String>`

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 3: 模板 Provider + CardEntryModel 扩展

**创建/修改文件:**
- `lib/providers/template_provider.dart`（新建）
- `lib/models/card_entry_model.dart`（修改）

**实现内容:**
- `CardEntryModel` 新增 `exampleTranslation` 字段（默认空字符串）
- `TemplateNotifier`：`build()` 从 SharedPreferences 读取已保存模板 ID（默认 `vocabulary`），`selectTemplate(id)` 切换并持久化，暴露 `presetTemplates` 列表

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 4: 设置面板 — 模板选择入口

**修改文件:**
- `lib/widgets/settings_dialog.dart`

**实现内容:**
- 新增"卡片模板"配置区（在"翻译 API 配置"上方）
- 下拉列表展示两个预设配置，从 `templateProvider` 读取
- 选中后下方展示字段映射配置区（只读，灰色文字展示映射关系）
- 切换时调用 `templateProvider.selectTemplate()`

**验证:**
```bash
flutter run -d macos
```
1. 打开设置，看到"卡片模板"下拉，两个选项可切换
2. 下方映射区实时更新
3. 关闭重开，选择保持

---

### Task 5: ResultsList — 使用自定义模板 + 例句高亮

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- `_addNoteToAnki`：读取 `templateProvider`，调用 `TemplateManager.ensureModelExists()` 确保模板已注册，调用 `TemplateManager.buildFields()` 构建字段 Map，替换硬编码的 `modelName: 'Basic'` 和 `fields`
- 例句高亮：构建 `example` 字段时，将选中词汇用 `<b>` 包裹（从 `wordSelectionProvider` 获取选中文本，替换原文中首次出现）

**验证:**
```bash
flutter run -d macos
```
1. 选中单词后点击添加，Anki 中确认使用自定义模板
2. 例句字段中选中词汇有高亮（`<b>` 标签）
3. 切换到"基础卡片"模板后，添加的卡片使用 Front/Back 字段

---

### Task 6: 预览弹窗 — 确认后触发添加

**修改文件:**
- `lib/widgets/preview_modal.dart`
- `lib/widgets/results_list.dart`

**实现内容:**
- `showPreviewModal` 返回可编辑的 `PreviewCardData`（用户可修改字段后确认）
- 预览弹窗字段改为可编辑 `TextField`
- `PreviewCardData` 新增 `exampleTranslation` 字段
- `ResultsList` 中预览确认后，用返回数据构建 `CardEntryModel` 并调用 `_addNoteToAnki`

**验证:**
```bash
flutter run -d macos
```
1. 点击"预览"，弹窗展示可编辑字段
2. 修改释义后点击"添加到 Anki"，卡片使用修改后内容
3. 点击"取消"不触发添加

---

## 第二部分：词典查询引擎 — Phase 1：手动添加

### Task 7: 空条目可编辑 — ResultEntry 编辑模式

**修改文件:**
- `lib/widgets/result_entry.dart`

**实现内容:**
- 新增 `isEditable` 参数（默认 `false`），空条目传入 `isEditable: true`
- 编辑模式下单词和释义区域变为 `TextField`（Fluent 风格边框）
- `onAdd` 回调签名改为 `void Function(CardEntryModel entry)`，传递编辑后的数据
- 无输入时按钮 disabled

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 8: ResultsList — 空条目编辑集成

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- 空条目的 `ResultEntry` 传入 `isEditable: true`
- `onAdd` 回调接收编辑后的 `CardEntryModel`，使用 Task 5 中已切换的自定义模板调用 `_addNoteToAnki`
- "预览编辑"按钮读取当前输入框内容传入 `showPreviewModal`

**验证:**
```bash
flutter run -d macos
```
1. 空条目显示可编辑输入框
2. 输入单词和释义后点击"添加卡片"，Anki 中确认使用自定义模板
3. 空输入时按钮不可点击

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| — | — | — | — |
