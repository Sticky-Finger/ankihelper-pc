# Anki划词助手 Phase 2 — AnkiConnect 基础连接 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现 AnkiConnect 基础连接功能，包括引入 HTTP 客户端、封装 AnkiConnect JSON-RPC 服务、连接状态检测、通过 AnkiConnect 添加样例卡片到 Anki，以及将状态栏和添加按钮连接到真实数据。

**架构:** 新增 `services/` 目录存放外部服务封装。`AnkiConnectService` 负责与本地 AnkiConnect 插件通信（JSON-RPC over HTTP）。通过 Riverpod Provider 管理连接状态，状态栏和结果列表从 Provider 读取真实数据。

**技术栈:** Flutter Desktop (macOS), Dart, Riverpod, `http` package

**核心文件结构:**
```
lib/
├── services/
│   └── anki_connect_service.dart    # AnkiConnect JSON-RPC 服务封装
├── providers/
│   └── anki_connect_provider.dart   # AnkiConnect 连接状态 Provider
├── widgets/
│   ├── status_bar.dart              # [修改] 动态连接状态
│   └── results_list.dart            # [修改] 添加按钮接入 AnkiConnect
├── app.dart                         # [修改] StatusBar 传入动态状态
└── pubspec.yaml                     # [修改] 添加 http 依赖
```

---

## Tasks

### Task 1: 引入 `http` 依赖 ✅

**步骤:**

1. **创建 Git feature 分支**:
   ```bash
   git checkout -b feature/ankiconnect-basic
   ```

2. **修改文件:**
   - `pubspec.yaml` — 在 `dependencies` 下添加 `http: ^12.0.0`

3. **安装依赖**:
   ```bash
   flutter pub get
   ```

**验证:**
```bash
flutter pub get && flutter analyze
```
无报错。

---

### Task 2: 实现 AnkiConnect 服务类 ✅

**创建文件:**
- `lib/services/anki_connect_service.dart`

**实现内容:**
- `AnkiConnectService` 类，构造函数接收 `baseUrl`（默认 `http://localhost:8765`）
- `Future<dynamic> invoke(String action, [Map<String, dynamic>? params])` — 统一 JSON-RPC 调用方法，发送 `{"action": ..., "version": 6, "params": ...}` 到 AnkiConnect 端点
- `Future<int> getVersion()` — 调用 `version` action，返回 AnkiConnect 版本号，超时 5 秒
- `Future<int> addNote({required String deckName, required String modelName, required Map<String, String> fields, List<String> tags = const ['ankihelper']})` — 调用 `addNote` action，返回 note ID
- 内部使用 `http.post`，设置 5 秒超时，捕获 `TimeoutException` 和网络异常并抛出自定义 `AnkiConnectException`

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 3: 实现 AnkiConnect Provider ✅

**创建文件:**
- `lib/providers/anki_connect_provider.dart`

**实现内容:**
- `ankiConnectServiceProvider` — 提供 `AnkiConnectService` 单例
- `AnkiConnectionNotifier` — `AsyncNotifier<bool>`，`build()` 时调用 `getVersion()` 检测连接，返回 `true`/`false`
- `ankiConnectionStatusProvider` — 对应的 `AsyncNotifierProvider`
- `AnkiConnectionNotifier` 暴露 `Future<void> refresh()` 方法供手动重试

**验证:**
```bash
flutter analyze
```
无报错。

---

### Task 4: 连接状态栏到真实数据 ✅

**修改文件:**
- `lib/widgets/status_bar.dart` — `StatusBar` 的 `ankiStatus` 参数改为由外部传入（不再硬编码），构造函数签名保持不变（已有 `ankiStatus` 参数）
- `lib/app.dart` — `MainScreen` 中 `StatusBar` 从 `ankiConnectionStatusProvider` 读取状态：
  - `AsyncLoading` → `StatusItem(label: 'AnkiConnect: 检测中…', level: StatusLevel.warning)`
  - `AsyncData(true)` → `StatusItem(label: 'AnkiConnect: 已连接', level: StatusLevel.success)`
  - `AsyncData(false)` / `AsyncError` → `StatusItem(label: 'AnkiConnect: 未连接', level: StatusLevel.danger)`

**验证:**
```bash
flutter run -d macos
```
- 启动 Anki Desktop + AnkiConnect 插件时，状态栏显示绿点 "AnkiConnect: 已连接"
- 未启动 Anki 时，状态栏显示红点 "AnkiConnect: 未连接"

---

### Task 5: 连接"添加"按钮到 AnkiConnect

**修改文件:**
- `lib/widgets/results_list.dart`
  - 导入 `anki_connect_provider` 和 `anki_connect_service.dart`
  - 数据条目的 `onAdd` 回调改为：调用 `ankiConnectServiceProvider` 的 `addNote(...)`，传入 `deckName: 'Default'`、`modelName: 'Basic'`、`fields: {'Front': entry.word, 'Back': entry.meaning}`
  - 成功 → `toastProvider.show('卡片已添加到 Anki')`
  - 捕获 `AnkiConnectException` → `toastProvider.show('添加失败: ${e.message}')`
  - 预览弹窗的返回值：`final confirmed = await showPreviewModal(...)`，返回 `true` 时同样触发 `addNote`

**验证:**
```bash
flutter run -d macos
```
1. 启动 Anki Desktop，确认 AnkiConnect 已安装
2. 点击结果列表中 "example" 条目的"添加"按钮
3. Toast 显示"卡片已添加到 Anki"
4. 在 Anki 的 Default 牌组中确认新增了一张正面为 "example"、背面为 "例子；实例" 的卡片
5. 预览弹窗点击"添加到 Anki"同样能添加卡片
6. 若 Anki 未运行，点击添加后 Toast 显示错误提示
