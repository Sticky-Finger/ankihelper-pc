import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'about_dialog.dart';
import 'fluent_buttons.dart';
import 'manual_input_dialog.dart';
import 'settings_dialog.dart';

/// 标题栏 — 左侧图标+标题+版本号，右侧操作按钮组
class TitleBar extends ConsumerWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onAbout;
  final VoidCallback? onManualInput;

  const TitleBar({
    super.key,
    this.onSettings,
    this.onAbout,
    this.onManualInput,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final theme = ref.watch(themeProvider);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: FluentTokens.spaceL),
      decoration: BoxDecoration(
        color: tokens.bgCard,
        border: Border(
          bottom: BorderSide(
            color: tokens.stroke3,
            width: FluentTokens.strokeWidthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====== 左侧：图标 + 标题 + 版本号 ======
          _AppIcon(color: tokens.fg1),
          const SizedBox(width: FluentTokens.spaceS),
          Text(
            'Anki划词助手',
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize300,
              fontWeight: FluentTokens.fontWeightSemibold,
              color: tokens.fg1,
              letterSpacing: -0.01,
            ),
          ),
          const SizedBox(width: FluentTokens.spaceXxs),
          Text(
            'v0.1',
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize200,
              fontWeight: FluentTokens.fontWeightRegular,
              color: tokens.fg4,
            ),
          ),
          const Spacer(),
          // ====== 右侧：操作按钮组 ======
          IconFluentButton(
            icon: Icon(
              theme.isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          FluentButton.subtle(
            label: '设置',
            isSmall: true,
            onPressed: onSettings ?? () => showSettingsDialog(context),
          ),
          FluentButton.subtle(
            label: '关于',
            isSmall: true,
            onPressed: onAbout ?? () => showAboutDialog_(context),
          ),
          FluentButton.subtle(
            label: '手动输入',
            isSmall: true,
            onPressed: onManualInput ?? () => showManualInputDialog(context),
          ),
        ],
      ),
    );
  }
}

/// 应用图标 — 从设计稿提取的桌面图标
class _AppIcon extends StatelessWidget {
  final Color color;

  const _AppIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _AppIconPainter(color: color),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  final Color color;

  _AppIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 显示器主体
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 3, 20, 14),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, paint);

    // 底座
    canvas.drawLine(const Offset(8, 21), const Offset(16, 21), paint);
    canvas.drawLine(const Offset(12, 17), const Offset(12, 21), paint);
  }

  @override
  bool shouldRepaint(_AppIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
