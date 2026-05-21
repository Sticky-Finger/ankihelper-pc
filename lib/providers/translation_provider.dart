import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/translation_config_model.dart';
import '../services/translation_service.dart';

/// 翻译状态
class TranslationState {
  final String translatedText;
  final bool isLoading;
  final String? errorMessage;
  final bool isEditing;

  const TranslationState({
    this.translatedText = '',
    this.isLoading = false,
    this.errorMessage,
    this.isEditing = false,
  });

  TranslationState copyWith({
    String? translatedText,
    bool? isLoading,
    String? errorMessage,
    bool? isEditing,
  }) =>
      TranslationState(
        translatedText: translatedText ?? this.translatedText,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isEditing: isEditing ?? this.isEditing,
      );

  /// 是否有翻译内容（不是占位符）
  bool get hasTranslation => translatedText.isNotEmpty;
}

/// 翻译配置和状态的 Notifier
class TranslationNotifier extends Notifier<TranslationState> {
  static const String _configKey = 'translation_config';
  TranslationConfig? _cachedConfig;

  @override
  TranslationState build() {
    _loadConfig();
    return const TranslationState();
  }

  /// 从持久化存储加载翻译配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    if (configJson != null) {
      try {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        _cachedConfig = TranslationConfig.fromJson(configMap);
      } catch (_) {
        _cachedConfig = const TranslationConfig();
      }
    } else {
      _cachedConfig = const TranslationConfig();
    }
  }

  /// 获取当前翻译配置
  TranslationConfig get config => _cachedConfig ?? const TranslationConfig();

  /// 保存翻译配置到持久化存储
  Future<void> saveConfig(TranslationConfig config) async {
    _cachedConfig = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, json.encode(config.toJson()));
  }

  /// 清空翻译（原文变化时调用）
  void clearTranslation() {
    state = const TranslationState();
  }

  /// 开始翻译
  Future<void> translate(String originalText) async {
    if (originalText.trim().isEmpty) {
      state = const TranslationState();
      return;
    }

    final config = _cachedConfig ?? const TranslationConfig();
    if (!config.isConfigured) {
      state = TranslationState(
        translatedText: '',
        errorMessage: '请先在设置中配置翻译 API',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final service = TranslationService(config);
      final result = await service.translate(originalText);
      state = TranslationState(
        translatedText: result,
        isLoading: false,
      );
    } catch (e) {
      state = TranslationState(
        translatedText: '',
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 设置翻译文本（用于手动编辑）
  void setTranslatedText(String text) {
    state = state.copyWith(translatedText: text);
  }

  /// 设置编辑状态
  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing);
  }

  /// 清除错误消息
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// 翻译 Provider
final translationProvider =
    NotifierProvider<TranslationNotifier, TranslationState>(
  TranslationNotifier.new,
);
