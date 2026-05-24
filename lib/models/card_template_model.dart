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

  /// 是否可删除（内置模板不可删除）
  bool get isDeletable => id != 'basic' && !id.startsWith('builtin_');

  /// 基础卡片模板（Anki 自带）
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
