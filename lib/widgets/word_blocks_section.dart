import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_token_model.dart';
import '../providers/word_selection_provider.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'word_token.dart';

/// 单词块区域 — 标题行 + Wrap 网格 + 选中词组展示
class WordBlocksSection extends ConsumerStatefulWidget {
  const WordBlocksSection({super.key});

  @override
  ConsumerState<WordBlocksSection> createState() => _WordBlocksSectionState();
}

class _WordBlocksSectionState extends ConsumerState<WordBlocksSection> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 派发默认示例数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(wordSelectionProvider.notifier);
      final tokens = tokenize('This is an example sentence that you copied.');
      notifier.setTokens(tokens);
      // 默认选中 "example sentence" (indices 3, 4)
      notifier.selectIndex(3);
      notifier.selectRange(4);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onTokenTap(int index) {
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    final notifier = ref.read(wordSelectionProvider.notifier);
    if (isShift) {
      notifier.selectRange(index);
    } else {
      notifier.toggleIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final selection = ref.watch(wordSelectionProvider);

    final hasSelection = selection.selectedIndices.isNotEmpty;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== 标题行 ======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '单词块（单击切换选中 / Shift+单击多选）',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  fontWeight: FluentTokens.fontWeightMedium,
                  color: tokens.fg3,
                ),
              ),
              Text(
                '单击切换 · Shift+单击多选',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  color: tokens.fg4,
                ),
              ),
            ],
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 单词块网格 ======
          Wrap(
            spacing: FluentTokens.spaceSNudge,
            runSpacing: FluentTokens.spaceSNudge,
            children: selection.tokens
                .map(
                  (t) => WordTokenWidget(
                    token: t,
                    isSelected: selection.selectedIndices.contains(t.index),
                    onTap: () => _onTokenTap(t.index),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 当前选中词组 ======
          Container(
            width: double.infinity,
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
            child: Row(
              children: [
                Text(
                  '当前选中词组：',
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize200,
                    fontWeight: FluentTokens.fontWeightMedium,
                    color: tokens.fg4,
                  ),
                ),
                const SizedBox(width: FluentTokens.spaceS),
                Text(
                  hasSelection ? selection.selectedText : '—',
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize300,
                    fontWeight: FluentTokens.fontWeightMedium,
                    color: hasSelection ? tokens.fgBrand : tokens.fg4,
                    fontStyle: hasSelection ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
