import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isSuccess 判定', () {
    expect(
      const DictionaryResult(word: 'library').isSuccess,
      isTrue,
    );
    expect(
      const DictionaryResult(aiMarkdown: '# 词条').isSuccess,
      isTrue,
    );
    expect(const DictionaryResult().isSuccess, isFalse);
    expect(
      const DictionaryResult(errorMessage: '失败').isSuccess,
      isFalse,
    );
  });

  test('mergedPhonetic 组合格式', () {
    expect(
      const DictionaryResult(ukPhonetic: 'a', usPhonetic: 'b').mergedPhonetic,
      '英 [a] 美 [b]',
    );
    expect(
      const DictionaryResult(ukPhonetic: 'a').mergedPhonetic,
      '英 [a]',
    );
    expect(const DictionaryResult().mergedPhonetic, isEmpty);
  });

  test('JSON 序列化往返', () {
    final original = DictionaryResult(
      source: DictionarySource.ai,
      word: 'library',
      ukPhonetic: 'ˈlaɪbrəri',
      usPhonetic: 'ˈlaɪbreri',
      senses: const [
        DictSense(pos: 'n.', def: '图书馆'),
        DictSense(pos: 'n.', def: '程序库'),
      ],
      sentences: const [DictSentence(eng: 'A library.', chs: '一座图书馆。')],
      inflections: const ['复数: libraries'],
      aiMarkdown: '# 词条',
    );

    final restored = DictionaryResult.fromJson(original.toJson());
    expect(restored.source, DictionarySource.ai);
    expect(restored.word, 'library');
    expect(restored.ukPhonetic, 'ˈlaɪbrəri');
    expect(restored.usPhonetic, 'ˈlaɪbreri');
    expect(restored.senses, hasLength(2));
    expect(restored.senses[0].pos, 'n.');
    expect(restored.senses[1].def, '程序库');
    expect(restored.sentences.single.eng, 'A library.');
    expect(restored.sentences.single.chs, '一座图书馆。');
    expect(restored.inflections, ['复数: libraries']);
    expect(restored.aiMarkdown, '# 词条');
    expect(restored.isSuccess, isTrue);
  });

  test('fromJson 容错：缺失字段回退默认值', () {
    final restored = DictionaryResult.fromJson({});
    expect(restored.source, DictionarySource.bing);
    expect(restored.word, isEmpty);
    expect(restored.senses, isEmpty);
    expect(restored.notFound, isFalse);
  });
}
