import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/dictionary_result_model.dart';
import 'bing_dict_api.dart' show kBrowserLikeHeaders;

const String _youdaoApiUrl =
    'https://dict.youdao.com/jsonapi_s?doctype=json&jsonversion=4';

/// 抓取有道词典网页版免费接口
///
/// 规格（源自 kiss-translator 提取文档 §2.2）：
/// POST jsonapi_s，form-urlencoded body：q={word}&le=en&t=3&client=web&keyfrom=webdict
Future<Map<String, dynamic>> fetchYoudaoDictJson(
  String word, {
  Duration timeout = const Duration(seconds: 8),
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          Uri.parse(_youdaoApiUrl),
          headers: {
            ...kBrowserLikeHeaders,
            'accept': 'application/json, text/plain, */*',
            'content-type': 'application/x-www-form-urlencoded',
          },
          body: {
            'q': word,
            'le': 'en',
            't': '3',
            'client': 'web',
            'keyfrom': 'webdict',
          },
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('有道词典请求失败 (HTTP ${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  } finally {
    if (client == null) httpClient.close();
  }
}

/// 解析有道 jsonapi_s 响应为结构化结果（纯函数，便于单测）
///
/// 字段路径（源自 kiss-translator 提取文档 §2.2）：
/// - word:      ec.word["return-phrase"]
/// - 音标:       ec.word.ukphone / ec.word.usphone
/// - senses:    ec.word.trs[] 的 {pos, tran}
/// - sentences: blng_sents_part["sentence-pair"][] 的 {sentence, sentence-translation}
DictionaryResult parseYoudaoDictJson(Map<String, dynamic> json) {
  final ec = json['ec'];
  final wordMap = ec is Map<String, dynamic> ? ec['word'] : null;
  final word = (wordMap is Map<String, dynamic>
          ? wordMap['return-phrase']
          : null)
      ?.toString()
      .trim() ?? '';
  if (word.isEmpty) {
    return DictionaryResult.failure('有道词典未收录', notFound: true);
  }

  final ukPhonetic = (wordMap['ukphone'] ?? '').toString().trim();
  final usPhonetic = (wordMap['usphone'] ?? '').toString().trim();

  final senses = <DictSense>[];
  final trs = wordMap['trs'];
  if (trs is List<dynamic>) {
    for (final item in trs) {
      if (item is Map<String, dynamic>) {
        final pos = (item['pos'] ?? '').toString().trim();
        final tran = (item['tran'] ?? '').toString().trim();
        if (pos.isNotEmpty || tran.isNotEmpty) {
          senses.add(DictSense(pos: pos, def: tran));
        }
      }
    }
  }

  final sentences = <DictSentence>[];
  final blng = json['blng_sents_part'];
  final pairs = blng is Map<String, dynamic> ? blng['sentence-pair'] : null;
  if (pairs is List<dynamic>) {
    for (final item in pairs) {
      if (item is Map<String, dynamic>) {
        final eng = (item['sentence'] ?? '').toString().trim();
        final chs = (item['sentence-translation'] ?? '').toString().trim();
        if (eng.isNotEmpty && chs.isNotEmpty) {
          sentences.add(DictSentence(eng: eng, chs: chs));
        }
      }
    }
  }

  return DictionaryResult(
    source: DictionarySource.youdao,
    word: word,
    ukPhonetic: ukPhonetic,
    usPhonetic: usPhonetic,
    senses: senses,
    sentences: sentences,
  );
}
