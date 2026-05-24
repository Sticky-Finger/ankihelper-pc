import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_entry_model.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'fluent_buttons.dart';

/// 单个结果条目 — 显示卡片数据 + 添加/预览按钮
class ResultEntry extends ConsumerStatefulWidget {
  final CardEntryModel entry;
  final int displayIndex;
  final VoidCallback? onAdd;
  final VoidCallback? onPreview;

  const ResultEntry({
    super.key,
    required this.entry,
    required this.displayIndex,
    this.onAdd,
    this.onPreview,
  });

  @override
  ConsumerState<ResultEntry> createState() => _ResultEntryState();
}

class _ResultEntryState extends ConsumerState<ResultEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final wordEmpty = widget.entry.word.isEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: wordEmpty ? null : widget.onAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: FluentTokens.spaceL,
            vertical: FluentTokens.spaceM,
          ),
          decoration: BoxDecoration(
            color: _hovered ? tokens.bgCardHover : tokens.bgCard,
            border: Border.all(
              color: _hovered ? tokens.stroke2 : tokens.stroke3,
              width: FluentTokens.strokeWidthThin,
            ),
            borderRadius: BorderRadius.circular(FluentTokens.radiusLg),
          ),
          child: IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ====== 序号 ======
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                width: 20,
                child: Text(
                  '${widget.displayIndex}.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyMono,
                    fontSize: FluentTokens.fontSize200,
                    fontWeight: FluentTokens.fontWeightSemibold,
                    color: tokens.fg4,
                  ),
                ),
              ),
              ),
              const SizedBox(width: FluentTokens.spaceM),
              // ====== 内容体 ======
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 单词
                    Text(
                      widget.entry.word,
                      style: TextStyle(
                        fontFamily: FluentTokens.fontFamilyBase,
                        fontSize: FluentTokens.fontSize400,
                        fontWeight: FluentTokens.fontWeightSemibold,
                        color: tokens.fg1,
                      ),
                    ),
                    // 音标
                    if (widget.entry.phonetic.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: FluentTokens.spaceXxs),
                        child: Text(
                          widget.entry.phonetic,
                          style: TextStyle(
                            fontFamily: FluentTokens.fontFamilyMono,
                            fontSize: FluentTokens.fontSize200,
                            color: tokens.fg3,
                          ),
                        ),
                      ),
                    // 词性 + 释义
                    if (widget.entry.pos.isNotEmpty ||
                        widget.entry.meaning.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: FluentTokens.spaceXxs),
                        child: Row(
                          children: [
                            if (widget.entry.pos.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: FluentTokens.spaceSNudge,
                                  vertical: 1,
                                ),
                                margin: const EdgeInsets.only(
                                  right: FluentTokens.spaceS,
                                ),
                                decoration: BoxDecoration(
                                  color: tokens.posTagBg,
                                  borderRadius: BorderRadius.circular(
                                    FluentTokens.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  widget.entry.pos,
                                  style: TextStyle(
                                    fontFamily: FluentTokens.fontFamilyBase,
                                    fontSize: FluentTokens.fontSize200,
                                    fontWeight: FluentTokens.fontWeightMedium,
                                    color: tokens.fg4,
                                  ),
                                ),
                              ),
                            if (widget.entry.meaning.isNotEmpty)
                              Expanded(
                                child: Text(
                                  widget.entry.meaning,
                                  style: TextStyle(
                                    fontFamily: FluentTokens.fontFamilyBase,
                                    fontSize: FluentTokens.fontSize300,
                                    color: tokens.fg2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                ),
              ),
              // ====== 操作按钮组 ======
              const SizedBox(width: FluentTokens.spaceM),
              Align(
                alignment: Alignment.center,
                child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FluentButton.outline(
                    label: '添加',
                    isSmall: true,
                    onPressed: wordEmpty ? null : widget.onAdd,
                  ),
                  const SizedBox(width: FluentTokens.spaceXs),
                  FluentButton.subtle(
                    label: '预览',
                    isSmall: true,
                    onPressed: widget.onPreview,
                  ),
                ],
              ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
