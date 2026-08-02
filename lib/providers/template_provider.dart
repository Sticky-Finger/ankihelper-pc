import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_template_model.dart';
import '../services/template_manager.dart';
import 'anki_connect_provider.dart';

/// 卡片模板状态管理
class TemplateNotifier extends Notifier<CardTemplateModel> {
  static const String _selectedTemplateIdKey = 'selected_template_id';
  static const String _importedTemplatesKey = 'imported_templates';

  final List<CardTemplateModel> _templates = [];

  @override
  CardTemplateModel build() {
    // 基础卡片始终在列表中
    _templates.add(CardTemplateModel.basic);
    // 异步初始化：加载内置模板与导入模板，再恢复上次选中的模板
    _initializeTemplates();
    return CardTemplateModel.basic;
  }

  /// 异步初始化模板列表（确保加载顺序：内置模板 → 导入模板 → 恢复选中）
  Future<void> _initializeTemplates() async {
    await _loadBuiltinTemplate();
    await _loadImportedTemplates();
    await _loadSelectedTemplateId();
  }

  /// 从 assets 加载内置模板（纯本地，不碰 Anki）
  Future<void> _loadBuiltinTemplate() async {
    if (_templates.any((t) => t.id.startsWith('builtin_'))) return;

    try {
      final htmlContent = await rootBundle
          .loadString('assets/template01/vocabulary_card_model.html');
      final parsed = TemplateManager.parseHtml(htmlContent);

      final jsonContent = await rootBundle
          .loadString('assets/template01/vocabulary_card_model.json');
      final config = json.decode(jsonContent) as Map<String, dynamic>;

      final template = CardTemplateModel(
        id: 'builtin_vocabulary_card_model',
        name: config['name'] as String,
        fields: parsed.fields,
        fieldMapping: (config['fieldMapping'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        frontHtml: parsed.frontTemplate,
        backHtml: parsed.backTemplate,
        css: parsed.css,
      );

      _templates.add(template);
      state = template;
    } catch (_) {
      // 加载失败静默忽略，不阻塞启动
    }
  }

  /// 从持久化存储加载选中的模板 ID
  Future<void> _loadSelectedTemplateId() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedTemplateIdKey);
    if (selectedId != null) {
      final template = _templates.cast<CardTemplateModel?>().firstWhere(
            (t) => t?.id == selectedId,
            orElse: () => null,
          );
      if (template != null) {
        state = template;
      }
    }
  }

  /// 启动时从持久化存储恢复已导入的模板
  Future<void> _loadImportedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _readImportedTemplateEntries(prefs);
    for (final entry in entries) {
      try {
        final service = ref.read(ankiConnectServiceProvider);
        final id = entry['id'] as String?;
        // 恢复用户保存过的字段映射（覆盖导入时的默认映射）
        final savedMapping =
            id == null ? null : await loadFieldMappingAsync(id);
        final template = await TemplateManager.importFromFile(
          filePath: entry['path'] as String,
          service: service,
          name: entry['name'] as String?,
          templateId: id,
          fieldMapping: savedMapping,
        );
        // 恢复已导入模板；不设置 state，选中交给 _loadSelectedTemplateId
        _templates.insert(0, template);
      } catch (_) {
        // 单条失败静默跳过，不阻塞启动
      }
    }
  }

  /// 读取已导入模板记录列表 [{path, id, name}]
  List<Map<String, dynamic>> _readImportedTemplateEntries(
      SharedPreferences prefs) {
    final raw = prefs.getString(_importedTemplatesKey);
    if (raw == null) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      // 解析失败视为无记录
    }
    return [];
  }

  /// 写入已导入模板记录列表
  Future<void> _writeImportedTemplateEntries(
    SharedPreferences prefs,
    List<Map<String, dynamic>> list,
  ) async {
    await prefs.setString(_importedTemplatesKey, json.encode(list));
  }

  /// 切换模板并持久化
  Future<void> selectTemplate(String id) async {
    final template = _templates.cast<CardTemplateModel?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
    if (template != null) {
      state = template;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedTemplateIdKey, id);
    }
  }

  /// 导入 HTML 模板文件
  Future<CardTemplateModel?> importTemplate(String filePath, {String? name}) async {
    final service = ref.read(ankiConnectServiceProvider);

    // 检查重名
    final defaultName = name ?? filePath.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'\.html$'), '');
    final finalName = _getUniqueTemplateName(defaultName);

    // 如果名称被修改了（因为重名），需要使用新名称
    final actualName = finalName != defaultName ? finalName : null;

    final template = await TemplateManager.importFromFile(
      filePath: filePath,
      service: service,
      name: actualName ?? defaultName,
    );

    // 添加到列表第一位
    _templates.insert(0, template);
    state = template;

    // 持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateIdKey, template.id);

    // 保存导入记录 {path, id, name}，用于重启后恢复
    final list = _readImportedTemplateEntries(prefs);
    if (!list.any((e) => e['id'] == template.id)) {
      list.add({'path': filePath, 'id': template.id, 'name': template.name});
      await _writeImportedTemplateEntries(prefs, list);
    }

    return template;
  }

  /// 获取唯一的模板名称（如果重名则自动添加数字后缀）
  String _getUniqueTemplateName(String baseName) {
    if (!hasTemplateWithName(baseName)) {
      return baseName;
    }

    // 找出已有的同名模板的最大数字后缀
    int maxSuffix = 0;
    for (final template in _templates) {
      final match = RegExp(r'^${RegExp.escape(baseName)}-(\d+)$').firstMatch(template.name);
      if (match != null) {
        final suffix = int.parse(match.group(1)!);
        if (suffix > maxSuffix) {
          maxSuffix = suffix;
        }
      }
    }

    return '$baseName-${maxSuffix + 1}';
  }

  /// 检查是否存在指定名称的模板
  bool hasTemplateWithName(String name) {
    return _templates.any((t) => t.name == name);
  }

  /// 删除模板（内置模板不可删除）
  Future<void> removeTemplate(String templateId) async {
    final template = _templates.cast<CardTemplateModel?>().firstWhere(
          (t) => t?.id == templateId,
          orElse: () => null,
        );
    if (template == null || !template.isDeletable) return;

    _templates.removeWhere((t) => t.id == templateId);

    // 如果删除的是当前选中的模板，切换到基础卡片
    if (state.id == templateId) {
      state = CardTemplateModel.basic;
    } else {
      // 触发 UI 更新
      state = state;
    }

    // 持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateIdKey, state.id);
    // 按 id 从导入记录中移除
    final list = _readImportedTemplateEntries(prefs);
    list.removeWhere((e) => e['id'] == templateId);
    await _writeImportedTemplateEntries(prefs, list);
    // 删除已保存的字段映射
    await prefs.remove('field_mapping_$templateId');
  }

  /// 更新模板名称（用于 Anki 中同名但字段不匹配时自动改名）
  Future<void> updateTemplateName(String templateId, String newName) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;

    _templates[index] = CardTemplateModel(
      id: _templates[index].id,
      name: newName,
      fields: _templates[index].fields,
      fieldMapping: _templates[index].fieldMapping,
      frontHtml: _templates[index].frontHtml,
      backHtml: _templates[index].backHtml,
      css: _templates[index].css,
    );

    // 如果当前选中的就是被改名的模板，同步更新 state
    if (state.id == templateId) {
      state = _templates[index];
    }

    // 持久化
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateIdKey, state.id);
  }

  /// 保存字段映射配置到持久化存储
  Future<void> saveFieldMapping(String templateId, Map<String, String> mapping) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'field_mapping_$templateId';
    await prefs.setString(key, json.encode(mapping));
  }

  /// 更新内存中模板的 fieldMapping（同时持久化）
  Future<void> updateFieldMapping(String templateId, Map<String, String> newMapping) async {
    final index = _templates.indexWhere((t) => t.id == templateId);
    if (index == -1) return;

    _templates[index] = CardTemplateModel(
      id: _templates[index].id,
      name: _templates[index].name,
      fields: _templates[index].fields,
      fieldMapping: newMapping,
      frontHtml: _templates[index].frontHtml,
      backHtml: _templates[index].backHtml,
      css: _templates[index].css,
    );

    if (state.id == templateId) {
      state = _templates[index];
    }

    await saveFieldMapping(templateId, newMapping);
  }

  /// 从持久化存储加载字段映射配置
  /// 返回格式: {模板字段名: 数据源key}
  Future<Map<String, String>?> loadFieldMappingAsync(String templateId) async {
    if (templateId == 'basic') {
      return null; // 基础卡片直接在 CardTemplateModel.basic 中定义
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'field_mapping_$templateId';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return null;
    }
  }

  /// 预设模板列表
  List<CardTemplateModel> get presetTemplates => List.unmodifiable(_templates);
}

/// 卡片模板 Provider
final templateProvider =
    NotifierProvider<TemplateNotifier, CardTemplateModel>(TemplateNotifier.new);
