import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pronunciation_service.dart';

/// 发音源持久化 Notifier
class PronunciationNotifier extends Notifier<PronunciationSource> {
  static const String _sourceKey = 'pronunciation_source';

  @override
  PronunciationSource build() {
    _loadSource();
    return PronunciationSource.youdaoAmE;
  }

  Future<void> _loadSource() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_sourceKey);
    if (index != null && index >= 0 && index < PronunciationSource.values.length) {
      state = PronunciationSource.values[index];
    }
  }

  /// 切换发音源
  Future<void> setSource(PronunciationSource source) async {
    state = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sourceKey, source.index);
  }
}

/// 发音源 Provider
final pronunciationProvider =
    NotifierProvider<PronunciationNotifier, PronunciationSource>(
  PronunciationNotifier.new,
);
