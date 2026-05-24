import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:ankihelper/models/card_template_model.dart';
import 'package:ankihelper/models/card_entry_model.dart';
import 'anki_connect_service.dart';

/// 模板解析结果
class ParsedTemplate {
  final String frontTemplate;
  final String backTemplate;
  final String css;
  final List<String> fields;

  const ParsedTemplate({
    required this.frontTemplate,
    required this.backTemplate,
    required this.css,
    required this.fields,
  });
}

/// 模板验证结果
class TemplateValidationResult {
  /// 实际用于添加卡片的 Anki 模型名
  final String modelName;

  /// 如果已改名，原名称（否则为 null）
  final String? renamedFrom;

  const TemplateValidationResult({
    required this.modelName,
    this.renamedFrom,
  });

  bool get wasRenamed => renamedFrom != null;
}

/// 模板管理工具类
class TemplateManager {
  TemplateManager._();

  /// 解析 HTML 模板文件（4 段 @@@ 分隔）
  static ParsedTemplate parseHtml(String htmlContent) {
    final parts = htmlContent.split('@@@');
    if (parts.length != 4) {
      throw Exception(
        '模板文件格式错误：需要 4 段 @@@ 分隔（正面/背面/CSS/字段名），实际 ${parts.length} 段',
      );
    }

    final frontTemplate = parts[0].trim();
    final backTemplate = parts[1].trim();
    final css = parts[2].trim();
    final fieldsText = parts[3].trim();

    // 解析字段名列表：按换行分割，过滤空行
    final fields = fieldsText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (fields.isEmpty) {
      throw Exception('模板文件格式错误：第 4 段未找到任何字段名');
    }

    return ParsedTemplate(
      frontTemplate: frontTemplate,
      backTemplate: backTemplate,
      css: css,
      fields: fields,
    );
  }

  /// 从文件路径导入模板并注册到 Anki
  static Future<CardTemplateModel> importFromFile({
    required String filePath,
    required AnkiConnectService service,
    String? name,
    Map<String, String>? fieldMapping,
  }) async {
    final file = File(filePath);
    final htmlContent = await file.readAsString();
    final parsed = parseHtml(htmlContent);

    // 从文件名提取默认名称
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final defaultName = fileName.replaceAll(RegExp(r'\.html$'), '');
    final templateName = name ?? defaultName;

    // 生成唯一 ID
    final id = 'imported_${DateTime.now().millisecondsSinceEpoch}';

    // 构建默认字段映射（如果未提供，使用模板字段名作为 key）
    final mapping = fieldMapping ?? _buildDefaultMapping(parsed.fields);

    // best-effort 注册到 Anki（失败不阻塞导入，添加卡片时会自动补注册）
    try {
      await _registerToAnki(
        service: service,
        name: templateName,
        parsed: parsed,
      );
    } catch (_) {
      // Anki 未打开或连接失败时静默忽略
    }

    return CardTemplateModel(
      id: id,
      name: templateName,
      fields: parsed.fields,
      fieldMapping: mapping,
      frontHtml: parsed.frontTemplate,
      backHtml: parsed.backTemplate,
      css: parsed.css,
    );
  }

  /// 从文件解析模板（不注册到 Anki，用于预览/确认名称）
  static ParsedTemplate parseFile(String filePath) {
    final file = File(filePath);
    final htmlContent = file.readAsStringSync();
    return parseHtml(htmlContent);
  }

  /// 从 assets 加载内置模板
  static Future<CardTemplateModel> loadFromAssets({
    required String basePath,
    required AnkiConnectService service,
    required String name,
    required Map<String, String> fieldMapping,
  }) async {
    final htmlContent = await rootBundle.loadString('$basePath.html');
    final parsed = parseHtml(htmlContent);

    // 注册到 Anki（如果不存在）
    await _registerToAnki(
      service: service,
      name: name,
      parsed: parsed,
    );

    return CardTemplateModel(
      id: 'builtin_${basePath.split('/').last}',
      name: name,
      fields: parsed.fields,
      fieldMapping: fieldMapping,
      frontHtml: parsed.frontTemplate,
      backHtml: parsed.backTemplate,
      css: parsed.css,
    );
  }

  /// 验证 Anki 中模板名称+字段是否匹配，不匹配时自动改名创建
  static Future<TemplateValidationResult> ensureModelFields({
    required AnkiConnectService service,
    required CardTemplateModel template,
  }) async {
    // 基础卡片使用 Anki 内置模型名 "Basic"
    if (template.id == 'basic') {
      return const TemplateValidationResult(modelName: 'Basic');
    }

    final existingModels = await service.getModelNames();

    // 名称不在 Anki 中 → 直接创建
    if (!existingModels.contains(template.name)) {
      await _registerToAnki(
        service: service,
        name: template.name,
        parsed: _templateToParsed(template),
      );
      return TemplateValidationResult(modelName: template.name);
    }

    // 名称已存在 → 检查字段
    final existingFields = await service.getModelFieldNames(template.name);
    if (_fieldListsMatch(existingFields, template.fields)) {
      // 字段匹配 → 直接使用
      return TemplateValidationResult(modelName: template.name);
    }

    // 字段不匹配 → 递增后缀找可用名
    int suffix = 1;
    String newName;
    do {
      newName = '${template.name}-$suffix';
      suffix++;
    } while (existingModels.contains(newName));

    await _registerToAnki(
      service: service,
      name: newName,
      parsed: _templateToParsed(template),
    );
    return TemplateValidationResult(
      modelName: newName,
      renamedFrom: template.name,
    );
  }

  /// 将 CardTemplateModel 转为 ParsedTemplate
  static ParsedTemplate _templateToParsed(CardTemplateModel template) {
    return ParsedTemplate(
      frontTemplate: template.frontHtml,
      backTemplate: template.backHtml,
      css: template.css,
      fields: template.fields,
    );
  }

  /// 比较两个字段列表是否一致（忽略顺序）
  static bool _fieldListsMatch(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  /// 注册模板到 Anki
  static Future<void> _registerToAnki({
    required AnkiConnectService service,
    required String name,
    required ParsedTemplate parsed,
  }) async {
    final existingModels = await service.getModelNames();
    if (existingModels.contains(name)) return;

    await service.createModel(
      name: name,
      css: parsed.css,
      frontTemplate: parsed.frontTemplate,
      backTemplate: parsed.backTemplate,
      fieldNames: parsed.fields,
    );
  }

  /// 中文模板字段名 → 应用字段名（entry.toMap() key）的映射表
  static const Map<String, String> _knownFieldNames = {
    '单词': 'word',
    'word': 'word',
    '音标': 'phonetic',
    'phonetic': 'phonetic',
    '释义': 'meaning',
    'meaning': 'meaning',
    '例句': 'example',
    'example': 'example',
    'exampleTranslation': 'exampleTranslation',
    '例句翻译': 'exampleTranslation',
  };

  /// 构建默认字段映射（尝试识别中文/英文字段名，未识别字段默认为空）
  ///
  /// 格式: {模板字段名: 数据源key}
  /// 第一个匹配到的字段映射到 'word'，其余已知字段映射到对应数据源，未知字段映射到 ''(空)
  static Map<String, String> _buildDefaultMapping(List<String> fields) {
    final mapping = <String, String>{};
    bool firstMatched = false;
    for (final field in fields) {
      final knownKey = _knownFieldNames[field];
      if (knownKey != null) {
        if (!firstMatched && knownKey == 'word') {
          // 第一个匹配到 word 的字段映射到单词数据源
          mapping[field] = 'word';
          firstMatched = true;
        } else {
          mapping[field] = knownKey;
        }
      } else {
        // 未知字段（如 'url'、'发音'）不加入默认映射
        // 用户在 buildFields 中会得到空字符串
      }
    }
    return mapping;
  }

  /// 根据模板配置将卡片条目转换为 Anki 字段映射
  ///
  /// fieldMapping 格式: {模板字段名: 数据源key}
  /// 数据源key: 'word'/'example'/'exampleTranslation'/''(空)
  /// 遍历模板所有字段，按字段映射填充值。未映射的字段填空字符串。
  static Map<String, String> buildFields(
    CardTemplateModel template,
    CardEntryModel entry,
  ) {
    final Map<String, String> result = {};
    final entryMap = entry.toMap();

    // 遍历所有模板字段
    for (final field in template.fields) {
      final dataSource = template.fieldMapping[field];
      if (dataSource == null || dataSource.isEmpty) {
        // 未映射或映射到'空' → 空字符串
        result[field] = '';
      } else {
        final value = entryMap[dataSource];
        result[field] = (value != null && value.isNotEmpty) ? value : '';
      }
    }

    return result;
  }
}
