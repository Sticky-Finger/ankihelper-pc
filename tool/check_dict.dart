// 词典真实接口连通性检查（开发工具，不参与构建）
// 用法: dart run tool/check_dict.dart [word]
import 'package:ankihelper/services/dict/bing_dict_api.dart';
import 'package:ankihelper/services/dict/youdao_dict_api.dart';

Future<void> main(List<String> args) async {
  final word = args.isNotEmpty ? args.first : 'library';

  try {
    final html = await fetchBingDictHtml(word);
    final r = parseBingDictHtml(html);
    print('[Bing] word=${r.word} isSuccess=${r.isSuccess} '
        'uk=${r.ukPhonetic} us=${r.usPhonetic} '
        'senses=${r.senses.length} sentences=${r.sentences.length} '
        'inflections=${r.inflections.length}');
    if (r.senses.isNotEmpty) {
      print('[Bing] 第一义项: ${r.senses.first.pos} ${r.senses.first.def}');
    }
    if (r.sentences.isNotEmpty) {
      print('[Bing] 第一例句: ${r.sentences.first.eng}');
    }
  } catch (e) {
    print('[Bing] 失败: $e');
  }

  try {
    final json = await fetchYoudaoDictJson(word);
    final r = parseYoudaoDictJson(json);
    print('[Youdao] word=${r.word} isSuccess=${r.isSuccess} '
        'uk=${r.ukPhonetic} us=${r.usPhonetic} senses=${r.senses.length}');
    if (r.senses.isNotEmpty) {
      print('[Youdao] 第一义项: ${r.senses.first.pos} ${r.senses.first.def}');
    }
  } catch (e) {
    print('[Youdao] 失败: $e');
  }
}
