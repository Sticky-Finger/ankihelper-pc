import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dictionary_result_model.dart';
import '../services/dictionary_service.dart';
import 'clipboard_provider.dart';
import 'dict_settings_provider.dart';

/// 词典查询状态
enum DictQueryStatus { idle, loading, aiStreaming, done, notFound, failed }

/// 词典查询状态数据
class DictionaryState {
  final DictQueryStatus status;

  /// 成功的查询结果（status == done 时非空）
  final DictionaryResult? result;

  /// 失败原因（status == failed 时非空）
  final String errorMessage;

  /// 本次查询词（竞态守卫：仅当与当前选中词一致时结果才生效）
  final String queriedWord;

  /// AI 流式 Markdown（流式期间逐步累积，最终保留全文）
  final String aiMarkdown;

  const DictionaryState({
    this.status = DictQueryStatus.idle,
    this.result,
    this.errorMessage = '',
    this.queriedWord = '',
    this.aiMarkdown = '',
  });

  bool get isLoading => status == DictQueryStatus.loading;
}

/// 词典查询状态管理
///
/// 编排逻辑在 [DictionaryService]（策略表 + 回退链 + 缓存），
/// 本 Notifier 负责状态生命周期与竞态守卫。
class DictionaryNotifier extends Notifier<DictionaryState> {
  @override
  DictionaryState build() {
    return const DictionaryState();
  }

  /// 异步查询单词
  Future<void> query(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;

    if (kDebugMode) {
      debugPrint('[DictionaryQuery] 开始查询: "$trimmed"');
    }

    state = DictionaryState(
      status: DictQueryStatus.loading,
      queriedWord: trimmed,
    );

    final settings = ref.read(dictSettingsProvider);
    final context = ref.read(clipboardProvider).originalText;
    final service = DictionaryService();

    final result = await service.query(
      word: trimmed,
      context: context,
      settings: settings,
      onStreamChunk: (markdown) {
        // 快速切换选中词时丢弃过期流式帧
        if (state.queriedWord != trimmed) return;
        state = DictionaryState(
          status: DictQueryStatus.aiStreaming,
          queriedWord: trimmed,
          aiMarkdown: markdown,
        );
      },
    );

    // 竞态守卫：查询期间用户已切换选中词 → 丢弃本次结果
    if (state.queriedWord != trimmed) {
      if (kDebugMode) {
        debugPrint('[DictionaryQuery] 丢弃过期结果: "$trimmed"');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('[DictionaryQuery] 查询结果: success=${result.isSuccess}, '
          'error="${result.errorMessage}"');
    }

    state = DictionaryState(
      status: result.isSuccess
          ? DictQueryStatus.done
          : (result.notFound
              ? DictQueryStatus.notFound
              : DictQueryStatus.failed),
      result: result.isSuccess ? result : null,
      errorMessage: result.isSuccess ? '' : result.errorMessage,
      queriedWord: trimmed,
      aiMarkdown: result.aiMarkdown,
    );
  }

  /// 清空状态（清空选中时调用）
  void clear() {
    state = const DictionaryState();
  }
}

/// 词典查询 Provider
final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(
  DictionaryNotifier.new,
);
