import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dict_settings_model.dart';
import '../models/translation_config_model.dart';
import '../providers/dict_settings_provider.dart';
import '../providers/template_provider.dart';
import '../providers/translation_provider.dart';
import '../services/dict/dict_cache.dart';
import 'field_mapping_editor.dart';

/// 显示设置弹窗
void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late TranslationConfig _config;
  late AiDictConfig _aiConfig;

  @override
  void initState() {
    super.initState();
    _config = ref.read(translationProvider.notifier).config;
    _aiConfig = ref.read(dictSettingsProvider).aiConfig;
  }

  void _onPreferredSourceChanged(DictSourcePreference? value) {
    if (value != null) {
      ref.read(dictSettingsProvider.notifier).setPreferredSource(value);
    }
  }

  void _onAiConfigChanged(AiDictConfig config) {
    setState(() => _aiConfig = config);
    ref.read(dictSettingsProvider.notifier).updateAiConfig(config);
  }

  void _onProviderChanged(TranslationProvider? value) {
    if (value != null) {
      setState(() => _config = _config.copyWith(provider: value));
    }
  }

  void _onAppIdChanged(String value) {
    setState(() => _config = _config.copyWith(appId: value));
  }

  void _onAppSecretChanged(String value) {
    setState(() => _config = _config.copyWith(appSecret: value));
  }

  void _onSave() {
    ref.read(translationProvider.notifier).saveConfig(_config);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译配置已保存')),
    );
  }

  /// 显示模板名称确认对话框
  Future<String?> _showTemplateNameDialog({
    required BuildContext context,
    required String defaultName,
    required bool hasDuplicate,
  }) async {
    final controller = TextEditingController(text: defaultName);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // 检查当前名称是否与已有模板重名
          final currentName = controller.text.trim();
          final isDuplicate = ref.read(templateProvider.notifier).hasTemplateWithName(currentName);

          return AlertDialog(
            title: Text(hasDuplicate ? '模板名称冲突' : '确认模板名称'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDuplicate)
                  const Text(
                    '已存在同名模板，请修改模板名称：',
                    style: TextStyle(color: Colors.orange),
                  )
                else
                  const Text('请输入模板名称：'),
                const SizedBox(height: 12),
                Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: '模板名称',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: isDuplicate ? '该模板名称已存在' : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '模板名称不能为空';
                      }
                      return null;
                    },
                    onChanged: (_) {
                      // 触发重新构建以更新按钮状态
                      setState(() {});
                    },
                    autofocus: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: isDuplicate
                    ? null
                    : () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(ctx).pop(controller.text.trim());
                        }
                      },
                child: const Text('确认导入'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ====== 词典管理 ======
            const Text(
              '词典管理',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '词典使用免费网页接口（必应/有道），无需 API Key；'
              'AI 词典为可选兜底，词组查询需配置。',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final dictSettings = ref.watch(dictSettingsProvider);

                return DropdownButtonFormField<DictSourcePreference>(
                  initialValue: dictSettings.preferredSource,
                  decoration: const InputDecoration(
                    labelText: '词典源',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: DictSourcePreference.values
                      .map((source) => DropdownMenuItem(
                            value: source,
                            child: Text(source.label),
                          ))
                      .toList(),
                  onChanged: _onPreferredSourceChanged,
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'AI 词典（OpenAI 兼容接口，可选）',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _aiConfig.baseUrl,
              decoration: const InputDecoration(
                labelText: '接口地址（如 https://api.deepseek.com）',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) =>
                  _onAiConfigChanged(_aiConfig.copyWith(baseUrl: value)),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _aiConfig.apiKey,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              obscureText: true,
              onChanged: (value) =>
                  _onAiConfigChanged(_aiConfig.copyWith(apiKey: value)),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _aiConfig.model,
              decoration: const InputDecoration(
                labelText: '模型（如 deepseek-chat）',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) =>
                  _onAiConfigChanged(_aiConfig.copyWith(model: value)),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await DictCache.shared.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('词典缓存已清除')),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('清除词典缓存'),
              ),
            ),
            const SizedBox(height: 16),
            // ====== 卡片模板 ======
            const Text(
              '卡片模板',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final currentTemplate = ref.watch(templateProvider);
                final notifier = ref.read(templateProvider.notifier);

                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: currentTemplate.id,
                        decoration: const InputDecoration(
                          labelText: '选择模板',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: notifier.presetTemplates
                            .map(
                              (template) => DropdownMenuItem(
                                value: template.id,
                                child: Text(template.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(templateProvider.notifier)
                                .selectTemplate(value);
                          }
                        },
                      ),
                    ),
                    if (currentTemplate.isDeletable) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: '删除模板',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text(
                                  '确定要删除模板"${currentTemplate.name}"吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await ref
                                .read(templateProvider.notifier)
                                .removeTemplate(currentTemplate.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('模板已删除')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // 导入模板按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (kDebugMode) {
                    debugPrint('[ImportTemplate] 按钮点击');
                  }
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['html'],
                      dialogTitle: '选择 HTML 模板文件',
                    );
                    if (kDebugMode) {
                      debugPrint('[ImportTemplate] 文件选择结果: $result');
                    }
                    if (result == null) {
                      if (kDebugMode) {
                        debugPrint('[ImportTemplate] 用户取消了文件选择');
                      }
                      return;
                    }
                    if (result.files.single.path != null) {
                      final filePath = result.files.single.path!;
                      if (kDebugMode) {
                        debugPrint('[ImportTemplate] 选择文件: $filePath');
                      }

                      // 提取默认模板名
                      final fileName = filePath.split(RegExp(r'[/\\]')).last;
                      final defaultName = fileName.replaceAll(RegExp(r'\.html$'), '');

                      // 检查是否已存在同名模板，如果有则生成建议名称
                      final notifier = ref.read(templateProvider.notifier);
                      bool hasDuplicate = notifier.hasTemplateWithName(defaultName);
                      String suggestedName = defaultName;
                      if (hasDuplicate) {
                        int maxSuffix = notifier.presetTemplates
                            .where((t) => t.name.startsWith('$defaultName-'))
                            .fold<int>(0, (max, t) {
                              final match = RegExp(r'-(\d+)$').firstMatch(t.name);
                              if (match != null) {
                                final num = int.parse(match.group(1)!);
                                return num > max ? num : max;
                              }
                              return max;
                            });
                        suggestedName = '$defaultName-${maxSuffix + 1}';
                      }

                      // 显示模板名称确认对话框
                      if (context.mounted) {
                        final confirmedName = await _showTemplateNameDialog(
                          context: context,
                          defaultName: suggestedName,
                          hasDuplicate: hasDuplicate,
                        );
                        if (confirmedName == null) {
                          if (kDebugMode) {
                            debugPrint('[ImportTemplate] 用户取消了名称确认');
                          }
                          return;
                        }

                        await ref.read(templateProvider.notifier).importTemplate(
                          filePath,
                          name: confirmedName,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('模板导入成功')),
                          );
                        }
                      }
                    }
                  } catch (e, stackTrace) {
                    if (kDebugMode) {
                      debugPrint('[ImportTemplate] 异常: $e');
                      debugPrint('[ImportTemplate] 堆栈: $stackTrace');
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('导入失败: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.file_upload_outlined, size: 18),
                label: const Text('导入 HTML 模板'),
              ),
            ),
            const SizedBox(height: 8),
            // 字段映射编辑器
            Consumer(
              builder: (context, ref, _) {
                final currentTemplate = ref.watch(templateProvider);

                return FieldMappingEditor(
                  templateFields: currentTemplate.fields,
                  initialMapping: currentTemplate.fieldMapping,
                  onChanged: (newMapping) {
                    // 修改 Select 时自动保存，用户无需额外操作
                    ref
                        .read(templateProvider.notifier)
                        .updateFieldMapping(currentTemplate.id, newMapping);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // ====== 翻译 API 配置 ======
            const Text(
              '翻译 API 配置',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // 服务商选择
            DropdownButtonFormField<TranslationProvider>(
              initialValue: _config.provider,
              decoration: const InputDecoration(
                labelText: '翻译服务商',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: TranslationProvider.baidu,
                  child: Text('百度翻译'),
                ),
                DropdownMenuItem(
                  value: TranslationProvider.youdao,
                  child: Text('有道智云'),
                ),
              ],
              onChanged: _onProviderChanged,
            ),
            const SizedBox(height: 12),
            // APP ID / 应用ID
            TextField(
              decoration: InputDecoration(
                labelText: _config.provider == TranslationProvider.baidu
                    ? 'APP ID'
                    : '应用 ID',
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: _onAppIdChanged,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // 密钥 / 应用密钥
            TextField(
              decoration: InputDecoration(
                labelText: _config.provider == TranslationProvider.baidu
                    ? '密钥'
                    : '应用密钥',
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              obscureText: true,
              onChanged: _onAppSecretChanged,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onSave(),
            ),
            const SizedBox(height: 8),
            // 配置提示
            Text(
              _config.provider == TranslationProvider.baidu
                  ? '获取百度翻译 API 凭证: https://api.fanyi.baidu.com/'
                  : '获取有道智云 API 凭证: https://ai.youdao.com/',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
