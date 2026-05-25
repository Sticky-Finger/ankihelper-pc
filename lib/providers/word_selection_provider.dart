import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_entry_model.dart';
import '../models/word_token_model.dart';
import '../services/pronunciation_service.dart';
import 'clipboard_provider.dart';
import 'pronunciation_provider.dart';
import 'translation_provider.dart';

/// 单词选中状态
class WordSelectionState {
  final List<WordTokenModel> tokens;
  final Set<int> selectedIndices;
  final int? lastClickedIndex;
  final CardEntryModel? currentEntry;

  const WordSelectionState({
    this.tokens = const [],
    this.selectedIndices = const {},
    this.lastClickedIndex,
    this.currentEntry,
  });

  /// 当前选中的文本（跳过标点）
  String get selectedText {
    if (selectedIndices.isEmpty) return '';
    final sorted = SplayTreeSet<int>.from(selectedIndices);
    final words = <String>[];
    for (final i in sorted) {
      if (i < tokens.length && !tokens[i].isPunctuation) {
        words.add(tokens[i].text);
      }
    }
    return words.join(' ');
  }

  /// currentEntry 不通过 copyWith 传递，由 Notifier 直接赋值

  WordSelectionState copyWith({
    List<WordTokenModel>? tokens,
    Set<int>? selectedIndices,
    int? lastClickedIndex,
    bool clearLastClicked = false,
  }) =>
      WordSelectionState(
        tokens: tokens ?? this.tokens,
        selectedIndices: selectedIndices ?? this.selectedIndices,
        lastClickedIndex:
            clearLastClicked ? null : (lastClickedIndex ?? this.lastClickedIndex),
        currentEntry: currentEntry,
      );
}

/// 单词选中状态 Notifier
class WordSelectionNotifier extends Notifier<WordSelectionState> {
  Timer? _debounceTimer;

  @override
  WordSelectionState build() {
    // 监听剪贴板变化 → 立即重算 currentEntry（不防抖）
    ref.listen(clipboardProvider, (prev, next) {
      if (prev?.originalText != next.originalText) {
        _recomputeEntry();
      }
    });
    // 监听翻译变化 → 立即重算 currentEntry（不防抖）
    ref.listen(translationProvider, (prev, next) {
      if (prev?.translatedText != next.translatedText) {
        _recomputeEntry();
      }
    });
    ref.onDispose(() => _debounceTimer?.cancel());
    return const WordSelectionState();
  }

  /// 设置分词结果
  void setTokens(List<WordTokenModel> tokens) {
    state = WordSelectionState(tokens: tokens);
    _debouncedRecompute();
  }

  /// 处理单击选中
  void selectIndex(int index) {
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: {index},
      lastClickedIndex: index,
    );
    _debouncedRecompute();
  }

  /// 处理 Shift+单击（连续多选）
  void selectRange(int index) {
    final last = state.lastClickedIndex;
    if (last == null) {
      selectIndex(index);
      return;
    }
    final start = last < index ? last : index;
    final end = last < index ? index : last;
    final indices = <int>{};
    for (int i = start; i <= end; i++) {
      if (i >= 0 && i < state.tokens.length) {
        indices.add(i);
      }
    }
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: indices,
      lastClickedIndex: last,
    );
    _debouncedRecompute();
  }

  /// 处理 Cmd/Ctrl+单击（切换选中）
  void toggleIndex(int index) {
    final indices = Set<int>.from(state.selectedIndices);
    if (indices.contains(index)) {
      indices.remove(index);
    } else {
      indices.add(index);
    }
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: indices,
      lastClickedIndex: index,
    );
    _debouncedRecompute();
  }

  /// 清除选中
  void clearSelection() {
    state = WordSelectionState(tokens: state.tokens);
    _debouncedRecompute();
  }

  /// selectedText 变化后 300ms 防抖重算 currentEntry
  void _debouncedRecompute() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _recomputeEntry);
  }

  /// 立即重算 currentEntry（剪贴板/翻译变化时调用）
  void _recomputeEntry() {
    _debounceTimer?.cancel();
    final selectedText = state.selectedText;
    final clipboard = ref.read(clipboardProvider).originalText;
    final translation = ref.read(translationProvider).translatedText;
    final entry = _buildEntry(selectedText, clipboard, translation);
    // 直接构造新 state，保留 currentEntry
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: state.selectedIndices,
      lastClickedIndex: state.lastClickedIndex,
      currentEntry: entry,
    );
  }

  /// 构建 example 字段：按选中位置精确高亮
  String _buildExample(String selectedText, String clipboard) {
    if (clipboard.isEmpty) return '';
    if (state.selectedIndices.isEmpty) return clipboard;

    final tokens = state.tokens;
    if (tokens.isEmpty) return clipboard;

    final sortedIndices = SplayTreeSet<int>.from(state.selectedIndices);
    final result = StringBuffer();
    int clipPos = 0;

    for (final token in tokens) {
      // 从剪贴板中找到这个 token 的实时位置（从上次结束位置开始查找）
      final tokenStart = clipboard.indexOf(token.text, clipPos);
      if (tokenStart == -1) {
        // 找不到则放弃高亮，返回原始文本
        return clipboard;
      }

      // 写入 token 前的文本（空白字符等）
      if (tokenStart > clipPos) {
        result.write(clipboard.substring(clipPos, tokenStart));
      }

      if (sortedIndices.contains(token.index) && !token.isPunctuation) {
        result.write('<b>${token.text}</b>');
      } else {
        result.write(token.text);
      }

      clipPos = tokenStart + token.text.length;
    }

    // 写入最后一个 token 后的剩余文本
    if (clipPos < clipboard.length) {
      result.write(clipboard.substring(clipPos));
    }

    return result.toString();
  }

  /// 构建 currentEntry
  CardEntryModel _buildEntry(
      String selectedText, String clipboard, String translation) {
    final source = ref.read(pronunciationProvider);
    final pronunciationUrl = selectedText.isNotEmpty
        ? '[sound:${PronunciationService.getUrl(selectedText, source)}]'
        : '';
    return CardEntryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      word: selectedText,
      example: _buildExample(selectedText, clipboard),
      exampleTranslation: translation,
      pronunciationUrl: pronunciationUrl,
    );
  }
}

/// 单词选中状态 Provider
final wordSelectionProvider =
    NotifierProvider<WordSelectionNotifier, WordSelectionState>(
  WordSelectionNotifier.new,
);
