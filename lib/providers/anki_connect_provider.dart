import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_connect_service.dart';

/// AnkiConnect 服务单例 Provider
final ankiConnectServiceProvider = Provider<AnkiConnectService>((ref) {
  return AnkiConnectService();
});

/// 连接状态详情
class ConnectionStatus {
  final bool connected;
  final String? errorMessage;

  const ConnectionStatus({required this.connected, this.errorMessage});
}

/// AnkiConnect 连接状态 Notifier
class AnkiConnectionStatusNotifier extends AsyncNotifier<ConnectionStatus> {
  @override
  Future<ConnectionStatus> build() async {
    return _checkConnection();
  }

  Future<ConnectionStatus> _checkConnection() async {
    final service = ref.read(ankiConnectServiceProvider);
    try {
      if (kDebugMode) {
        debugPrint('[AnkiConnect Provider] 正在检测连接...');
      }
      final version = await service.getVersion();
      if (kDebugMode) {
        debugPrint('[AnkiConnect Provider] 连接成功，版本: $version');
      }
      return const ConnectionStatus(connected: true);
    } on AnkiConnectException catch (e) {
      if (kDebugMode) {
        debugPrint('[AnkiConnect Provider] 连接失败: ${e.message}');
      }
      return ConnectionStatus(connected: false, errorMessage: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnkiConnect Provider] 未知错误: $e');
      }
      return ConnectionStatus(connected: false, errorMessage: e.toString());
    }
  }

  /// 手动刷新连接状态
  Future<void> refresh() async {
    if (kDebugMode) {
      debugPrint('[AnkiConnect Provider] 手动刷新连接状态');
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkConnection());
  }
}

/// AnkiConnect 连接状态 Provider
final ankiConnectionStatusProvider =
    AsyncNotifierProvider<AnkiConnectionStatusNotifier, ConnectionStatus>(
  AnkiConnectionStatusNotifier.new,
);
