import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_entry_model.dart';
import '../models/card_template_model.dart';
import '../models/dict_settings_model.dart';
import '../models/dictionary_result_model.dart' show DictionarySourceLabel;
import '../providers/anki_connect_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/dict_settings_provider.dart';
import '../providers/toast_provider.dart';
import '../providers/deck_provider.dart';
import '../providers/template_provider.dart';
import '../providers/word_selection_provider.dart';
import '../services/template_manager.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'deck_selector.dart';
import 'preview_modal.dart';
import 'result_entry.dart';

/// 结果列表容器 — 标题 + 词典标签 + 条目列表 + AI 卡片 + 底部提示
class ResultsList extends ConsumerWidget {
  const ResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final selection = ref.watch(wordSelectionProvider);
    final currentEntry = selection.currentEntry;
    final dictState = ref.watch(dictionaryProvider);

    // 词典标签：优先显示实际命中源，未查询时显示设置的首选源
    final dictLabel = _dictionaryLabel(ref, dictState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====== 标题行 ======
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '结果列表',
              style: TextStyle(
                fontFamily: FluentTokens.fontFamilyBase,
                fontSize: FluentTokens.fontSize200,
                fontWeight: FluentTokens.fontWeightMedium,
                color: tokens.fg3,
                letterSpacing: 0.04,
              ),
            ),
            // 牌组选择器 + 词典标签
            Row(
              children: [
                const DeckSelector(),
                const SizedBox(width: FluentTokens.spaceS),
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: FluentTokens.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.bgCard,
                    border: Border.all(
                      color: tokens.stroke3,
                      width: FluentTokens.strokeWidthThin,
                    ),
                    borderRadius: BorderRadius.circular(FluentTokens.radiusCircular),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '📖',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: FluentTokens.spaceXs),
                      Text(
                        dictLabel,
                        style: TextStyle(
                          fontFamily: FluentTokens.fontFamilyBase,
                          fontSize: FluentTokens.fontSize200,
                          color: tokens.fg3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FluentTokens.spaceXs),
                IconButton(
                  icon: const Icon(Icons.search, size: 18),
                  onPressed: () => _manualSearch(ref),
                  tooltip: '手动搜索词典',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: tokens.fg3,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: FluentTokens.spaceM),
        // ====== 条目列表 ======
        // 手动空条目（第一条）+ 词典义项条目
        ..._buildEntries(context, ref, tokens, currentEntry,
            selection.senseEntries),
        // ====== 查询中加载动画 ======
        if (_isQuerying(dictState, selection))
          Padding(
            padding: const EdgeInsets.only(
              top: FluentTokens.spaceS,
              bottom: FluentTokens.spaceXs,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: FluentTokens.spaceS),
                Text(
                  dictState.status == DictQueryStatus.aiStreaming
                      ? 'AI 词典生成中…'
                      : '词典查询中…',
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize200,
                    color: tokens.fg3,
                  ),
                ),
              ],
            ),
          ),
        // ====== AI 词典 Markdown 卡片 ======
        if (_aiMarkdownForSelection(dictState, selection).isNotEmpty)
          _AiDictCard(markdown: _aiMarkdownForSelection(dictState, selection)),
        const SizedBox(height: FluentTokens.spaceXs),
        // ====== 底部提示 ======
        Center(
          child: Text(
            _bottomHint(dictState, selection),
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize200,
              color: dictState.status == DictQueryStatus.failed
                  ? tokens.statusDangerFg
                  : tokens.fg4,
            ),
          ),
        ),
      ],
    );
  }

  /// 词典标签文案
  String _dictionaryLabel(WidgetRef ref, DictionaryState dictState) {
    if (dictState.status == DictQueryStatus.done &&
        dictState.result != null) {
      return dictState.result!.source.label;
    }
    final preferred = ref.watch(dictSettingsProvider).preferredSource;
    return switch (preferred) {
      DictSourcePreference.bing => '必应词典',
      DictSourcePreference.youdao => '有道词典',
      DictSourcePreference.ai => 'AI 词典',
      DictSourcePreference.auto => '必应词典',
    };
  }

  /// 是否正在查询（且当前有选中词）
  bool _isQuerying(DictionaryState dictState, WordSelectionState selection) {
    if (selection.selectedText.isEmpty) return false;
    return dictState.status == DictQueryStatus.loading ||
        (dictState.status == DictQueryStatus.aiStreaming &&
            dictState.queriedWord == selection.selectedText);
  }

  /// 当前选中词对应的 AI Markdown（无则为空）
  String _aiMarkdownForSelection(
      DictionaryState dictState, WordSelectionState selection) {
    if (selection.selectedText.isEmpty) return '';
    if (dictState.queriedWord != selection.selectedText) return '';
    if (dictState.status != DictQueryStatus.done &&
        dictState.status != DictQueryStatus.aiStreaming) {
      return '';
    }
    return dictState.aiMarkdown;
  }

  /// 底部提示文案
  String _bottomHint(DictionaryState dictState, WordSelectionState selection) {
    if (selection.selectedText.isEmpty) {
      return '提示：双击条目可快速添加 （若无查询结果，仅显示空条目）';
    }
    switch (dictState.status) {
      case DictQueryStatus.notFound:
        return '词典未收录「${dictState.queriedWord}」，可手动填写空条目';
      case DictQueryStatus.failed:
        return '词典查询失败：${dictState.errorMessage}（可手动填写空条目）';
      default:
        return '提示：双击条目可快速添加 （若无查询结果，仅显示空条目）';
    }
  }

  List<Widget> _buildEntries(
    BuildContext context,
    WidgetRef ref,
    FluentTokens tokens,
    CardEntryModel? currentEntry,
    List<CardEntryModel> senseEntries,
  ) {
    final widgets = <Widget>[];

    // 手动空条目（始终第一条）+ 词典义项条目
    final entries = <CardEntryModel>[
      currentEntry ?? const CardEntryModel(id: 'editable', word: ''),
      ...senseEntries,
    ];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: FluentTokens.spaceXs),
          child: ResultEntry(
            entry: entry,
            displayIndex: i,
            onAdd: () {
              _addNoteToAnki(ref, entry);
            },
            onPreview: () async {
              final template = ref.read(templateProvider);
              final initialValues =
                  _buildPreviewInitialValues(ref, template, entry);
              final result = await showPreviewModal(
                context,
                fields: template.fields,
                initialValues: initialValues,
              );
              if (result != null) {
                await _addNoteWithFields(ref, result);
              }
            },
          ),
        ),
      );
    }

    return widgets;
  }

  /// 手动触发词典查询（重新查询当前选中词）
  Future<void> _manualSearch(WidgetRef ref) async {
    final selectedText = ref.read(wordSelectionProvider).selectedText;
    if (selectedText.isEmpty) {
      ref.read(toastProvider.notifier).show('请先选择一个单词');
      return;
    }
    await ref.read(dictionaryProvider.notifier).query(selectedText);
  }

  /// 添加笔记到 Anki
  Future<void> _addNoteToAnki(WidgetRef ref, CardEntryModel entry) async {
    final deckName = ref.read(selectedDeckProvider);
    if (kDebugMode) {
      debugPrint('[AddNote] 开始添加卡片: ${entry.word} -> ${entry.meaning}');
      debugPrint('[AddNote] 目标牌组: $deckName');
    }
    try {
      final service = ref.read(ankiConnectServiceProvider);

      // 读取当前模板配置
      final template = ref.read(templateProvider);

      // 验证 Anki 中模板存在且字段匹配，不匹配时自动改名创建
      final validation = await TemplateManager.ensureModelFields(
        service: service,
        template: template,
      );

      // 如果模板被改名，更新本地状态并提示用户
      if (validation.wasRenamed) {
        await ref.read(templateProvider.notifier).updateTemplateName(
              template.id,
              validation.modelName,
            );
        ref.read(toastProvider.notifier).show(
              '模板名称已改为 ${validation.modelName}',
            );
      }

      // 构建字段映射
      final fields = TemplateManager.buildFields(template, entry);

      // 至少一个字段非空才能添加
      if (fields.values.every((v) => v.isEmpty)) {
        ref.read(toastProvider.notifier).show('请至少填写一个字段');
        return;
      }

      await service.addNote(
        deckName: deckName,
        modelName: validation.modelName,
        fields: fields,
        allowDuplicate: true,
      );
      ref.read(toastProvider.notifier).show('卡片已添加到 $deckName');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AddNote] 添加失败: $e');
      }
      ref.read(toastProvider.notifier).show('添加失败: $e');
    }
  }

  /// 为预览弹窗构建初始值（模板字段名 → 值）
  /// 按字段映射从 entry 中取值，未映射的字段填空字符串
  Map<String, String> _buildPreviewInitialValues(
    WidgetRef ref,
    CardTemplateModel template,
    CardEntryModel? entry,
  ) {
    final initial = <String, String>{};
    if (entry == null) return initial;

    final entryMap = entry.toMap();

    // fieldMapping 格式: {模板字段名: 数据源key}，直接使用
    for (final field in template.fields) {
      final dataSource = template.fieldMapping[field];
      if (dataSource != null && dataSource.isNotEmpty) {
        initial[field] = entryMap[dataSource] ?? '';
      } else {
        initial[field] = '';
      }
    }

    return initial;
  }

  /// 使用预构建的字段映射直接添加卡片（跳过 buildFields）
  Future<void> _addNoteWithFields(
    WidgetRef ref,
    Map<String, String> fields,
  ) async {
    final deckName = ref.read(selectedDeckProvider);
    try {
      final service = ref.read(ankiConnectServiceProvider);
      final template = ref.read(templateProvider);

      final validation = await TemplateManager.ensureModelFields(
        service: service,
        template: template,
      );

      if (validation.wasRenamed) {
        await ref.read(templateProvider.notifier).updateTemplateName(
              template.id,
              validation.modelName,
            );
        ref.read(toastProvider.notifier).show(
              '模板名称已改为 ${validation.modelName}',
            );
      }

      if (fields.values.every((v) => v.isEmpty)) {
        ref.read(toastProvider.notifier).show('请至少填写一个字段');
        return;
      }

      await service.addNote(
        deckName: deckName,
        modelName: validation.modelName,
        fields: fields,
        allowDuplicate: true,
      );
      ref.read(toastProvider.notifier).show('卡片已添加到 $deckName');
    } catch (e) {
      ref.read(toastProvider.notifier).show('添加失败: $e');
    }
  }
}

/// AI 词典 Markdown 卡片（流式渐进渲染 + 复制）
class _AiDictCard extends ConsumerWidget {
  final String markdown;

  const _AiDictCard({required this.markdown});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: FluentTokens.spaceS),
      padding: const EdgeInsets.all(FluentTokens.spaceM),
      decoration: BoxDecoration(
        color: tokens.bgCard,
        border: Border.all(
          color: tokens.stroke3,
          width: FluentTokens.strokeWidthThin,
        ),
        borderRadius: BorderRadius.circular(FluentTokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI 词典',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  fontWeight: FluentTokens.fontWeightMedium,
                  color: tokens.fg3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: '复制 Markdown',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: tokens.fg3,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: markdown));
                  ref.read(toastProvider.notifier).show('已复制 AI 释义 Markdown');
                },
              ),
            ],
          ),
          const SizedBox(height: FluentTokens.spaceXs),
          MarkdownBody(
            data: markdown,
            shrinkWrap: true,
            selectable: false,
          ),
        ],
      ),
    );
  }
}
