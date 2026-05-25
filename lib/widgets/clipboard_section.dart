import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/clipboard_provider.dart';
import '../providers/toast_provider.dart';
import '../providers/translation_provider.dart';
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
  final _translationController = TextEditingController();
  final _translationFocusNode = FocusNode();

  bool _isEditing = false;
  bool _isTranslating = false;
  String? _lastOriginalText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onOriginalFocusChange);
    _translationFocusNode.addListener(_onTranslationFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onOriginalFocusChange);
    _focusNode.dispose();
    _translationController.dispose();
    _translationFocusNode.removeListener(_onTranslationFocusChange);
    _translationFocusNode.dispose();
    super.dispose();
  }

  void _onOriginalFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _isEditing = false;
      ref.read(clipboardProvider.notifier).setEditing(false);
      final text = _controller.text.trim();
      ref.read(clipboardProvider.notifier).setText(text);
    }
  }

  void _onTranslationFocusChange() {
    final isEditing = ref.read(translationProvider).isEditing;
    if (!_translationFocusNode.hasFocus && isEditing) {
      ref.read(translationProvider.notifier).setEditing(false);
      final text = _translationController.text.trim();
      ref.read(translationProvider.notifier).setTranslatedText(text);
    }
  }

  void _onOriginalTap() {
    if (ref.read(clipboardProvider).isLocked) return; // 锁定状态不可编辑
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

  void _onTranslationTap() {
    final translationState = ref.read(translationProvider);
    if (!translationState.isEditing) {
      ref.read(translationProvider.notifier).setEditing(true);
      _translationController.text = translationState.translatedText;
      _translationController.selection = TextSelection.fromPosition(
        TextPosition(offset: _translationController.text.length),
      );
    }
  }

  Future<void> _onRefreshTranslation() async {
    final originalText = ref.read(clipboardProvider).originalText;
    if (originalText.trim().isEmpty) return;

    setState(() => _isTranslating = true);
    await ref.read(translationProvider.notifier).translate(originalText);
    if (mounted) {
      setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final clipboardState = ref.watch(clipboardProvider);
    final translationState = ref.watch(translationProvider);
    final originalText = clipboardState.originalText;

    // 原文变化时清空翻译
    if (_lastOriginalText != null &&
        _lastOriginalText != originalText &&
        originalText.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(translationProvider.notifier).clearTranslation();
      });
    }
    _lastOriginalText = originalText;

    // 显示错误提示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (translationState.errorMessage != null) {
        ref.read(toastProvider.notifier).show(translationState.errorMessage!);
        ref.read(translationProvider.notifier).clearError();
      }
    });

    if (!_isEditing && _controller.text != originalText) {
      _controller.text = originalText;
    }

    if (!translationState.isEditing &&
        _translationController.text != translationState.translatedText) {
      _translationController.text = translationState.translatedText;
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
          // ====== 标题 + 锁定按钮 ======
          Row(
            children: [
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
              const SizedBox(width: FluentTokens.spaceS),
              GestureDetector(
                onTap: () => ref.read(clipboardProvider.notifier).toggleLock(),
                child: Icon(
                  clipboardState.isLocked ? Icons.lock : Icons.lock_open,
                  size: 14,
                  color: clipboardState.isLocked
                      ? Colors.orange
                      : tokens.fg4,
                ),
              ),
            ],
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 原文可编辑框 ======
          GestureDetector(
            onTap: _onOriginalTap,
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
                child: GestureDetector(
                  onTap: _onTranslationTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FluentTokens.spaceM,
                      vertical: FluentTokens.spaceSNudge,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.bgInput,
                      border: Border.all(
                        color: translationState.isEditing
                            ? tokens.strokeFocus
                            : tokens.stroke3,
                        width: FluentTokens.strokeWidthThin,
                      ),
                      borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
                    ),
                    child: translationState.isEditing
                        ? TextField(
                            controller: _translationController,
                            focusNode: _translationFocusNode,
                            autofocus: true,
                            maxLines: null,
                            style: TextStyle(
                              fontFamily: FluentTokens.fontFamilyBase,
                              fontSize: FluentTokens.fontSize300,
                              color: tokens.fg1,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: '输入翻译内容...',
                            ),
                            onSubmitted: (_) {
                              _translationFocusNode.unfocus();
                            },
                          )
                        : translationState.isLoading || _isTranslating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: tokens.fg4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '翻译中...',
                                    style: TextStyle(
                                      fontFamily: FluentTokens.fontFamilyBase,
                                      fontSize: FluentTokens.fontSize300,
                                      color: tokens.fg4,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                translationState.hasTranslation
                                    ? translationState.translatedText
                                    : '（等待翻译...）',
                                style: TextStyle(
                                  fontFamily: FluentTokens.fontFamilyBase,
                                  fontSize: FluentTokens.fontSize300,
                                  color: translationState.hasTranslation
                                      ? tokens.fg1
                                      : tokens.fg4,
                                ),
                              ),
                  ),
                ),
              ),
              const SizedBox(width: FluentTokens.spaceS),
              FluentButton.subtle(
                label: '刷新翻译',
                icon: _isTranslating || translationState.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                isSmall: true,
                onPressed: (_isTranslating || translationState.isLoading)
                    ? null
                    : _onRefreshTranslation,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
