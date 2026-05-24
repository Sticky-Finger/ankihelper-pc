import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 剪贴板状态
class ClipboardState {
  final String originalText;
  final bool isEditing;
  final bool isLocked;

  const ClipboardState({
    this.originalText = '',
    this.isEditing = false,
    this.isLocked = false,
  });

  ClipboardState copyWith({
    String? originalText,
    bool? isEditing,
    bool? isLocked,
  }) =>
      ClipboardState(
        originalText: originalText ?? this.originalText,
        isEditing: isEditing ?? this.isEditing,
        isLocked: isLocked ?? this.isLocked,
      );

  /// 原文是否为空
  bool get isEmpty => originalText.isEmpty;
}

/// 剪贴板状态管理
///
/// 集成 clipboard_watcher 监听系统剪贴板变化，
/// 编辑期间暂停监听避免循环触发。
class ClipboardNotifier extends Notifier<ClipboardState>
    with ClipboardListener {
  Timer? _debounceTimer;
  String? _lastText;

  @override
  ClipboardState build() {
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    ref.onDispose(() {
      _debounceTimer?.cancel();
      clipboardWatcher.removeListener(this);
      clipboardWatcher.stop();
    });
    return const ClipboardState();
  }

  /// 手动设置原文（由编辑完成时调用）
  void setText(String text) {
    _lastText = state.originalText;
    state = state.copyWith(originalText: text);
  }

  /// 设置编辑状态（编辑期间暂停剪贴板监听）
  void setEditing(bool editing) {
    state = state.copyWith(isEditing: editing);
  }

  /// 切换锁定状态（锁定后不可编辑且不监听剪贴板）
  void toggleLock() {
    state = state.copyWith(isLocked: !state.isLocked);
  }

  @override
  void onClipboardChanged() {
    if (state.isEditing || state.isLocked) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _readClipboard();
    });
  }

  Future<void> _readClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        final text = data.text!.trim();
        if (text != state.originalText) {
          _lastText = state.originalText;
          state = state.copyWith(originalText: text);
        }
      }
    } catch (_) {
      // 读取剪贴板失败时静默忽略
    }
  }

  /// 原文是否发生变化（用于判断是否需要清空翻译）
  bool get hasOriginalTextChanged =>
      _lastText != null && _lastText != state.originalText;
}

final clipboardProvider =
    NotifierProvider<ClipboardNotifier, ClipboardState>(
  ClipboardNotifier.new,
);
