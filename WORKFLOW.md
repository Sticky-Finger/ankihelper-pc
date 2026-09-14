## 开发工作流

本项目采用以下AI编程协作流程：

1. **需求与设计**（不在 Claude Code 中进行）  
   - 在网页端 DeepSeek 等AI聊天工具完成技术调研、PRD 讨论
   - 最终 PRD 维护在 `docs/PRD.md`

2. **任务拆解**  
   - 使用 `openspec` 等spec工具或者手动根据 PRD 制作具体的 TODO 清单（`docs/TODO.md`）

3. **制定计划与编码实现**（在 Claude Code 中）  
   - 仅处理 `docs/TODO.md` 中未完成的任务  
   - 制定实现计划与执行代码**不强制使用 superpowers**，按任务特点选择以下方式之一：

   - **方式 A · superpowers 计划流（默认，适合可拆成多个 Task 的大功能）**  
     使用 `superpowers` 的 `writing-plans` + `executing-plan` 技能，按原子步骤实现并标记进度（✅），支持断点续传。详细规范见 `CLAUDE.md`

   - **方式 B · 直接计划流（适合单一内聚任务 / 基建类任务，如测试基建、CI 配置）**  
     由 AI 直接生成实现计划，**经用户确认后直接执行**，不调用 superpowers 技能。执行产出与方式 A 一致：遵循 Git 分支与提交规范、完成后回写 `docs/TODO.md`（如涉及 PRD 一并更新）

   - **两种方式共同要求**：  
     - 计划必须经用户确认后再动手实现  
     - 计划文档要以文件引用链接的形式附在 `docs/TODO.md` 和 `docs/PRD.md` 对应需求条目下面（引用行格式如 `> 实现计划：docs/superpowers/plans/YYYY-MM-DD-xxx.md`）  
     - 从目标分支（一般为最新 `master`）新建 feature 分支开发，完成后 `git merge --ff-only` 合回目标分支并删除 feature 分支（不使用 worktree）  
     - 建议将最终计划存档到 `docs/superpowers/plans/`（复选框记录完成情况），便于追溯与中断续传；方式 B 存档为纯 Markdown 计划即可，不要求 superpowers 的 Task/✅ 结构

4. **进度跟踪**  
   - 每个任务的实现计划存放在 `docs/superpowers/plans/`  
   - 计划文件中的复选框记录了完成情况，支持任务中断后重新开始  
   - 完成 `docs/superpowers/plans/` 里的任务后，会更新 TODO.md 和 PRD.md 中相关的任务进度
