import 'package:flutter/services.dart' show rootBundle;
import 'package:ankihelper/models/card_template_model.dart';
import 'package:ankihelper/models/card_entry_model.dart';
import 'anki_connect_service.dart';

/// 模板管理工具类
class TemplateManager {
  // 私有构造函数，防止实例化
  TemplateManager._();

  /// 确保模板模型在 Anki 中存在
  ///
  /// 对于非 Anki 自带模板，从 assets 读取 HTML 模板文件并注册到 Anki
  static Future<void> ensureModelExists(
    AnkiConnectService service,
    CardTemplateModel template,
  ) async {
    // 基础卡片模板是 Anki 自带的，跳过注册
    if (template.id == 'basic') {
      return;
    }

    // 检查模型是否已存在
    final existingModels = await service.getModelNames();
    if (existingModels.contains(template.name)) {
      return;
    }

    // 从 assets 读取模板 HTML
    final htmlContent = await rootBundle.loadString(
      'assets/template01/vocabulary_card_model.html',
    );

    // 按 @@@ 分割为 front/back/css 三段
    final parts = htmlContent.split('@@@');
    if (parts.length != 3) {
      throw Exception(
        '模板文件格式错误：未找到完整的 @@@ 分隔符（需要 front、back、css 三段）',
      );
    }

    final frontTemplate = parts[0].trim();
    final backTemplate = parts[1].trim();
    final css = parts[2].trim();

    // 调用 AnkiConnect API 创建模型
    await service.createModel(
      name: template.name,
      css: css,
      frontTemplate: frontTemplate,
      backTemplate: backTemplate,
      fieldNames: template.fields,
    );
  }

  /// 根据模板配置将卡片条目转换为 Anki 字段映射
  ///
  /// [template] 模板配置，包含字段映射规则
  /// [entry] 卡片条目数据
  ///
  /// 返回模板字段名到字段值的映射（仅包含非空字段）
  static Map<String, String> buildFields(
    CardTemplateModel template,
    CardEntryModel entry,
  ) {
    final Map<String, String> result = {};

    // 遍历映射配置，转换非空字段
    template.fieldMapping.forEach((appField, templateField) {
      // 获取条目中对应字段的值
      String? value;
      switch (appField) {
        case 'word':
          value = entry.word;
          break;
        case 'phonetic':
          value = entry.phonetic;
          break;
        case 'meaning':
          value = entry.meaning;
          break;
        case 'example':
          value = entry.example;
          break;
        // Task 3 会添加 exampleTranslation 支持
        // case 'exampleTranslation':
        //   value = entry.exampleTranslation;
        //   break;
        default:
          // 忽略未知字段
          return;
      }

      // 仅添加非空字段
      if (value.isNotEmpty) {
        result[templateField] = value;
      }
    });

    return result;
  }
}
