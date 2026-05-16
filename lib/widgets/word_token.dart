import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_token_model.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// 单个单词块 — 圆角边框 + hover 高亮 + 选中态品牌色
class WordTokenWidget extends ConsumerStatefulWidget {
  final WordTokenModel token;
  final bool isSelected;
  final VoidCallback onTap;

  const WordTokenWidget({
    super.key,
    required this.token,
    required this.isSelected,
    required this.onTap,
  });

  @override
  ConsumerState<WordTokenWidget> createState() => _WordTokenWidgetState();
}

class _WordTokenWidgetState extends ConsumerState<WordTokenWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (widget.isSelected) {
      bgColor = _hovered ? tokens.wordSelectedHover : tokens.statusBrandBg;
      fgColor = _hovered ? tokens.fg1 : tokens.fgBrand;
      borderColor = _hovered ? tokens.fgBrand : tokens.strokeBrand;
    } else if (widget.token.isPunctuation) {
      bgColor = _hovered ? tokens.bgCardHover : tokens.bgCard;
      fgColor = tokens.fg4;
      borderColor = _hovered ? tokens.stroke1 : tokens.stroke2;
    } else {
      bgColor = _hovered ? tokens.bgCardHover : tokens.bgCard;
      fgColor = _hovered ? tokens.fg1 : tokens.fg2;
      borderColor = _hovered ? tokens.stroke1 : tokens.stroke2;
    }

    return IntrinsicWidth(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: FluentTokens.spaceM),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
              border: Border.all(
                color: borderColor,
                width: FluentTokens.strokeWidthThin,
              ),
            ),
            child: Center(
              child: Text(
                widget.token.text,
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize300,
                  fontWeight: widget.isSelected
                      ? FluentTokens.fontWeightMedium
                      : FluentTokens.fontWeightRegular,
                  color: fgColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
