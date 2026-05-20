# 牌组选择器 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现牌组选择器功能，让用户从 AnkiConnect 获取的牌组列表中选择目标牌组，替换硬编码的 `ankihelper-pc-test`。

**架构:** 新增 Riverpod Provider 管理牌组列表和选中状态，在 `ResultsList` 标题行中用可搜索的下拉选择器替换静态词典标签，添加卡片时读取用户选中的牌组。

**技术栈:** Flutter, Riverpod, AnkiConnect JSON-RPC

**核心文件结构:**
```
lib/
├── providers/
│   └── deck_provider.dart           # [新建] 牌组列表 + 选中状态 Provider
├── widgets/
│   ├── deck_selector.dart           # [新建] 牌组选择器组件
│   └── results_list.dart            # [修改] 集成选择器 + 使用选中牌组
```

---

## Tasks

### Task 1: 创建牌组 Provider ✅

**创建文件:**
- `lib/providers/deck_provider.dart`

**实现内容:**
- `DeckNotifier` — `AsyncNotifier<List<String>>`，`build()` 时调用 `AnkiConnectService.getDeckNames()` 获取牌组列表
- `deckListProvider` — 对应的 `AsyncNotifierProvider`
- `selectedDeckProvider` — `StateProvider<String>`，默认值 `'Default'`，存储当前选中牌组名
- `DeckNotifier` 暴露 `Future<void> refresh()` 方法供手动刷新

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 2: 创建牌组选择器组件 ✅

**创建文件:**
- `lib/widgets/deck_selector.dart`

**实现内容:**
- `DeckSelector` — `ConsumerStatefulWidget`，匹配 Open Design 设计稿中 `results-section__deck-group` 样式
- 药丸形容器（圆角 `radiusCircular`，高度 24px，背景 `bgCard`，描边 `stroke3`）
- 标签文字"选择Anki牌组"（`fg4`，`fontSize200`）
- 可搜索输入框（宽度 130px，无边框透明背景，`fontSize200`）
- 下拉菜单（`OverlayEntry`，最大高度 240px，圆角 `radiusMd`，描边 `stroke1`）
- 下拉列表从 `deckListProvider` 读取牌组，支持输入过滤
- 选中项高亮（`bgSubtleSelected` + `fgBrand` + `fontWeightMedium`）
- 点击选项更新 `selectedDeckProvider` 并关闭下拉

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 3: 集成牌组选择器到结果列表

**修改文件:**
- `lib/widgets/results_list.dart`

**实现内容:**
- 导入 `deck_selector.dart` 和 `deck_provider.dart`
- 标题行（第 41-71 行）：将静态词典标签 `Container` 替换为 `DeckSelector()`
- `_addNoteToAnki` 方法（第 148-177 行）：
  - 删除 `static const _testDeckName = 'ankihelper-pc-test'`
  - 从 `selectedDeckProvider` 读取当前选中牌组名
  - 移除 `service.createDeck()` 调用（牌组应已存在于 Anki 中）
  - `addNote` 的 `deckName` 改为使用选中牌组
  - Toast 消息改为显示实际牌组名

**验证:**
```bash
flutter run -d macos
```
1. 启动 Anki Desktop + AnkiConnect
2. 结果列表标题行显示牌组选择器（药丸形 + "选择Anki牌组"）
3. 点击选择器，下拉菜单显示 Anki 中的所有牌组
4. 输入关键字可过滤牌组列表
5. 选择一个牌组后，点击"添加卡片"，卡片添加到所选牌组
6. Toast 显示所选牌组名

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| | | | |
