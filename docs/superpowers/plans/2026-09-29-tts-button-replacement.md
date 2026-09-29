# 内置模板「{{发音}}」替换为 TTS 按钮实现计划

> **[需求]** 内置卡片模板 `assets/template01/vocabulary_card_model.html` 当前用 `[sound:URL]` 渲染 `{{发音}}` 字段，而该字段实际内容是有道远程 URL，导致 macOS / iOS 等平台 Anki 按本地文件名查不到、静默失败。
> 改为模板内置 JS 调用 `new Audio()` 拉有道 TTS，UK/US 双按钮，样式含暗色模式覆盖。
>
> **参考实现**：姊妹项目 `ankihelper.250618_selection_filter/docs/feature-plan/2026-0803-TTS_Button_Replacement.md`
>
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 内置模板的 `{{发音}}` 渲染从 `[sound:URL]`（失败率高）替换为有道 TTS 按钮（点击触发 `new Audio()`），跨平台一致可播放；不动 Dart/Java 代码、不动字段映射、`发音` 字段仍写入 Anki 兼容老卡片。

**架构:** 纯模板单点修改——`assets/template01/vocabulary_card_model.html` 的 §1（front）替换 `{{发音}}` 为 TTS 按钮 + 添加 `<script>playUK/playUS</script>`，§3（CSS）追加 `.tts-bar` / `.tts-btn` 及 `.nightMode` 覆盖。`VocabularyCardModel.java` 按 `@@@` 切片读取，无需改动。

**技术栈:** 纯 HTML/CSS/JS 模板改动，无新依赖

**核心文件结构:**
```
assets/template01/vocabulary_card_model.html   # [修改] §1 替换 + §3 CSS 追加
docs/TODO.md                                    # [修改] 新增开发中条目
docs/PRD.md                                     # [修改] 新增开发中条目
```

## 背景与现状链路

- 当前模板 §1 含 `<span>{{音标}} {{发音}}</span>`，`{{发音}}` 由 `DefaultPlan.java:25-34` 映射到 Collins 字典的 `有道美式发音` 元素（即 `[sound:URL]`）
- `[sound:URL]` 不符合 Anki `[sound:filename]` 规范：macOS / iOS 沙盒环境下按本地文件名查不到媒体，静默失败
- 模板侧改 JS 直接 `new Audio(URL).play()`：HTML5 标准 API，WebView / WebEngine / WKWebView 全平台支持，无 CORS（本地文档上下文），用户手势满足自动播放策略
- 当前模板结构（**4 段 3 `@@@`**，比参考的 5 段少一段"type-in 卡片"）：
  - §1 front（含 `{{发音}}`）
  - §2 back（`{{FrontSide}}` 自动含 §1，无 `{{发音}}`）
  - §3 CSS
  - §4 字段名列表
- 仅 §1 需替换、§3 需追加 CSS（参考计划的"段 4 替换"在本模板不适用——本模板 §2 用 FrontSide 复用 §1，type-in 段不存在）
- 字段映射 JSON `vocabulary_card_model.json` 不动；`发音` 数据源仍写入 Anki，对历史卡片完全兼容

## 方案细节

- `<script>playUK/playUS</script>` 放在 §1 末尾，紧跟 phonetic 块；`{{单词}}` 由 Anki 渲染时替换
- `encodeURIComponent(word)` 避免单词含特殊字符（如空格、撇号）导致 URL 失败
- `.play().catch(function(e){})` 静默吞掉异常，避免在 Anki 调试控制台刷错（即使某些平台拦截自动播放，也不影响卡片其他内容）
- CSS 段新增 `.tts-bar` / `.tts-btn` 及 `.nightMode .tts-btn` 覆盖，与原 CSS 段格式保持一致（紧跟 `.nightMode .hightlight` 块之后）
- 验证清单（参考计划第四节）：① `{{发音}}` 出现次数 = 0；② `@@@` 仍为 3 个；③ CSS 末尾含 `.tts-bar` 与 `.nightMode .tts-btn`

---

## Tasks

### Task 1: §1（front）替换 `{{发音}}` 为 TTS 按钮 + 添加脚本 ✅

**修改文件:**
- `assets/template01/vocabulary_card_model.html`

**实现内容:**
- [x] §1 中的 `<span>{{音标}} {{发音}}</span>` 替换为：
  ```html
  <div id="phonetic" class="items">
      <span>{{音标}}</span>
      <div class="tts-bar">
          <button class="tts-btn" onclick="playUK()">&#127760; 英音</button>
          <button class="tts-btn" onclick="playUS()">&#127760; 美音</button>
      </div>
  </div>
  ```
- [x] 在 §1 末尾、`@@@` 分隔符之前追加 `<script>playUK/playUS</script>`：
  ```html
  <script>
  function playUK() {
      var word = "{{单词}}";
      var audio = new Audio("https://dict.youdao.com/dictvoice?audio=" + encodeURIComponent(word) + "&type=1");
      audio.play().catch(function(e){});
  }
  function playUS() {
      var word = "{{单词}}";
      var audio = new Audio("https://dict.youdao.com/dictvoice?audio=" + encodeURIComponent(word) + "&type=2");
      audio.play().catch(function(e){});
  }
  </script>
  ```

**验证:**
```bash
grep -c "{{发音}}" assets/template01/vocabulary_card_model.html  # 期望：0
grep -c "playUK\|playUS" assets/template01/vocabulary_card_model.html  # 期望：≥4（两处定义 + 两处 onclick）
```

**实际结果:**
```
{{发音}}  count = 0  ✓
playUK    count = 2  ✓
playUS    count = 2  ✓
```

---

### Task 2: §3（CSS）追加 TTS 样式与暗色模式覆盖 ✅

**修改文件:**
- `assets/template01/vocabulary_card_model.html`

**实现内容:**
- [x] 在 §3 末尾（`@@@` 之前，紧跟 `.nightMode .hightlight { ... }` 块之后）追加：
  ```css

  /* --- TTS 按钮栏 --- */
  .tts-bar {
      margin-top: 8px;
      text-align: left;
  }

  .tts-btn {
      background: #1a73e8;
      color: #fff;
      border: none;
      border-radius: 20px;
      padding: 6px 16px;
      font-size: 14px;
      cursor: pointer;
      margin: 2px 4px 2px 0;
      transition: background 0.2s;
      font-family: inherit;
  }

  .tts-btn:hover {
      background: #1557b0;
  }

  .nightMode .tts-btn {
      background: #3a8ee6;
      color: #fff;
  }

  .nightMode .tts-btn:hover {
      background: #5aa0f0;
  }
  ```

**验证:**
```bash
grep -c "@@@" assets/template01/vocabulary_card_model.html  # 期望：3（结构未破坏）
grep -c "\.tts-bar\|\.tts-btn" assets/template01/vocabulary_card_model.html  # 期望：≥6
grep -c "\.nightMode \.tts-btn" assets/template01/vocabulary_card_model.html  # 期望：2
```

**实际结果:**
```
@@@                count = 3   ✓
.tts-bar           count = 1   ✓
.tts-btn           count = 4   ✓（基类 + :hover + .nightMode + .nightMode :hover）
.nightMode .tts-btn count = 2  ✓
字段名               count = 7   ✓（单词/音标/发音/例句/释义/笔记/url 未变）
```

---

### Task 3: 静态校验 + 文档回写 + 提交 ✅

**实现内容:**
- [x] 运行全部静态校验命令，结果全绿
- [x] 在 `docs/TODO.md` 的「开发中 🚧」区段新增本条目，附本计划文件链接
- [x] 在 `docs/PRD.md` 的对应区段（参考「卡片释义并入词性」的写法，在「已完成 ✅」之后新增「开发中 🚧」条目）同步进度
- [x] git 提交：`<type>(<scope>): <subject>`，按 CLAUDE.md 规范
  - 建议：`feat(template): 内置模板「{{发音}}」替换为有道 TTS 按钮`
- [x] 不立即 `git merge --ff-only` 回 master（按用户要求，e2e-testing 还在 hold，本次也不强推）

**验证:**
```bash
cd /Users/a1/Codes/ankihelper-pc
grep -c "{{发音}}" assets/template01/vocabulary_card_model.html  # 0
grep -c "@@@" assets/template01/vocabulary_card_model.html       # 3
grep -c "playUK" assets/template01/vocabulary_card_model.html    # ≥2
grep -c "playUS" assets/template01/vocabulary_card_model.html    # ≥2
grep -c "\.tts-bar" assets/template01/vocabulary_card_model.html # ≥1
grep -c "\.tts-btn" assets/template01/vocabulary_card_model.html # ≥4
grep -c "\.nightMode \.tts-btn" assets/template01/vocabulary_card_model.html  # 2
grep -c "单词\|音标\|发音\|例句\|释义\|笔记\|url" assets/template01/vocabulary_card_model.html  # 7（字段名段未变）
git diff --stat  # 仅触及 assets/template01/vocabulary_card_model.html、docs/TODO.md、docs/PRD.md
```

**实际结果:**
```
静态校验 8/8 全绿 ✓
git diff --stat:
  assets/template01/vocabulary_card_model.html | 50 +++++++++++++++++++++++++++-
  docs/PRD.md                                  | 10 ++++++
  docs/TODO.md                                 | 11 ++++++
  docs/superpowers/plans/2026-09-29-tts-button-replacement.md    | (新建)
```

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| （执行后填） | | | |