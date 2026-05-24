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

  /// 确保模板模型在 Anki 中存在
  static Future<void> ensureModelExists(
    AnkiConnectService service,
    CardTemplateModel template,
  ) async {
    // 基础卡片模板是 Anki 自带的，跳过注册
    if (template.id == 'basic') return;

    final existingModels = await service.getModelNames();
    if (existingModels.contains(template.name)) return;

    // 从 assets 读取模板 HTML
    final htmlContent = await rootBundle.loadString(
      'assets/template01/vocabulary_card_model.html',
    );
    final parsed = parseHtml(htmlContent);

    await _registerToAnki(
      service: service,
      name: template.name,
      parsed: parsed,
    );
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

  /// 构建默认字段映射（模板字段名 → 模板字段名）
  static Map<String, String> _buildDefaultMapping(List<String> fields) {
    final mapping = <String, String>{};
    for (final field in fields) {
      mapping[field] = field;
    }
    return mapping;
  }

  /// 根据模板配置将卡片条目转换为 Anki 字段映射
  static Map<String, String> buildFields(
    CardTemplateModel template,
    CardEntryModel entry,
  ) {
    final Map<String, String> result = {};
    final entryMap = entry.toMap();

    template.fieldMapping.forEach((appField, templateField) {
      final value = entryMap[appField];
      if (value != null && value.isNotEmpty) {
        result[templateField] = value;
      }
    });

    return result;
  }
}
