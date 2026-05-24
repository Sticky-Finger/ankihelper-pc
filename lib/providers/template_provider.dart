import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_template_model.dart';
import '../services/template_manager.dart';
import 'anki_connect_provider.dart';

/// 卡片模板状态管理
class TemplateNotifier extends Notifier<CardTemplateModel> {
  static const String _selectedTemplateIdKey = 'selected_template_id';
  static const String _importedTemplatesKey = 'imported_template_paths';

  final List<CardTemplateModel> _templates = [];

  @override
  CardTemplateModel build() {
    // 基础卡片始终在列表中
    _templates.add(CardTemplateModel.basic);
    // 从持久化存储恢复选中的模板
    _loadSelectedTemplateId();
    return CardTemplateModel.basic;
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

    // 保存导入的文件路径
    final paths = prefs.getStringList(_importedTemplatesKey) ?? [];
    if (!paths.contains(filePath)) {
      paths.add(filePath);
      await prefs.setStringList(_importedTemplatesKey, paths);
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

  /// 预设模板列表
  List<CardTemplateModel> get presetTemplates => List.unmodifiable(_templates);
}

/// 卡片模板 Provider
final templateProvider =
    NotifierProvider<TemplateNotifier, CardTemplateModel>(TemplateNotifier.new);
