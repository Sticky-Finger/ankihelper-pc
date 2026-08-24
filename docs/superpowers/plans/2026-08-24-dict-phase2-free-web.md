# 词典查询引擎 Phase 2 实现计划（免费网页词典 + AI 词典）

> **[解冻]** 原有道智云付费 API 方案（包年 30 万）已废弃，本计划改用免费网页端词典接口，
> 一并实现原冻结的「云端词典请求」与「字段解析」两个 TODO 项。
> 查询逻辑提取自 kiss-translator 项目分析文档 `DICT_LOOKUP_LOGIC_EXTRACTION.zh-cn.md`
> （位于 `D:\ubuntu_docs\Codes\To-Study\kiss-translator\docs\code-analysis\component-analysis\`，仓库外路径；
> 本计划附录已收录全部关键规格——请求参数、选择器映射表、响应字段路径、AI 提示词全文——计划自包含，无外部依赖）。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 用免费网页词典接口（Bing 词典 HTML + 有道 jsonapi_s）+ 可选 AI 词典替换已冻结的有道智云付费 API，完成词典查询引擎 Phase 2：自动查词、字段解析（音标/词性/释义）、结果条目展示、字段映射扩展、状态栏接线。

**架构:** 参考 kiss-translator 的 `dictHandlers` 策略表设计。`lib/services/dict/` 下每个词典源一个独立模块（抓取与解析分离，解析为纯函数便于测试），`DictionaryService` 作为编排器负责回退链、超时与缓存；`dictionaryProvider` 管理查询状态与 AI 流式回调，`WordSelectionNotifier` 解冻 300ms 防抖触发并把义项转换为结果条目；结果列表按 PRD 原设计展示「空条目 + 义项条目」，AI 结果以 Markdown 卡片附加展示。

**技术栈:** `package:http`（含 `Client.send` SSE 流式）、`package:html`（新增，Bing HTML 解析）、`package:crypto`（缓存键/语境签名）、`package:markdown` + `flutter_markdown`（新增，AI 释义转 HTML 与渲染）、Riverpod、SharedPreferences

**核心文件结构:**
```
lib/
├── models/
│   ├── dictionary_result_model.dart     # [重写] 结构化词典结果（替代 rawResponse 字符串）
│   └── card_entry_model.dart            # [修改] 新增 aiDictMarkdown 字段
├── services/
│   ├── dict/                            # [新建] 词典源模块目录
│   │   ├── bing_dict_api.dart           # Bing HTML 抓取 + parseBingDictHtml 纯函数
│   │   ├── youdao_dict_api.dart         # 有道 jsonapi_s 抓取 + parseYoudaoDictJson 纯函数
│   │   ├── ai_dict_api.dart             # AI 词典（提示词 + OpenAI 兼容 + SSE 流式）
│   │   └── dict_cache.dart              # KV 缓存（内存 + SharedPreferences，7 天 TTL）
│   ├── dictionary_service.dart          # [重写] 编排器（策略表 + 回退链，删除付费 API 代码）
│   └── template_manager.dart            # [修改] aiDictMarkdown → HTML 转换
├── providers/
│   ├── dictionary_provider.dart         # [重写] 查询状态 + queriedWord 竞态守卫 + 流式回调
│   ├── dict_settings_provider.dart      # [新建] 词典源偏好 / AI 接口配置（持久化）
│   └── word_selection_provider.dart     # [修改] 解冻词典触发 + senseEntries 义项条目
├── widgets/
│   ├── results_list.dart                # [修改] 空条目+义项条目+AI卡片+词典标签+搜索按钮
│   ├── settings_dialog.dart             # [修改] 词典管理区落地，移除付费 API 说明卡
│   ├── field_mapping_editor.dart        # [修改] 新增音标/释义/AI 释义数据源
│   ├── status_bar.dart                  # [修改] 词典查询状态接真实数据
│   └── app.dart                         # [修改] 组装 dictStatus
└── pubspec.yaml                          # [修改] 新增 html / markdown / flutter_markdown
test/
├── fixtures/                            # [新建] Bing HTML / 有道 JSON 真实响应存档
├── models/dictionary_result_test.dart   # [新建]
└── services/dict/                       # [新建] 各解析器 + SSE + 缓存单测
```

## 关键设计决策

1. **词典源与回退链**：默认 `Bing → 有道 jsonapi_s → AI`（AI 需在设置中配置接口后才启用）；设置面板可指定首选源（自动/必应/有道/AI）。策略表架构为 Phase 3 本地词典预留扩展位（新增源 = 新增一个模块 + 注册表登记）。
2. **查询路由**：`isValidWord`（`/^[a-zA-Z-]+$/`，允许中划线连字符词）→ 传统词典链；词组/非纯单词 → 直接走 AI 词典（提示词自带"词典模式/纯翻译模式"智能路由）；全部不可用 → 手动模式兜底，制卡流程永不阻断。
3. **结果展示**：PRD 原设计「空条目 + 义项条目」。手动空条目始终第一条（`currentEntry` 不变），词典各义项转为 `senseEntries`（每条带 word/phonetic/pos/meaning，例句复用剪贴板原文 + `<b>` 高亮），复用现有 `ResultEntry` 的添加/预览/双击逻辑。
4. **AI 输出集成**：Markdown 不强拆为结构化字段。以独立卡片展示（`flutter_markdown` 渲染 + 复制按钮）+ 新增「AI 释义」数据源（`package:markdown` 转 HTML 写入 Anki 字段，附加在手动空条目上供映射）。
5. **解析与抓取分离**：`parseXxx` 为纯函数（`String`/`Map` → `DictionaryResult`），单测无需 HTTP mock；夹具为真实响应存档，词典网站改版时可回归定位。
6. **缓存**：键 = `sha256(source|word|contextSig)`，TTL 7 天；AI 的 `contextSig` = 剪贴板原句 SHA-256 前 16 位（同词不同语境独立缓存）。
7. **反爬对策**：Bing/有道请求带浏览器级 `User-Agent` 与 `Accept-Language` 头；Bing 解析不出词条视为该源本次不可用，静默切换下一源，不重试轰炸。

---

## Tasks

### Task 1: 新增依赖与目录结构

**修改文件:**
- `pubspec.yaml`

**实现内容:**
- [x] dependencies 新增：`html: ^0.18.2`、`markdown: ^7.0.0`、`flutter_markdown: ^0.7.0`
- [x] 创建 `lib/services/dict/` 目录
- [x] 确认 `flutter pub get` 通过、无版本冲突（flutter_markdown 与当前 Flutter SDK 兼容）

**验证:**
```bash
flutter pub get && flutter analyze
```

---

### Task 2: 重写 DictionaryResult 结构化模型

**修改文件:**
- `lib/models/dictionary_result_model.dart`（重写）

**实现内容:**
- [x] `enum DictionarySource { bing, youdao, ai }`
- [x] `class DictSense { final String pos; final String def; }`（词性 + 释义）
- [x] `class DictSentence { final String eng; final String chs; }`（双语例句）
- [x] `class DictionaryResult`：`source` / `word`（词条原型，即提取文档的 reWord）/ `ukPhonetic` / `usPhonetic` / `senses` / `sentences` / `inflections`（时态变形）/ `aiMarkdown`（AI 路线结果）/ `errorMessage`
- [x] 便捷 getter：`isSuccess`、`isAi`、`mergedPhonetic`（`英 [x] 美 [y]` 格式）
- [x] `toJson()` / `fromJson()`（供缓存持久化），删除原 `fromYoudaoResponse` 及错误码映射（付费 API 专用）
- [x] 新建 `test/models/dictionary_result_test.dart`：序列化往返、isSuccess 判定

**验证:**
```bash
flutter analyze && flutter test test/models/dictionary_result_test.dart
```

---

### Task 3: Bing 词典 API（抓取 + 纯函数解析 + 夹具测试）

**创建文件:**
- `lib/services/dict/bing_dict_api.dart`
- `test/fixtures/bing_dict_library.html`（真实页面存档，实现时 curl 抓取一次）
- `test/services/dict/bing_dict_parser_test.dart`

**实现内容:**
- [x] `fetchBingDict(String word, {Duration timeout})`：GET `https://www.bing.com/dict/search?q={word}&FORM=BDVSP6&cc=cn`，请求头带浏览器级 `User-Agent` 与 `Accept-Language`（提取文档 §5 反爬经验）
- [x] `DictionaryResult parseBingDictHtml(String html)` 纯函数，用 `package:html` 的 `parse().querySelector()` 按附录 A 选择器映射表逐条实现：
    - [x] 词条 `#headword > h1`（取不到 → 查询失败返回未收录）
    - [x] 基本释义 `div.qdef > ul > li` 的 `.pos` / `.def`
    - [x] 时态变形 `div.hd_div1>.hd_if>.p1-5`
    - [x] 音标与发音 `#bigaud_uk` / `#bigaud_us` 的 `data-mp3link` + 前兄弟元素 `[...]` 文本；为空时 `.hd_pr` / `.hd_prUS` 兜底
    - [x] 双语例句 `#sentenceSeg .se_li` 的 `.sen_en` / `.sen_cn`（两者都有值才收录）
- [x] 解析器测试：夹具覆盖全部字段断言（word/trs/aus/ecs/sentences/presents）、headword 缺失返回失败、空 HTML 容错

**验证:**
```bash
flutter test test/services/dict/bing_dict_parser_test.dart
```

---

### Task 4: 有道免费接口 jsonapi_s（POST + 解析 + 测试）

**创建文件:**
- `lib/services/dict/youdao_dict_api.dart`
- `test/fixtures/youdao_dict_library.json`（真实响应存档）
- `test/services/dict/youdao_dict_parser_test.dart`

**实现内容:**
- [x] `fetchYoudaoDict(String word, {Duration timeout})`：POST `https://dict.youdao.com/jsonapi_s?doctype=json&jsonversion=4`，body `q={word}&le=en&t=3&client=web&keyfrom=webdict`（form-urlencoded），`accept` / `accept-language` 头照搬提取文档 §2.2
- [x] `DictionaryResult parseYoudaoDictJson(Map<String, dynamic> json)` 纯函数，按附录 B 字段路径表提取：
    - [x] `ec.word["return-phrase"]` → word（词条原型）
    - [x] `ec.word.ukphone` / `ec.word.usphone` → 英/美音标
    - [x] `ec.word.trs[]` 的 `{pos, tran}` → senses
    - [x] `blng_sents_part["sentence-pair"][]` 的 `{sentence, sentence-translation}` → sentences
    - [x] `ec` 节点缺失 → 未收录（返回失败结果）
- [x] 解析器测试：夹具全字段断言、`ec` 缺失/空 trs 容错

**验证:**
```bash
flutter test test/services/dict/youdao_dict_parser_test.dart
```

---

### Task 5: 词典结果缓存

**创建文件:**
- `lib/services/dict/dict_cache.dart`
- `test/services/dict/dict_cache_test.dart`

**实现内容:**
- [x] 内存 `Map<String, _CacheEntry>` 一层 + `SharedPreferences` 持久化一层（值 = `DictionaryResult.toJson()` + 时间戳）
- [x] 键 = `sha256(source|word|contextSig)` 十六进制摘要；传统词典 `contextSig` 固定空串，AI = 剪贴板原句 SHA-256 前 16 位
- [x] TTL 7 天（`3600 * 24 * 7` 秒），读取时过期即视为未命中并清除
- [x] `Future<DictionaryResult?> get(String source, String word, String contextSig)` / `Future<void> put(...)` / `Future<void> clearAll()`（供设置面板"清除缓存"）
- [x] 惰性加载：首次访问时从 SharedPreferences 恢复内存层；写入节流（防抖批量落盘或直接同步写，量小可接受）

**验证:**
```bash
flutter test test/services/dict/dict_cache_test.dart
```

---

### Task 6: AI 词典 API（提示词移植 + OpenAI 兼容 + SSE 流式）

**创建文件:**
- `lib/services/dict/ai_dict_api.dart`
- `test/services/dict/ai_dict_api_test.dart`

**实现内容:**
- [x] `defaultDictPrompt`（系统提示词）与 `defaultDictUserPrompt`（用户提示词模板）**逐字移植**提取文档 §3.3（全文见附录 C），含 `createEnglishDictionaryPrompt` 的中文 labels 参数化
- [x] 占位符替换函数：`{{text}}`（查询单词）、`{{context}}`（剪贴板原句）、`{{title}}/{{description}}/{{summary}}` 填空串（纯字符串 replaceAll）
- [x] 请求构造（OpenAI 兼容协议）：`POST {baseUrl}/chat/completions`，`Authorization: Bearer {apiKey}`，body `{model, messages: [system, user], stream: true}`（messages 结构见附录 C 末尾示例）
- [x] SSE 流式：`http.Client().send()` 获取字节流 → 按 `\n\n` 分帧 → 取 `data: ` 后内容 → `[DONE]` 结束；每帧 `jsonDecode` 后取 `choices[0].delta.content`
- [x] `stripMarkdownCodeBlock(String text, {bool startOnly})`：流式期间只剥开头围栏，流结束剥结尾（提取文档 §3.6.2 逻辑）
- [x] `onStreamChunk(String markdown)` 回调：每次 delta 累积后全量推送（驱动 UI 渐进渲染）
- [x] 流式协议异常自动降级为非流式请求（`stream: false`，取 `choices[0].message.content`），降级记日志不报错
- [x] 结果为空 → 抛"词典返回为空"错误；超时 60 秒
- [x] 单测：占位符替换、SSE 帧拆分、delta 提取、剥围栏（开头/结尾/startOnly）、空响应

**验证:**
```bash
flutter test test/services/dict/ai_dict_api_test.dart
```

---

### Task 7: DictionaryService 编排重写（策略表 + 回退链）

**修改文件:**
- `lib/services/dictionary_service.dart`（重写）

**实现内容:**
- [x] 删除有道付费 API 调用、SHA-256 签名、`TranslationConfig` 耦合（免费接口无需凭证）
- [x] 策略表：`DictionarySource → apiFn`（bing/youdao/ai 三项注册，对应提取文档 §2.4 dictHandlers 结构）
- [x] `Future<DictionaryResult> query(String word, {required String context, required DictSettings settings, void Function(String)? onStreamChunk})`：
    - [x] 先查缓存（Task 5），命中直接返回
    - [x] 构建源顺序：设置指定首选源（非"自动"）置顶，其余按 `bing → youdao → ai` 补齐；AI 未配置则从链中剔除
    - [x] 依序尝试：某源失败/未收录/超时（传统 8s、AI 60s）→ 静默切换下一源；AI 源透传 `onStreamChunk`
    - [x] 全部失败 → 返回带聚合错误信息的失败结果
    - [x] 成功后写缓存
- [x] `isValidWord(String)` 工具函数（`/^[a-zA-Z-]+$/`）放本文件或独立 utils，供 provider 路由使用

**验证:**
```bash
flutter analyze
```

---

### Task 8: 词典设置（Provider + 设置面板词典管理区）

**创建文件:**
- `lib/providers/dict_settings_provider.dart`

**修改文件:**
- `lib/widgets/settings_dialog.dart`

**实现内容:**
- [x] `DictSettings`：`preferredSource`（自动/必应/有道/AI）+ `AiDictConfig`（`baseUrl` / `apiKey` / `model`），SharedPreferences 持久化（参照现有 TranslationConfig 模式）
- [x] 设置面板"词典管理"区（替换"暂无词典 — 功能即将上线"占位）：
    - [x] 词典源下拉选择（默认"自动"）
    - [x] AI 词典配置表单（baseUrl/apiKey/model，apiKey 密文样式输入框）
    - [x] "清除词典缓存"按钮（调 `DictCache.clearAll()` + Toast 反馈）
- [x] 删除原"词典查询服务"说明卡片（介绍有道智云共享凭证的付费方案说明，已失效）

**验证:**
```bash
flutter run --debug
```
设置面板词典管理区可配置、重启后保持。

---

### Task 9: dictionary_provider 重写 + word_selection_provider 解冻集成

**修改文件:**
- `lib/providers/dictionary_provider.dart`（重写）
- `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] `DictionaryState`：`status`（就绪/查询中/AI生成中/完成/未收录/失败 枚举）、`result`、`queriedWord`、`aiMarkdown`（流式增量）；移除 TranslationConfig 依赖，改读 `dictSettingsProvider`
- [x] `query(String word)`：从 `clipboardProvider` 读原句作 context，调 `DictionaryService.query`；AI 流式期间 `onStreamChunk` 逐步更新 `aiMarkdown` 并置 `status = aiStreaming`
- [x] **竞态守卫**：结果返回时仅当 `queriedWord == wordSelectionProvider.selectedText` 才写入 state 生效（防快速切换选中词串台）
- [x] `WordSelectionNotifier`：
    - [x] 解冻 `_triggerDictionaryQuery()`（去掉 `unused_element` ignore）：在 `_debouncedRecompute` 300ms 回调末尾调用；`isValidWord(selectedText)` → 走 `dictionaryProvider.query`；词组且 AI 已配置 → 同样走 query（编排器内部路由到 AI）
    - [x] `build()` 中 `ref.listen(dictionaryProvider, ...)`（镜像现有 translationProvider 监听模式）：结果变化时重算条目
    - [x] state 新增 `senseEntries: List<CardEntryModel>`：每个 `DictSense` 一条（word、phonetic=`mergedPhonetic`、pos、meaning，example 复用 `_buildExample` 高亮逻辑，exampleTranslation/pronunciationUrl 同手动条目）
    - [x] AI markdown 写入手动条目（`currentEntry.aiDictMarkdown`）
- [x] 查询中状态传递：`dictionaryProvider.isLoading` 时 ResultsList 显示加载动画（Task 10 消费）

**验证:**
```bash
flutter analyze
```

---

### Task 10: UI 集成（结果列表 / 词典标签 / 搜索按钮 / 状态栏）

**修改文件:**
- `lib/widgets/results_list.dart`
- `lib/widgets/status_bar.dart`
- `lib/app.dart`

**实现内容:**
- [x] `_buildEntries` 渲染顺序：手动空条目（`currentEntry`，含 AI markdown 数据）→ `senseEntries` 各义项条目（复用 `ResultEntry`，onAdd/onPreview 已按 entry 参数化）
- [x] 查询中：条目列表位置展示加载动画（PRD"加载中状态：条目位置展示加载动画"）；失败/未收录：仅空条目 + 底部提示文字更新
- [x] AI 结果卡片：`senseEntries` 之后追加 `flutter_markdown` 渲染区块（流式渐进更新）+ "复制 Markdown" 按钮
- [x] 词典标签：硬编码"牛津高阶 (本地)"替换为实际命中源（📖 必应词典 / 有道词典 / AI 词典；未查询时显示设置的首选源名）
- [x] `_manualSearch` 恢复：读取当前选中词重新触发 `dictionaryProvider.query`，空选中 Toast"请先选择一个单词"
- [x] `app.dart` 组装 `dictStatus`：watch dictionaryProvider → 就绪(绿)/查询中(黄)/AI 生成中(黄)/完成 (N条释义)(绿)/未收录(黄)/失败(红)

**验证:**
```bash
flutter run -d windows
```
复制英文句子 → 选中单词 → 300ms 后义项条目出现音标/词性/释义 → 预览/添加到 Anki。

---

### Task 11: 字段映射扩展 + 内置模板默认映射核对

**修改文件:**
- `lib/models/card_entry_model.dart`
- `lib/widgets/field_mapping_editor.dart`
- `lib/services/template_manager.dart`
- `assets/template01/`（默认映射 json，按需）

**实现内容:**
- [x] `CardEntryModel` 新增 `aiDictMarkdown` 字段（默认空串），`toMap()` 输出 `markdownToHtml(aiDictMarkdown)` 结果（预览与添加所见即所得）
- [x] `field_mapping_editor.dart`：`kDataSources` 增补「音标」「释义」「AI 释义」；`_internalToDisplay` / `_displayToInternal` 增加 `phonetic` / `meaning` / `aiDictMarkdown` 映射
- [x] `template_manager.dart` `buildFields`：确认 `aiDictMarkdown` 数据源走 `toMap` 的 HTML 值（转换在模型层完成，此处无需特判则不改）
- [x] 核对内置模板 `assets/template01/.json` 默认字段映射：「音标」→ 音标、「释义」→ 释义（不一致则更新并保持向后兼容：旧映射里未知 key 落"空"）

**验证:**
```bash
flutter analyze && flutter run -d windows
```
设置中字段映射编辑器出现新数据源；默认模板音标/释义字段可预填充。

---

### Task 12: 测试全绿 + 端到端验证 + 文档回写

**实现内容:**
- [x] `flutter analyze` 无告警；`flutter test` 全部通过（32 项，含既有 `widget_test.dart`）
- [x] 真实接口连通性验证（`dart run tool/check_dict.dart`）：library 全字段解析成功、asdfzzx 双源未收录
- [ ] 手动端到端（`flutter run -d windows`，交互式走查留待桌面环境执行）：
    - [ ] 复制英文句子 → 点选单词 → 300ms 自动查询 → 空条目 + 义项条目（音标/词性/释义）→ 预览编辑 → 添加到 Anki 成功
    - [ ] 词典源切换（必应/有道/AI）生效，词典标签随命中源变化
    - [ ] 配置 AI 接口后查询词组 → Markdown 卡片流式渲染 → 「AI 释义」数据源可映射
    - [ ] 断网 → 仅空条目 + 状态栏红点失败提示，手动制卡不受影响
    - [ ] 同词二次查询命中缓存（日志/耗时验证）
- [x] 回写进度：`docs/TODO.md` 与 `docs/PRD.md` 中本节任务勾选，填写下方「实现偏差记录」表

**验证:**
```bash
flutter analyze && flutter test
```

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| 测试夹具 | 真实 Bing 页面存档 | 按提取文档选择器构造的最小夹具 | 真实页面含大量动态脚本体积过大；改以 `tool/check_dict.dart` 连通性脚本对线上真实页面验证解析器（library/asdfzzx 均符合预期），夹具用于回归测试 |
| DictSettings 模型位置 | 归入 dict_settings_provider.dart | 独立为 `lib/models/dict_settings_model.dart` | 与仓库 TranslationConfig 的模型/Provider 分层惯例一致 |
| DictionaryService 构造 | const 构造函数 | 普通构造函数（注入 DictCache） | `DictCache.shared` 为运行时单例，不能作 const 默认值 |
| 内置模板默认映射 | 核对并按需更新 `assets/template01/.json` | 无需修改 | 检查发现默认映射已含 `音标→phonetic`、`释义→meaning` |
| 真实接口验证方式 | `flutter run` 手动端到端 | analyze + 32 项单测 + 真实抓取脚本验证 | 编码环境无法交互式驱动桌面 UI；交互式走查留待用户在桌面环境执行（Task 12 剩余未勾选项） |

---

## 风险与对策

1. **Bing 改版/反爬**：选择器集中在 `bing_dict_api.dart` 一处，夹具回归测试可快速定位失效点；双源自动回退兜底；桌面端 Dart http 无 CORS 限制，带浏览器 UA 头降低拦截概率。仍被拦截时（HTML 中无词条）静默切换有道。
2. **非官方接口稳定性**：有道 jsonapi_s 为纯 JSON 接口相对稳定；两个接口均为网页端公开接口、非官方承诺 API，存在失效风险——失效时手动模式兜底不受影响，修复只需更新对应解析器与夹具。
3. **AI 输出不可结构化解析**：Markdown 不强拆字段，以独立卡片展示 + 「AI 释义」数据源（转 HTML）方式集成，模板字段映射保持灵活。
4. **SSE 兼容性**：`package:http` 的 `Client.send` 在 Windows 桌面端支持流式响应；流式异常已有非流式自动降级，功能可用性优先。
5. **缓存膨胀**：SharedPreferences 存 JSON 体量有限，词典结果单条 KB 级、7 天 TTL + 手动清除可控；后续量大可迁移 sqflite（P2）。

---

## 附录 A：Bing 词典请求规格与选择器映射表

请求规格：

| 项 | 值 |
| --- | --- |
| URL | `https://www.bing.com/dict/search?q={word}&FORM=BDVSP6&cc=cn` |
| 方法 | GET |
| 请求头 | 浏览器级 `User-Agent`、`Accept-Language`（降低人机拦截概率） |
| 返回 | HTML 文本 |

选择器 → 输出字段映射：

| 输出字段 | CSS 选择器 | 说明 |
| --- | --- | --- |
| `word` | `#headword > h1` | 词条；**查不到即判定失败/未收录** |
| `senses[]` | `div.qdef > ul > li`，子级 `.pos` / `.def` | `{pos: 词性, def: 释义}` |
| `inflections[]` | `div.hd_div1>.hd_if>.p1-5` | 时态变形文本（如 "复数: libraries"） |
| `sentences[]` | `#sentenceSeg .se_li`，子级 `.sen_en` / `.sen_cn` | `{eng, chs}`，两者都有值才收录 |
| 音标+音频 | `#bigaud_uk` / `#bigaud_us` 的 `data-mp3link` 属性 + 前一个兄弟元素文本中的 `[...]` | `package:html` 中用 `previousElementSibling` |
| 备选音标 | `.hd_pr` / `.hd_prUS` | 上者为空时兜底，只取音标无音频 |

## 附录 B：有道 jsonapi_s 请求规格与响应字段路径

请求规格：

| 项 | 值 |
| --- | --- |
| URL | `https://dict.youdao.com/jsonapi_s?doctype=json&jsonversion=4` |
| 方法 | POST，`Content-Type: application/x-www-form-urlencoded` |
| Body | `q={word}&le=en&t=3&client=web&keyfrom=webdict` |
| 关键 Headers | `accept: application/json, text/plain, */*`；`accept-language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,...` |
| 返回 | JSON |

响应字段路径：

| 字段路径 | 含义 |
| --- | --- |
| `ec.word["return-phrase"]` | 单词原型（词形还原结果） |
| `ec.word.ukphone` / `ec.word.usphone` | 英/美音标 |
| `ec.word.trs[]` → `{pos, tran}` | 词性 + 中文释义 |
| `blng_sents_part["sentence-pair"][]` → `{sentence, "sentence-translation"}` | 双语例句 |

## 附录 C：AI 词典提示词模板（逐字收录自提取文档 §3.3）

系统提示词生成函数（`createEnglishDictionaryPrompt`，输出契约核心）：

```js
export const defaultDictPrompt = createEnglishDictionaryPrompt({
  targetLanguage: "Chinese",
  translationExample: "用于 Web 和原生用户界面的库",
  labels: {
    entry: "词条",
    essentials: "基础形态与音标",
    pronunciation: "发音标注",
    meanings: "词性与核心义项",
    context: "语境精析",
    contextMeaning: "当前语义锁定",
    register: "语境色调",
    replacements: "原句平替词",
    deepDive: "词源深度解构与辨析",
    etymology: "词源与记忆锚点",
    collocations: "高频搭配",
    synonyms: "同义词微观辨析",
    examples: "语料库双解例句",
    translation: "中文翻译",
    scene: "场景标签",
  },
});

function createEnglishDictionaryPrompt({
  targetLanguage,
  translationExample,
  labels,
}) {
  return `# Role
You are an expert English-${targetLanguage} lexicographer specializing in contrastive linguistics and modern corpus linguistics. Analyze the user's English text with academic rigor and clear, elegant formatting, or translate it naturally into ${targetLanguage} when dictionary analysis is not appropriate.

# Execution Rules
1. **Smart routing (CRITICAL)**: Choose the mode strictly from the length and nature of \`[Target]\`:
   - **Dictionary mode**: Use the dictionary output format only when \`[Target]\` is clearly a single English word, an idiom, or a fixed collocation of no more than 3 words.
   - **Pure translation mode**: Use pure translation for complete sentences, clauses, natural-language phrases, paragraphs, long text, or any continuous text longer than 3 words. When uncertain, choose pure translation mode.
2. **Context first**: In dictionary mode, if \`[Context]\` contains useful information, put the contextually correct sense first.
3. **Target-language contract**: All headings, labels, definitions, explanations, usage notes, and example translations in dictionary mode must be written in ${targetLanguage}. Keep English only for the entry, English examples, pronunciation, and English words being compared.
4. **No extra framing**: Follow the selected format exactly. Do not add greetings, prefaces, or closing summaries.

---

# Pure Translation Output Contract (only for pure translation mode)

Your entire response must contain only the ${targetLanguage} translation itself:
- Do not output the source text, bilingual comparison, headings, labels, language names, quotation marks, Markdown, or explanations.
- Do not add prefixes such as "Translation:" or include pronunciation, etymology, collocations, examples, or acknowledgements.
- If the source has one paragraph, output one paragraph. Preserve paragraph breaks only when the source has multiple paragraphs.

Example:
- Input: The library for web and native user interfaces
- Correct output: ${translationExample}

# Output Format (only for dictionary mode)

## ${labels.entry}: [original word or phrase]
> [If the form is inflected in \`[Context]\`, provide its lemma in parentheses.]

### 1. ${labels.essentials}
- **${labels.pronunciation}**: 🇺🇸 [US IPA] ｜ 🇬🇧 [UK IPA]
- **${labels.meanings}**:
  - \`[part of speech]\` ① [primary ${targetLanguage} definition] ② [secondary ${targetLanguage} definition]
  - \`[part of speech]\` ① [primary ${targetLanguage} definition]

### 2. ${labels.context} *[include only when useful Context exists]*
- **${labels.contextMeaning}**: State the part of speech and precise meaning in the given context.
- **${labels.register}**: Describe sentiment, register, formality, and tone.
- **${labels.replacements}**: Give 1-2 English synonyms that can replace the entry in this context without changing the meaning.

### 3. ${labels.deepDive}
- **${labels.etymology}**: Explain roots, affixes, historical development, or provide a logical memory aid.
- **${labels.collocations}**:
  * \`[collocation 1]\` ➔ [precise ${targetLanguage} translation]
  * \`[collocation 2]\` ➔ [precise ${targetLanguage} translation]
- **${labels.synonyms}**:
  * **[entry] vs [synonym 1] vs [synonym 2]**: Explain their differences in context, intensity, register, or collocation habits in 1-2 sentences.

### 4. ${labels.examples}
[Provide 2-3 natural examples from publications, news, professional writing, or everyday English.]

1. **[natural English example]**
   - 💡 *${labels.translation}*: [accurate, idiomatic ${targetLanguage} translation]
   - 📌 *${labels.scene}*: \`[localized scene label]\``;
}
```

用户提示词模板（`defaultDictUserPrompt`）：

```js
export const defaultDictUserPrompt = `# Input Data

## [Context] (Optional)
> Use this information to identify the target text's meaning in context:
- Document title: {{title}}
- Document description: {{description}}
- Document summary: {{summary}}
- Surrounding paragraph: {{context}}

## [Target] (Required)
> Use this text to choose between dictionary mode and pure translation mode:
{{text}}`;
```

占位符说明：`{{text}}` = 查询单词/词组；`{{context}}` = 剪贴板原句（本应用的选区语境）；`{{title}}/{{description}}/{{summary}}` = 桌面端无页面概念，统一填空串。替换即纯字符串 `replaceAll`。

最终请求体形态（OpenAI 兼容）：

```
POST {baseUrl}/chat/completions
Authorization: Bearer {apiKey}
Content-Type: application/json

{
  "model": "...",
  "messages": [
    { "role": "system", "content": <渲染后的系统提示词> },
    { "role": "user",   "content": <渲染后的用户提示词> }
  ],
  "stream": true
}
```

SSE 帧形态与 delta 提取：标准 OpenAI 兼容流按 `\n\n` 分帧，取 `data: ` 后内容；每帧 `JSON.decode` 后取 `choices[0].delta.content`；收到 `data: [DONE]` 结束。流式期间每帧累积后调 `stripMarkdownCodeBlock(full, startOnly: true)` 剥开头围栏，流结束再剥结尾围栏并 trim。
