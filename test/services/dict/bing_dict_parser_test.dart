import 'dart:io';

import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:ankihelper/services/dict/bing_dict_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String fixture;

  setUpAll(() {
    fixture = File('test/fixtures/bing_dict_library.html').readAsStringSync();
  });

  group('parseBingDictHtml — 完整夹具', () {
    test('解析全部字段', () {
      final r = parseBingDictHtml(fixture);

      expect(r.source, DictionarySource.bing);
      expect(r.isSuccess, isTrue);
      expect(r.word, 'library');

      // 音标（从 #bigaud_uk/us 前兄弟元素提取）
      expect(r.ukPhonetic, 'ˈlaɪbrəri');
      expect(r.usPhonetic, 'ˈlaɪbreri');
      expect(r.mergedPhonetic, '英 [ˈlaɪbrəri] 美 [ˈlaɪbreri]');

      // 义项
      expect(r.senses, hasLength(2));
      expect(r.senses[0].pos, 'n.');
      expect(r.senses[0].def, '图书馆; 藏书室');
      expect(r.senses[1].def, '库,程序库');

      // 时态变形
      expect(r.inflections, contains('复数: libraries'));

      // 双语例句（缺中文的不收录）
      expect(r.sentences, hasLength(2));
      expect(r.sentences[0].eng, 'The library is open until 9 pm.');
      expect(r.sentences[0].chs, '图书馆开放到晚上9点。');

      expect(r.errorMessage, isEmpty);
    });
  });

  group('parseBingDictHtml — 容错', () {
    test('无词条 → 未收录', () {
      final r = parseBingDictHtml('<html><body><div>没有词典结果</div></body></html>');
      expect(r.isSuccess, isFalse);
      expect(r.notFound, isTrue);
      expect(r.errorMessage, contains('未收录'));
    });

    test('空 HTML → 未收录', () {
      final r = parseBingDictHtml('');
      expect(r.isSuccess, isFalse);
      expect(r.notFound, isTrue);
    });

    test('只有词条无其他节点 → 成功但字段为空', () {
      final r = parseBingDictHtml('<div id="headword"><h1>word</h1></div>');
      expect(r.isSuccess, isTrue);
      expect(r.word, 'word');
      expect(r.senses, isEmpty);
      expect(r.sentences, isEmpty);
      expect(r.mergedPhonetic, isEmpty);
    });

    test('无音频节点时走 .hd_pr 兜底音标', () {
      final html = '''
        <div id="headword"><h1>test</h1></div>
        <span class="hd_pr">[test]</span>
        <span class="hd_prUS">[tɛst]</span>
      ''';
      final r = parseBingDictHtml(html);
      expect(r.ukPhonetic, 'test');
      expect(r.usPhonetic, 'tɛst');
    });
  });
}
