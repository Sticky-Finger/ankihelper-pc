/// 卡片模板数据模型
class CardTemplateModel {
  /// 模板唯一标识
  final String id;

  /// 模板显示名称
  final String name;

  /// 模板字段名称列表
  final List<String> fields;

  /// 应用字段到模板字段的映射（应用字段名 → 模板字段名）
  final Map<String, String> fieldMapping;

  const CardTemplateModel({
    required this.id,
    required this.name,
    required this.fields,
    required this.fieldMapping,
  });

  /// 词汇卡片模板预设
  static const CardTemplateModel vocabulary = CardTemplateModel(
    id: 'vocabulary',
    name: '词汇卡片',
    fields: ['单词', '音标', '发音', '例句', '释义', '例句翻译', 'url'],
    fieldMapping: {
      'word': '单词',
      'phonetic': '音标',
      'meaning': '释义',
      'example': '例句',
      'exampleTranslation': '例句翻译',
    },
  );

  /// 基础卡片模板预设（Anki 自带）
  static const CardTemplateModel basic = CardTemplateModel(
    id: 'basic',
    name: '基础卡片',
    fields: ['Front', 'Back'],
    fieldMapping: {
      'word': 'Front',
      'meaning': 'Back',
    },
  );
}
