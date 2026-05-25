/// 单词块类型
enum WordTokenType { word, punctuation }

/// 单词块数据模型
class WordTokenModel {
  final String text;
  final int index;
  final WordTokenType type;

  /// 在原始文本中的起始位置（用于精确高亮）
  final int originalStart;

  const WordTokenModel({
    required this.text,
    required this.index,
    this.type = WordTokenType.word,
    this.originalStart = 0,
  });

  bool get isPunctuation => type == WordTokenType.punctuation;
}

/// 将句子分词为 [WordTokenModel] 列表
///
/// 按空白字符分割，标点符号单独成块（类型为 [WordTokenType.punctuation]）。
List<WordTokenModel> tokenize(String text) {
  if (text.trim().isEmpty) return [];

  final tokens = <WordTokenModel>[];
  final segments = text.split(RegExp(r'(\s+)'));
  int index = 0;
  int globalPos = 0;

  for (final segment in segments) {
    final cleaned = segment.trim();
    if (cleaned.isEmpty) {
      globalPos += segment.length;
      continue;
    }

    // 检查整个 segment 是否全是标点
    if (RegExp(r'^[^\w\s]+$').hasMatch(cleaned)) {
      tokens.add(WordTokenModel(
        text: cleaned,
        index: index++,
        type: WordTokenType.punctuation,
        originalStart: globalPos,
      ));
      globalPos += segment.length;
      continue;
    }

    // 混合内容：将单词和标点拆开
    int start = 0;
    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      if (RegExp(r'[^\w]').hasMatch(char)) {
        // 标点前的单词部分
        if (i > start) {
          tokens.add(WordTokenModel(
            text: cleaned.substring(start, i),
            index: index++,
            originalStart: globalPos + start,
          ));
        }
        // 标点本身
        tokens.add(WordTokenModel(
          text: char,
          index: index++,
          type: WordTokenType.punctuation,
          originalStart: globalPos + i,
        ));
        start = i + 1;
      }
    }
    // 剩余单词部分
    if (start < cleaned.length) {
      tokens.add(WordTokenModel(
        text: cleaned.substring(start),
        index: index++,
        originalStart: globalPos + start,
      ));
    }

    globalPos += segment.length;
  }

  return tokens;
}
