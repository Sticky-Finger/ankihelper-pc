# CI：测试打包触发方式改进（已搁置，待 v0.0.3 发版后处理）

> **[背景]** 当前"测试打包"只能通过 GitHub UI 手动触发 Actions → Run workflow，每次手动点网页不便。
> 本文档记录三种改进方案，待 v0.0.3 发版完成后再决定是否实施。**当前阶段不动 CI 配置。**

> 生成日期: 2026-09-29
> 触发讨论: v0.0.3 发版流程复盘时提出
> 状态: **已搁置 / 等待后续版本**

---

## 〇、现状痛点

当前发版前测试打包的标准流程：

1. 把最新 commit 合并到 master
2. 打开 GitHub → Actions → "构建发布" workflow → 点 "Run workflow"
3. 留空 `create_draft_release` 输入框 → Run
4. 等 4 个平台 build 跑完（~10-15 分钟）
5. 下载 artifacts 手动测试
6. 测试通过后 → 同页面再 Run workflow → 勾选 `create_draft_release` + 填 `release_version` → Run

痛点：**步骤 2 和 6 都要去网页点**，每次测试打包都要切换到浏览器。

我们想达到的体验：**像 `git push origin v0.0.3` 自动触发 release 一样，本地一条命令就能触发测试打包**。

---

## 一、对比方案

### 方案 A：修 `gh` CLI 认证 + `gh workflow run` + shell alias

**前置**：执行 `gh auth login -h github.com`（token 在 keyring 里失效了，需重新登录）

**日常用法**：

```bash
# 一次性配置
gh auth login -h github.com

# 一键触发测试 build（复用现有 workflow_dispatch 入口，零 workflow 改动）
gh workflow run "构建发布" --ref master

# 一键触发发版（勾选 create_draft_release）
gh workflow run "构建发布" --ref master \
  -f create_draft_release=true \
  -f release_version=v0.0.3
```

**包成 git alias / shell function**（可选）：

```bash
# 加到 ~/.zshrc 或 ~/.bashrc
alias test-build='gh workflow run "构建发布" --ref master'
alias release-build='function _rb() { gh workflow run "构建发布" --ref master \
  -f create_draft_release=true -f release_version="$1"; }; _rb'
```

**优点**：
- workflow **零改动**
- 完全本地操作，不开网页
- 修好 gh 后所有 GitHub 操作（PR、issue、release）都能复用
- 触发命令简洁，配合 alias 体验接近 `git push`

**缺点**：
- 需要一次性修 `gh` 认证（5 分钟）

---

### 方案 B：加 `release-test` 分支 push 触发（纯 git 方案）

**workflow 改动**（`.github/workflows/build.yml`）：

```yaml
on:
  push:
    branches:
      - 'release-test'   # 新增
    tags:
      - 'v*'             # 已有
  workflow_dispatch: ...  # 已有
```

**日常用法**：

```bash
# 初始化（一次性）
git push origin master:release-test       # 建 release-test 分支

# 一键触发测试 build（永远一条命令，零认证）
git push -f origin master:release-test    # 把 master 最新强制推到 release-test
```

**优点**：
- **零认证配置** — 纯 git 操作，跟 `git push tag` 体验完全一样
- 可 force-push 保持分支历史干净（永远只有一个 commit）
- tag 列表完全不动

**缺点**：
- 分支列表里多一个 `release-test`（需在 repo 描述里注明用途）
- 偶尔会有人误以为这是正式分支

---

### 方案 C：`repository_dispatch` API 触发（最干净）

**workflow 改动**（`.github/workflows/build.yml`）：

```yaml
on:
  repository_dispatch:
    types: [test-build]    # 新增监听名为 "test-build" 的事件
  push: ...                # 已有
  workflow_dispatch: ...   # 已有
```

**日常用法**：

```bash
# 用 gh API 触发
gh api repos/Sticky-Finger/ankihelper-pc/dispatches \
  -F event_type=test-build

# 或用 curl + PAT
curl -X POST -H "Authorization: token $PAT" \
  https://api.github.com/repos/Sticky-Finger/ankihelper-pc/dispatches \
  -d '{"event_type":"test-build"}'
```

**优点**：
- **触发不留任何痕迹** — 不动 tag/branch/commit
- 语义最干净（"dispatch a test-build event"）

**缺点**：
- 需要 PAT 或修 gh（类似方案 A）
- 触发器名称（`repository_dispatch`）需要先在 workflow 里定义
- 触发习惯跟 git 操作不一样（不是 `push` 命令）

---

## 二、方案对比

| 维度 | A. gh workflow run | B. release-test 分支 | C. repository_dispatch |
|---|---|---|---|
| 是否污染 tag/branch | ❌ 不污染 | ⚠️ 多一个 release-test 分支 | ❌ 不污染 |
| 是否需要认证 | 修 gh | 无 | PAT 或修 gh |
| 触发命令 | `gh workflow run ...` | `git push -f origin master:release-test` | `gh api ...` 或 `curl ...` |
| workflow 改动 | ❌ 无 | 加 2 行 | 加 5 行 |
| 日常心智 | "跑 workflow" | "推到测试分支"（最像 push tag） | "dispatch 事件" |
| 适合谁 | gh 重度用户 | 纯 git 派 | 想要最干净的 API |

---

## 三、讨论遗留问题

- 用户对"tag 污染"有顾虑（B 方案不动 tag 但有 release-test 分支，可接受）
- 用户对"走 API 认证"有顾虑（A/C 方案都需要 gh auth 或 PAT）
- 待用户决定偏好后再实施

---

## 四、Tasks

> **当前状态：全部任务未启动，方案待选**

### Task 1: 选定方案并实施

**实现内容:**
- [ ] 在三个方案中选定一个
- [ ] 按选定方案修改 `.github/workflows/build.yml`（如需要）
- [ ] 配置触发命令（gh auth / alias / PAT 等）
- [ ] 跑一次端到端验证（push 触发 → build 成功 → 不创建 release）
- [ ] 回写本计划勾选状态 + 更新 `docs/TODO.md` / `docs/PRD.md`

**验证:**
- 测试构建能由本地命令触发，无需打开 GitHub UI
- 触发后 build job 跑成功，但 release job 不创建任何 Release

---

## 五、实施条件

- v0.0.3 发版完成（草稿 Release 已 publish）
- 用户明确选定方案
- 用户的认证 / 配置就绪（取决于方案）

---

## 六、参考

- 讨论时间：2026-09-29
- 相关 workflow 文件：`.github/workflows/build.yml`
- 相关讨论上下文：用户希望在 v0.0.3 发版成功后回头处理这个改进