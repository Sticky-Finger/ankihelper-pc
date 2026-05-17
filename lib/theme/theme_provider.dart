import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fluent_tokens.dart';

/// 主题枚举
enum AppTheme { light, dark }

/// 主题状态
class ThemeState {
  final AppTheme current;

  const ThemeState({this.current = AppTheme.light});

  ThemeState copyWith(AppTheme? current) =>
      ThemeState(current: current ?? this.current);

  bool get isDark => current == AppTheme.dark;
}

/// 主题切换 Notifier（Riverpod 3.x Notifier 模式）
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => const ThemeState();

  void toggle() {
    state = state.copyWith(
      state.current == AppTheme.light ? AppTheme.dark : AppTheme.light,
    );
  }

  void setTheme(AppTheme theme) {
    state = state.copyWith(theme);
  }
}

/// 主题状态 Provider
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

/// 根据当前主题提供 FluentTokens
final fluentTokensProvider = Provider<FluentTokens>((ref) {
  final theme = ref.watch(themeProvider);
  return theme.isDark ? FluentTokens.dark : FluentTokens.light;
});
