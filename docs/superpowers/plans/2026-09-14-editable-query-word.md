# 「当前选中词组」可编辑实现计划（查询词与卡片用编辑后的词）

> **需求背景**：例句中选中的词可能是大写、过去式等非原型形式（如 "went"、"Went"），当前系统直接用选中原文查词典并制作卡片，而用户实际想要的是单词原型的释义。
> 「当前选中词组」目前是只读 `Text`，无法改成原型。

> **For agentic workers:** 按本计划逐 Task 实现，复选框（`- [ ]`）记录完成情况，支持任务中断后重新开始。

**目标:** 把「当前选中词组」改为可编辑输入框。选中词组后自动填入原文；用户可将其改为原型（如 went → go），词典查询、结果条目的 word 字段、发音 URL 均改用输入框内容；例句中的 `<b>` 加粗高亮仍按选中位置展示，不受编辑影响。

**核心设计:** `WordSelectionState` 新增 `queryWord`（查询词）字段，作为词典查询与卡片 word 字段的唯一数据源。选中变化时自动初始化为选中原文；编辑时立即更新，300ms 防抖后重查（与现有词块选中防抖一致），失焦（onBlur）/回车时立即提交查询。

**技术栈:** Riverpod（现有 Notifier 体系），无新增依赖。

## 关键设计决策

1. **`queryWord` 为唯一查询源**：`_triggerDictionaryQuery` / `_recomputeEntry` / `_buildEntry` / `_buildSenseEntry` / `_buildPronunciationUrl` 以及结果列表的竞态守卫全部改用 `queryWord`；未编辑时 `queryWord` 恒等于 `selectedText`，行为与现状完全一致。
2. **编辑触发时机（用户明确要求）**：`onChanged` 立即更新状态 + 300ms 防抖查询（合并连续按键，避免每字母一次网络请求）；输入栏**失去焦点立即提交**（用户改完词直接点界面其他地方即生效）；回车同样立即提交。
3. **高亮与查询词解耦**：`_buildExample` 的 `<b>` 高亮只依赖 `selectedIndices` + `tokens`，与查询词无关，保持不动。
4. **选中驱动覆盖编辑**：再次点击词块时输入栏重置为新选中词组（覆盖上次编辑），符合"选中驱动"心智模型。
5. **trim 一致性**：`updateQueryWord` 存入 trim 后的值，与 `DictionaryNotifier.query` 的 `queriedWord`（trim 后）保持一致，竞态守卫 `dictState.queriedWord == queryWord` 不会因空格失配。
6. **双定时器互斥**：选中防抖 `_debounceTimer` 与编辑防抖 `_editDebounceTimer` 互相取消，避免选中交互与编辑输入的查询互相踩踏；`_recomputeEntry` 不取消编辑防抖（词典流式回调频繁触发重算时不能打断用户正在输入的提交）。
7. **控制器单向同步**：TextField 的 `TextEditingController` 仅在选中变化/tokens 更替时从 state 回写（打字过程不回写，避免光标跳动）。

---

## Tasks

### Task 1: `WordSelectionState` 增加 `queryWord` 字段

**修改文件:** `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] `WordSelectionState` 增加 `final String queryWord`（构造默认 `''`）
- [x] `selectedText` getter 的拼接逻辑抽成静态方法 `WordSelectionState.textFromIndices(tokens, indices)`，getter 复用
- [x] `copyWith` 增加 `queryWord` 参数

**验证:** `flutter analyze`

---

### Task 2: `WordSelectionNotifier` 选中方法初始化 `queryWord`

**修改文件:** `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] `selectIndex` / `selectRange` / `toggleIndex` / `clearSelection` / `setTokens`：构造新 state 时 `queryWord` 初始化为派生 selectedText（无选中为 `''`）
- [x] `_recomputeEntry` 末尾重建 state 时保留 `queryWord`

**验证:** `flutter analyze`

---

### Task 3: 编辑查询词 API（updateQueryWord / commitQueryWord）

**修改文件:** `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] 新增 `updateQueryWord(String text)`：trim 后跳过无变化更新；写入 state 并清掉旧 `currentEntry`/`senseEntries`；`_editDebounceTimer` 300ms 防抖后 `_recomputeEntry()` + `_triggerDictionaryQuery()`
- [x] 新增 `commitQueryWord()`：取消防抖立即 `_recomputeEntry()` + `_triggerDictionaryQuery()`（供失焦/回车调用）
- [x] 双定时器互斥取消；`ref.onDispose` 一并取消 `_editDebounceTimer`

**验证:** `flutter analyze`

---

### Task 4: 查询与条目构建改用 `queryWord`

**修改文件:** `lib/providers/word_selection_provider.dart`

**实现内容:**
- [x] `_recomputeEntry()`：局部变量改用 `state.queryWord`，竞态守卫 `dictState.queriedWord == queryWord`
- [x] `_triggerDictionaryQuery()`：改用 `state.queryWord`，为空时 `clear()`
- [x] `_buildEntry` / `_buildSenseEntry` 入参用 `queryWord`（卡片 word、发音 URL 为编辑后的词）
- [x] `_buildExample` 删除未使用的 `selectedText` 形参（纯清理，高亮逻辑不动）

**验证:** `flutter analyze`

---

### Task 5: 输入栏改为可编辑 TextField

**修改文件:** `lib/widgets/word_blocks_section.dart`

**实现内容:**
- [x] State 持有 `TextEditingController _queryWordController` + `FocusNode _queryWordFocusNode`（initState 创建 / dispose 释放，失焦回调 → `commitQueryWord()`）
- [x] 只读 `Text` 替换为 `Expanded` + `TextField`：延续现有容器样式，无边框密集输入框，`hintText: '选中后自动填入，可直接编辑（如改为原型）'`
- [x] `onChanged` → `updateQueryWord(text)`；`onSubmitted` → `commitQueryWord()`
- [x] build 中 `ref.listen(wordSelectionProvider, ...)`：仅当 `selectedText` 变化或 tokens 更替时回写 `controller.text = state.queryWord`
- [x] 发音播放按钮改用 `selection.queryWord`

**验证:** `flutter analyze` 通过 + `flutter test` 冒烟渲染通过（桌面端手动交互待用户确认）

---

### Task 6: 结果列表守卫与手动搜索改用 `queryWord`

**修改文件:** `lib/widgets/results_list.dart`

**实现内容:**
- [x] `_isQuerying` / `_aiMarkdownForSelection` / `_bottomHint`：`selection.selectedText` → `selection.queryWord`
- [x] `_manualSearch`：改查 `queryWord`，toast 改为"请先选择或输入单词"

**验证:** `flutter analyze`

---

### Task 7: 新增 Provider 单元测试

**新建文件:** `test/providers/word_selection_provider_test.dart`

**实现内容:**
- [x] `ProviderContainer` + 覆盖 `dictionaryProvider` 为记录调用的假 Notifier（真实 timer + 短等待，避免引入 fake_async 传递依赖）
- [x] 验证：选中后 `queryWord` 自动初始化；`updateQueryWord` 立即更新状态/防抖后用编辑词查询；`commitQueryWord` 立即查询且不重复；再次选中重置 `queryWord`；清除选中置空并清空词典状态

**验证:** `flutter test test/providers/word_selection_provider_test.dart`

---

### Task 8: 全量验证与进度回写

**实现内容:**
- [x] `flutter analyze` 通过
- [x] `flutter test`：本计划相关用例全部通过（唯一失败 `dict_cache_test.dart` 经 master 基线复测确认为预先存在，与本计划无关）
- [x] 勾选本文件复选框，更新 `docs/PRD.md` / `docs/TODO.md` 任务进度

**验证:** `flutter analyze && flutter test`

> **完成记录（2026-09-14）**：`flutter analyze` 无问题；`flutter test` 37 通过 + 1 个预先存在的失败（`dict_cache_test.dart: 过期视为未命中并清除`，master 上同样失败）。新增 `test/providers/word_selection_provider_test.dart` 6 个用例全部通过。实现分支：`feature/editable-query-word`。
