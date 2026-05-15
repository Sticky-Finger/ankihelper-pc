/// 单词块类型
enum WordTokenType { word, punctuation }

/// 单词块数据模型
class WordTokenModel {
  final String text;
  final int index;
  final WordTokenType type;

  const WordTokenModel({
    required this.text,
    required this.index,
    this.type = WordTokenType.word,
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

  for (final segment in segments) {
    final cleaned = segment.trim();
    if (cleaned.isEmpty) continue;

    // 检查整个 segment 是否全是标点
    if (RegExp(r'^[^\w\s]+$').hasMatch(cleaned)) {
      tokens.add(WordTokenModel(
        text: cleaned,
        index: index++,
        type: WordTokenType.punctuation,
      ));
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
          ));
        }
        // 标点本身
        tokens.add(WordTokenModel(
          text: char,
          index: index++,
          type: WordTokenType.punctuation,
        ));
        start = i + 1;
      }
    }
    // 剩余单词部分
    if (start < cleaned.length) {
      tokens.add(WordTokenModel(
        text: cleaned.substring(start),
        index: index++,
      ));
    }
  }

  return tokens;
}
