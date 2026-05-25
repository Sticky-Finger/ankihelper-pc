import 'package:flutter/material.dart';

/// UI 数据源选项
const List<String> kDataSources = ['单词', '例句', '例句翻译', '发音', '空'];

/// 字段映射编辑器 — 为模板的每个字段选择数据源
///
/// 每次修改 Select 自动触发 onChanged 回调，不需要额外保存按钮。
/// onChanged 返回格式：{模板字段名: 数据源内部key}，如 {'单词': 'word', '音标': '', ...}
class FieldMappingEditor extends StatefulWidget {
  final List<String> templateFields;
  final Map<String, String> initialMapping;
  final ValueChanged<Map<String, String>> onChanged;

  const FieldMappingEditor({
    super.key,
    required this.templateFields,
    required this.initialMapping,
    required this.onChanged,
  });

  @override
  State<FieldMappingEditor> createState() => _FieldMappingEditorState();
}

class _FieldMappingEditorState extends State<FieldMappingEditor> {
  /// 模板字段名 → 数据源显示名（如 '单词'/'例句'/'例句翻译'/'空'）
  late Map<String, String> _fieldToSource;

  @override
  void initState() {
    super.initState();
    _buildFromInitialMapping();
  }

  @override
  void didUpdateWidget(FieldMappingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMapping != widget.initialMapping) {
      _buildFromInitialMapping();
    }
  }

  /// initialMapping 格式: {模板字段名: 数据源内部key}
  /// 转为: {模板字段名: 中文显示名}
  void _buildFromInitialMapping() {
    _fieldToSource = {};
    // 按 templateFields 顺序构建，保证固定顺序
    for (final field in widget.templateFields) {
      final internalKey = widget.initialMapping[field];
      if (internalKey != null) {
        _fieldToSource[field] = _internalToDisplay(internalKey);
      } else {
        _fieldToSource[field] = '空';
      }
    }
  }

  /// 数据源内部key → 中文显示名
  String _internalToDisplay(String key) {
    switch (key) {
      case 'word':
        return '单词';
      case 'example':
        return '例句';
      case 'exampleTranslation':
        return '例句翻译';
      case 'pronunciationUrl':
        return '发音';
      default:
        return '空';
    }
  }

  /// 中文显示名 → 数据源内部key
  String _displayToInternal(String displayName) {
    switch (displayName) {
      case '单词':
        return 'word';
      case '例句':
        return 'example';
      case '例句翻译':
        return 'exampleTranslation';
      case '发音':
        return 'pronunciationUrl';
      default:
        return '';
    }
  }

  void _notifyChanged() {
    final result = <String, String>{};
    for (final entry in _fieldToSource.entries) {
      result[entry.key] = _displayToInternal(entry.value);
    }
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '字段映射',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._fieldToSource.entries.map((entry) {
          final templateField = entry.key;
          final currentSource = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    templateField,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('←', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: currentSource,
                    isDense: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: kDataSources
                        .map((source) => DropdownMenuItem(
                              value: source,
                              child: Text(source,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _fieldToSource[templateField] = value;
                        });
                        _notifyChanged();
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
