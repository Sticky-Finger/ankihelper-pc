import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_token_model.dart';
import '../providers/clipboard_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../providers/word_selection_provider.dart';
import '../services/pronunciation_service.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(clipboardProvider, (prev, next) {
        if (next.originalText != prev?.originalText) {
          final tokens = next.originalText.isNotEmpty
              ? tokenize(next.originalText)
              : <WordTokenModel>[];
          ref.read(wordSelectionProvider.notifier).setTokens(tokens);
        }
      });
      final current = ref.read(clipboardProvider);
      if (current.originalText.isNotEmpty) {
        final tokens = tokenize(current.originalText);
        ref.read(wordSelectionProvider.notifier).setTokens(tokens);
      }
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
          const SizedBox(height: FluentTokens.spaceSNudge),
          // ====== 发音控制行 ======
          _PronunciationControls(),
        ],
      ),
    );
  }
}

/// 发音控制组件：播放按钮 + 发音源下拉
class _PronunciationControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final selection = ref.watch(wordSelectionProvider);
    final currentSource = ref.watch(pronunciationProvider);

    return Row(
      children: [
        // 播放发音按钮
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.volume_up, size: 18, color: tokens.fg2),
            onPressed: () async {
              final word = selection.selectedText;
              final source = ref.read(pronunciationProvider);
              await PronunciationPlayer.play(word, source);
            },
            tooltip: '播放发音',
          ),
        ),
        const SizedBox(width: FluentTokens.spaceS),
        // 发音源下拉
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: tokens.bgInput,
            border: Border.all(
              color: tokens.stroke3,
              width: FluentTokens.strokeWidthThin,
            ),
            borderRadius: BorderRadius.circular(FluentTokens.radiusSm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PronunciationSource>(
              value: currentSource,
              isDense: true,
              style: TextStyle(
                fontFamily: FluentTokens.fontFamilyBase,
                fontSize: FluentTokens.fontSize200,
                color: tokens.fg2,
              ),
              items: PronunciationSource.values.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(source.label),
                );
              }).toList(),
              onChanged: (source) {
                if (source != null) {
                  ref.read(pronunciationProvider.notifier).setSource(source);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
