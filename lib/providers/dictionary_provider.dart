import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dictionary_result_model.dart';
import '../models/translation_config_model.dart';
import '../services/dictionary_service.dart';

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
  DictionaryService? _service;

  @override
  DictionaryState build() {
    _loadConfig();
    return const DictionaryState();
  }

  /// 从持久化存储加载翻译配置（与翻译服务共用凭证）
  Future<void> _loadConfig() async {
    const configKey = 'translation_config';
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(configKey);
    TranslationConfig config;
    if (configJson != null) {
      try {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        config = TranslationConfig.fromJson(configMap);
      } catch (_) {
        config = const TranslationConfig();
      }
    } else {
      config = const TranslationConfig();
    }
    _updateService(config);
  }

  /// 更新 API 配置
  void updateConfig(TranslationConfig config) {
    _updateService(config);
  }

  void _updateService(TranslationConfig config) {
    if (config.isConfigured && config.provider == TranslationProvider.youdao) {
      _service = DictionaryService(config: config);
    } else {
      _service = null;
    }
  }

  /// 异步查询单词
  Future<void> query(String word) async {
    if (_service == null) {
      state = DictionaryState(
        result: const DictionaryResult(errorMessage: '请在设置中配置有道智云 API'),
        hasError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, hasError: false);

    final result = await _service!.query(word);

    state = DictionaryState(
      result: result,
      isLoading: false,
      hasError: !result.isSuccess,
    );
  }

  /// 清空结果
  void clear() {
    _service = null;
    state = const DictionaryState();
  }
}

/// 词典查询 Provider
final dictionaryProvider =
    NotifierProvider<DictionaryNotifier, DictionaryState>(
  DictionaryNotifier.new,
);
