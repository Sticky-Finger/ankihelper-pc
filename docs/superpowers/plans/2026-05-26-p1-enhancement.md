# P1功能（体验增强）实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 实现 P1功能（体验增强），包括移除冗余的"手动输入"按钮，以及添加有道词典查询 API 支持自动填充音标和释义字段

**架构:** 移除已废弃的 `manual_input_dialog.dart`，新增 `DictionaryService` 调用有道词典 API，新增 `dictionary_provider` 管理词典查询状态，在 `word_selection_provider` 的防抖流程中集成词典查询，在设置面板添加词典 API 配置说明（复用翻译服务配置），在结果列表添加手动搜索按钮

**技术栈:** 有道智云词典 API (v2/dict), `package:http`, SHA-256 签名 (复用 `crypto` 包), Riverpod 状态管理

**核心文件结构:**
```
lib/
├── models/
│   └── dictionary_result_model.dart     # [新建] 词典查询结果模型
├── services/
│   └── dictionary_service.dart          # [新建] 有道词典 API 服务
├── providers/
│   ├── dictionary_provider.dart         # [新建] 词典查询状态管理
│   └── word_selection_provider.dart     # [修改] 集成词典查询到防抖流程
├── widgets/
│   ├── title_bar.dart                   # [修改] 移除手动输入按钮
│   ├── settings_dialog.dart             # [修改] 添加词典服务说明
│   └── results_list.dart                # [修改] 添加手动搜索按钮
└── widgets/
    └── manual_input_dialog.dart         # [删除] 已废弃
```

---

## Tasks

### Task 1: 移除"手动输入"按钮及关联代码 ✅

**修改文件:**
- `lib/widgets/title_bar.dart` — 删除手动输入按钮、`onManualInput` 参数及 `manual_input_dialog.dart` 导入

**删除文件:**
- `lib/widgets/manual_input_dialog.dart`

**实现内容:**
- [x] 删除 `manual_input_dialog.dart` 文件（61 行）
- [x] 修改 `title_bar.dart`：移除 `import 'manual_input_dialog.dart'`、`onManualInput` 参数、手动输入按钮

**验证:**
```bash
flutter run --debug
```
应用正常启动，标题栏只显示主题切换、设置、关于三个按钮

---

### Task 2: 创建词典查询结果模型 ✅

**创建文件:**
- `lib/models/dictionary_result_model.dart`

**实现内容:**
- `DictionaryResult` 模型类，包含 `rawResponse`（原始 JSON）、`errorMessage`（错误信息）
- `fromYoudaoResponse()` 工厂方法仅检查 `errorCode`，暂不实现字段解析
- `_getYoudaoErrorMessage()` 静态方法映射错误码
- `isSuccess` getter 判断查询是否成功
- `empty` 静态常量表示空结果

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 3: 创建有道词典 API 服务 ✅

**创建文件:**
- `lib/services/dictionary_service.dart`

**实现内容:**
- `DictionaryService` 类，接受 `TranslationConfig` 和 `timeout` 参数（默认 5 秒）
- `query(String word)` 方法调用有道词典 API（`https://openapi.youdao.com/v2/dict`）
- `_queryYoudao()` 私有方法执行 HTTP 请求，支持超时控制
- `_generateYoudaoSign()` 方法生成 SHA-256 签名（复用翻译服务算法）
- 错误处理：超时、网络错误、API 错误码
- 复用翻译 API 的 `appId` 和 `appSecret`（仅支持有道智云）

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 4: 创建词典查询 Provider ✅

**创建文件:**
- `lib/providers/dictionary_provider.dart`

**实现内容:**
- [x] `DictionaryState` 状态类，包含 `result`、`isLoading`、`hasError`
- [x] `DictionaryNotifier` 状态管理类：
  - `updateConfig(TranslationConfig)` 更新 API 配置
  - `query(String word)` 异步查询单词
  - `clear()` 清空结果
- [x] `dictionaryProvider` — 对应的 `NotifierProvider`
- [x] `dictionaryConfigProvider` — 监听翻译配置变化，自动更新词典服务

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 5: 集成词典查询到 WordSelectionNotifier ✅

**修改文件:**
- `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] 导入 `dictionary_provider.dart` 和 `toast_provider.dart`
- [x] 修改 `_buildEntry()` 方法：暂不填充 `phonetic` 和 `meaning`，保留空值
- [x] 修改 `_debouncedRecompute()` 方法：在防抖回调中触发词典查询
- [x] 添加查询错误处理：当 `hasError` 时通过 `toastProvider` 显示错误信息

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 6: 添加词典 API 配置说明到设置面板

**修改文件:**
- `lib/widgets/settings_dialog.dart`

**实现内容:**
- 在翻译 API 配置区域下方添加"词典查询服务"说明卡片
- 说明内容：
  - 词典查询使用有道智云 API（与翻译服务共享凭证）
  - 查询超时时间：5 秒
- 使用 `Icons.info_outline` 图标，与现有样式一致

**验证:**
```bash
flutter run --debug
```
设置面板显示词典服务说明。

---

### Task 7: 在结果列表添加手动搜索按钮

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- 在词典标签容器（"📖 牛津高阶 (本地)"）右侧添加放大镜按钮
- `_manualSearch()` 方法：读取当前选中单词，调用 `dictionaryProvider.notifier.query()`
- 空选中时显示 Toast 提示"请先选择一个单词"
- 导入 `dictionary_provider.dart`

**验证:**
```bash
flutter run --debug
```
点击放大镜按钮重新触发词典查询。

---

### Task 8: 端到端测试与验证

**验证步骤:**

1. **验证手动输入按钮已移除**
   - 标题栏右上角只显示：主题切换、设置、关于

2. **配置有道智云 API**
   - 设置 → 翻译 API 配置 → 选择"有道智云" → 填写 App Key 和 App Secret

3. **测试自动词典查询**
   - 输入英文句子 → 选中单词 → 等待 300ms → 控制台打印原始 JSON 响应

4. **测试查询失败提示**
   - 断网 → 选中单词 → 显示 Toast 错误提示

5. **测试手动搜索按钮**
   - 选中单词 → 点击放大镜 → 重新触发查询

6. **测试可编辑模式**
   - 点击"剪贴板原文"输入框 → 输入英文 → 自动分词

7. **更新 PRD.md**
   - 勾选 `docs/PRD.md` 第 177-186 行 P1功能相关任务

---

### Task 9: 字段解析（根据实际返回数据实现）

**前提条件:**
- Task 8 完成，能够获取正确的 API 响应数据

**实现内容:**
- 根据实际返回数据结构，解析并提取：
  - 音标（phonetic, usPhonetic, ukPhonetic）
  - 释义（explain, explains）
  - 词性（synonyms.pos）
- 映射到 `CardEntryModel` 的 `phonetic`、`meaning`、`pos` 字段

**验证:**
- 选中单词后，结果列表显示音标和释义

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| DictionaryResult 模型 | 包含 phonetic、meaning 字段 | 仅包含 rawResponse、errorMessage | 两阶段实现策略：先获取响应，再解析字段 |
| 字段解析逻辑 | Task 2 中实现 | 独立为 Task 9 | 基于实际返回数据结构实现 |
