import 'package:ankihelper/app.dart';
import 'package:ankihelper/providers/anki_connect_provider.dart';
import 'package:ankihelper/providers/dictionary_provider.dart';
import 'package:ankihelper/services/anki_connect_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_anki_connect_server.dart';
import 'fake_dictionary_service.dart';

/// E2E 统一 bootstrap
///
/// - 每个用例重置 SharedPreferences 为干净的 mock 存储
/// - 以独立的 ProviderScope 启动应用（Riverpod 状态随用例隔离）
/// - 外部依赖注入假实现：
///   - [dictionary]：假词典服务（默认返回 donate 预设结果）
///   - [ankiBaseUrl]：AnkiConnect 服务地址（指向 [FakeAnkiConnectServer] 或
///     必然关闭的端口以模拟未连接）
Future<void> pumpApp(
  WidgetTester tester, {
  FakeDictionaryService? dictionary,
  String? ankiBaseUrl,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dictionaryServiceProvider.overrideWithValue(
          dictionary ?? FakeDictionaryService(defaultResult: donateResult),
        ),
        ankiConnectServiceProvider.overrideWithValue(
          AnkiConnectService(baseUrl: ankiBaseUrl ?? 'http://127.0.0.1:1'),
        ),
      ],
      child: const AnkiHelperApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// 轮询等待某个 Finder 出现（真实窗口环境下异步事件按真实时间推进）
///
/// [timeout] 内每 100ms pump 一帧；出现返回 true，超时返回 false。
Future<bool> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return true;
  }
  return finder.evaluate().isNotEmpty;
}
