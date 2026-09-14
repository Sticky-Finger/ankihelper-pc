import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_entry_model.dart';
import '../models/dictionary_result_model.dart';
import '../models/word_token_model.dart';
import '../services/pronunciation_service.dart';
import 'clipboard_provider.dart';
import 'dictionary_provider.dart';
import 'pronunciation_provider.dart';
import 'translation_provider.dart';

/// 单词选中状态
class WordSelectionState {
  final List<WordTokenModel> tokens;
  final Set<int> selectedIndices;
  final int? lastClickedIndex;

  /// 查询词：选中变化时自动初始化为选中原文，可由用户编辑（如改为原型）。
  /// 词典查询、卡片 word 字段与发音 URL 均以此为准。
  final String queryWord;

  final CardEntryModel? currentEntry;

  /// 词典义项条目（查询成功时与手动空条目并列展示）
  final List<CardEntryModel> senseEntries;

  const WordSelectionState({
    this.tokens = const [],
    this.selectedIndices = const {},
    this.lastClickedIndex,
    this.queryWord = '',
    this.currentEntry,
    this.senseEntries = const [],
  });

  /// 当前选中的文本（跳过标点）
  String get selectedText =>
      WordSelectionState.textFromIndices(tokens, selectedIndices);

  /// 按选中索引拼接词组文本（跳过标点）
  static String textFromIndices(
    List<WordTokenModel> tokens,
    Set<int> indices,
  ) {
    if (indices.isEmpty) return '';
    final sorted = SplayTreeSet<int>.from(indices);
    final words = <String>[];
    for (final i in sorted) {
      if (i < tokens.length && !tokens[i].isPunctuation) {
        words.add(tokens[i].text);
      }
    }
    return words.join(' ');
  }

  /// currentEntry / senseEntries 不通过 copyWith 传递，由 Notifier 直接赋值

  WordSelectionState copyWith({
    List<WordTokenModel>? tokens,
    Set<int>? selectedIndices,
    int? lastClickedIndex,
    bool clearLastClicked = false,
    String? queryWord,
  }) =>
      WordSelectionState(
        tokens: tokens ?? this.tokens,
        selectedIndices: selectedIndices ?? this.selectedIndices,
        lastClickedIndex:
            clearLastClicked ? null : (lastClickedIndex ?? this.lastClickedIndex),
        queryWord: queryWord ?? this.queryWord,
        currentEntry: currentEntry,
        senseEntries: senseEntries,
      );
}

/// 单词选中状态 Notifier
class WordSelectionNotifier extends Notifier<WordSelectionState> {
  Timer? _debounceTimer;

  /// 编辑查询词的防抖定时器（与选中防抖互斥）
  Timer? _editDebounceTimer;

  /// 是否存在未提交的编辑（commitQueryWord 只在有编辑时触发查询）
  bool _hasPendingEdit = false;

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
    // 监听词典结果 → 重算条目（义项条目 + AI 释义，含流式增量）
    ref.listen(dictionaryProvider, (prev, next) {
      _recomputeEntry();
    });
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _editDebounceTimer?.cancel();
    });
    return const WordSelectionState();
  }

  /// 设置分词结果
  void setTokens(List<WordTokenModel> tokens) {
    state = WordSelectionState(tokens: tokens);
    _debouncedRecompute();
  }

  /// 处理单击选中
  void selectIndex(int index) {
    _applySelection({index}, index);
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
    _applySelection(indices, last);
  }

  /// 处理 Cmd/Ctrl+单击（切换选中）
  void toggleIndex(int index) {
    final indices = Set<int>.from(state.selectedIndices);
    if (indices.contains(index)) {
      indices.remove(index);
    } else {
      indices.add(index);
    }
    _applySelection(indices, index);
  }

  /// 清除选中
  void clearSelection() {
    _applySelection(const <int>{}, null);
  }

  /// 应用新选中集：queryWord 重置为选中原文，覆盖此前的编辑
  void _applySelection(Set<int> indices, int? lastClickedIndex) {
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: indices,
      lastClickedIndex: lastClickedIndex,
      queryWord: WordSelectionState.textFromIndices(state.tokens, indices),
    );
    _debouncedRecompute();
  }

  /// 用户编辑查询词：立即更新状态（旧条目清除），300ms 防抖后重查（合并连续按键）
  void updateQueryWord(String text) {
    final trimmed = text.trim();
    if (trimmed == state.queryWord) return;
    _debounceTimer?.cancel();
    _editDebounceTimer?.cancel();
    _hasPendingEdit = true;
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: state.selectedIndices,
      lastClickedIndex: state.lastClickedIndex,
      queryWord: trimmed,
    );
    _editDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _hasPendingEdit = false;
      _recomputeEntry();
      _triggerDictionaryQuery();
    });
  }

  /// 立即提交查询词（输入栏失焦 / 回车时调用）
  void commitQueryWord() {
    if (!_hasPendingEdit) return;
    _hasPendingEdit = false;
    _editDebounceTimer?.cancel();
    _debounceTimer?.cancel();
    _recomputeEntry();
    _triggerDictionaryQuery();
  }

  /// 选中变化后 300ms 防抖重算 currentEntry 并触发词典查询
  void _debouncedRecompute() {
    _editDebounceTimer?.cancel();
    _hasPendingEdit = false;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _recomputeEntry();
      _triggerDictionaryQuery();
    });
  }

  /// 立即重算 currentEntry（剪贴板/翻译/词典结果变化时调用）
  void _recomputeEntry() {
    _debounceTimer?.cancel();
    final queryWord = state.queryWord;
    final clipboard = ref.read(clipboardProvider).originalText;
    final translation = ref.read(translationProvider).translatedText;
    final dictState = ref.read(dictionaryProvider);

    // 竞态守卫：词典结果只对当前查询词生效
    var senseEntries = const <CardEntryModel>[];
    var aiMarkdown = '';
    if (queryWord.isNotEmpty && dictState.queriedWord == queryWord) {
      if (dictState.status == DictQueryStatus.done) {
        final result = dictState.result;
        if (result != null && !result.isAi) {
          senseEntries = result.senses
              .where((sense) => sense.def.isNotEmpty)
              .map((sense) => _buildSenseEntry(
                    queryWord,
                    clipboard,
                    translation,
                    result,
                    sense,
                  ))
              .toList();
        }
        aiMarkdown = dictState.aiMarkdown;
      } else if (dictState.status == DictQueryStatus.aiStreaming) {
        aiMarkdown = dictState.aiMarkdown;
      }
    }

    final entry = _buildEntry(queryWord, clipboard, translation, aiMarkdown);
    // 直接构造新 state，保留 currentEntry
    state = WordSelectionState(
      tokens: state.tokens,
      selectedIndices: state.selectedIndices,
      lastClickedIndex: state.lastClickedIndex,
      queryWord: state.queryWord,
      currentEntry: entry,
      senseEntries: senseEntries,
    );
  }

  /// 触发词典查询（查询词非空时；词组由服务内部路由到 AI 词典）
  void _triggerDictionaryQuery() {
    final queryWord = state.queryWord;
    if (queryWord.isEmpty) {
      ref.read(dictionaryProvider.notifier).clear();
      return;
    }
    ref.read(dictionaryProvider.notifier).query(queryWord);
  }

  /// 构建 example 字段：按选中位置精确高亮（与查询词无关，编辑不改高亮）
  String _buildExample(String clipboard) {
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

  /// 构建发音字段（Anki [sound:] 格式）
  String _buildPronunciationUrl(String queryWord) {
    if (queryWord.isEmpty) return '';
    final source = ref.read(pronunciationProvider).selectedSource;
    return '[sound:${PronunciationService.getUrl(queryWord, source)}]';
  }

  /// 构建 currentEntry（手动空条目，AI 释义附加于此供字段映射）
  CardEntryModel _buildEntry(
    String queryWord,
    String clipboard,
    String translation,
    String aiMarkdown,
  ) {
    return CardEntryModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      word: queryWord,
      example: _buildExample(clipboard),
      exampleTranslation: translation,
      pronunciationUrl: _buildPronunciationUrl(queryWord),
      aiDictMarkdown: aiMarkdown,
    );
  }

  /// 构建词典义项条目（word 用查询词：选中原文或用户编辑后的原型）
  CardEntryModel _buildSenseEntry(
    String queryWord,
    String clipboard,
    String translation,
    DictionaryResult result,
    DictSense sense,
  ) {
    return CardEntryModel(
      id: 'sense_${result.word}_${sense.pos}_${sense.def.hashCode}',
      word: queryWord,
      phonetic: result.mergedPhonetic,
      pos: sense.pos,
      meaning: sense.def,
      example: _buildExample(clipboard),
      exampleTranslation: translation,
      pronunciationUrl: _buildPronunciationUrl(queryWord),
    );
  }
}

/// 单词选中状态 Provider
final wordSelectionProvider =
    NotifierProvider<WordSelectionNotifier, WordSelectionState>(
  WordSelectionNotifier.new,
);
