import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:ankihelper/services/dict/dict_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  final cache = DictCache(clock: () => now);

  setUp(() {
    now = DateTime(2026, 8, 24, 12, 0, 0);
    SharedPreferences.setMockInitialValues({});
  });

  test('put/get 往返', () async {
    final result = DictionaryResult(
      source: DictionarySource.bing,
      word: 'library',
      ukPhonetic: 'ˈlaɪbrəri',
      usPhonetic: 'ˈlaɪbreri',
      senses: const [DictSense(pos: 'n.', def: '图书馆')],
      inflections: const ['复数: libraries'],
    );
    await cache.put('bing', 'library', '', result);

    final hit = await cache.get('bing', 'library', '');
    expect(hit, isNotNull);
    expect(hit!.word, 'library');
    expect(hit.senses, hasLength(1));
    expect(hit.mergedPhonetic, '英 [ˈlaɪbrəri] 美 [ˈlaɪbreri]');
  });

  test('不同 contextSig 独立缓存', () async {
    final a = DictionaryResult(source: DictionarySource.ai, aiMarkdown: '# 语境A');
    final b = DictionaryResult(source: DictionarySource.ai, aiMarkdown: '# 语境B');
    await cache.put('ai', 'run', 'sig-a', a);
    await cache.put('ai', 'run', 'sig-b', b);

    expect((await cache.get('ai', 'run', 'sig-a'))!.aiMarkdown, '# 语境A');
    expect((await cache.get('ai', 'run', 'sig-b'))!.aiMarkdown, '# 语境B');
    expect(await cache.get('ai', 'run', 'sig-c'), isNull);
  });

  test('过期视为未命中并清除', () async {
    await cache.put('bing', 'test', '',
        const DictionaryResult(source: DictionarySource.bing, word: 'test'));

    // 6 天后仍命中
    now = now.add(const Duration(days: 6));
    expect(await cache.get('bing', 'test', ''), isNotNull);

    // 8 天后过期
    now = now.add(const Duration(days: 2));
    expect(await cache.get('bing', 'test', ''), isNull);
    // 且已从持久化层清除：新建缓存实例（同一 mock prefs）也读不到
    final fresh = DictCache(clock: () => now);
    expect(await fresh.get('bing', 'test', ''), isNull);
  });

  test('clearAll 清空', () async {
    await cache.put('bing', 'a', '',
        const DictionaryResult(source: DictionarySource.bing, word: 'a'));
    await cache.put('youdao', 'b', '',
        const DictionaryResult(source: DictionarySource.youdao, word: 'b'));
    await cache.clearAll();

    expect(await cache.get('bing', 'a', ''), isNull);
    expect(await cache.get('youdao', 'b', ''), isNull);
  });

  test('buildKey 稳定且区分 source', () {
    final k1 = DictCache.buildKey('bing', 'run', '');
    final k2 = DictCache.buildKey('youdao', 'run', '');
    expect(k1, isNot(equals(k2)));
    expect(k1, equals(DictCache.buildKey('bing', 'run', '')));
  });
}
