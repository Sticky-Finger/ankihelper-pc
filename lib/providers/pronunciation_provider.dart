import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pronunciation_service.dart';

/// 发音源状态
class PronunciationState {
  final PronunciationSource selectedSource;
  final List<PronunciationSource> customSources;

  const PronunciationState({
    required this.selectedSource,
    this.customSources = const [],
  });

  /// 获取所有发音源（内置 + 自定义）
  List<PronunciationSource> get allSources =>
      [...builtinPronunciationSources, ...customSources];

  PronunciationState copyWith({
    PronunciationSource? selectedSource,
    List<PronunciationSource>? customSources,
  }) =>
      PronunciationState(
        selectedSource: selectedSource ?? this.selectedSource,
        customSources: customSources ?? this.customSources,
      );
}

/// 发音源持久化 Notifier
class PronunciationNotifier extends Notifier<PronunciationState> {
  static const String _selectedSourceKey = 'pronunciation_selected_source';
  static const String _customSourcesKey = 'pronunciation_custom_sources';

  @override
  PronunciationState build() {
    _loadState();
    return PronunciationState(
      selectedSource: builtinPronunciationSources[1], // 默认有道美音
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载自定义发音源
    final customSourcesJson = prefs.getString(_customSourcesKey);
    List<PronunciationSource> customSources = [];
    if (customSourcesJson != null) {
      try {
        final List<dynamic> jsonList = json.decode(customSourcesJson);
        customSources = jsonList
            .map((json) => PronunciationSource.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (_) {
        customSources = [];
      }
    }

    // 加载选中的发音源
    final selectedId = prefs.getString(_selectedSourceKey);
    PronunciationSource selectedSource = builtinPronunciationSources[1]; // 默认有道美音

    if (selectedId != null) {
      // 先在内置源中查找
      final builtinMatch = builtinPronunciationSources.where((s) => s.id == selectedId);
      if (builtinMatch.isNotEmpty) {
        selectedSource = builtinMatch.first;
      } else {
        // 再在自定义源中查找
        final customMatch = customSources.where((s) => s.id == selectedId);
        if (customMatch.isNotEmpty) {
          selectedSource = customMatch.first;
        }
      }
    }

    state = PronunciationState(
      selectedSource: selectedSource,
      customSources: customSources,
    );
  }

  /// 切换发音源
  Future<void> setSource(PronunciationSource source) async {
    state = state.copyWith(selectedSource: source);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSourceKey, source.id);
  }

  /// 添加自定义发音源
  Future<void> addCustomSource(PronunciationSource source) async {
    final updatedSources = [...state.customSources, source];
    state = state.copyWith(customSources: updatedSources);
    await _saveCustomSources(updatedSources);
  }

  /// 删除自定义发音源
  Future<void> removeCustomSource(String sourceId) async {
    final updatedSources = state.customSources.where((s) => s.id != sourceId).toList();
    state = state.copyWith(customSources: updatedSources);
    await _saveCustomSources(updatedSources);

    // 如果删除的是当前选中的发音源，切换到默认发音源
    if (state.selectedSource.id == sourceId) {
      await setSource(builtinPronunciationSources[1]);
    }
  }

  /// 保存自定义发音源列表
  Future<void> _saveCustomSources(List<PronunciationSource> sources) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sources.map((s) => s.toJson()).toList();
    await prefs.setString(_customSourcesKey, json.encode(jsonList));
  }
}

/// 发音源 Provider
final pronunciationProvider =
    NotifierProvider<PronunciationNotifier, PronunciationState>(
  PronunciationNotifier.new,
);
