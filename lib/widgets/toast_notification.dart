import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/toast_provider.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// Toast 通知覆盖层 — 包裹子组件，底部居中显示通知
class ToastOverlay extends ConsumerWidget {
  final Widget child;

  const ToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final toast = ref.watch(toastProvider);

    return Stack(
      children: [
        child,
        // Toast 通知（底部居中，始终在树中以便播放离场动画）
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: toast.isVisible ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: toast.isVisible ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FluentTokens.spaceL,
                    vertical: FluentTokens.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgCard,
                    border: Border.all(
                      color: tokens.stroke2,
                      width: FluentTokens.strokeWidthThin,
                    ),
                    borderRadius:
                        BorderRadius.circular(FluentTokens.radiusXl),
                    boxShadow: tokens.shadow4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: FluentTokens.spaceS),
                      Text(
                        toast.message,
                        style: TextStyle(
                          fontFamily: FluentTokens.fontFamilyBase,
                          fontSize: FluentTokens.fontSize300,
                          color: tokens.fg1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
