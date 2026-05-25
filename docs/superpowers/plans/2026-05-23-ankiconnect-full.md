# AnkiConnect 完整功能 + 手动添加 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现统一的模板管理机制（从文件解析而非硬编码）、可编辑的字段映射配置、预览确认后添加、例句高亮，以及空条目手动编辑添加功能。

**架构:** 模板的所有细节（字段、CSS、正反面 HTML）从 `.html` 文件解析。字段映射独立存储：导入时默认映射（首字段→单词，其余→空），用户在设置弹窗中通过 Select 选择器配置，配置随模板持久化。

**执行顺序:** Task 1/2/2.7/4/5/6 已完成。Task 2.8（模板系统修复）已完成。Task 7/8（选中驱动结果列表）已完成。最后执行 Task 3（内置模板自动导入）。

**当前进度:**
- Task 2.8: ✅ 全部完成（1~8）
- Task 7.1: ✅ WordSelectionState 增强
- Task 7.2: ✅ 删除 cardDataProvider，数据源切换到 wordSelectionProvider
- Task 7.3: ✅ 清理 isPlaceholder 冗余，添加按钮 word 为空时 disabled
- FluentButton: ✅ 新增 disabled 样式（onPressed==null 时灰色、无 hover）
- Task 8: ✅ 数据源切换、预览弹窗动态字段、添加流程均已实现

**技术栈:** Flutter, Riverpod, AnkiConnect JSON-RPC, SharedPreferences

**核心文件结构:**
```
assets/template01/
├── vocabulary_card_model.html    # [已有] 模板 HTML（4 段 @@@ 分隔）
└── vocabulary_card_model.json    # [Task 3] 模板配置（name + fieldMapping）

lib/
├── models/
│   ├── card_template_model.dart    # [已完成] 纯数据类 + isDeletable + frontHtml/backHtml/css
│   └── card_entry_model.dart       # [已完成] toMap()
├── services/
│   ├── anki_connect_service.dart   # [已完成] modelNames / createModel / modelFieldNames
│   └── template_manager.dart       # [已完成] 统一解析器 + 动态 buildFields + ensureModelFields
├── providers/
│   ├── word_selection_provider.dart # [已完成] 增强：currentEntry + 多词高亮
│   ├── clipboard_provider.dart     # [已完成] 剪贴板原文 + 锁定功能
│   ├── translation_provider.dart   # [已有] 原文翻译
│   └── template_provider.dart      # [已完成] 动态模板列表 + removeTemplate + updateFieldMapping
├── widgets/
│   ├── settings_dialog.dart        # [已完成] 字段映射编辑器集成
│   ├── field_mapping_editor.dart   # [已完成] 字段映射编辑器（Select 自动保存）
│   ├── results_list.dart           # [Task 8] watch wordSelectionProvider
│   ├── result_entry.dart           # [Task 7] 编辑模式：全部字段可编辑
│   └── preview_modal.dart          # [已完成] 动态字段渲染
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

### Task 2.8: 模板系统修复 — 导入不依赖 Anki + 添加卡片时模板验证

**问题:**
1. `importFromFile` 中 `_registerToAnki` 失败会阻塞整个导入（Anki 未打开时导入失败）
2. 添加卡片时没有验证 Anki 中模板的字段是否匹配
3. app 中删除模板不同步删除 Anki 中的模型

**修改文件:**
- `lib/services/template_manager.dart`
- `lib/providers/template_provider.dart`
- `lib/widgets/results_list.dart`（`_addNoteToAnki` 中调用新验证逻辑）
- `lib/models/card_template_model.dart`（添加 frontHtml/backHtml/css 字段）

**实现内容:**

#### 2.8.1 导入模板：best-effort 注册 ✅

- `importFromFile` 中 `_registerToAnki` 包裹 try-catch，失败不抛异常
- 模板正常返回并存入本地，Anki 注册延迟到添加卡片时
- 设计原则：导入模板 = 本地操作（解析 + 存储），不依赖 Anki

#### 2.8.2 CardTemplateModel 添加 HTML 字段 ✅

- 新增 `frontHtml`/`backHtml`/`css` 字段（默认空字符串）
- `importFromFile` 和 `loadFromAssets` 在构建时从 parsed 中传入

#### 2.8.3 添加卡片：模板验证逻辑（替换 `ensureModelExists`） ✅

- **使用模板自身存储的 HTML 注册到 Anki**（不再从 `assets/template01/` 读取）
- 基础卡片（`id=='basic'`）跳过验证，直接用 Anki 内置模型名 "Basic"

添加卡片前，执行以下验证流程：

```
1. 获取 Anki 中所有模型名 → getModelNames()
2. 检查 app 模板名是否在 Anki 中
   ├─ 不在 → 使用模板的 frontHtml/backHtml/css 调用 createModel，添加卡片
   └─ 在 → 获取该模型的字段 → getModelFieldNames()
       ├─ 字段匹配 → 直接用这个模型添加卡片
       └─ 字段不匹配 →
           a. 递增后缀找到可用名（<原名>-1，-2...）
           b. 用新名 createModel
           c. 添加卡片
           d. 返回 renamedFrom 信息
```

#### 2.8.4 TemplateNotifier 暴露模板名更新方法 ✅

- 新增 `updateTemplateName(String templateId, String newName)` 方法
- 更新 `_templates` 列表中对应模板的 name
- 更新 `state`（当前选中模板）
- 持久化到 SharedPreferences

#### 2.8.5 `_addNoteToAnki` 接入新逻辑 + 宽松字段验证 ✅

- 替代原有的 `ensureModelExists` 调用，接入 2.8.3 的新验证
- 新验证返回实际的模型名 + 是否重命名，重命名时调用 `updateTemplateName` 并 Toast 提示
- **去除了"所有字段必须填满"的隐含限制**：
  - `buildFields` 只输出非空字段
  - `addNote` 前检查构建后的 `fields` 是否**全部为空**（`fields.isEmpty`）
  - 全部为空时才拒绝添加，只要**至少有一个字段非空**就允许添加
  - 兼容自定义模板（不一定有 "word" 字段）

#### 2.8.6 修复 _buildDefaultMapping 中文→英文映射 ✅

- 添加 `_knownFieldNames` 映射表（中文→英文）
- 导入模板时自动识别常见字段名（单词→word、音标→phonetic、释义→meaning、例句→example、例句翻译→exampleTranslation）
- 未知字段（如 url、发音）不加入默认映射
- `buildFields` 改用 `_knownFieldNames` 查找到的英文 key 去 `entry.toMap()` 取值

#### 2.8.7 字段映射配置 UI + 持久化 ✅

**目标:** 用户可在设置弹窗中查看和修改每个模板的字段映射，映射配置随模板持久化。修改 Select 即自动保存，无需额外按钮。

**新建文件:**
- `lib/widgets/field_mapping_editor.dart` — 字段映射编辑器组件

**修改文件:**
- `lib/widgets/settings_dialog.dart` — 用字段映射编辑器替换原有的只读展示区
- `lib/providers/template_provider.dart` — 映射持久化 + 保存方法

**UI 数据源（4 个可选值）:**
| 数据源 | 说明 |
|--------|------|
| `单词` | 当前选中词组 |
| `例句` | 剪贴板原文 |
| `例句翻译` | 翻译 API 结果 |
| `空` | 空字符串（默认值） |

**字段映射编辑器（field_mapping_editor.dart）:**
- 每行左侧显示模板字段名（label），右侧为 Select 下拉选择器
- 选项：单词、例句、例句翻译、空
- 显示格式：`<模板字段名> ← <选中的数据源>`
- 导入默认映射：第一个模板字段→`单词`，其余→`空`
- 基础卡片写死：`Front ← 单词`、`Back ← 空`
- 底部"保存映射"按钮

**持久化（template_provider.dart）:**
- 新增 `saveFieldMapping(String templateId, Map<String, String> mapping)` 方法
- 映射以 JSON 存入 SharedPreferences（key: `field_mapping_$templateId`）
- 加载模板时从持久化恢复映射
- 删除模板时同步清除映射

#### 2.8.8 预览弹窗动态字段渲染 ✅

**修改文件:** `lib/widgets/preview_modal.dart`

**实现内容:**
- 预览弹窗根据选中模板的字段列表动态生成输入框，label 为模板字段名
- 输入框初始值按字段映射从 UI 数据源预填充：
  - 映射→`单词`：填入 `entry.word`
  - 映射→`例句`：填入 `entry.example`
  - 映射→`例句翻译`：填入 `entry.exampleTranslation`
  - 映射→`空`：填入空字符串
- 用户可在预览弹窗中修改任何字段值
- 确认添加时返回 `Map<String, String>`（字段名→值）
- 移除硬编码的四个输入框，`PreviewCardData` 替换为 `Map<String, String>`

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 导入模板 → 设置中查看字段映射 → 默认首字段→单词，其余→空
2. 修改映射 → 保存 → 关闭设置 → 重新打开 → 映射保持
3. 选中单词 → 预览编辑 → 弹窗动态显示模板字段，label 正确
4. 字段值按映射预填充
5. 修改预览字段 → 添加到 Anki → 卡片内容正确
6. 删除模板 → 重新导入 → 映射恢复默认
7. `flutter analyze` 无报错

---

### Task 4: 设置面板 — 模板选择入口

（已完成，无需改动）

---

### Task 5: ResultsList — 使用自定义模板 + 例句高亮

（已完成，无需改动 — 已通过 templateProvider + TemplateManager 工作）

---

### Task 6: 预览弹窗 — 确认后触发添加

（已完成，无需改动）

---

## 第二部分：词典查询引擎 — Phase 1：手动添加

### Task 7: 选中驱动结果列表 — wordSelectionProvider 增强

**目标:** 选中单词块后，结果列表立即显示预填充的空条目（单词、例句、翻译来自 UI 状态）。不硬编码任何单词数据。

**修改文件:**
- `lib/providers/word_selection_provider.dart` — 增强：新增 `currentEntry` 派生
- `lib/widgets/result_entry.dart` — 编辑模式支持全部字段
- 删除 `lib/providers/card_data_provider.dart`

**实现内容:**

#### 7.1 WordSelectionState 增强 ✅

- 新增 `currentEntry` (CardEntryModel): 从选中状态 + 剪贴板 + 翻译自动派生
- Provider 内 watch `clipboardProvider` 和 `translationProvider`，任一变化时重算 `currentEntry`
- **防抖逻辑**：selectedText 变化后延迟 300ms 再重算 `currentEntry`
  - 使用 `Timer` 或 Riverpod 的 `ref.listen` + debounce 模式
  - 300ms 内再次变化则重置计时器
  - 剪贴板原文 / 翻译 的变化不防抖（变化频率低，且用户期望即时响应）
- 构建规则：
  - `word` = selectedText（无选中时为空）
  - `example` = 剪贴板原文，选中词用 `<b>` 包裹（无选中时为原始剪贴板文本）
  - `exampleTranslation` = 翻译文本（无翻译时为空）
  - `phonetic` / `meaning` = 空（Phase 1 无词典）

#### 7.2 删除 cardDataProvider

- 删除 `lib/providers/card_data_provider.dart`
- 搜索所有引用处，替换为 `wordSelectionProvider.currentEntry`

#### 7.3 ResultEntry 清理冗余 + 按钮禁用 ✅

- 删除 `isPlaceholder` 参数和所有相关逻辑（▶、"[空条目]"、虚线边框）
- 条目显示统一的序号、单词、音标、释义
- word 为空时"添加"按钮 disabled
- FluentButton 新增 disabled 样式（灰色、无 hover 反馈）

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 不选中任何单词 → 结果列表显示空条目，所有字段为空
2. 选中 "example" → 空条目预填充：单词=`example`，例句=`This is an <b>example</b>.`，翻译=原文翻译
3. Shift+多选 "example sentence" → 单词变为 `example sentence`，例句高亮对应词组
4. 取消所有选中 → 回到全空状态
5. 快速连续点击多个单词块 → 结果列表只在停止点击 300ms 后更新一次（不闪烁）
6. 剪贴板原文变化 → 结果列表即时更新（不走防抖）
7. `flutter analyze` 无报错

---

### Task 8: ResultsList — 选中驱动集成 ✅

**目标:** ResultsList 直接监听 `wordSelectionProvider`，渲染 `currentEntry`。

**实现内容:**
- 移除对 `cardDataProvider` 的 watch，改为 `ref.watch(wordSelectionProvider)` 获取 `currentEntry`
- 结果列表使用 `currentEntry` 数据展示，word 为空时按钮 disabled
- `onAdd` 使用当前模板调用 `_addNoteToAnki`
- `_addNoteToAnki` 中使用 Task 2.8 的模板验证逻辑（替换原 `ensureModelExists`）
- "预览"按钮打开动态字段预览弹窗，确认后调用 `_addNoteWithFields`

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 选中单词 → 结果列表立即显示预填充的空条目
2. 编辑字段后点击"添加卡片" → Anki 中确认字段正确
3. 点击"预览编辑" → 弹窗显示全部字段，均可编辑 → 确认后添加成功
4. 单词为空时"添加卡片"不可点击
5. `flutter analyze` 无报错

---

### Task 3: 内置模板自动加载（启动时纯本地）⚠️ 最后执行

**目标:** 启动时从 assets 加载内置模板（纯本地，不碰 Anki）。添加卡片时由 `ensureModelFields` 延迟注册到 Anki，与手动导入模板的流程一致。

**设计原则:** 内置模板的加载方式与手动导入模板对齐：
- 手动导入：`File().readAsString()` → `parseHtml()` → 构造 `CardTemplateModel`（best-effort 注册 Anki）
- 内置模板：`rootBundle.loadString()` → `parseHtml()` → 构造 `CardTemplateModel`（不注册 Anki，延迟到加卡片）

**新增文件:**
- `assets/template01/vocabulary_card_model.json` — 内置模板配置（name + fieldMapping）

**修改文件:**
- `lib/providers/template_provider.dart` — `build()` 中异步加载 assets 模板
- `lib/services/template_manager.dart` — 复用现有 `parseHtml()`，不需要新方法

**无需修改:** `pubspec.yaml`（`assets/template01/` 已涵盖所有文件）

**实现内容:**

#### 3.1 创建内置模板配置文件

`assets/template01/vocabulary_card_model.json`：

格式与 `CardTemplateModel.fieldMapping` 的内存格式一致（`{模板字段名: 数据源key}`），读取后直接赋值，无需翻转。

```json
{
  "name": "词汇卡片",
  "fieldMapping": {
    "单词": "word",
    "音标": "phonetic",
    "释义": "meaning",
    "例句": "example",
    "例句翻译": "exampleTranslation"
  }
}
```

注意：
- "发音"和"url"字段不在 `_knownFieldNames` 中，无对应数据源，不在 JSON 中定义映射 → 默认映射为空，用户可在设置中手动配置
- 与手动导入的 `_buildDefaultMapping` 行为一致（未知字段不映射）

#### 3.2 TemplateProvider 启动时加载内置模板

`TemplateNotifier.build()` 扩展逻辑（已有 `_loadSelectedTemplateId` 的 fire-and-forget 模式）：

```
build()
  ├─ 添加基础卡片
  ├─ _loadBuiltinTemplate()     ← 新增：异步加载内置模板
  ├─ _loadSelectedTemplateId()  ← 已有
  └─ return 基础卡片（默认）
```

`_loadBuiltinTemplate()` 流程：

```
1. 检查 _templates 中是否已有 builtin_ 前缀的模板 → 有则跳过（防止重复加载）
2. rootBundle.loadString('assets/template01/vocabulary_card_model.html')
   → TemplateManager.parseHtml() → fields / frontHtml / backHtml / css
3. rootBundle.loadString('assets/template01/vocabulary_card_model.json')
   → json.decode() → name / fieldMapping
4. 构造 CardTemplateModel(
     id: 'builtin_vocabulary_card_model',
     name: '词汇卡片',
     fields: 解析结果.fields,
     fieldMapping: JSON 中的 mapping,
     frontHtml / backHtml / css: 解析结果,
   )
5. _templates.add(template)
6. 如果未选中任何模板 → state = template（首次启动默认选中内置模板）
   否则 → state = state（触发 UI 刷新）
7. 异常捕获：加载失败静默忽略（不阻塞启动）
```

**不注册到 Anki：** 与已有的 `inline ` 不同，`_loadBuiltinTemplate` 只做纯本地操作。注册 Anki 延迟到 `ensureModelFields`（add-card 时）。

#### 3.3 模板列表中模板的优先级

当前模板列表顺序（从 `TemplateNotifier` 的 `presetTemplates` 返回 `_templates`）：

1. 基础卡片（`id='basic'`，始终第一个添加）
2. 内置模板（`id='builtin_vocabulary_card_model'`，启动后异步加载）
3. 用户导入的模板（手动插入列表第一位）

**验证（需用户手动操作）:**
```bash
flutter run -d macos
```
1. 首次启动 → 设置 → 下拉列表出现"词汇卡片"和"基础卡片"（无 Anki 连接也正常显示）
2. 选择"词汇卡片" → 字段映射区正确显示所有映射（单词/音标/释义/例句/例句翻译）
3. 选中单词 → 添加卡片 → Anki 中自动创建"词汇卡片"模型，卡片内容正确
4. 关闭应用 → 重新打开 → 下拉列表仍然显示"词汇卡片"，Anki 中不重复创建
5. 若 Anki 中已存在同名但不同字段的"词汇卡片"模型 → 添加卡片时自动创建"词汇卡片-1"
6. `flutter analyze` 无报错

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
| cardDataProvider | 独立 provider 硬编码数据 | 删除，职责移入 wordSelectionProvider.currentEntry | 选中单词后结果列表无响应，需选中状态与数据合一 |
| 结果列表数据源 | cardDataProvider.entries | wordSelectionProvider.currentEntry | 选中变化 → 立即派生 entry → UI 刷新 |
| 空条目编辑字段 | 仅单词+释义 | 全部字段（单词/音标/释义/例句/例句翻译） | 用户要求预览编辑时所有字段可编辑 |
| 模板导入 | 必须连接 Anki | best-effort 注册，失败不阻塞 | 用户发现 Anki 未打开时导入失败 |
| 添加卡片模板验证 | ensureModelExists 仅检查名称+从 assets 注册 | 验证名称+字段，使用模板自身 HTML 注册 | 用户要求字段也要对上 |
| app 删除模板 | 仅删本地 | 需同步删除 Anki 中的模型 | 待实现 |
| 添加卡片字段验证 | 必须全部字段填满 | 至少一个字段非空即可 | 用户反馈全部填满才让添加不合理 |
| 模板重建数据源 | ensureModelExists 从 assets/template01/ 读 HTML | 使用模板自身存储的 frontHtml/backHtml/css | 导入的模板字段和 assets 的不同 |
| 字段映射来源 | 从 .json 配置文件解析 | UI 数据源（单词/例句/例句翻译/空）× 模板字段的 Select 选择器 | 用户要求直观可配置，且适配各种字段名的模板 |
| 字段映射默认值 | 预期手动逐个配置 | 首字段→单词，其余→空 | 用户要求在导入时直接可用 |
| 字段映射持久化 | 从 .json 文件读 | SharedPreferences JSON 字符串（模板 ID 索引） | 删除模板时方便一并清除 |
| 预览弹窗字段 | 写死 front/phonetic/back/example 四个 | 根据模板字段列表动态渲染 | 不同模板字段不同，无法硬编码 |
| _buildDefaultMapping | 模板字段名→自身 | 中文→英文映射表 | 中文模板字段名不匹配 entry.toMap() 的英文 key |
| 字段映射 key 方向 | {数据源key: 模板字段名} | {模板字段名: 数据源key} | 旧格式多个'空'字段 key 重复被覆盖，映射不保存、字段顺序乱跳 |
| 结果列表数据源 | cardDataProvider（硬编码 example） | wordSelectionProvider.currentEntry | 用户选中词后结果列表无响 |
| 剪贴板锁定功能 | 未规划 | isLocked + toggleLock + UI 锁按钮 | 用户反馈翻译复制时会覆盖原文 |
| 多词高亮 | 整个选中词组用 <b> 包裹 | 每个单词单独用 <b> 包裹 | 非连续选中词时整体替换不匹配 |
