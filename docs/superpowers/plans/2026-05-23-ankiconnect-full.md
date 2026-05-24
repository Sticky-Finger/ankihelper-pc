# AnkiConnect 完整功能 + 手动添加 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现统一的模板管理机制（从文件解析而非硬编码）、预览确认后添加、例句高亮，以及空条目手动编辑添加功能。

**架构:** 模板的所有细节（字段、CSS、正反面 HTML、字段映射）均从 `.html` + `.json` 文件解析，内置模板和未来用户导入的模板共用同一套解析和注册逻辑。先实现手动导入，再实现首次运行自动导入内置模板。

**执行顺序:** 先完成 Task 1/2/2.7/4/5/6/7/8，最后执行 Task 3（内置模板自动导入）。

**技术栈:** Flutter, Riverpod, AnkiConnect JSON-RPC, SharedPreferences

**核心文件结构:**
```
assets/template01/
├── vocabulary_card_model.html    # [已有] 模板 HTML（4 段 @@@ 分隔）
└── vocabulary_card_model.json    # [Task 2b] 模板配置（name + fieldMapping）

lib/
├── models/
│   ├── card_template_model.dart    # [Task 2a] 纯数据类 + [Task 2.7] isDeletable
│   └── card_entry_model.dart       # [Task 2a] 新增 toMap()
├── services/
│   ├── anki_connect_service.dart   # [已完成] modelNames / createModel / modelFieldNames
│   └── template_manager.dart       # [Task 2a] 统一解析器 + 动态 buildFields
├── providers/
│   └── template_provider.dart      # [Task 2a] 动态模板列表 + [Task 2.7] removeTemplate + [Task 2b] 启动自动导入
├── widgets/
│   ├── settings_dialog.dart        # [Task 2a] 添加"导入模板"按钮 + [Task 2.7] 删除按钮
│   ├── results_list.dart           # [已完成] 自定义模板 + 例句高亮
│   ├── result_entry.dart           # [Task 3] 支持编辑模式
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

### Task 2: 手动导入 HTML 模板 ✅

**目标:** 在设置弹窗添加"导入模板"按钮，用户选择 HTML 文件后解析并注册到 Anki，导入的模板作为默认选项。

**修改文件:**
- `lib/models/card_template_model.dart` — 删除硬编码预设，纯数据类
- `lib/services/template_manager.dart` — 重写：4 段解析器 + 动态 buildFields
- `lib/providers/template_provider.dart` — 支持动态添加模板、设置默认
- `lib/widgets/settings_dialog.dart` — 添加"导入模板"按钮 + 文件选择器
- `lib/models/card_entry_model.dart` — 新增 `toMap()` 方法

**实现内容:**

#### 2.1 CardTemplateModel 简化 ✅

- 删除 `static const vocabulary` 和 `static const basic` 预设
- 保留纯数据类：`id`、`name`、`fields`、`fieldMapping`

#### 2.2 CardEntryModel 扩展 ✅

- 新增 `toMap()` 方法：返回 `Map<String, String>`（字段名→值），用于动态字段映射
  ```dart
  Map<String, String> toMap() => {
    'word': word,
    'phonetic': phonetic,
    'meaning': meaning,
    'example': example,
    'exampleTranslation': exampleTranslation,
  };
  ```

#### 2.3 TemplateManager 重写 ✅

- `parseHtml(String html)` — 统一解析器，按 `@@@` 分割为 4 段（front/back/css/fields），第 4 段按换行得到字段名列表
- `parseHtmlFromFile(String filePath)` — 从文件路径读取 HTML 内容后调用 parseHtml
- `importFromFile(String filePath, AnkiConnectService service)` — 完整导入流程：解析 HTML → 注册到 Anki → 返回 CardTemplateModel
- `ensureModelExists(service, template)` — 检查 Anki 中是否已注册，未注册则调用 `createModel`
- `buildFields(template, entry)` — 遍历 `template.fieldMapping`，从 `entry.toMap()` 取值，只添加非空字段

#### 2.4 TemplateProvider 重构 ✅

- `presetTemplates` 改为动态列表，包含 Anki 自带的 basic 模板 + 用户导入的模板
- `importTemplate(String filePath)` — 调用 TemplateManager 导入，添加到列表第一位，设为默认
- basic 模板作为 Anki 自带模板始终出现在列表中（id='basic', name='基础卡片', fields=['Front','Back'], fieldMapping={word→Front, meaning→Back})
- 持久化用户导入的模板路径到 SharedPreferences，下次启动自动加载

#### 2.5 设置弹窗 — 导入模板入口 ✅

- 在"卡片模板"区域添加"导入模板"按钮
- 点击后打开文件选择器（file_picker），过滤 .html 文件
- 导入成功后 Toast 提示，下拉列表更新，新模板设为默认
- 导入失败（格式错误、Anki 连接失败）显示错误提示

#### 2.6 模板名称冲突处理 ✅

- 选择文件后，自动检测文件名是否与已有模板重名
- 重名时预填充 `<文件名>-<数字>` 格式的建议名称（自动递增数字）
- 弹出模板名称确认对话框，显示建议名称
- 对话框中实时验证：输入框下方显示"该模板名称已存在"错误提示
- 重名时"确认导入"按钮禁用，直到名称唯一
- macOS 需添加 `com.apple.security.files.user-selected.read-only` 权限

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 打开设置 → 卡片模板区域出现"导入模板"按钮
2. 点击"导入模板" → 选择 `assets/template01/vocabulary_card_model.html`
3. 弹出名称确认框 → 确认后 Toast 提示导入成功
4. 下拉列表第一位显示新模板，字段映射区正确显示所有映射
5. 再次导入同一文件 → 弹窗预填充 `<文件名>-2`，实时验证重名
6. 修改为不重名的名称 → 按钮恢复可用 → 导入成功
7. 选中单词 → 添加卡片 → Anki 中确认使用导入的模板
8. 关闭应用 → 重新打开 → 设置中模板列表保持
9. `flutter analyze` 无报错

---

### Task 2.7: 已有模板删除功能 ✅

**目标:** 在设置弹窗中删除已导入的模板，内置模板（如"基础卡片"）不可删除。

**修改文件:**
- `lib/models/card_template_model.dart` — 添加 `isDeletable` getter
- `lib/providers/template_provider.dart` — 添加 `removeTemplate()` 方法
- `lib/widgets/settings_dialog.dart` — 添加删除按钮 UI

**实现内容:**

#### 2.7.1 CardTemplateModel 添加 isDeletable

- 添加 `bool get isDeletable`：`id != 'basic' && !id.startsWith('builtin_')` 时为 true
- 基础卡片和未来内置模板不可删除

#### 2.7.2 TemplateNotifier 添加 removeTemplate

- `removeTemplate(String templateId)` — 从 `_templates` 列表移除，从 SharedPreferences 持久化路径中移除
- 删除的是当前选中模板时，自动切换到基础卡片
- 不可删除的模板调用此方法时静默忽略
- 通过重新赋值 `state` 触发 UI 更新

#### 2.7.3 设置弹窗 — 删除按钮

- 将"选择模板"下拉框和删除按钮放在同一行（Row）
- 仅当 `currentTemplate.isDeletable` 时显示删除按钮
- 点击删除按钮弹出二次确认对话框
- 删除成功后 Toast 提示

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 先导入一个模板 → 选中它 → 下拉框右侧出现红色删除按钮
2. 选择"基础卡片" → 删除按钮不显示
3. 选中导入的模板 → 点击删除按钮 → 弹出确认对话框
4. 点击"取消" → 模板保留
5. 再次点击删除 → 确认删除 → 模板从列表消失，自动切换到"基础卡片"，Toast 提示"模板已删除"
6. 关闭应用 → 重新打开 → 已删除的模板不再出现在列表中
7. `flutter analyze` 无报错

---

### Task 4: 设置面板 — 模板选择入口

（已完成，无需改动 — 已通过 templateProvider 读取模板列表）

---

### Task 5: ResultsList — 使用自定义模板 + 例句高亮

（已完成，无需改动 — 已通过 templateProvider + TemplateManager 工作）

---

### Task 6: 预览弹窗 — 确认后触发添加

（已完成，无需改动）

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

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 空条目显示可编辑输入框（单词、释义）
2. 不输入任何内容 → "添加卡片"按钮为灰色不可点击
3. 输入单词和释义后 → 按钮变为可点击状态
4. `flutter analyze` 无报错

---

### Task 8: ResultsList — 空条目编辑集成

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- 空条目的 `ResultEntry` 传入 `isEditable: true`
- `onAdd` 回调接收编辑后的 `CardEntryModel`，使用自定义模板调用 `_addNoteToAnki`
- "预览编辑"按钮读取当前输入框内容传入 `showPreviewModal`

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 空条目显示可编辑输入框
2. 输入单词和释义后点击"添加卡片"，Anki 中确认使用自定义模板，字段正确填充
3. 点击"预览编辑" → 弹窗显示当前输入框内容 → 确认后添加成功
4. 空输入时按钮不可点击
5. `flutter analyze` 无报错

---

### Task 3: 内置模板自动导入（首次运行）⚠️ 最后执行

**目标:** 首次运行应用时，自动将内置 `vocabulary_card_model.html` 导入 Anki。

**新增文件:**
- `assets/template01/vocabulary_card_model.json`

**修改文件:**
- `lib/providers/template_provider.dart` — 启动时检测并自动导入内置模板
- `pubspec.yaml` — 确认 assets 包含 `.json`

**实现内容:**

#### 3.1 创建内置模板配置文件

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

#### 3.2 TemplateProvider 启动自动导入

- `build()` 时：检查 Anki 中是否已存在"词汇卡片"模型
  - 已存在 → 跳过，从 Anki 获取字段列表构建 CardTemplateModel
  - 不存在 → 从 assets 加载 HTML + JSON → 调用 `createModel` 注册
- 内置模板添加到列表中（用户导入的模板仍排第一）

**验证（需用户手动操作）:**
```bash
# 先在 Anki 中手动删除"词汇卡片"模型（如果存在）
flutter run -d macos
```
1. 启动应用 → 设置 → 下拉列表出现"词汇卡片"和"基础卡片"
2. 选择"词汇卡片" → 字段映射区正确显示所有映射
3. 添加卡片 → Anki 中确认使用"词汇卡片"模板
4. 关闭应用 → 重新打开 → Anki 中不重复创建"词汇卡片"模型
5. `flutter analyze` 无报错

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| 模板数据模型 | 静态常量预设 | 从 .html + .json 文件动态加载 | 用户要求不硬编码 |
| HTML 解析器 | 3 段 @@@ 分割 | 4 段 @@@ 分割（含字段名） | 原实现忽略了第 4 段 |
| 字段映射 | 硬编码 switch | 遍历 fieldMapping + entry.toMap() | 统一动态映射 |
| basic 模板名 | "基础卡片" 直接传给 addNote | template.id=='basic' 时用 "Basic" | Anki 内置模型名为 "Basic" |
| 模板导入顺序 | 先自动导入内置模板 | 先手动导入，再自动导入 | 用户要求手动导入优先 |
| 模板名称冲突 | 未考虑 | 实时验证 + 预填充建议名称 | 用户要求重名时提示且不让提交 |
| macOS 文件权限 | 未考虑 | 添加 files.user-selected.read-only | file_picker 需要沙箱权限 |
| 模板删除 | 未考虑 | isDeletable + removeTemplate + 删除按钮 | 用户要求可删除已导入模板，内置模板不可删 |
