# 构建与发布流程说明

本文档说明 Anki划词助手 如何通过 GitHub Actions 一键构建多平台可执行文件，并在测试通过后发布到 GitHub Release。

> 实现载体：`.github/workflows/build.yml`

## 一、背景与目标

- 项目是 Flutter 桌面应用，需交付 **macOS（arm64/x64）、Windows、Linux** 四个平台的可执行文件。
- 不希望在每个平台的机器上各自配置开发环境再分别编译，希望借助 GitHub Actions **一次构建多平台产物**，下载到对应系统测试。
- **小改动场景**（修小 bug / 加小功能，达不到发版级别）：只需构建产物拿去测试，**不创建任何 Release / 草稿**。
- **正式发版场景**：测试通过后，把某个版本的产物发布成 Release。
- **核心诉求**：
  - 构建与发版可分开控制；
  - 打 tag 即代表「决定发版」，发版产物必须是**打 tag 那次构建的原文件**（不重复构建）；
  - Release 以**草稿**形式创建（不公开），由开发者写 changelog 后手动发布，发布后仍可编辑。

## 二、触发矩阵

| 操作 | 结果 |
|---|---|
| 推 `v1.0.0` 标签 | 构建 4 平台 + **自动创建草稿 Release**，产物直接挂上（原文件，不重复构建） |
| Actions 手动运行，**不勾选** | 只构建，产物命名带 `dev`，**无任何 Release 实体** |
| Actions 手动运行，**勾选「创建草稿 Release」+ 填版本号** | 构建 + 创建草稿 Release（不建 tag 也能发版） |

**设计要点：**
- 打 tag = 决定发版 → 自动建草稿；小功能测试用手动不勾选，全程零 Release 实体。
- 草稿不公开，正式发布永远由开发者手动点「Publish」，发布后仍可 Edit。

## 三、实现方案

### 1. 触发与手动输入

```yaml
on:
  workflow_dispatch:
    inputs:
      create_draft_release: # 布尔，默认 false；构建后是否创建草稿 Release
      release_version:      # 字符串；手动发版时填的版本号，如 v1.0.1
  push:
    tags: [ 'v*' ]          # 推送 v 开头的 tag 触发
```

### 2. 构建矩阵（4 平台，`fail-fast: false`）

| 平台 | runner | 产物 |
|---|---|---|
| macOS arm64 | macos-latest / arm64 | `.dmg`（create-dmg 打包） |
| macOS x64 | macos-latest / x64（Rosetta） | `.dmg` |
| Windows | windows-latest | `.zip`（Compress-Archive 压缩 Release 文件夹） |
| Linux | ubuntu-22.04 | `.tar.gz`（tar 压缩 bundle） |

- 每次构建执行：检出代码 → 安装系统依赖 → Flutter 环境 → `flutter analyze` → `flutter test` → `flutter build --release` → 打包 → 上传 artifact。
- **产物命名带版本号**：`ankihelper-<平台>-<版本>.<扩展名>`，版本来源 = 手动填的版本号 / tag 名 / `dev`（纯手动构建）。
- Windows / Linux 构建输出是**文件夹**，而 GitHub Release 资源必须是单个文件，所以先压缩成 zip / tar.gz。

### 3. 发版（release job）

- **发版条件**：`(push 且是 v* tag)` **或** `(手动且勾选了 create_draft_release)`。该判定在 **step 内**通过 `github.event.inputs.*` 完成（`inputs` 在 job 级读取不可靠，故特意放到 step 里读）。
- **版本号解析**：打 tag 用 tag 名；手动勾选用输入的版本号（留空则明确报错提示）。
- **流程**：下载本次运行 4 个构建产物 → `softprops/action-gh-release@v2` 创建**草稿** Release → 上传产物。
- **草稿配置**：`draft: true`（不公开）+ `generate_release_notes: true`（自动生成一版发布说明作底稿）。
- **版本号即 tag**：手动发版填的版本号会作为 Release 的 tag；若该 tag 不存在，GitHub 会自动创建它（指向当前分支）。打 tag 发版则直接用 tag 名。
- **关键保证**：打 tag 的构建与发版在**同一次运行**内，产物是同一份文件，不存在「测试的和发布的不是同一份」的问题。

## 四、使用流程

### 小功能 / 小 bug 测试（不发版）

1. Actions 手动运行，不勾选（或干脆不推 tag）。
2. 下载产物到各平台测试。

### 正式发版

1. `git tag v1.0.0 && git push origin v1.0.0`
2. 自动构建 4 平台并建好**草稿**（不公开），产物已挂上。
3. 从草稿下载产物到各平台测试。
4. 测试通过 → 打开 Releases 页面上的草稿，在**描述框**里写/改 changelog（不是写在 Actions 输入栏，也无需本地 `CHANGELOG.md`）→ **Publish**。
5. 测试不通过 → 删草稿、修 bug、重新打 tag。

> 若不想用 tag 发版，也可手动运行并勾选「创建草稿 Release」+ 填版本号，效果相同；注意该版本号会被 GitHub 自动创建成 tag。

## 五、注意事项

- **只在默认分支生效**：`build.yml` 的改动必须合入 `master` 才会被 GitHub 采用。
- **草稿 = 私密**：对外不可见，只有有权限的人能查看、能发布。
- **重复打同名 tag**：会覆盖更新该 Release，同名产物自动替换。
- 本地已通过校验：YAML 语法 ✅、actionlint ✅。
