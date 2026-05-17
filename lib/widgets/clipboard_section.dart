import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'fluent_buttons.dart';

/// 剪贴板区域 — 展示剪贴板原文与中文翻译
class ClipboardSection extends ConsumerWidget {
  final String originalText;
  final String translationText;
  final VoidCallback? onRefreshTranslation;

  const ClipboardSection({
    super.key,
    this.originalText = '',
    this.translationText = '',
    this.onRefreshTranslation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);

    return Container(
      padding: const EdgeInsets.all(FluentTokens.spaceL),
      decoration: BoxDecoration(
        color: tokens.bgCard,
        border: Border.all(
          color: tokens.stroke3,
          width: FluentTokens.strokeWidthThin,
        ),
        borderRadius: BorderRadius.circular(FluentTokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== 标题 ======
          Text(
            '剪贴板原文',
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize200,
              fontWeight: FluentTokens.fontWeightMedium,
              color: tokens.fg3,
              letterSpacing: 0.04,
            ),
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 原文展示框 ======
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: FluentTokens.spaceM,
              vertical: FluentTokens.spaceMNudge,
            ),
            decoration: BoxDecoration(
              color: tokens.bgInput,
              border: Border.all(
                color: tokens.stroke3,
                width: FluentTokens.strokeWidthThin,
              ),
              borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
            ),
            child: Text(
              originalText.isNotEmpty ? originalText : '（等待剪贴板内容...）',
              style: TextStyle(
                fontFamily: FluentTokens.fontFamilyBase,
                fontSize: FluentTokens.fontSize400,
                color: originalText.isNotEmpty ? tokens.fg1 : tokens.fg4,
              ),
            ),
          ),
          const SizedBox(height: FluentTokens.spaceS),
          // ====== 翻译行 ======
          Row(
            children: [
              // 翻译标签
              Text(
                '原文翻译',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  fontWeight: FluentTokens.fontWeightMedium,
                  color: tokens.fg4,
                ),
              ),
              const SizedBox(width: FluentTokens.spaceS),
              // 翻译文本展示框
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FluentTokens.spaceM,
                    vertical: FluentTokens.spaceSNudge,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgInput,
                    border: Border.all(
                      color: tokens.stroke3,
                      width: FluentTokens.strokeWidthThin,
                    ),
                    borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
                  ),
                  child: Text(
                    translationText.isNotEmpty
                        ? translationText
                        : '（等待翻译...）',
                    style: TextStyle(
                      fontFamily: FluentTokens.fontFamilyBase,
                      fontSize: FluentTokens.fontSize300,
                      color: translationText.isNotEmpty
                          ? tokens.fg2
                          : tokens.fg4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FluentTokens.spaceS),
              // 刷新翻译按钮
              FluentButton.subtle(
                label: '刷新翻译',
                icon: const Icon(Icons.refresh),
                isSmall: true,
                onPressed: onRefreshTranslation,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
