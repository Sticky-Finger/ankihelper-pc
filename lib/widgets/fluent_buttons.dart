import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

// ============================================================
// Fluent 2 按钮合集 — 从设计原型提取四种样式
// ============================================================

enum FluentButtonStyle { subtle, outline, primary }

/// 基础 Fluent 按钮 — 通过 [style] 区分三种文字样式
class FluentButton extends ConsumerStatefulWidget {
  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final double? width;
  final bool isSmall;
  final FluentButtonStyle style;

  const FluentButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.isSmall = false,
    this.style = FluentButtonStyle.subtle,
  });

  const FluentButton.subtle({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.isSmall = false,
  }) : style = FluentButtonStyle.subtle;

  const FluentButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.isSmall = false,
  }) : style = FluentButtonStyle.outline;

  const FluentButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.width,
    this.isSmall = false,
  }) : style = FluentButtonStyle.primary;

  @override
  ConsumerState<FluentButton> createState() => _FluentButtonState();
}

class _FluentButtonState extends ConsumerState<FluentButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);

    Color bgColor;
    Color fgColor;
    Color borderColor;

    final isOutline = widget.style == FluentButtonStyle.outline;
    final isPrimary = widget.style == FluentButtonStyle.primary;

    if (isPrimary) {
      bgColor = _pressed
          ? tokens.bgBrandPressed
          : _hovered
              ? tokens.bgBrandHover
              : tokens.bgBrand;
      fgColor = tokens.fgOnBrand;
      borderColor = bgColor;
    } else if (isOutline) {
      bgColor = _pressed
          ? tokens.bgSubtlePressed
          : _hovered
              ? tokens.bgSubtleHover
              : tokens.bgSubtle;
      fgColor = _hovered ? tokens.fg1 : tokens.fg2;
      borderColor = tokens.stroke1;
    } else {
      // subtle
      bgColor = _pressed
          ? tokens.bgSubtlePressed
          : _hovered
              ? tokens.bgSubtleHover
              : tokens.bgSubtle;
      fgColor = _hovered ? tokens.fg1 : tokens.fg2;
      borderColor = Colors.transparent;
    }

    final height = widget.isSmall ? 28.0 : 32.0;
    final hPadding = widget.isSmall ? FluentTokens.spaceS : FluentTokens.spaceM;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
            border: Border.all(
              color: borderColor,
              width: FluentTokens.strokeWidthThin,
            ),
          ),
          child: Center(
            child: widget.icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: widget.isSmall ? 14.0 : 16.0,
                          color: fgColor,
                        ),
                        child: widget.icon!,
                      ),
                      const SizedBox(width: FluentTokens.spaceSNudge),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: FluentTokens.fontFamilyBase,
                          fontSize: widget.isSmall
                              ? FluentTokens.fontSize200
                              : FluentTokens.fontSize300,
                          fontWeight: FluentTokens.fontWeightRegular,
                          color: fgColor,
                        ),
                      ),
                    ],
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: FluentTokens.fontFamilyBase,
                      fontSize: widget.isSmall
                          ? FluentTokens.fontSize200
                          : FluentTokens.fontSize300,
                      fontWeight: FluentTokens.fontWeightRegular,
                      color: fgColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 图标按钮（Subtle 样式）
class IconFluentButton extends ConsumerStatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final double size;

  const IconFluentButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 32.0,
  });

  @override
  ConsumerState<IconFluentButton> createState() => _IconFluentButtonState();
}

class _IconFluentButtonState extends ConsumerState<IconFluentButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);

    final bgColor = _pressed
        ? tokens.bgSubtlePressed
        : _hovered
            ? tokens.bgSubtleHover
            : tokens.bgSubtle;
    final fgColor = _hovered ? tokens.fg1 : tokens.fg2;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: widget.onPressed != null
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
          ),
          child: IconTheme(
            data: IconThemeData(size: 16.0, color: fgColor),
            child: Center(child: widget.icon),
          ),
        ),
      ),
    );
  }
}
