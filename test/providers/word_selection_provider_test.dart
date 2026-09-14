import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ankihelper/models/word_token_model.dart';
import 'package:ankihelper/providers/clipboard_provider.dart';
import 'package:ankihelper/providers/dictionary_provider.dart';
import 'package:ankihelper/providers/pronunciation_provider.dart';
import 'package:ankihelper/providers/translation_provider.dart';
import 'package:ankihelper/providers/word_selection_provider.dart';
import 'package:ankihelper/services/pronunciation_service.dart';

/// 记录查询调用的假词典 Notifier（不发网络请求）
class _RecordingDictionaryNotifier extends DictionaryNotifier {
  final List<String> queries = [];
  int clears = 0;

  @override
  Future<void> query(String word) async => queries.add(word);

  @override
  void clear() => clears++;
}

/// 跳过 clipboard_watcher 平台通道的假剪贴板 Notifier
class _StubClipboardNotifier extends ClipboardNotifier {
  @override
  ClipboardState build() => const ClipboardState();
}

/// 跳过持久化加载的假翻译 Notifier
class _StubTranslationNotifier extends TranslationNotifier {
  @override
  TranslationState build() => const TranslationState();
}

/// 跳过 SharedPreferences 加载的假发音源 Notifier
class _StubPronunciationNotifier extends PronunciationNotifier {
  @override
  PronunciationState build() =>
      PronunciationState(selectedSource: builtinPronunciationSources[1]);
}

void main() {
  late ProviderContainer container;
  late _RecordingDictionaryNotifier dict;
  late WordSelectionNotifier notifier;

  setUp(() {
    container = ProviderContainer(overrides: [
      clipboardProvider.overrideWith(_StubClipboardNotifier.new),
      translationProvider.overrideWith(_StubTranslationNotifier.new),
      pronunciationProvider.overrideWith(_StubPronunciationNotifier.new),
      dictionaryProvider.overrideWith(_RecordingDictionaryNotifier.new),
    ]);
    addTearDown(container.dispose);
    dict =
        container.read(dictionaryProvider.notifier)
            as _RecordingDictionaryNotifier;
    notifier = container.read(wordSelectionProvider.notifier);
  });

  test('选中单词后 queryWord 自动初始化为选中原文并防抖查询', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went

    expect(container.read(wordSelectionProvider).queryWord, 'went');

    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(dict.queries, ['went']);
  });

  test('编辑查询词：状态立即更新并 trim，防抖后用编辑词查询', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went
    await Future<void>.delayed(const Duration(milliseconds: 450));

    notifier.updateQueryWord('  go  ');

    // 状态立即更新（trim 后），旧词条目清除
    final state = container.read(wordSelectionProvider);
    expect(state.queryWord, 'go');
    expect(state.currentEntry, isNull);

    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(dict.queries, ['went', 'go']);
    // 重算后的手动空条目 word 用编辑词（卡片正面为原型）
    expect(
      container.read(wordSelectionProvider).currentEntry?.word,
      'go',
    );
  });

  test('commitQueryWord：立即查询且与防抖不重复', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went
    await Future<void>.delayed(const Duration(milliseconds: 450));

    notifier.updateQueryWord('go');
    notifier.commitQueryWord();

    // 无需等待即已查询（失焦/回车立即生效）
    expect(dict.queries.last, 'go');

    // 防抖被取消，不重复查询
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(dict.queries.where((w) => w == 'go').length, 1);
  });

  test('无编辑时 commitQueryWord 不触发冗余查询', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went
    await Future<void>.delayed(const Duration(milliseconds: 450));

    notifier.commitQueryWord();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(dict.queries, ['went']);
  });

  test('再次选中单词重置 queryWord（覆盖编辑）', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went
    await Future<void>.delayed(const Duration(milliseconds: 450));

    notifier.updateQueryWord('go');
    notifier.selectIndex(2); // home

    expect(container.read(wordSelectionProvider).queryWord, 'home');
  });

  test('清除选中后 queryWord 置空并清空词典状态', () async {
    notifier.setTokens(tokenize('He went home.'));
    notifier.selectIndex(1); // went
    await Future<void>.delayed(const Duration(milliseconds: 450));

    notifier.clearSelection();

    expect(container.read(wordSelectionProvider).queryWord, '');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(dict.clears, 1);
  });
}
