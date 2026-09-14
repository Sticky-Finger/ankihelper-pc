import 'package:ankihelper/models/dictionary_result_model.dart';
import 'package:ankihelper/services/dictionary_service.dart';

/// 假词典服务（E2E 测试专用）
///
/// 覆盖 [DictionaryService.query]，不发任何网络请求。
/// 通过 [handler] 按查询词返回预设结果，未命中时返回 [defaultResult]。
class FakeDictionaryService extends DictionaryService {
  FakeDictionaryService({this.defaultResult, this.handler});

  /// 默认返回结果（handler 未命中或未设置时使用）
  final DictionaryResult? defaultResult;

  /// 按查询词定制结果的回调（如模拟「未收录」）
  final DictionaryResult? Function(String word)? handler;

  /// 记录收到的查询词（断言防抖/竞态行为用）
  final List<String> queriedWords = [];

  @override
  Future<DictionaryResult> query({
    required String word,
    required String context,
    required DictSettings settings,
    void Function(String markdown)? onStreamChunk,
  }) async {
    queriedWords.add(word);
    return handler?.call(word) ?? defaultResult ?? _notConfigured(word);
  }

  static DictionaryResult _notConfigured(String word) {
    return DictionaryResult.failure('假词典未配置「$word」的结果');
  }
}

/// 预设结果：donate（2 个义项，含词性）
const DictionaryResult donateResult = DictionaryResult(
  source: DictionarySource.bing,
  word: 'donate',
  ukPhonetic: 'dəʊˈneɪt',
  usPhonetic: 'ˈdoʊneɪt',
  senses: [
    DictSense(pos: 'v.', def: '捐赠；捐献'),
    DictSense(pos: 'n.', def: '捐赠，捐赠物'),
  ],
);
