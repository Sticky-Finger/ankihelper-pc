# E2E 自动化测试指南

> 实现计划存档：`docs/superpowers/plans/2026-09-14-e2e-testing.md`

## 体系总览

| 层级 | 工具 | 运行形态 | 覆盖目标 |
| --- | --- | --- | --- |
| E2E 集成测试 | Flutter 官方 `integration_test` | 真实 Windows 桌面窗口（源码构建，debug 模式） | 功能回归：查词、义项制卡、设置持久化等主流程 |
| release 产物冒烟 | `tool/smoke_packaged.ps1` | 直接启动打包产物 exe | 打包层回归：缺 DLL、资源丢失、启动即崩 |

**为什么不是 Selenium 那样的黑盒自动化？**（选型时已查证）

- **Patrol**：不支持桌面平台（仅 Android/iOS，Web 走 Playwright）。
- **Appium Flutter Driver**：要求应用以插桩方式构建（暴露 Dart VM 服务），
  无法测试正常打包的 release 产物，且生态面向移动端。
- **OS 层自动化（pywinauto / FlaUI / WinAppDriver）**：Flutter 桌面应用
  在 OS 层只暴露一整个渲染窗口；Flutter Windows 目前仅通过 MSAA 桥暴露
  部分语义树，且没有 AutomationId，元素定位不可靠，不适合做深度 GUI 自动化。
- **结论**：`integration_test` 在真实窗口里以 Dart 代码驱动 UI（能力等同
  Selenium 的元素定位/点击/输入/断言），是 Flutter 桌面 E2E 的事实标准；
  打包产物再用冒烟脚本兜底，二者组合已覆盖绝大部分人工冒烟场景。

## 本地运行

```bash
# E2E 集成测试（会拉起真实应用窗口，Windows 本机即可跑）
flutter test integration_test -d windows

# 单元测试 / 静态分析
flutter test
flutter analyze

# release 产物冒烟（先构建）
flutter build windows --release
pwsh ./tool/smoke_packaged.ps1
# 冒烟脚本参数：-ExePath / -StartupTimeoutSec（默认 30）/ -AliveSec（默认 5）
```

## CI 接入

- `.github/workflows/ci.yml`：**PR 与 master push** 触发，Windows runner 上执行
  `flutter analyze` → `flutter test` → `flutter test integration_test -d windows`。
- `.github/workflows/build.yml`：发版构建的 Windows job 在打包 zip 前运行
  `tool/smoke_packaged.ps1` 冒烟，失败即中止发版。
- GitHub 的 windows runner 自带交互式桌面会话与 VS 工具链，E2E 可直接跑。

## 外部依赖的假服务策略

CI 环境没有 Anki、也不应依赖外网词典接口，所有外部依赖在测试内替换：

| 依赖 | 替代方式 | 位置 |
| --- | --- | --- |
| AnkiConnect | 本地 `FakeAnkiConnectServer`（127.0.0.1 随机端口，真实 HTTP JSON-RPC 路径），经 `AnkiConnectService(baseUrl:)` 注入 | `integration_test/helpers/fake_anki_connect_server.dart` |
| 词典 API（Bing/有道/AI） | `FakeDictionaryService` 覆盖 `DictionaryService.query`，经 `dictionaryServiceProvider` override 注入 | `integration_test/helpers/fake_dictionary_service.dart` |
| SharedPreferences | 每用例 `setMockInitialValues({})` 重置 | `integration_test/helpers/pump_app.dart` |
| 「AnkiConnect 未连接」场景 | 服务指向必然关闭的本地端口（连接立即被拒绝） | `pump_app.dart` 默认 `http://127.0.0.1:1` |

## 测试编写要点（真实窗口环境与单元测试的差异）

- **时间按真实时钟推进**：防抖（300ms）、网络、assets 加载都是真实异步。
  交互后先 `await tester.pump(const Duration(milliseconds: 500))` 真实等待，
  再 `pumpAndSettle()` 收敛帧——直接 `pumpAndSettle()` 会在异步间隙提前收敛。
- **文本框提交用回车**：`tester.testTextInput.receiveAction(TextInputAction.done)`
  对应真实键盘 Enter（点击非可聚焦区域不会让 TextField 失焦）。
- **惰性 Provider 需预热**：如 `templateProvider` 在首次被读取时才异步加载
  内置模板，制卡用例前先等待内置模板就绪（见 `warmUpTemplate`）。
- **单个测试文件 = 一次应用启动**：桌面端每个 `*_test.dart` 都会重新编译
  启动一次应用，用例集中在同一文件、以 group 组织。
- **真剪贴板用例**：`Clipboard.setData` 走真实系统剪贴板 + clipboard_watcher，
  已在本地验证通过；若 CI 环境不稳定可标记 skip（用例名已注明「尽力而为」）。

## 当前用例清单（`integration_test/app_e2e_test.dart`）

1. 启动冒烟：核心区域渲染 + AnkiConnect 未连接状态
2. AnkiConnect 已连接（假服务 version 探活）
3. 输入原文 → 分词 → 点选单词 → 义项渲染（含状态栏/词典标签）
4. 编辑查询词（改为原型）后按新词查询
5. 词典未收录时的提示与空条目保留
6. 义项直接添加：卡片「释义」并入词性前缀（`v. 捐赠；捐献`）
7. 预览弹窗：预填释义含词性，确认后添加成功
8. 制卡失败路径：AnkiConnect 返回错误时 toast 提示
9. 设置持久化：切换词典源写入 SharedPreferences
10. 真实剪贴板取词（尽力而为）

## 后续扩展

- **Linux**：`ubuntu-latest` runner 无显示服务，需 `xvfb-run flutter test
  integration_test -d linux` + GTK 依赖（build.yml 已有依赖清单），在 ci.yml
  加 matrix 即可。
- **macOS**：`macos-latest` 直接 `flutter test integration_test -d macos`。
- **失败截图**：桌面端 `flutter test integration_test` 不自动落盘截图，
  如需可在用例内调 `binding.takeScreenshot` 并结合自定义 runner 上传。
