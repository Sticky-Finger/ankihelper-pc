import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_connect_service.dart';

/// AnkiConnect 服务单例 Provider
final ankiConnectServiceProvider = Provider<AnkiConnectService>((ref) {
  return AnkiConnectService();
});

/// AnkiConnect 连接状态 Notifier
class AnkiConnectionStatusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.read(ankiConnectServiceProvider);
    try {
      await service.getVersion();
      return true;
    } on AnkiConnectException {
      return false;
    }
  }

  /// 手动刷新连接状态
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(ankiConnectServiceProvider);
      await service.getVersion();
      return true;
    });
  }
}

/// AnkiConnect 连接状态 Provider
final ankiConnectionStatusProvider =
    AsyncNotifierProvider<AnkiConnectionStatusNotifier, bool>(
  AnkiConnectionStatusNotifier.new,
);
