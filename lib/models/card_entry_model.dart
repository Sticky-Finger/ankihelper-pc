/// 卡片条目数据模型
class CardEntryModel {
  final String id;
  final String word;
  final String phonetic;
  final String pos;
  final String meaning;
  final String example;

  const CardEntryModel({
    required this.id,
    required this.word,
    this.phonetic = '',
    this.pos = '',
    this.meaning = '',
    this.example = '',
  });

  /// 是否为占位空条目
  bool get isEmpty => word.isEmpty;
}
