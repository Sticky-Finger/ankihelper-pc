# 翻译服务 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**目标:** 实现剪贴板原文翻译功能，支持百度翻译/有道智云 API，用户可手动触发翻译并编辑结果

**架构:** 新增 Riverpod Provider 管理翻译状态和配置，TranslationService 封装第三方翻译 API 调用，修改 ClipboardSection 支持翻译显示/编辑，在设置中添加 API 配置界面

**技术栈:** Flutter, Riverpod, http, crypto (签名), shared_preferences (持久化)

**核心文件结构:**
```
lib/
├── models/
│   └── translation_config_model.dart   # [新建] 翻译配置数据模型
├── providers/
│   ├── translation_provider.dart        # [新建] 翻译状态 + 配置 Provider
│   └── clipboard_provider.dart          # [修改] 原文变化时发送通知
├── services/
│   └── translation_service.dart         # [新建] 翻译 API 服务封装
└── widgets/
    ├── clipboard_section.dart           # [修改] 集成翻译显示/编辑
    └── settings_dialog.dart             # [修改] 添加翻译 API 配置界面
pubspec.yaml                              # [修改] 添加 crypto 和 shared_preferences
```

---

## Tasks

### Task 1: 添加依赖 ✅

**修改文件:**
- `pubspec.yaml`

**实现内容:**
- dependencies 中添加 `crypto: ^3.0.6`（用于 MD5 和 SHA256 签名）
- dependencies 中添加 `shared_preferences: ^2.3.5`（用于持久化存储 API 配置）

**验证:**
```bash
flutter pub get
flutter analyze
```
无报错。

---

### Task 2: 创建翻译配置数据模型 ✅

**创建文件:**
- `lib/models/translation_config_model.dart`

**实现内容:**
- `TranslationProvider` 枚举 — `baidu` (百度翻译) 和 `youdao` (有道智云)
- `TranslationConfig` 类 — 包含 `provider`、`appId`、`appSecret` 字段
- `isConfigured` getter — 判断是否已填写完整 API 凭证
- `toJson()` / `fromJson()` — 用于持久化存储
- `copyWith()` 方法

**验证:**
```bash
flutter analyze lib/models/translation_config_model.dart
```
无报错。

---

### Task 3: 创建翻译服务 ✅

**创建文件:**
- `lib/services/translation_service.dart`

**实现内容:**
- `TranslationService` 类 — 接收 `TranslationConfig` 构造
- `translate(String text)` 方法 — 根据 provider 调用对应 API
- `_translateBaidu(String text)` — 百度翻译 API 实现
  - 生成 MD5 签名：`MD5(appid + q + salt + 密钥)`
  - 调用 `https://fanyi-api.baidu.com/api/trans/vip/translate`
  - 解析响应并合并 `trans_result` 段落
- `_translateYoudao(String text)` — 有道智云 API 实现
  - 生成 SHA-256 签名：`SHA256(appKey + input + salt + curtime + appSecret)`
  - 调用 `https://openapi.youdao.com/api`
  - 解析响应并合并 `translation` 段落
- `TranslationException` 异常类
- 百度错误码处理（`error_code` / `error_msg`）
- 有道错误码处理（`errorCode` 映射为中文描述）

**验证:**
```bash
flutter analyze lib/services/translation_service.dart
```
无报错。

---

### Task 4: 创建翻译状态管理 Provider ✅

**创建文件:**
- `lib/providers/translation_provider.dart`

**实现内容:**
- `TranslationState` 类 — 包含 `translatedText`、`isLoading`、`errorMessage`、`isEditing`
- `TranslationNotifier` — `Notifier<TranslationState>`
  - `build()` — 从 shared_preferences 加载配置
  - `_loadConfig()` / `saveConfig()` — 持久化存储 API 配置
  - `config` getter — 获取当前配置
  - `clearTranslation()` — 清空翻译（原文变化时调用）
  - `translate(String)` — 调用 TranslationService 执行翻译
  - `setTranslatedText()` / `setEditing()` — 手动编辑支持
- `translationProvider` — 对应的 NotifierProvider

**验证:**
```bash
flutter analyze lib/providers/translation_provider.dart
```
无报错。

---

### Task 5: 修改剪贴板 Provider 支持原文变化通知 ✅

**修改文件:**
- `lib/providers/clipboard_provider.dart`

**实现内容:**
- `ClipboardState` 添加 `isEmpty` getter
- `ClipboardNotifier` 添加 `_lastText` 私有字段追踪上一次原文
- `setText()` 中更新 `_lastText`
- `_readClipboard()` 中更新 `_lastText`
- `hasOriginalTextChanged` getter — 判断原文是否变化

**验证:**
```bash
flutter analyze lib/providers/clipboard_provider.dart
```
无报错。

---

### Task 6: 修改剪贴板区域 UI 集成翻译功能 ✅

**修改文件:**
- `lib/widgets/clipboard_section.dart`

**实现内容:**
- 导入 `translation_provider.dart`
- 添加 `_translationController` 和 `_translationFocusNode`
- 添加 `_lastOriginalText` 追踪上一次原文
- `build()` 中监听 `clipboardProvider`，原文变化时调用 `translationProvider.clearTranslation()`
- 翻译行 UI 修改：
  - 外层包裹 `GestureDetector` 支持点击编辑
  - 翻译字段根据 `isEditing` 显示 `TextField` 或 `Text`
  - 加载中状态显示 `CircularProgressBar` + "翻译中..."
  - 空状态显示"（等待翻译...）"
  - 有内容时显示翻译文本
- 刷新翻译按钮：
  - 加载中时禁用并显示旋转图标
  - 点击时调用 `translationProvider.translate(originalText)`
- 错误提示通过 `toastProvider.notifier.show()` 显示（与其他模块一致）

**验证:**
```bash
flutter analyze lib/widgets/clipboard_section.dart
```
无报错。

---

### Task 7: 修改设置弹窗添加翻译 API 配置界面 ✅

**修改文件:**
- `lib/widgets/settings_dialog.dart`

**实现内容:**
- 改为 `ConsumerStatefulWidget`
- 添加本地 `_config` 状态管理表单输入
- `initState()` 中从 `translationProvider` 加载当前配置
- "翻译 API 配置" 部分添加：
  - `DropdownButtonFormField` 选择服务商（百度/有道）
  - `TextField` 输入 APP ID / 应用 ID
  - `TextField` 输入密钥（`obscureText: true`）
  - 获取 API 凭证链接（百度/有道官网）
  - 保存/取消按钮
- `_onSave()` 调用 `translationProvider.saveConfig()` 并关闭弹窗

**验证:**
```bash
flutter analyze lib/widgets/settings_dialog.dart
```
无报错。

---

### Task 8: 最终验证和测试 ✅

**验证步骤:**

1. **代码分析**
```bash
flutter analyze
```
无报错。

2. **手动测试**
```bash
flutter run -d macos
```
测试清单：
- 打开设置，配置百度翻译或有道智云 API 凭证并保存
- 复制英文文本到剪贴板
- 验证原文显示正确，翻译字段显示"（等待翻译...）"
- 点击"刷新翻译"，验证翻译结果正确显示
- 点击翻译字段进行编辑，验证可以手动修改
- 复制新的英文文本，验证翻译字段被清空
- 测试无 API 配置时的错误提示
- 测试无效 API 凭证时的错误提示

---

## 实现偏差记录

| 项目 | 原计划 | 实际实现 | 原因 |
|------|--------|----------|------|
|       |        |          |      |
