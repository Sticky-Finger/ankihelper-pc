# 发音服务 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 用户选中单词后可在应用内试听发音，添加卡片时发音 URL 自动填充到模板的「发音」字段

**架构:**
- `PronunciationService` — 管理多个发音源的 URL 模板（有道英音/有道美音等），提供 URL 拼装和音频播放方法
- `PronunciationProvider` — 持久化用户选择的发音源
- 发音按钮 + 发音源下拉选择器放在「当前选中词组」下方（`WordBlocksSection`），不在设置面板中重复
- 使用 `audioplayers` 包在应用内播放音频文件
- `CardEntryModel` 增加 `pronunciationUrl` 字段，在 `WordSelectionNotifier._buildEntry()` 中自动注入发音 URL
- `TemplateManager._knownFieldNames` 增加「发音」映射，使字段映射编辑器能自动识别

**技术栈:** Flutter, Riverpod, audioplayers, SharedPreferences

---

## Tasks

### Task 1: 添加 audioplayers 依赖

**修改文件:**
- `pubspec.yaml`

**实现内容:**
- 在 `dependencies:` 中添加 `audioplayers: ^6.4.0`
- 运行 `flutter pub get` 安装依赖

**验证:**
```bash
flutter pub get && flutter analyze
```
无报错。

---

### Task 2: 创建 PronunciationService（固定英音/美音）

**创建文件:**
- `lib/services/pronunciation_service.dart`

**实现内容:**
- `PronunciationSource` 枚举：`youdaoBrE`（有道英音）、`youdaoAmE`（有道美音）
- `PronunciationSourceMeta` 扩展：每个枚举值对应 `label`（中文显示名）和 `urlTemplate`（URL 模板，用 `{word}` 作占位符）
- `PronunciationService.getUrl(word, source)`：URL 编码单词后替换模板占位符，返回完整发音 URL
- `PronunciationPlayer.play(word, source)`：使用 `AudioPlayer` 播放指定单词的发音 URL；word 为空时用 `"test"` 做测试词

**验证:**
```bash
flutter analyze lib/services/pronunciation_service.dart
```
无报错。

---

### Task 3: 创建 PronunciationProvider

**创建文件:**
- `lib/providers/pronunciation_provider.dart`

**实现内容:**
- `PronunciationNotifier` — `Notifier<PronunciationSource>`，通过 SharedPreferences 持久化用户选择的发音源（存索引值 `int`）
- 默认值为 `PronunciationSource.youdaoAmE`（有道美音）
- 暴露 `setSource(PronunciationSource)` 方法，调用时同步更新 state 和持久化存储
- `pronunciationProvider` — 对应的 `NotifierProvider`

**验证:**
```bash
flutter analyze lib/providers/pronunciation_provider.dart
```
无报错。

---

### Task 4: CardEntryModel 增加 pronunciationUrl 字段

**修改文件:**
- `lib/models/card_entry_model.dart`

**实现内容:**
- 增加 `pronunciationUrl` 字段（`String`，默认值 `''`）
- 在构造函数参数列表和 `toMap()` 方法中同步添加该字段

**验证:**
```bash
flutter analyze lib/models/card_entry_model.dart
```
无报错。

---

### Task 5: WordSelectionNotifier 自动注入发音 URL

**修改文件:**
- `lib/providers/word_selection_provider.dart`

**实现内容:**
- 导入 `PronunciationService` 和 `pronunciationProvider`
- 修改 `_buildEntry()` 方法：读取当前发音源配置，调用 `PronunciationService.getUrl()` 生成发音 URL，传入 `CardEntryModel`

**验证:**
```bash
flutter analyze lib/providers/word_selection_provider.dart
```
无报错。

---

### Task 6: 模板字段映射支持「发音」字段

**修改文件:**
- `lib/services/template_manager.dart`

**实现内容:**
- 在 `_knownFieldNames` 映射表中增加 `'发音': 'pronunciationUrl'` 和 `'pronunciationUrl': 'pronunciationUrl'`，使字段映射编辑器能自动识别「发音」字段并对应到 `pronunciationUrl` 数据源

**验证:**
```bash
flutter analyze lib/services/template_manager.dart
```
无报错。

---

### Task 7: WordBlocksSection 添加发音按钮 + 发音源下拉

**修改文件:**
- `lib/widgets/word_blocks_section.dart`

**实现内容:**
- 导入 `PronunciationService` 和 `pronunciationProvider`
- 在「当前选中词组」容器下方新增一行控制条，包含：
  - **播放发音按钮**：点击后调用 `PronunciationPlayer.play()`，有选中词则播放选中词发音，否则用 "test" 试听
  - **发音源下拉选择器**：展示 `PronunciationSource.values` 所有选项，切换后实时更新 Provider
- 样式匹配现有 Fluent 2 设计风格（圆角容器、`bgInput` 背景、`stroke3` 描边）

**验证:**
```bash
flutter analyze lib/widgets/word_blocks_section.dart
```
无报错。

**手工测试：**
1. 启动应用，复制一段英文文本
2. 在单词块区域选中一个单词（如 "hello"）
3. 看到「当前选中词组」下方出现「播放发音」按钮和「有道美音」下拉
4. 点击播放发音按钮，应听到该单词的美式发音
5. 下拉切换到「有道英音」，点击播放发音按钮，应听到英式发音
6. 取消所有选中状态，点击播放发音按钮，应播放 "test" 的发音（说明无选中词时使用测试词）
7. 关闭应用重新打开，确认发音源下拉保持上次选择的选项

---

### Task 8: 端到端验证（发音流程走通）

- [ ] **步骤 1：运行完整分析**

```bash
flutter analyze
```
无新增报错。

- [ ] **步骤 2：运行测试**

```bash
flutter test
```
全部通过。

- [ ] **步骤 3：手工测试完整制卡流程**

1. 启动 Anki Desktop + AnkiConnect
2. 启动应用，复制一段英文句子到剪贴板
3. 选中一个单词，点击播放发音按钮确认能听到发音
4. 点击「预览」，确认预览弹窗中「发音」字段自动填充了有道发音 URL（格式如 `https://dict.youdao.com/dictvoice?audio=hello&type=1`）
5. 点击「添加到 Anki」
6. 在 Anki 中查看刚刚添加的卡片，确认正面显示发音按钮或音频可播放

- [ ] **步骤 4：提交代码**

```
feat(pronunciation): 添加发音服务 - 支持有道英音/美音 URL 自动填充与试听
```

---

### Task 9: 发音源增删管理

**修改文件:**
- `lib/services/pronunciation_service.dart`
- `lib/providers/pronunciation_provider.dart`
- `lib/widgets/settings_dialog.dart` 或 `word_blocks_section.dart`

**实现内容:**
- 将发音源从固定枚举改为可扩展的数据结构（内置不可删 + 用户自定义可增删）
- 内置发音源：有道英音、有道美音（不可删除）
- 用户可添加自定义发音源：输入名称和 URL 模板（含 `{word}` 占位符）
- 用户可删除自定义发音源
- 发音源列表持久化到 SharedPreferences
- 发音下拉选择器同步更新
- 管理入口放在发音按钮旁边（如小齿轮图标或「管理」按钮），打开管理弹窗进行操作

**验证:**
```bash
flutter analyze
```
无报错。

**手工测试：**
1. 点击发音源旁边的管理按钮，确认弹窗显示有道英音、有道美音（不可删除）
2. 点击添加，输入名称「Google 美音」、URL 模板 `https://example.com/audio/{word}.mp3`
3. 确认下拉选择器中出现新增的「Google 美音」
4. 选中它后播放发音，应调用新 URL
5. 删除自定义的「Google 美音」，确认下拉中已移除
6. 确认有道英音/有道美音不可删除（删除按钮灰色或隐藏）
7. 关闭应用重新打开，确认自定义发音源仍然存在

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
