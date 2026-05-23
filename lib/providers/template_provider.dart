import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_template_model.dart';

/// 卡片模板状态管理
class TemplateNotifier extends Notifier<CardTemplateModel> {
  static const String _selectedTemplateIdKey = 'selected_template_id';

  @override
  CardTemplateModel build() {
    // 从持久化存储加载选中的模板 ID，默认使用 vocabulary 模板
    _loadSelectedTemplateId();
    return CardTemplateModel.vocabulary;
  }

  /// 从持久化存储加载选中的模板 ID
  Future<void> _loadSelectedTemplateId() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString(_selectedTemplateIdKey);
    if (selectedId != null) {
      final template = presetTemplates.cast<CardTemplateModel?>().firstWhere(
            (t) => t?.id == selectedId,
            orElse: () => null,
          );
      state = template ?? CardTemplateModel.vocabulary;
    }
  }

  /// 切换模板并持久化
  Future<void> selectTemplate(String id) async {
    final template = presetTemplates.cast<CardTemplateModel?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
    state = template ?? CardTemplateModel.vocabulary;

    // 持久化到 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedTemplateIdKey, id);
  }

  /// 预设模板列表
  List<CardTemplateModel> get presetTemplates => [
        CardTemplateModel.vocabulary,
        CardTemplateModel.basic,
      ];
}

/// 卡片模板 Provider
final templateProvider =
    NotifierProvider<TemplateNotifier, CardTemplateModel>(TemplateNotifier.new);
