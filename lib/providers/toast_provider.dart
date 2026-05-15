import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toast 状态
class ToastState {
  final String message;
  final bool isVisible;

  const ToastState({this.message = '', this.isVisible = false});
}

/// Toast 通知 Notifier
class ToastNotifier extends Notifier<ToastState> {
  Timer? _timer;

  @override
  ToastState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ToastState();
  }

  /// 显示 Toast 通知，2 秒后自动消失
  void show(String message) {
    _timer?.cancel();
    state = ToastState(message: message, isVisible: true);
    _timer = Timer(const Duration(seconds: 2), () {
      state = ToastState(message: message, isVisible: false);
    });
  }

  /// 手动隐藏
  void hide() {
    _timer?.cancel();
    state = const ToastState();
  }
}

/// Toast Provider
final toastProvider =
    NotifierProvider<ToastNotifier, ToastState>(ToastNotifier.new);
