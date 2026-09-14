// E2E 集成测试（真实桌面窗口运行）
//
// 运行方式：flutter test integration_test -d windows
//
// 设计要点：
// - 外部依赖全部由假服务替代：
//   - AnkiConnect → 本地 FakeAnkiConnectServer（真实 HTTP 路径）；
//     未指定时指向必然关闭的本地端口（连接立即被拒绝，模拟未连接）
//   - 词典 API   → FakeDictionaryService（Provider override）
// - 防抖（300ms）与异步查询按真实时间推进，用 pump(Duration) 等待
// - 输入提交统一用回车（receiveAction），对应真实键盘的 Enter 路径
import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:ankihelper/providers/template_provider.dart';
import 'package:ankihelper/widgets/result_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_anki_connect_server.dart';
import 'helpers/fake_dictionary_service.dart';
import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// 在「当前选中词组」输入框输入查询词并回车提交
  Future<void> submitQueryWord(WidgetTester tester, String word) async {
    final queryField =
        find.widgetWithText(TextField, '选中后自动填入，可直接编辑（如改为原型）');
    await tester.tap(queryField);
    await tester.pump();
    await tester.enterText(queryField, word);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('启动冒烟', () {
    testWidgets('核心区域渲染', (tester) async {
      await pumpApp(tester);

      expect(find.text('Anki划词助手'), findsOneWidget);
      expect(find.text('剪贴板原文'), findsOneWidget);
      expect(find.text('单词块（单击切换选中 / Shift+单击多选）'), findsOneWidget);
      expect(find.text('结果列表'), findsOneWidget);
      expect(find.text('当前选中词组：'), findsOneWidget);
      expect(find.text('词典查询: 就绪'), findsOneWidget);

      // AnkiConnect 指向已关闭端口 → 不应显示已连接
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('AnkiConnect: 已连接'), findsNothing);
      expect(find.textContaining('AnkiConnect:'), findsOneWidget);
    });
  });

  group('AnkiConnect 连接状态', () {
    testWidgets('假服务在线时显示已连接', (tester) async {
      final fakeAnki = FakeAnkiConnectServer();
      await fakeAnki.start();
      addTearDown(() => fakeAnki.stop());

      await pumpApp(tester, ankiBaseUrl: fakeAnki.baseUrl);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('AnkiConnect: 已连接'), findsOneWidget);
      expect(fakeAnki.receivedActions, contains('version'));
    });
  });

  group('查词流程', () {
    testWidgets('输入原文 → 分词 → 点选单词 → 义项渲染', (tester) async {
      final fakeDict = FakeDictionaryService(defaultResult: donateResult);
      await pumpApp(tester, dictionary: fakeDict);

      // 1. 点击原文区进入编辑，输入例句后回车提交
      await tester.tap(find.text('（点击输入或等待剪贴板内容...）'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, '输入或粘贴英文文本...'),
        'He donated blood yesterday.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 2. 分词：单词块出现
      expect(find.text('He'), findsOneWidget);
      expect(find.text('donated'), findsOneWidget);
      expect(find.text('blood'), findsOneWidget);

      // 3. 点选单词块 → 300ms 防抖后自动查询
      await tester.tap(find.text('donated'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(fakeDict.queriedWords, contains('donated'));
      // 义项条目（2 条）
      expect(find.text('捐赠；捐献'), findsOneWidget);
      expect(find.text('捐赠，捐赠物'), findsOneWidget);
      // 查询词输入框回显选中词
      expect(find.widgetWithText(TextField, 'donated'), findsOneWidget);
      // 状态栏与词典标签
      expect(find.text('词典查询: 完成 (2条释义)'), findsOneWidget);
      expect(find.text('必应词典'), findsOneWidget);
    });

    testWidgets('编辑查询词（改为原型）后按新词查询', (tester) async {
      final fakeDict = FakeDictionaryService(defaultResult: donateResult);
      await pumpApp(tester, dictionary: fakeDict);

      await submitQueryWord(tester, 'donate');

      expect(fakeDict.queriedWords, contains('donate'));
      expect(find.text('捐赠；捐献'), findsOneWidget);
    });

    testWidgets('词典未收录时保留空条目并提示', (tester) async {
      final fakeDict = FakeDictionaryService(
        handler: (word) => DictionaryResult.failure(
          '词典未收录「$word」',
          notFound: true,
        ),
      );
      await pumpApp(tester, dictionary: fakeDict);

      await submitQueryWord(tester, 'qqqqzzzz');

      expect(find.text('词典查询: 未收录'), findsOneWidget);
      expect(find.textContaining('词典未收录「qqqqzzzz」'), findsOneWidget);
    });
  });

  /// 预热模板 Provider：主动触发读取并等待内置模板从 assets 加载完成
  ///
  /// templateProvider 是惰性构建的，若直到制卡才首次读取，异步的内置模板
  /// 加载尚未完成会退化为 Basic 模板（真实用户从启动到制卡有时间差）。
  Future<void> warmUpTemplate(WidgetTester tester) async {
    final container =
        ProviderScope.containerOf(tester.element(find.text('Anki划词助手')));
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (container.read(templateProvider).id.startsWith('builtin_')) return;
    }
    fail('内置模板 5s 内未加载完成');
  }

  group('义项条目制卡', () {
    /// 启动应用（带假 AnkiConnect）并完成一次查询，出现义项条目
    Future<FakeAnkiConnectServer> pumpWithAnki(WidgetTester tester) async {
      final fakeAnki = FakeAnkiConnectServer();
      await fakeAnki.start();
      await pumpApp(tester, ankiBaseUrl: fakeAnki.baseUrl);
      await warmUpTemplate(tester);
      await tester.pumpAndSettle();

      await submitQueryWord(tester, 'donate');
      expect(find.text('捐赠；捐献'), findsOneWidget);
      return fakeAnki;
    }

    testWidgets('直接添加：卡片「释义」字段并入词性前缀', (tester) async {
      final fakeAnki = await pumpWithAnki(tester);
      addTearDown(() => fakeAnki.stop());

      // 点第一个义项（v.）的「添加」
      final senseEntry = find.ancestor(
        of: find.text('捐赠；捐献'),
        matching: find.byType(ResultEntry),
      );
      await tester.tap(
        find.descendant(of: senseEntry, matching: find.text('添加')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 成功 toast + 假服务收到笔记
      expect(find.textContaining('卡片已添加到 Default'), findsOneWidget);
      expect(fakeAnki.addedNotes, hasLength(1));
      final note = fakeAnki.addedNotes.single;
      expect(note['deckName'], 'Default');
      expect(note['modelName'], '划词助手Antimoon模板');
      final fields = Map<String, String>.from(note['fields'] as Map);
      expect(fields['单词'], 'donate');
      expect(fields['释义'], 'v. 捐赠；捐献'); // 词性并入释义
      expect(fields['音标'], '英 [dəʊˈneɪt] 美 [ˈdoʊneɪt]');
    });

    testWidgets('预览弹窗：预填释义含词性，确认后添加成功', (tester) async {
      final fakeAnki = await pumpWithAnki(tester);
      addTearDown(() => fakeAnki.stop());

      final senseEntry = find.ancestor(
        of: find.text('捐赠；捐献'),
        matching: find.byType(ResultEntry),
      );
      await tester.tap(
        find.descendant(of: senseEntry, matching: find.text('预览')),
      );
      // onPreview 异步读取模板后才 showDialog，需真实等待再收敛帧
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('卡片预览'), findsOneWidget);
      final dialog = find.byType(Dialog);
      // 预填的释义字段含词性前缀、单词字段为查询词
      expect(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(TextField, 'v. 捐赠；捐献'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(TextField, 'donate'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('添加到 Anki'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('卡片已添加到 Default'), findsOneWidget);
      expect(fakeAnki.addedNotes, hasLength(1));
      final fields =
          Map<String, String>.from(fakeAnki.addedNotes.single['fields'] as Map);
      expect(fields['释义'], 'v. 捐赠；捐献');
    });

    testWidgets('AnkiConnect 返回错误时提示添加失败', (tester) async {
      final fakeAnki = await pumpWithAnki(tester);
      addTearDown(() => fakeAnki.stop());
      fakeAnki.errorForNextAddNote = '模拟：字段校验失败';

      final senseEntry = find.ancestor(
        of: find.text('捐赠；捐献'),
        matching: find.byType(ResultEntry),
      );
      await tester.tap(
        find.descendant(of: senseEntry, matching: find.text('添加')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('添加失败'), findsOneWidget);
      expect(fakeAnki.addedNotes, isEmpty);
    });
  });

  group('设置持久化', () {
    testWidgets('切换词典源后写入 SharedPreferences', (tester) async {
      await pumpApp(tester);

      // 打开设置弹窗（标题栏「设置」按钮）
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 词典源下拉（弹窗内），默认「自动（必应优先）」
      final dialog = find.byType(AlertDialog);
      await tester.tap(find.descendant(
        of: dialog,
        matching: find.text('自动（必应优先）'),
      ));
      await tester.pumpAndSettle();

      // 选择「有道词典」→ 立即持久化
      await tester.tap(find.text('有道词典').last);
      await tester.pumpAndSettle();

      // 关闭弹窗（点击遮罩），结果列表词典标签变为有道
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('有道词典'), findsOneWidget);

      // SharedPreferences 中已写入 youdao
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dict_settings'), contains('youdao'));
    });
  });

  group('真实剪贴板', () {
    testWidgets('复制文本后原文区自动更新（尽力而为，CI 不稳可跳过）',
        (tester) async {
      await pumpApp(tester);

      await Clipboard.setData(
        const ClipboardData(text: 'Real clipboard e2e sentence.'),
      );
      final appeared = await pumpUntil(
        tester,
        find.text('Real clipboard e2e sentence.'),
        timeout: const Duration(seconds: 5),
      );
      expect(appeared, isTrue);
    });
  });
}
