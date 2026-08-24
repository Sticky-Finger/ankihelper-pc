import 'dart:convert';
import 'dart:io';

import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:ankihelper/services/dict/youdao_dict_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> fixture;

  setUpAll(() {
    fixture =
        jsonDecode(File('test/fixtures/youdao_dict_library.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  test('解析全部字段', () {
    final r = parseYoudaoDictJson(fixture);

    expect(r.source, DictionarySource.youdao);
    expect(r.isSuccess, isTrue);
    expect(r.word, 'library');
    expect(r.ukPhonetic, 'ˈlaɪbrəri');
    expect(r.usPhonetic, 'ˈlaɪbreri');
    expect(r.mergedPhonetic, '英 [ˈlaɪbrəri] 美 [ˈlaɪbreri]');

    expect(r.senses, hasLength(2));
    expect(r.senses[0].pos, 'n.');
    expect(r.senses[0].def, '图书馆；藏书室');

    expect(r.sentences, hasLength(2));
    expect(r.sentences[0].eng, 'The library closes at nine.');
    expect(r.sentences[0].chs, '图书馆九点关门。');
  });

  test('ec 节点缺失 → 未收录', () {
    final r = parseYoudaoDictJson({'input': 'asdfzzx'});
    expect(r.isSuccess, isFalse);
    expect(r.notFound, isTrue);
  });

  test('return-phrase 为空 → 未收录', () {
    final r = parseYoudaoDictJson({
      'ec': {'word': {'ukphone': 'x'}}
    });
    expect(r.isSuccess, isFalse);
    expect(r.notFound, isTrue);
  });

  test('trs / sentence-pair 缺失或格式异常 → 成功但列表为空', () {
    final r = parseYoudaoDictJson({
      'ec': {
        'word': {
          'return-phrase': 'test',
          'trs': 'not-a-list',
        }
      },
      'blng_sents_part': {'sentence-pair': null},
    });
    expect(r.isSuccess, isTrue);
    expect(r.word, 'test');
    expect(r.senses, isEmpty);
    expect(r.sentences, isEmpty);
  });
}
