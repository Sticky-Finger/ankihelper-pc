import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dictionary_result_model.dart';
import '../models/translation_config_model.dart';
import '../services/dictionary_service.dart';
import 'translation_provider.dart';

/// 词典查询状态
class DictionaryState {
  final DictionaryResult result;
  final bool isLoading;
  final bool hasError;

  const DictionaryState({
    this.result = DictionaryResult.empty,
    this.isLoading = false,
    this.hasError = false,
  });

  DictionaryState copyWith({
    DictionaryResult? result,
    bool? isLoading,
    bool? hasError,
  }) =>
      DictionaryState(
        result: result ?? this.result,
        isLoading: isLoading ?? this.isLoading,
        hasError: hasError ?? (hasError ?? this.hasError),
      );
}

/// 词典查询状态管理
class DictionaryNotifier extends Notifier<DictionaryState> {
  @override
  DictionaryState build() {
    return const DictionaryState();
  }

  /// 获取最新的有道智云配置
  DictionaryService? _buildService() {
    final config = ref.read(translationProvider.notifier).config;
    if (config.isConfigured && config.provider == TranslationProvider.youdao) {
      return DictionaryService(config: config);
    }
    return null;
  }

  /// 异步查询单词
  Future<void> query(String word) async {
    final service = _buildService();

    if (service == null) {
      if (kDebugMode) {
        debugPrint('[DictionaryQuery] 服务未初始化（API 未配置或非有道智云）');
      }
      state = DictionaryState(
        result: const DictionaryResult(errorMessage: '请在设置中配置有道智云 API'),
        hasError: true,
      );
      return;
    }

    if (kDebugMode) {
      debugPrint('[DictionaryQuery] 开始查询: "$word"');
    }

    state = state.copyWith(isLoading: true, hasError: false);

    final result = await service.query(word);

    if (kDebugMode) {
      debugPrint('[DictionaryQuery] 查询结果: success=${result.isSuccess}, error="${result.errorMessage}"');
      if (result.rawResponse.isNotEmpty) {
        debugPrint('[DictionaryQuery] 原始响应: ${result.rawResponse}');
      }
    }

    state = DictionaryState(
      result: result,
      isLoading: false,
      hasError: !result.isSuccess,
    );
  }

  /// 清空结果
  void clear() {
    state = const DictionaryState();
  }
}

/// 词典查询 Provider
final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(
  DictionaryNotifier.new,
);
