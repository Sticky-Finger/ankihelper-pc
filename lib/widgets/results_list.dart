import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_entry_model.dart';
import '../providers/anki_connect_provider.dart';
import '../providers/card_data_provider.dart';
import '../providers/toast_provider.dart';
import '../providers/deck_provider.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'deck_selector.dart';
import 'preview_modal.dart';
import 'result_entry.dart';

/// 结果列表容器 — 标题 + 词典标签 + 条目列表 + 底部提示
class ResultsList extends ConsumerWidget {
  const ResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final data = ref.watch(cardDataProvider);

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
                        '牛津高阶 (本地)',
                        style: TextStyle(
                          fontFamily: FluentTokens.fontFamilyBase,
                          fontSize: FluentTokens.fontSize200,
                          color: tokens.fg3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: FluentTokens.spaceM),
        // ====== 条目列表 ======
        // 空条目（占位）+ 数据条目
        ..._buildEntries(context, ref, tokens, data.entries),
        const SizedBox(height: FluentTokens.spaceXs),
        // ====== 底部提示 ======
        Center(
          child: Text(
            '提示：双击条目可快速添加 （若无查询结果，仅显示空条目）',
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize200,
              color: tokens.fg4,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEntries(BuildContext context, WidgetRef ref,
      FluentTokens tokens, List<CardEntryModel> entries) {
    final widgets = <Widget>[];

    // 首条固定为空条目（占位符）
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: FluentTokens.spaceXs),
        child: ResultEntry(
          entry: CardEntryModel(
            id: 'placeholder',
            word: entries.isNotEmpty ? entries.first.word : '',
          ),
          displayIndex: 0,
          isPlaceholder: true,
          onAdd: () => ref.read(toastProvider.notifier).show('空条目 — 请先编辑内容'),
          onPreview: () => showPreviewModal(context, data: PreviewCardData(
            front: entries.isNotEmpty ? entries.first.word : '',
            back: '',
          )),
        ),
      ),
    );

    // 数据条目
    for (int i = 0; i < entries.length; i++) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: FluentTokens.spaceXs),
          child: ResultEntry(
            entry: entries[i],
            displayIndex: i + 1,
            onAdd: () {
              _addNoteToAnki(ref, entries[i]);
            },
            onPreview: () async {
              final confirmed = await showPreviewModal(context, data: PreviewCardData(
                front: entries[i].word,
                phonetic: entries[i].phonetic,
                back: entries[i].meaning,
                example: entries[i].example,
              ));
              if (confirmed == true) {
                await _addNoteToAnki(ref, entries[i]);
              }
            },
          ),
        ),
      );
    }

    return widgets;
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

      final noteId = await service.addNote(
        deckName: deckName,
        modelName: 'Basic',
        fields: {'Front': entry.word, 'Back': entry.meaning},
        allowDuplicate: true,
      );
      if (kDebugMode) {
        debugPrint('[AddNote] 添加成功，noteId: $noteId');
      }
      ref.read(toastProvider.notifier).show('卡片已添加到 $deckName');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AddNote] 添加失败: $e');
      }
      ref.read(toastProvider.notifier).show('添加失败: $e');
    }
  }
}
