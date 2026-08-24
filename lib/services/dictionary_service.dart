import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/dict_settings_model.dart';
import '../models/dictionary_result_model.dart'
    show DictionaryResult, DictionarySource, DictionarySourceLabel;
import 'dict/ai_dict_api.dart';
import 'dict/bing_dict_api.dart';
import 'dict/dict_cache.dart';
import 'dict/youdao_dict_api.dart';

export '../models/dict_settings_model.dart'
    show DictSettings, DictSourcePreference;

/// 判断是否为合法的纯英文单词（仅字母及中划线）
///
/// 与 kiss-translator 的 isValidWord 一致：允许 "state-of-the-art"，
/// 不允许空格、撇号；词形还原（words → word）由词典服务端完成。
final RegExp _wordRegex = RegExp(r'^[a-zA-Z-]+$');

bool isValidWord(String text) =>
    text.trim().isNotEmpty && _wordRegex.hasMatch(text.trim());

/// 计算语境签名（AI 缓存键成分）：剪贴板原句 SHA-256 前 16 位
///
/// 同一单词在不同语境下 AI 释义独立缓存。
String contextSignature(String context) {
  if (context.trim().isEmpty) return '';
  return sha256
      .convert(utf8.encode('$context|dict'))
      .toString()
      .substring(0, 16);
}

/// 词典查询编排服务（策略表 + 回退链 + 缓存）
///
/// 对应 kiss-translator 的 dictHandlers 策略表设计：
/// 每个词典源一个 API 模块，本类负责按设置构建回退链并依序尝试。
/// 回退链默认 `Bing → 有道 → AI`（AI 需配置接口后才启用）；
/// 词组（非 isValidWord）只有 AI 词典能处理。
class DictionaryService {
  DictionaryService({
    this.traditionalTimeout = const Duration(seconds: 8),
    this.aiTimeout = const Duration(seconds: 60),
    DictCache? cache,
  }) : cache = cache ?? DictCache.shared;

  final Duration traditionalTimeout;
  final Duration aiTimeout;

  /// 缓存实例（测试可注入带 mock 时钟的实例）
  final DictCache cache;

  /// 构建词典源回退链
  List<DictionarySource> _buildChain(DictSettings settings) {
    final aiEnabled = settings.aiConfig.isConfigured;
    const bing = DictionarySource.bing;
    const youdao = DictionarySource.youdao;
    const ai = DictionarySource.ai;
    switch (settings.preferredSource) {
      case DictSourcePreference.bing:
        return [bing, youdao, if (aiEnabled) ai];
      case DictSourcePreference.youdao:
        return [youdao, bing, if (aiEnabled) ai];
      case DictSourcePreference.ai:
        return [if (aiEnabled) ai, bing, youdao];
      case DictSourcePreference.auto:
        return [bing, youdao, if (aiEnabled) ai];
    }
  }

  /// 查询单词/词组
  ///
  /// [context] 为剪贴板原句（AI 词典的语境，也参与 AI 缓存键）。
  /// [onStreamChunk] 在 AI 流式输出期间回调（累积后的全量 Markdown）。
  Future<DictionaryResult> query({
    required String word,
    required String context,
    required DictSettings settings,
    void Function(String markdown)? onStreamChunk,
  }) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) {
      return DictionaryResult.failure('查询单词不能为空');
    }

    var chain = _buildChain(settings);
    // 词组只有 AI 词典能处理（提示词自带词典/翻译智能路由）
    if (!isValidWord(trimmed)) {
      chain = chain.where((s) => s == DictionarySource.ai).toList();
      if (chain.isEmpty) {
        return DictionaryResult.failure(
          '「$trimmed」不是单词，词组查询需要配置 AI 词典',
        );
      }
    }

    final contextSig = contextSignature(context);
    final errors = <String>[];
    var allNotFound = true;

    for (final source in chain) {
      final sig = source == DictionarySource.ai ? contextSig : '';
      final cached = await cache.get(source.name, trimmed, sig);
      if (cached != null) {
        return cached;
      }
      try {
        final result = await _fetch(
          source: source,
          word: trimmed,
          context: context,
          settings: settings,
          onStreamChunk: onStreamChunk,
        );
        if (result.isSuccess) {
          await cache.put(source.name, trimmed, sig, result);
          return result;
        }
        allNotFound = allNotFound && result.notFound;
        errors.add('${source.label}: ${result.errorMessage}');
      } catch (e) {
        allNotFound = false;
        errors.add('${source.label}: $e');
      }
    }

    if (allNotFound) {
      return DictionaryResult.failure('词典未收录「$trimmed」', notFound: true);
    }
    return DictionaryResult.failure('词典查询失败（${errors.join('；')}）');
  }

  Future<DictionaryResult> _fetch({
    required DictionarySource source,
    required String word,
    required String context,
    required DictSettings settings,
    void Function(String markdown)? onStreamChunk,
  }) async {
    switch (source) {
      case DictionarySource.bing:
        return parseBingDictHtml(
            await fetchBingDictHtml(word, timeout: traditionalTimeout));
      case DictionarySource.youdao:
        return parseYoudaoDictJson(
            await fetchYoudaoDictJson(word, timeout: traditionalTimeout));
      case DictionarySource.ai:
        final markdown = await AiDictApi.query(
          config: settings.aiConfig,
          text: word,
          context: context,
          timeout: aiTimeout,
          onStreamChunk: onStreamChunk,
        );
        return DictionaryResult(
          source: DictionarySource.ai,
          aiMarkdown: markdown,
        );
    }
  }
}
