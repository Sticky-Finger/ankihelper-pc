import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../../models/dictionary_result_model.dart';

const String _bingHost = 'https://www.bing.com';

/// 浏览器级请求头，降低被人机拦截的概率（kiss-translator 反爬经验）
const Map<String, String> kBrowserLikeHeaders = {
  'user-agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
  'accept-language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7',
};

/// 抓取 Bing 词典搜索页 HTML
///
/// 规格：GET https://www.bing.com/dict/search?q={word}&FORM=BDVSP6&cc=cn
Future<String> fetchBingDictHtml(
  String word, {
  Duration timeout = const Duration(seconds: 8),
  http.Client? client,
}) async {
  final url =
      '$_bingHost/dict/search?q=${Uri.encodeComponent(word)}&FORM=BDVSP6&cc=cn';
  final httpClient = client ?? http.Client();
  try {
    final response =
        await httpClient.get(Uri.parse(url), headers: kBrowserLikeHeaders).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Bing 词典请求失败 (HTTP ${response.statusCode})');
    }
    return response.body;
  } finally {
    if (client == null) httpClient.close();
  }
}

/// 从文本中提取方括号内的音标，如 "[ˈlaɪbrəri]" → "ˈlaɪbrəri"
String? _extractPhonetic(String? text) {
  if (text == null) return null;
  final match = RegExp(r'\[([^\]]+)\]').firstMatch(text.trim());
  return match?.group(1);
}

/// 解析 Bing 词典 HTML 为结构化结果（纯函数，便于单测）
///
/// 选择器映射（源自 kiss-translator 提取文档 §2.1）：
/// - word:        #headword > h1（取不到 → 未收录）
/// - senses:      div.qdef > ul > li 的 .pos / .def
/// - inflections: div.hd_div1>.hd_if>.p1-5
/// - 音标:         #bigaud_uk / #bigaud_us 前兄弟元素文本中的 [..]，
///                为空时 .hd_pr / .hd_prUS 兜底
/// - sentences:   #sentenceSeg .se_li 的 .sen_en / .sen_cn（两者都有值才收录）
DictionaryResult parseBingDictHtml(String html) {
  final doc = html_parser.parse(html);

  final word = doc.querySelector('#headword > h1')?.text.trim() ?? '';
  if (word.isEmpty) {
    return DictionaryResult.failure('Bing 词典未收录', notFound: true);
  }

  // 基本释义列表
  final senses = <DictSense>[];
  for (final li in doc.querySelectorAll('div.qdef > ul > li')) {
    final pos = li.querySelector('.pos')?.text.trim() ?? '';
    final def = li.querySelector('.def')?.text.trim() ?? '';
    if (pos.isNotEmpty || def.isNotEmpty) {
      senses.add(DictSense(pos: pos, def: def));
    }
  }

  // 时态变形
  final inflections = <String>[];
  for (final el in doc.querySelectorAll('div.hd_div1 > .hd_if > .p1-5')) {
    final text = el.text.trim();
    if (text.isNotEmpty) inflections.add(text);
  }

  // 英美音标：优先取发音按钮结构，取不到再用纯文本音标兜底
  String? ukPhonetic;
  String? usPhonetic;
  final ukAudio = doc.querySelector('#bigaud_uk');
  if (ukAudio != null) {
    ukPhonetic = _extractPhonetic(
        ukAudio.parent?.previousElementSibling?.text);
  }
  final usAudio = doc.querySelector('#bigaud_us');
  if (usAudio != null) {
    usPhonetic = _extractPhonetic(
        usAudio.parent?.previousElementSibling?.text);
  }
  ukPhonetic ??= _extractPhonetic(doc.querySelector('.hd_pr')?.text);
  usPhonetic ??= _extractPhonetic(doc.querySelector('.hd_prUS')?.text);

  // 双语例句
  final sentences = <DictSentence>[];
  for (final li in doc.querySelectorAll('#sentenceSeg .se_li')) {
    final eng = li.querySelector('.sen_en')?.text.trim() ?? '';
    final chs = li.querySelector('.sen_cn')?.text.trim() ?? '';
    if (eng.isNotEmpty && chs.isNotEmpty) {
      sentences.add(DictSentence(eng: eng, chs: chs));
    }
  }

  return DictionaryResult(
    source: DictionarySource.bing,
    word: word,
    ukPhonetic: ukPhonetic ?? '',
    usPhonetic: usPhonetic ?? '',
    senses: senses,
    sentences: sentences,
    inflections: inflections,
  );
}
