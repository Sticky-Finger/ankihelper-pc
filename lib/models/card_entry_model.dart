import 'package:markdown/markdown.dart';

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

  /// AI 词典输出的 Markdown 全文（作为「AI 释义」数据源）
  ///
  /// 存原始 Markdown；toMap 时转 HTML 供预览与 Anki 字段使用。
  final String aiDictMarkdown;

  const CardEntryModel({
    required this.id,
    required this.word,
    this.phonetic = '',
    this.pos = '',
    this.meaning = '',
    this.example = '',
    this.exampleTranslation = '',
    this.pronunciationUrl = '',
    this.aiDictMarkdown = '',
  });

  /// 是否为占位空条目
  bool get isEmpty => word.isEmpty;

  /// 卡片「释义」数据源：词性并入释义（如 `v. donate...`）
  ///
  /// - pos 或 meaning 任一为空 → 原样返回（手动空条目不受影响）
  /// - meaning 已以 "$pos " 开头 → 原样返回（防重复：个别词典释义文本自带词性）
  String get cardMeaning {
    if (pos.isEmpty || meaning.isEmpty) return meaning;
    if (meaning.startsWith('$pos ')) return meaning;
    return '$pos $meaning';
  }

  /// 转换为 Map，用于动态字段映射
  Map<String, String> toMap() => {
        'word': word,
        'phonetic': phonetic,
        'meaning': cardMeaning,
        'example': example,
        'exampleTranslation': exampleTranslation,
        'pronunciationUrl': pronunciationUrl,
        'aiDictMarkdown':
            aiDictMarkdown.isEmpty ? '' : markdownToHtml(aiDictMarkdown),
      };
}
