# 过程记录

## 1 初始化项目时，写项目级文档
### 1.1 和AI讨论需求得到精炼的README.md
### 1.2 在cc中讨论并生成PRD.md、TODO.md
> 这次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-15-1902-caveat-the-messages-below-were-generated-by-the-u.txt](../../chat-logs-sanitized/2026-05-15-1902-caveat-the-messages-below-were-generated-by-the-u.txt)

## 2. 实现TODO.md中第一个任务——`P0 Phase 1 — UI 组件层（按设计稿优先实现）`

### 2.1 plan文档制作
> 这次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-15-2001-caveat-the-messages-below-were-generated-by-the-u.txt](../../chat-logs-sanitized/2026-05-15-2001-caveat-the-messages-below-were-generated-by-the-u.txt)

**要点内容**：

- plan文档为：[2026-05-15-ankihelper-phase1-ui.md](../superpowers/plans/2026-05-15-ankihelper-phase1-ui.md)

### 2.2 实现plan文档中Task 1
> 这次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-15-2319-use-superpowersexecuting-plan-to-implement-the-t.txt](../../chat-logs-sanitized/2026-05-15-2319-use-superpowersexecuting-plan-to-implement-the-t.txt)

**要点内容**

- 创建 Git feature 分支 feature/phase1-ui，然后再做接下来的开发工作
- 创建项目骨架：`flutter create . --project-name ankihelper`。使得Flutter初始化应用跑起来

### 2.3 实现plan文档中其他的Task（即Task 2~13）,并添加Task 14用来做UI测试验收
> 这次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-16-0302-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-16-0302-local-command-caveatcaveat-the-messages-below.txt)

**要点内容**

- 一个会话实现所有UI，即Task 2~13。验收这些task为完成的要求，只需组件显示出来、不报错就行
- docs/superpowers/plans/2026-05-15-ankihelper-phase1-ui.md 新增Task 14专门去做UI细节和样式的验收

### 2.4  实现plan文档中用来做UI测试验收Task 14的前7个点
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-16-163302-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-16-163302-local-command-caveatcaveat-the-messages-below.txt)

### 2.5  实现plan文档中用来做UI测试验收Task 14的所有内容，从第8个点开始
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-17-131408-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-17-131408-local-command-caveatcaveat-the-messages-below.txt)

## 3. 配置github action中的构建工作，实现当前应用在github aciton上的构建
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-17-162638-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-17-162638-local-command-caveatcaveat-the-messages-below.txt)

**要点内容**
- 生成号build.yml并且将其commit并push到github仓库，就其合并到**master分支**才能建立和触发github actions上的构建流程

## 4. 调理了 PRD/TODO 中的 Phase 2 任务，并创建2026-05-18-ankiconnect-basic.md
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-18-114927-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-18-114927-local-command-caveatcaveat-the-messages-below.txt)

### 4.1 实现plan 2026-05-18-ankiconnect-basic.md 中所有内容
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-19-150429-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-19-150429-local-command-caveatcaveat-the-messages-below.txt)

## 5 添加‘牌组选择器’需求
### 5.1 ‘牌组选择器’需求更新进PRD和TODO文档
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-19-172606-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-19-172606-local-command-caveatcaveat-the-messages-below.txt)

### 5.2 实现2026-05-20-deck-selector.md
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-20-194322-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-20-194322-local-command-caveatcaveat-the-messages-below.txt)

## 6 修改‘剪贴板监听’为‘剪贴板监听与原文编辑’，并制订计划以及编码实现功能
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-21-145443-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-21-145443-local-command-caveatcaveat-the-messages-below.txt)

## 7. 将PRD和PRD里面的需求“翻译服务”放到未做完的需求的最前面并做实现上的调整，然后制订plan编码实现该需求

> 次任务全程使用了模型：mimo-v2.5-pro、glm-4.7、mimo-v2.5-pro

对话过程记录：[2026-05-21-235014-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-21-235014-local-command-caveatcaveat-the-messages-below.txt)

## 8. 更新此应用的图标
> 次任务全程使用了模型：glm-4.7

对话过程记录：[2026-05-22-095221-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-22-095221-local-command-caveatcaveat-the-messages-below.txt)

## 9. fix: '剪切板原文'input输入栏值变化时重新分词
> 次任务全程使用了模型：mimo-v2.5-pro

对话过程记录：[2026-05-22-101009-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-22-101009-local-command-caveatcaveat-the-messages-below.txt)

## 10. docs: 更新核心流程图与需求文档，拆分词典查询引擎为三阶段
> 次任务使用了模型：glm-4.7、mimo-v2.5-pro

对话过程记录：[2026-05-23-104921-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-23-104921-local-command-caveatcaveat-the-messages-below.txt)

**要点内容**：

- 流程图中节点 `H[自动查询当前选中词典]` 做细化修改：将词典查询引擎拆分为手动添加、云端词典、本地词典三阶段
- 新增卡片模板与字段映射需求（设置入口、预设映射、预留自定义接口）

## 11. 调整PRD和TODO中的“AnkiConnect 完整功能 > 卡片模板与字段映射“、以及编写plan

### 11.1 根据‘10’中的修改，调整当前“AnkiConnect 完整功能 > 卡片模板与字段映射”的实现plan，并编写一部分实现代码
> 次任务使用了模型：subagent用glm-4.7、其他的大部分时候切换使用mimo-v2.5-pro

对话过程记录：[2026-05-24-085925-local-command-caveatcaveat-the-messages-below.txt](../../chat-logs-sanitized/2026-05-24-085925-local-command-caveatcaveat-the-messages-below.txt)

**要点内容**：

- 编写plan后，使用superpowers:executing-plan写实现代码，做到task4时，发现“AnkiConnect 完整功能”这个功能点的实现不符合预期，需要进行需求修改
- 在修改“AnkiConnect 完整功能”需求点时，没有修改完成（即没有改到符合预期的程度），但上下文已经用到了150k，于是准备终止当前cc会话。使用`/compact`压缩当前会话开始新会话，接下来继续讨论修改“AnkiConnect 完整功能”的需求

### 11.2 `/compact`压缩前面的对话，重新修改调整PRD和TODO中“AnkiConnect 完整功能”需求，修改PLAN，然后实现到Task2
> 次任务使用了模型：glm-4.7、大部分时候使用mimo-v2.5-pro

对话过程记录：[2026-05-24-114955-this-session-is-being-continued-from-a-previous-c.txt](../../chat-logs-sanitized/2026-05-24-114955-this-session-is-being-continued-from-a-previous-c.txt)

**要点内容**：

- 使用`/compact`压缩上一个cc会话，来开启新的
- 先做PRD和TODO中的需求更改，改好后再去改动PLAN。原因是：上一个对话先改的PLAN，然后改动跑偏效果不好，且占了很大的上下文。
