# AnkiConnect 完整功能 + 手动添加 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现统一的模板管理机制（从文件解析而非硬编码）、预览确认后添加、例句高亮，以及空条目手动编辑添加功能。

**架构:** 模板的所有细节（字段、CSS、正反面 HTML、字段映射）均从 `.html` + `.json` 文件解析，内置模板和未来用户导入的模板共用同一套解析和注册逻辑。首次连接 Anki 时自动导入内置模板。

**技术栈:** Flutter, Riverpod, AnkiConnect JSON-RPC, SharedPreferences

**核心文件结构:**
```
assets/template01/
├── vocabulary_card_model.html    # [已有] 模板 HTML（4 段 @@@ 分隔）
└── vocabulary_card_model.json    # [新建] 模板配置（name + fieldMapping）

lib/
├── models/
│   ├── card_template_model.dart    # [重写] 纯数据类，删除硬编码预设
│   └── card_entry_model.dart       # [修改] 新增 exampleTranslation + toMap()
├── services/
│   ├── anki_connect_service.dart   # [已完成] modelNames / createModel / modelFieldNames
│   └── template_manager.dart       # [重写] 统一解析器 + 动态 buildFields
├── providers/
│   └── template_provider.dart      # [重写] 启动自动导入 + 动态模板列表
├── widgets/
│   ├── settings_dialog.dart        # [已完成] 模板选择入口
│   ├── results_list.dart           # [已完成] 自定义模板 + 例句高亮
│   ├── result_entry.dart           # [待做] 支持编辑模式
│   └── preview_modal.dart          # [已完成] 确认后触发添加
```

---

## 第一部分：AnkiConnect 完整功能

### Task 1: AnkiConnect 服务扩展 — 模板管理 API ✅

**修改文件:**
- `lib/services/anki_connect_service.dart`

**实现内容:**
- 新增 `getModelNames()` → 调用 `modelNames` action，返回 `List<String>`
- 新增 `createModel({name, css, frontTemplate, backTemplate, fieldNames})` → 调用 `createModel` action
- 新增 `getModelFieldNames(modelName)` → 调用 `modelFieldNames` action，返回 `List<String>`

**验证:** `flutter analyze` 无报错。

---

### Task 2: 统一模板管理 — 消除硬编码

**新增文件:**
- `assets/template01/vocabulary_card_model.json`

**修改文件:**
- `lib/models/card_template_model.dart`
- `lib/services/template_manager.dart`
- `lib/providers/template_provider.dart`
- `lib/models/card_entry_model.dart`
- `pubspec.yaml`

**实现内容:**

#### 2.1 创建内置模板配置文件

`assets/template01/vocabulary_card_model.json`：
```json
{
  "name": "词汇卡片",
  "fieldMapping": {
    "word": "单词",
    "phonetic": "音标",
    "meaning": "释义",
    "example": "例句",
    "exampleTranslation": "例句翻译"
  }
}
```

#### 2.2 CardEntryModel 扩展

- 新增 `toMap()` 方法：返回 `Map<String, String>`（字段名→值），用于动态字段映射

#### 2.3 CardTemplateModel 简化

- 删除 `static const vocabulary` 和 `static const basic` 预设
- 保留纯数据类：`id`、`name`、`fields`、`fieldMapping`

#### 2.4 TemplateManager 重写

- `parseHtml(String html)` — 统一解析器，按 `@@@` 分割为 4 段（front/back/css/fields），第 4 段按换行得到字段名列表
- `loadFromAssets(String basePath)` — 读取 `.html` + `.json`，组装为 `CardTemplateModel`
- `ensureModelExists(service, template)` — 检查 Anki 中是否已注册，未注册则调用 `createModel`
- `buildFields(template, entry)` — 遍历 `template.fieldMapping`，从 `entry.toMap()` 取值，只添加非空字段

#### 2.5 TemplateProvider 重构

- `build()` 时：加载内置模板 → 自动导入到 Anki → 恢复上次选中的模板 ID
- `basic` 模板作为 Anki 自带模板始终出现在列表中（id='basic', name='基础卡片', fields=['Front','Back'], fieldMapping={word→Front, meaning→Back})
- `presetTemplates` 返回动态列表

#### 2.6 pubspec.yaml

确认 `assets/template01/` 包含 `.json` 文件类型。

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 3: 设置面板 — 模板选择入口 ✅

（已完成，无需改动 — 已通过 templateProvider 读取模板列表）

---

### Task 4: ResultsList — 使用自定义模板 + 例句高亮 ✅

（已完成，无需改动 — 已通过 templateProvider + TemplateManager 工作）

---

### Task 5: 预览弹窗 — 确认后触发添加 ✅

（已完成，无需改动）

---

## 第二部分：词典查询引擎 — Phase 1：手动添加

### Task 6: 空条目可编辑 — ResultEntry 编辑模式

**修改文件:**
- `lib/widgets/result_entry.dart`

**实现内容:**
- 新增 `isEditable` 参数（默认 `false`），空条目传入 `isEditable: true`
- 编辑模式下单词和释义区域变为 `TextField`（Fluent 风格边框）
- `onAdd` 回调签名改为 `void Function(CardEntryModel entry)`，传递编辑后的数据
- 无输入时按钮 disabled

**验证:** `flutter analyze` 无报错。

---

### Task 7: ResultsList — 空条目编辑集成

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- 空条目的 `ResultEntry` 传入 `isEditable: true`
- `onAdd` 回调接收编辑后的 `CardEntryModel`，使用自定义模板调用 `_addNoteToAnki`
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
| 模板数据模型 | 静态常量预设 | 从 .html + .json 文件动态加载 | 用户要求不硬编码 |
| HTML 解析器 | 3 段 @@@ 分割 | 4 段 @@@ 分割（含字段名） | 原实现忽略了第 4 段 |
| 字段映射 | 硬编码 switch | 遍历 fieldMapping + entry.toMap() | 统一动态映射 |
| basic 模板名 | "基础卡片" 直接传给 addNote | template.id=='basic' 时用 "Basic" | Anki 内置模型名为 "Basic" |
