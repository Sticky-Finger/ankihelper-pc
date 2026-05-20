import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'anki_connect_provider.dart';

/// 牌组列表获取 + 刷新
class DeckNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchDecks();
  }

  Future<List<String>> _fetchDecks() async {
    final service = ref.read(ankiConnectServiceProvider);
    try {
      if (kDebugMode) {
        debugPrint('[DeckProvider] 正在获取牌组列表...');
      }
      final decks = await service.getDeckNames();
      if (kDebugMode) {
        debugPrint('[DeckProvider] 获取到 ${decks.length} 个牌组');
      }
      return decks;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeckProvider] 获取牌组列表失败: $e');
      }
      rethrow;
    }
  }

  /// 手动刷新牌组列表
  Future<void> refresh() async {
    if (kDebugMode) {
      debugPrint('[DeckProvider] 手动刷新牌组列表');
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDecks());
  }
}

/// 牌组列表 Provider（异步）
final deckListProvider =
    AsyncNotifierProvider<DeckNotifier, List<String>>(DeckNotifier.new);

/// 当前选中牌组名状态管理
class SelectedDeckNotifier extends Notifier<String> {
  @override
  String build() => 'Default';

  void select(String deckName) {
    state = deckName;
  }
}

/// 当前选中的牌组名 Provider（默认 'Default'）
final selectedDeckProvider =
    NotifierProvider<SelectedDeckNotifier, String>(SelectedDeckNotifier.new);
