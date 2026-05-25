import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_token_model.dart';
import '../providers/clipboard_provider.dart';
import '../providers/pronunciation_provider.dart';
import '../providers/toast_provider.dart';
import '../providers/word_selection_provider.dart';
import '../services/pronunciation_service.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'word_token.dart';

/// 单词块区域 — 标题行 + Wrap 网格 + 选中词组展示
class WordBlocksSection extends ConsumerStatefulWidget {
  const WordBlocksSection({super.key});

  @override
  ConsumerState<WordBlocksSection> createState() => _WordBlocksSectionState();
}

class _WordBlocksSectionState extends ConsumerState<WordBlocksSection> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(clipboardProvider, (prev, next) {
        if (next.originalText != prev?.originalText) {
          final tokens = next.originalText.isNotEmpty
              ? tokenize(next.originalText)
              : <WordTokenModel>[];
          ref.read(wordSelectionProvider.notifier).setTokens(tokens);
        }
      });
      final current = ref.read(clipboardProvider);
      if (current.originalText.isNotEmpty) {
        final tokens = tokenize(current.originalText);
        ref.read(wordSelectionProvider.notifier).setTokens(tokens);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onTokenTap(int index) {
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    final notifier = ref.read(wordSelectionProvider.notifier);
    if (isShift) {
      notifier.selectRange(index);
    } else {
      notifier.toggleIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final selection = ref.watch(wordSelectionProvider);

    final hasSelection = selection.selectedIndices.isNotEmpty;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====== 标题行 ======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '单词块（单击切换选中 / Shift+单击多选）',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  fontWeight: FluentTokens.fontWeightMedium,
                  color: tokens.fg3,
                ),
              ),
              Text(
                '单击切换 · Shift+单击多选',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  color: tokens.fg4,
                ),
              ),
            ],
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 单词块网格 ======
          Wrap(
            spacing: FluentTokens.spaceSNudge,
            runSpacing: FluentTokens.spaceSNudge,
            children: selection.tokens
                .map(
                  (t) => WordTokenWidget(
                    token: t,
                    isSelected: selection.selectedIndices.contains(t.index),
                    onTap: () => _onTokenTap(t.index),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: FluentTokens.spaceM),
          // ====== 当前选中词组 ======
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: FluentTokens.spaceM,
              vertical: FluentTokens.spaceSNudge,
            ),
            decoration: BoxDecoration(
              color: tokens.bgInput,
              border: Border.all(
                color: tokens.stroke3,
                width: FluentTokens.strokeWidthThin,
              ),
              borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
            ),
            child: Row(
              children: [
                Text(
                  '当前选中词组：',
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize200,
                    fontWeight: FluentTokens.fontWeightMedium,
                    color: tokens.fg4,
                  ),
                ),
                const SizedBox(width: FluentTokens.spaceS),
                Text(
                  hasSelection ? selection.selectedText : '—',
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize300,
                    fontWeight: FluentTokens.fontWeightMedium,
                    color: hasSelection ? tokens.fgBrand : tokens.fg4,
                    fontStyle: hasSelection ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FluentTokens.spaceSNudge),
          // ====== 发音控制行 ======
          _PronunciationControls(),
        ],
      ),
    );
  }
}

/// 发音控制组件：播放按钮 + 发音源下拉 + 管理按钮
class _PronunciationControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final selection = ref.watch(wordSelectionProvider);
    final pronunciationState = ref.watch(pronunciationProvider);
    final currentSource = pronunciationState.selectedSource;

    return Row(
      children: [
        // 播放发音按钮
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.volume_up, size: 18, color: tokens.fg2),
            onPressed: () async {
              final word = selection.selectedText;
              final source = ref.read(pronunciationProvider).selectedSource;
              try {
                await PronunciationPlayer.play(word, source);
              } catch (e) {
                ref.read(toastProvider.notifier).show('发音播放失败，请检查 URL 是否可访问');
              }
            },
            tooltip: '播放发音',
          ),
        ),
        const SizedBox(width: FluentTokens.spaceS),
        // 发音源下拉
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: tokens.bgInput,
            border: Border.all(
              color: tokens.stroke3,
              width: FluentTokens.strokeWidthThin,
            ),
            borderRadius: BorderRadius.circular(FluentTokens.radiusSm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PronunciationSource>(
              value: currentSource,
              isDense: true,
              style: TextStyle(
                fontFamily: FluentTokens.fontFamilyBase,
                fontSize: FluentTokens.fontSize200,
                color: tokens.fg2,
              ),
              items: pronunciationState.allSources.map((source) {
                return DropdownMenuItem(
                  value: source,
                  child: Text(source.name),
                );
              }).toList(),
              onChanged: (source) {
                if (source != null) {
                  ref.read(pronunciationProvider.notifier).setSource(source);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: FluentTokens.spaceS),
        // 管理按钮
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.settings, size: 18, color: tokens.fg2),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const _PronunciationManagerDialog(),
              );
            },
            tooltip: '管理发音源',
          ),
        ),
      ],
    );
  }
}

/// 发音源管理弹窗
class _PronunciationManagerDialog extends ConsumerStatefulWidget {
  const _PronunciationManagerDialog();

  @override
  ConsumerState<_PronunciationManagerDialog> createState() =>
      _PronunciationManagerDialogState();
}

class _PronunciationManagerDialogState
    extends ConsumerState<_PronunciationManagerDialog> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _addCustomSource() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final urlTemplate = _urlController.text.trim();

      // 生成唯一 ID
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

      final newSource = PronunciationSource(
        id: id,
        name: name,
        urlTemplate: urlTemplate,
        isBuiltin: false,
      );

      ref.read(pronunciationProvider.notifier).addCustomSource(newSource);

      // 清空输入框
      _nameController.clear();
      _urlController.clear();

      // 关闭对话框
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pronunciationState = ref.watch(pronunciationProvider);
    final allSources = pronunciationState.allSources;

    return AlertDialog(
      title: const Text('管理发音源'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 发音源列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allSources.length,
                itemBuilder: (context, index) {
                  final source = allSources[index];
                  return ListTile(
                    title: Text(source.name),
                    subtitle: Text(
                      source.urlTemplate,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: source.isBuiltin
                        ? const Chip(label: Text('内置'))
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              ref
                                  .read(pronunciationProvider.notifier)
                                  .removeCustomSource(source.id);
                            },
                          ),
                  );
                },
              ),
            ),
            const Divider(),
            // 添加自定义发音源表单
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加自定义发音源',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '名称',
                      hintText: '例如：Google 美音',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL 模板',
                      hintText: 'https://example.com/audio/{word}.mp3',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入 URL 模板';
                      }
                      if (!value.contains('{word}')) {
                        return 'URL 模板必须包含 {word} 占位符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _addCustomSource,
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
