import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_token_model.dart';

/// 单词选中状态
class WordSelectionState {
  final List<WordTokenModel> tokens;
  final Set<int> selectedIndices;
  final int? lastClickedIndex;

  const WordSelectionState({
    this.tokens = const [],
    this.selectedIndices = const {},
    this.lastClickedIndex,
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
      );
}

/// 单词选中状态 Notifier
class WordSelectionNotifier extends Notifier<WordSelectionState> {
  @override
  WordSelectionState build() => const WordSelectionState();

  /// 设置分词结果
  void setTokens(List<WordTokenModel> tokens) {
    state = WordSelectionState(tokens: tokens);
  }

  /// 处理单击选中
  void selectIndex(int index) {
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: {index},
      lastClickedIndex: index,
    );
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
  }

  /// 清除选中
  void clearSelection() {
    state = WordSelectionState(tokens: state.tokens);
  }
}

/// 单词选中状态 Provider
final wordSelectionProvider =
    NotifierProvider<WordSelectionNotifier, WordSelectionState>(
  WordSelectionNotifier.new,
);
