import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/clipboard_provider.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'fluent_buttons.dart';

/// 剪贴板区域 — 可编辑原文 + 翻译展示
class ClipboardSection extends ConsumerStatefulWidget {
  const ClipboardSection({super.key});

  @override
  ConsumerState<ClipboardSection> createState() => _ClipboardSectionState();
}

class _ClipboardSectionState extends ConsumerState<ClipboardSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _isEditing = false;
      ref.read(clipboardProvider.notifier).setEditing(false);
      final text = _controller.text.trim();
      ref.read(clipboardProvider.notifier).setText(text);
    }
  }

  void _onTap() {
    if (!_isEditing) {
      _isEditing = true;
      ref.read(clipboardProvider.notifier).setEditing(true);
      final currentText = ref.read(clipboardProvider).originalText;
      _controller.text = currentText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final clipboardState = ref.watch(clipboardProvider);
    final originalText = clipboardState.originalText;

    if (!_isEditing && _controller.text != originalText) {
      _controller.text = originalText;
    }

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
          // ====== 原文可编辑框 ======
          GestureDetector(
            onTap: _onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: FluentTokens.spaceM,
                vertical: FluentTokens.spaceMNudge,
              ),
              decoration: BoxDecoration(
                color: tokens.bgInput,
                border: Border.all(
                  color: _isEditing ? tokens.strokeFocus : tokens.stroke3,
                  width: FluentTokens.strokeWidthThin,
                ),
                borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
              ),
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLines: null,
                      style: TextStyle(
                        fontFamily: FluentTokens.fontFamilyBase,
                        fontSize: FluentTokens.fontSize400,
                        color: tokens.fg1,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: '输入或粘贴英文文本...',
                      ),
                      onSubmitted: (_) {
                        _focusNode.unfocus();
                      },
                    )
                  : Text(
                      originalText.isNotEmpty
                          ? originalText
                          : '（点击输入或等待剪贴板内容...）',
                      style: TextStyle(
                        fontFamily: FluentTokens.fontFamilyBase,
                        fontSize: FluentTokens.fontSize400,
                        color: originalText.isNotEmpty
                            ? tokens.fg1
                            : tokens.fg4,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: FluentTokens.spaceS),
          // ====== 翻译行 ======
          Row(
            children: [
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
                    '（等待翻译...）',
                    style: TextStyle(
                      fontFamily: FluentTokens.fontFamilyBase,
                      fontSize: FluentTokens.fontSize300,
                      color: tokens.fg4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FluentTokens.spaceS),
              FluentButton.subtle(
                label: '刷新翻译',
                icon: const Icon(Icons.refresh),
                isSmall: true,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
