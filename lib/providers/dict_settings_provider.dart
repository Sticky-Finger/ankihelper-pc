import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dict_settings_model.dart';

/// 词典设置状态管理（持久化于 SharedPreferences）
class DictSettingsNotifier extends Notifier<DictSettings> {
  static const String _prefsKey = 'dict_settings';

  @override
  DictSettings build() {
    _load();
    return const DictSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        state = DictSettings.fromJson(json);
      }
    } catch (_) {
      // 配置损坏时保持默认值
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  /// 设置首选词典源（立即持久化）
  Future<void> setPreferredSource(DictSourcePreference source) async {
    state = state.copyWith(preferredSource: source);
    await _persist();
  }

  /// 更新 AI 词典接口配置（立即持久化）
  Future<void> updateAiConfig(AiDictConfig config) async {
    state = state.copyWith(aiConfig: config);
    await _persist();
  }
}

/// 词典设置 Provider
final dictSettingsProvider =
    NotifierProvider<DictSettingsNotifier, DictSettings>(
  DictSettingsNotifier.new,
);
