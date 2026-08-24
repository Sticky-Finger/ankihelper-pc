/// 词典查询来源
enum DictionarySource { bing, youdao, ai }

extension DictionarySourceLabel on DictionarySource {
  /// 展示名（词典标签 / 错误信息用）
  String get label => switch (this) {
        DictionarySource.bing => '必应词典',
        DictionarySource.youdao => '有道词典',
        DictionarySource.ai => 'AI 词典',
      };
}

/// 词性 + 释义（一个义项）
class DictSense {
  final String pos;
  final String def;

  const DictSense({this.pos = '', this.def = ''});

  factory DictSense.fromJson(Map<String, dynamic> json) => DictSense(
        pos: (json['pos'] ?? '').toString(),
        def: (json['def'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'pos': pos, 'def': def};
}

/// 双语例句
class DictSentence {
  final String eng;
  final String chs;

  const DictSentence({this.eng = '', this.chs = ''});

  factory DictSentence.fromJson(Map<String, dynamic> json) => DictSentence(
        eng: (json['eng'] ?? '').toString(),
        chs: (json['chs'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'eng': eng, 'chs': chs};
}

/// 词典查询结构化结果
///
/// 传统词典（Bing/有道）填充 word/音标/senses/sentences/inflections，
/// AI 词典填充 aiMarkdown（Markdown 词典卡片）。
class DictionaryResult {
  final DictionarySource source;

  /// 词条原型（词形还原结果，如查 "went" 返回 "go"）
  final String word;

  /// 英式音标（不含方括号）
  final String ukPhonetic;

  /// 美式音标（不含方括号）
  final String usPhonetic;

  /// 词性 + 释义列表
  final List<DictSense> senses;

  /// 双语例句列表
  final List<DictSentence> sentences;

  /// 时态变形（如 "复数: libraries"）
  final List<String> inflections;

  /// AI 词典输出的 Markdown 全文
  final String aiMarkdown;

  /// 错误信息（查询失败时非空）
  final String errorMessage;

  /// 是否为"词典未收录"（区别于网络/解析失败）
  final bool notFound;

  const DictionaryResult({
    this.source = DictionarySource.bing,
    this.word = '',
    this.ukPhonetic = '',
    this.usPhonetic = '',
    this.senses = const [],
    this.sentences = const [],
    this.inflections = const [],
    this.aiMarkdown = '',
    this.errorMessage = '',
    this.notFound = false,
  });

  /// 查询是否成功（无错误且拿到了词条或 AI 结果）
  bool get isSuccess =>
      errorMessage.isEmpty && (word.isNotEmpty || aiMarkdown.isNotEmpty);

  /// 是否来自 AI 词典
  bool get isAi => source == DictionarySource.ai;

  /// 合并展示的音标："英 [x] 美 [y]"
  String get mergedPhonetic {
    final parts = <String>[];
    if (ukPhonetic.isNotEmpty) parts.add('英 [$ukPhonetic]');
    if (usPhonetic.isNotEmpty) parts.add('美 [$usPhonetic]');
    return parts.join(' ');
  }

  /// 失败结果
  static DictionaryResult failure(
    String message, {
    bool notFound = false,
    DictionarySource source = DictionarySource.bing,
  }) =>
      DictionaryResult(
        source: source,
        errorMessage: message,
        notFound: notFound,
      );

  Map<String, dynamic> toJson() => {
        'source': source.name,
        'word': word,
        'ukPhonetic': ukPhonetic,
        'usPhonetic': usPhonetic,
        'senses': senses.map((s) => s.toJson()).toList(),
        'sentences': sentences.map((s) => s.toJson()).toList(),
        'inflections': inflections,
        'aiMarkdown': aiMarkdown,
        'errorMessage': errorMessage,
        'notFound': notFound,
      };

  factory DictionaryResult.fromJson(Map<String, dynamic> json) {
    DictionarySource parseSource(String? value) {
      switch (value) {
        case 'youdao':
          return DictionarySource.youdao;
        case 'ai':
          return DictionarySource.ai;
        default:
          return DictionarySource.bing;
      }
    }

    return DictionaryResult(
      source: parseSource(json['source'] as String?),
      word: (json['word'] ?? '').toString(),
      ukPhonetic: (json['ukPhonetic'] ?? '').toString(),
      usPhonetic: (json['usPhonetic'] ?? '').toString(),
      senses: (json['senses'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DictSense.fromJson)
          .toList(),
      sentences: (json['sentences'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DictSentence.fromJson)
          .toList(),
      inflections: (json['inflections'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      aiMarkdown: (json['aiMarkdown'] ?? '').toString(),
      errorMessage: (json['errorMessage'] ?? '').toString(),
      notFound: json['notFound'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'DictionaryResult(${source.name}, success: $isSuccess, '
      'word: "$word", senses: ${senses.length}, error: "$errorMessage")';
}
