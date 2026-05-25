/// 卡片条目数据模型
class CardEntryModel {
  final String id;
  final String word;
  final String phonetic;
  final String pos;
  final String meaning;
  final String example;
  final String exampleTranslation;
  final String pronunciationUrl;

  const CardEntryModel({
    required this.id,
    required this.word,
    this.phonetic = '',
    this.pos = '',
    this.meaning = '',
    this.example = '',
    this.exampleTranslation = '',
    this.pronunciationUrl = '',
  });

  /// 是否为占位空条目
  bool get isEmpty => word.isEmpty;

  /// 转换为 Map，用于动态字段映射
  Map<String, String> toMap() => {
    'word': word,
    'phonetic': phonetic,
    'meaning': meaning,
    'example': example,
    'exampleTranslation': exampleTranslation,
    'pronunciationUrl': pronunciationUrl,
  };
}
