import 'package:flutter/material.dart';

/// Fluent 2 设计令牌 — 从设计原型 [anki-word-helper.html] 提取
class FluentTokens {
  final bool isDark;

  const FluentTokens({required this.isDark});

  // ============================================================
  // 便捷构造
  // ============================================================
  static const light = FluentTokens(isDark: false);
  static const dark = FluentTokens(isDark: true);

  // ============================================================
  // 背景色
  // ============================================================
  Color get bgApp => isDark ? const Color(0xFF202020) : const Color(0xFFF5F5F5);
  Color get bgCard =>
      isDark ? const Color(0xFF292929) : const Color(0xFFFFFFFF);
  Color get bgCardHover =>
      isDark ? const Color(0xFF3D3D3D) : const Color(0xFFEBEBEB);
  Color get bgCardPressed =>
      isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE0E0E0);
  Color get bgCardSelected =>
      isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8);
  Color get bgInput =>
      isDark ? const Color(0xFF1F1F1F) : const Color(0xFFFFFFFF);
  Color get bgSurfaceOverlay =>
      isDark ? const Color(0x80000000) : const Color(0x66000000);
  Color get bgSubtle => const Color(0x00000000); // transparent（亮/暗一致）
  Color get bgSubtleHover =>
      isDark ? const Color(0xFF383838) : const Color(0xFFE8E8E8);
  Color get bgSubtlePressed =>
      isDark ? const Color(0xFF2E2E2E) : const Color(0xFFDEDEDE);
  Color get bgSubtleSelected =>
      isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8);
  Color get bgBrand => const Color(0xFF0078D4);
  Color get bgBrandHover => const Color(0xFF106EBE);
  Color get bgBrandPressed => const Color(0xFF004578);

  // ============================================================
  // 前景色（文字/图标）
  // ============================================================
  Color get fg1 =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);
  Color get fg2 =>
      isDark ? const Color(0xFFD6D6D6) : const Color(0xFF424242);
  Color get fg3 =>
      isDark ? const Color(0xFFADADAD) : const Color(0xFF616161);
  Color get fg4 =>
      isDark ? const Color(0xFF999999) : const Color(0xFF808080);
  Color get fgDisabled =>
      isDark ? const Color(0xFF5C5C5C) : const Color(0xFFB0B0B0);
  Color get fgBrand =>
      isDark ? const Color(0xFF479EF5) : const Color(0xFF0078D4);
  Color get fgOnBrand => const Color(0xFFFFFFFF);
  Color get fgLink =>
      isDark ? const Color(0xFF479EF5) : const Color(0xFF0078D4);
  Color get fgLinkHover =>
      isDark ? const Color(0xFF62ABF5) : const Color(0xFF005A9E);

  // ============================================================
  // 描边色
  // ============================================================
  Color get stroke1 =>
      isDark ? const Color(0xFF666666) : const Color(0xFFD1D1D1);
  Color get stroke2 =>
      isDark ? const Color(0xFF525252) : const Color(0xFFE0E0E0);
  Color get stroke3 =>
      isDark ? const Color(0xFF3D3D3D) : const Color(0xFFE8E8E8);
  Color get strokeFocus =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get strokeBrand =>
      isDark ? const Color(0xFF479EF5) : const Color(0xFF0078D4);
  Color get strokeOnBrand =>
      isDark ? const Color(0xFF292929) : const Color(0xFFFFFFFF);
  Color get strokeSubtle =>
      isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF0F0F0);

  // ============================================================
  // 状态色
  // ============================================================
  // 成功
  Color get statusSuccessBg =>
      isDark ? const Color(0xFF043B04) : const Color(0xFFDFF6DD);
  Color get statusSuccessFg =>
      isDark ? const Color(0xFF54B054) : const Color(0xFF0E700E);
  Color get statusSuccessBorder =>
      isDark ? const Color(0xFF359B35) : const Color(0xFF9FD89F);
  // 警告
  Color get statusWarningBg =>
      isDark ? const Color(0xFF433500) : const Color(0xFFFFF4CE);
  Color get statusWarningFg =>
      isDark ? const Color(0xFFF2C661) : const Color(0xFF8A6D00);
  Color get statusWarningBorder =>
      isDark ? const Color(0xFFD0B232) : const Color(0xFFF0C643);
  // 危险
  Color get statusDangerBg =>
      isDark ? const Color(0xFF5C0204) : const Color(0xFFFDE7E9);
  Color get statusDangerFg =>
      isDark ? const Color(0xFFDC626D) : const Color(0xFFC42B1C);
  Color get statusDangerBorder =>
      isDark ? const Color(0xFFD33F4C) : const Color(0xFFF1A6A8);
  // 品牌色状态（选中高亮背景）
  Color get statusBrandBg =>
      isDark ? const Color(0xFF002848) : const Color(0xFFE8F2FC);
  Color get statusBrandFg =>
      isDark ? const Color(0xFF62ABF5) : const Color(0xFF0078D4);

  // ============================================================
  // 滚动条
  // ============================================================
  Color get scrollbarThumb =>
      isDark ? const Color(0x26FFFFFF) : const Color(0x26000000);
  Color get scrollbarThumbHover =>
      isDark ? const Color(0x40FFFFFF) : const Color(0x40000000);

  // ============================================================
  // 组件专用
  // ============================================================
  Color get wordSelectedHover =>
      isDark ? const Color(0xFF003560) : const Color(0xFFCCE4F9);
  Color get emptyEntryHover =>
      isDark ? const Color(0x08FFFFFF) : const Color(0x08000000);
  Color get posTagBg =>
      isDark ? const Color(0x0FFFFFFF) : const Color(0x0D000000);

  // ============================================================
  // 字体家族
  // ============================================================
  static const String fontFamilyBase =
      'Segoe UI, -apple-system, BlinkMacSystemFont, Roboto, Helvetica Neue, sans-serif';
  static const String fontFamilyMono = 'Consolas, Courier New, Courier, monospace';

  // ============================================================
  // 字号 (单位: px)
  // ============================================================
  static const double fontSize100 = 10.0;
  static const double fontSize200 = 12.0;
  static const double fontSize300 = 14.0;
  static const double fontSize400 = 16.0;
  static const double fontSize500 = 20.0;
  static const double fontSize600 = 24.0;
  static const double fontSize700 = 28.0;

  // ============================================================
  // 行高 (单位: px)
  // ============================================================
  static const double lineHeight100 = 14.0;
  static const double lineHeight200 = 16.0;
  static const double lineHeight300 = 20.0;
  static const double lineHeight400 = 22.0;
  static const double lineHeight500 = 28.0;

  // ============================================================
  // 字重
  // ============================================================
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;

  // ============================================================
  // 间距 (单位: px)
  // ============================================================
  static const double spaceXxs = 2.0;
  static const double spaceXs = 4.0;
  static const double spaceSNudge = 6.0;
  static const double spaceS = 8.0;
  static const double spaceMNudge = 10.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXl = 20.0;
  static const double spaceXxl = 24.0;

  // ============================================================
  // 圆角 (单位: px)
  // ============================================================
  static const double radiusNone = 0.0;
  static const double radiusSm = 2.0;
  static const double radiusMd = 4.0;
  static const double radiusLg = 6.0;
  static const double radiusXl = 8.0;
  static const double radiusCircular = 10000.0;

  // ============================================================
  // 阴影
  // ============================================================
  List<BoxShadow> get shadow2 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 2,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  List<BoxShadow> get shadow4 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 2,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get shadow8 => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 2,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  // ============================================================
  // 描边宽度
  // ============================================================
  static const double strokeWidthThin = 1.0;
  static const double strokeWidthThick = 2.0;

  // ============================================================
  // 快捷方法：获取对应主题的 TextTheme
  // ============================================================
  TextStyle get textDefault => TextStyle(
        fontFamily: fontFamilyBase,
        fontSize: fontSize300,
        fontWeight: fontWeightRegular,
        color: fg1,
      );
}
