# 卡片释义并入词性实现计划（义项条目制卡增强）

> **[需求]** 词典查询返回义项条目后，点击「添加/预览」生成的单词卡片「释义」字段
> 仅含释义文本，缺少词性（v./n. 等）。期望卡片释义带上词性前缀（如 `v. donate...`）。
> 结果列表展示保持现状（词性为独立标签 + 纯释义文本），仅预览与卡片的「释义」数据源合并。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**目标:** 义项条目制卡时，「释义」数据源输出 `词性 + 空格 + 释义`；直接添加、预览编辑后添加、字段映射三条路径一致生效；列表展示与其他数据源零影响。

**架构:** 单点修改数据源层——`CardEntryModel` 新增 `cardMeaning` getter（词性并入释义，含防重复守卫），`toMap()['meaning']` 改用它。`toMap()` 是 `TemplateManager.buildFields`（直接添加）与预览弹窗预填的唯一取值入口，单点生效即覆盖全部制卡路径；`ResultEntry` 列表展示直接读 `entry.pos` / `entry.meaning` 字段，不经 `toMap()`，天然不受影响。

**技术栈:** 纯 Dart 模型层修改 + flutter_test，无新依赖

**核心文件结构:**
```
lib/models/card_entry_model.dart            # [修改] cardMeaning getter + toMap
test/models/card_entry_model_test.dart      # [新建] 模型单测
```

## 背景与现状链路

- `word_selection_provider._buildSenseEntry` 填充 `pos`（如 `v.`）与 `meaning`（纯释义）两个独立字段
- `ResultEntry` 列表以「词性标签 + 释义文本」展示（保持不变）
- 制卡取值全部经 `CardEntryModel.toMap()`：`TemplateManager.buildFields`（直接添加/双击添加）与 `_buildPreviewInitialValues`（预览预填）→ 目前 `'meaning'` 直接返回纯释义，词性丢失

## 方案细节

- `cardMeaning` 规则：
  1. `pos` 或 `meaning` 任一为空 → 原样返回 `meaning`（手动空条目、AI 条目不受影响）
  2. `meaning` 已以 `"$pos "` 开头 → 原样返回（防重复守卫：个别词典方的释义文本自带词性，避免 `n. n. xxx`）
  3. 否则返回 `"$pos $meaning"`（如 `v. donate money to charity`）
- `toMap()` 中 `'meaning': cardMeaning`；其余键与 `aiDictMarkdown` 的 Markdown→HTML 转换逻辑不变
- 预览弹窗中用户看到的释义即卡片实际写入值（WYSIWYG），可再手动编辑

---

## Tasks

### Task 1: CardEntryModel 卡片释义数据源

**修改文件:**
- `lib/models/card_entry_model.dart`

**实现内容:**
- [x] 新增 `cardMeaning` getter（按上述三条规则）
- [x] `toMap()` 的 `'meaning'` 改用 `cardMeaning`

**验证:**
```bash
flutter analyze
```

---

### Task 2: 单元测试

**创建文件:**
- `test/models/card_entry_model_test.dart`

**实现内容:**
- [x] 有词性：`pos: 'v.'` + `meaning: 'donate…'` → `toMap()['meaning'] == 'v. donate…'`
- [x] 无词性（手动空条目）：原样返回，不受影响
- [x] 防重复守卫：`meaning: 'n. 图书馆'` + `pos: 'n.'` → 不出现 `n. n.`
- [x] `aiDictMarkdown` Markdown→HTML 转换与空值行为（顺带覆盖既有逻辑）
- [x] `toMap()` 其余键值不受影响

**验证:**
```bash
flutter test test/models/card_entry_model_test.dart
```

---

### Task 3: 全量验证 + 手动验证 + 文档回写

**实现内容:**
- [x] `flutter analyze` + `flutter test` 全绿（44 项，含本计划新增 6 项模型单测）
- [ ] 手动验证：查词 → 点义项「预览」→ 释义字段含词性前缀；「添加」→ Anki 中卡片释义含词性
- [ ] 手动回归：手动空条目制卡、「AI 释义」数据源路径无异常
- [x] 回写 `docs/TODO.md` / `docs/PRD.md` 需求条目进度

**验证:**
```bash
flutter analyze && flutter test
```

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
| 范围外修复：dict_cache 过期时钟 | 仅改 CardEntryModel 及其测试 | 一并修复 `DictCache.put` 过期时间改用注入时钟 | 跑全量测试时暴露既有 bug：put 用真实墙钟、测试用 mock 时钟，两者仅在同一日期时恰好一致（2026-08-24 当天通过），日期推移后 `dict_cache_test` 必然失败；修复后与 get 判定共用注入时钟 |
