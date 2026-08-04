# 自动化 Release Notes：从 CHANGELOG.md 提取版本段落

## Context

用户每次发版都要手动把 `docs/CHANGELOG.md` 里对应版本的内容复制到 GitHub Release 描述框，比较麻烦。当前 workflow `.github/workflows/build.yml` 的 release job 用 `softprops/action-gh-release@v2` 且配置了 `generate_release_notes: true`，notes 由 GitHub 从 PR/commit 自动生成，用户不满意。

目标：发布草稿 Release 时，自动读取仓库源码中的 `docs/CHANGELOG.md`，按版本号提取对应段落作为 Release notes（替代 `generate_release_notes`）。仅影响**以后**的发版；当前那个 v0.0.1 草稿照旧手动粘贴（内容已提供）。

## 方案概述

只改一个 workflow 文件 + 同步一份文档。不引入第三方 action，提取逻辑用 python3（ubuntu-latest 自带）。

### 改动 1：`计算发版计划` step（build.yml 第 207-222 行）

在 `workflow_dispatch` 分支里补充：
- 版本号格式校验：`^v?[0-9]+\.[0-9]+\.[0-9]+$`，非法输入 exit 1（与现有「未填版本号」报错风格一致）
- **v 前缀规范化**：手动填 `0.0.1` 时自动补成 `v0.0.1`，保证 Release tag、Release 名称、CHANGELOG 段落匹配三者命名统一（仓库既有 tag 均为 v 前缀）

改动后该 step 的 `workflow_dispatch` 分支：
```yaml
          elif [ "${{ github.event_name }}" = "workflow_dispatch" ] && [ "${{ github.event.inputs.create_draft_release }}" = "true" ]; then
            if [ -z "${{ github.event.inputs.release_version }}" ]; then
              echo "已勾选「创建草稿 Release」但未填写版本号，请填写如 v1.0.1"
              exit 1
            fi
            # 手动发版版本号格式校验：vX.Y.Z 或 X.Y.Z
            if [[ ! "${{ github.event.inputs.release_version }}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
              echo "版本号格式不正确，应为 vX.Y.Z（或 X.Y.Z），例如 v1.0.1"
              exit 1
            fi
            # 兼容手动填写时漏掉 v 前缀：统一补 v
            VERSION="${{ github.event.inputs.release_version }}"
            [[ "$VERSION" =~ ^v ]] || VERSION="v$VERSION"
            echo "release=true" >> "$GITHUB_OUTPUT"
            echo "tag=$VERSION" >> "$GITHUB_OUTPUT"
          else
            echo "release=false" >> "$GITHUB_OUTPUT"
          fi
```
（push 分支 `github.ref_name` 由 `tags: ['v*']` 保证带 v 前缀，无需改动）

### 改动 2：release job 新增两个 step（插在「下载全部构建产物」之前）

a) 检出代码（release job 目前无工作区，读 CHANGELOG 前必须先 checkout）：
```yaml
      # release job 默认无工作区，读取 CHANGELOG.md 前必须先检出代码
      - name: 检出代码（读取 CHANGELOG 用）
        if: steps.plan.outputs.release == 'true'
        uses: actions/checkout@v4
```

b) 提取发版说明（python3 读 `docs/CHANGELOG.md`，匹配 `## [vX.Y.Z] - ` 段落，写 `release-notes.md`）：
```yaml
      # 从仓库 docs/CHANGELOG.md 提取当前版本段落，作为 Release notes 写入文件
      - name: 提取发版说明
        if: steps.plan.outputs.release == 'true'
        env:
          # 该 tag 已由「计算发版计划」统一规范为 v 前缀
          RELEASE_TAG: ${{ steps.plan.outputs.tag }}
        run: |
          python3 - <<'PY'
          import os, re, sys

          tag = os.environ["RELEASE_TAG"].strip()
          norm = tag if tag.startswith("v") else "v" + tag  # 防御性再补一次 v

          path = "docs/CHANGELOG.md"
          try:
              with open(path, encoding="utf-8") as f:
                  content = f.read()
          except FileNotFoundError:
              print(f"错误：仓库中未找到 {path}，请确认该文件已提交后再发版")
              sys.exit(1)

          # 精确匹配段落标题：要求 "]" 紧跟版本号后，避免 v0.0.1 误匹配到 v0.0.10
          header = re.compile(r"^## \[" + re.escape(norm) + r"\] - ", re.MULTILINE)
          m = header.search(content)
          if not m:
              print(f"错误：在 {path} 中未找到版本 [{norm}] 对应的段落，请先提交该版本的 changelog 后再发版")
              sys.exit(1)

          # 跳过标题行本身，正文从标题下一行开始（兼容 CRLF）
          body_start = content.index("\n", m.end()) + 1
          region = content[body_start:]
          # 段落到下一个 "## " 开头的行为止（### 子标题不属于段落边界）
          end = re.search(r"^## ", region, re.MULTILINE)
          body = region[: end.start()] if end else region

          # 清理段首/段尾空行，保证末尾单换行
          body = body.strip() + "\n"
          if body == "\n":
              print(f"错误：版本 [{norm}] 的段落内容为空，无法生成发布说明")
              sys.exit(1)

          with open("release-notes.md", "w", encoding="utf-8") as f:
              f.write(body)
          print(f"已提取 [{norm}] 段落的发布说明，共 {len(body)} 字节")
          PY
```

### 改动 3：`创建草稿 Release 并上传产物` step（build.yml 第 231-239 行）

删掉 `generate_release_notes: true`，改用 `body_path: release-notes.md`：
```yaml
      - name: 创建草稿 Release 并上传产物
        if: steps.plan.outputs.release == 'true'
        uses: softprops/action-gh-release@v2
        with:
          files: release-assets/*
          tag_name: ${{ steps.plan.outputs.tag }}
          name: Anki划词助手 ${{ steps.plan.outputs.tag }}
          # 改用 CHANGELOG 提取的说明，不再使用 GitHub 自动生成的 release notes
          body_path: release-notes.md
          draft: true
```

### 改动 4：同步更新 `docs/BUILD_RELEASE.md`

- **三.3 发版**：「流程」行补「检出代码 → 从 `docs/CHANGELOG.md` 按版本段落提取发布说明」；「草稿配置」行把 `generate_release_notes: true` 改为 `body_path` 读取 CHANGELOG 提取内容，找不到对应段落会报错中止；「版本号解析」补一句手动填版本号自动补 v 前缀
- **四、正式发版流程**：步骤 1 前加前置条件「先确保 `docs/CHANGELOG.md` 已提交该版本段落再打 tag」；步骤 4 改为「草稿描述已自动带上 CHANGELOG 对应段落内容，按需补充后 Publish」；手动发版备注提示版本号建议带 v 前缀
- **一、核心诉求**第 16 行：「由开发者写 changelog 后手动发布」→「草稿描述自动从 CHANGELOG.md 提取，开发者可在此基础上补充后发布」

## 关键设计决策

- **CHANGELOG 格式约定（与用户确认）**：提取是固定逻辑脚本（非 AI），只有「段落标题」需要固定格式 `## [vX.Y.Z] - 描述`；段落内部（`###` 子标题、列表、加粗、代码块等）完全自由，原样进 notes。用户需维护三条约定：①每个版本一个带 v 前缀的标题段落；②发版前先把该段落提交进 CHANGELOG（否则流程报错中止）；③版本号三段式 `v1.0.1`，暂不支持 `-beta` 等预发布号。现有 v0.0.1 段落已符合，无需改。
- **找不到版本段落 → 直接 fail**（exit 1 + 中文报错），不发布空 notes 的 Release，与现有「未填版本号就报错」的行为一致。强制先提交 CHANGELOG 再发版。
- 选 python3 而非 awk：段落是多行 markdown，python3 用 `re.escape` 精确匹配 + `strip()` 清理，规避 shell 转义问题。
- `v0.0.1` 不会误匹配 `[v0.0.10]`（正则 `\] - ` 紧跟版本号）；`### 子标题` 不构成段落边界。

## 验证

1. `flutter analyze` 不受影响（纯 CI 改动，无 Dart 代码变更）。
2. GitHub Actions 手动运行 workflow，**不勾选**创建草稿 → 只构建，无 Release 实体（确认新增 step 的 `if` 条件在纯构建时跳过，日志无报错）。
3. 手动运行并勾选创建草稿 + 填版本号（如 `v0.0.1`）→ release job 应成功，草稿 Release 描述框里是 CHANGELOG 中 `## [v0.0.1]` 段落内容（而非自动生成）。
4. 边界验证（可选）：填一个 CHANGELOG 里没有的版本号（如 `v9.9.9`）→ 流程在「提取发版说明」step 明确报错中止，不创建 Release。
5. 确认 `docs/BUILD_RELEASE.md` 与 workflow 行为一致。

## 涉及文件

- `.github/workflows/build.yml`（核心改动）
- `docs/BUILD_RELEASE.md`（同步文档）
- `docs/CHANGELOG.md`（只读数据源，不改）
