import 'package:ankihelper/models/card_entry_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cardMeaning — 词性并入卡片释义', () {
    test('有词性与释义 → 合并（v. + 释义）', () {
      const entry = CardEntryModel(
        id: 'sense_1',
        word: 'donate',
        pos: 'v.',
        meaning: 'donate money to charity 捐赠',
      );
      expect(entry.cardMeaning, 'v. donate money to charity 捐赠');
      expect(entry.toMap()['meaning'], 'v. donate money to charity 捐赠');
    });

    test('无词性（手动空条目）→ 原样返回', () {
      const entry = CardEntryModel(
        id: 'manual',
        word: 'test',
        meaning: '我自己填的释义',
      );
      expect(entry.cardMeaning, '我自己填的释义');
      expect(entry.toMap()['meaning'], '我自己填的释义');
    });

    test('释义为空 → 原样返回空', () {
      const entry = CardEntryModel(id: 'x', word: 'test', pos: 'n.');
      expect(entry.cardMeaning, '');
    });

    test('防重复守卫：释义已自带词性前缀不再重复拼接', () {
      const entry = CardEntryModel(
        id: 'sense_2',
        word: 'library',
        pos: 'n.',
        meaning: 'n. 图书馆；藏书室',
      );
      expect(entry.cardMeaning, 'n. 图书馆；藏书室');
      expect(entry.cardMeaning.startsWith('n. n.'), isFalse);
    });
  });

  group('toMap — 其余数据源不受影响', () {
    test('各键值完整，aiDictMarkdown 转 HTML', () {
      const entry = CardEntryModel(
        id: 'e1',
        word: 'library',
        phonetic: '英 [ˈlaɪbrəri] 美 [ˈlaɪbreri]',
        pos: 'n.',
        meaning: '图书馆',
        example: 'a <b>library</b> card',
        exampleTranslation: '借书证',
        pronunciationUrl: '[sound:https://dict.youdao.com/dictvoice]',
        aiDictMarkdown: '# 词条\n**library**',
      );
      final map = entry.toMap();
      expect(map['word'], 'library');
      expect(map['phonetic'], '英 [ˈlaɪbrəri] 美 [ˈlaɪbreri]');
      expect(map['meaning'], 'n. 图书馆');
      expect(map['example'], 'a <b>library</b> card');
      expect(map['exampleTranslation'], '借书证');
      expect(map['pronunciationUrl'], '[sound:https://dict.youdao.com/dictvoice]');
      expect(map['aiDictMarkdown'], contains('<h1>'));
      expect(map['aiDictMarkdown'], contains('<strong>library</strong>'));
    });

    test('aiDictMarkdown 为空 → 输出空串', () {
      const entry = CardEntryModel(id: 'e2', word: 'test');
      expect(entry.toMap()['aiDictMarkdown'], '');
    });
  });
}
