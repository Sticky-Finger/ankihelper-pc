import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_entry_model.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';
import 'fluent_buttons.dart';

/// 单个结果条目 — 支持空条目（虚线边框+▶+空标签）和释义条目
class ResultEntry extends ConsumerStatefulWidget {
  final CardEntryModel entry;
  final int displayIndex;
  final bool isPlaceholder;
  final VoidCallback? onAdd;
  final VoidCallback? onPreview;

  const ResultEntry({
    super.key,
    required this.entry,
    required this.displayIndex,
    this.isPlaceholder = false,
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onDoubleTap: widget.onAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          padding: const EdgeInsets.symmetric(
            horizontal: FluentTokens.spaceL,
            vertical: FluentTokens.spaceM,
          ),
          decoration: BoxDecoration(
            color: widget.isPlaceholder
                ? (_hovered ? tokens.emptyEntryHover : Colors.transparent)
                : (_hovered ? tokens.bgCardHover : tokens.bgCard),
            border: Border.all(
              color: widget.isPlaceholder
                  ? (_hovered ? tokens.stroke1 : tokens.stroke2)
                  : (_hovered ? tokens.stroke2 : tokens.stroke3),
              width: FluentTokens.strokeWidthThin,
            ),
            borderRadius: BorderRadius.circular(FluentTokens.radiusLg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== 序号 ======
              SizedBox(
                width: 20,
                child: Text(
                  widget.isPlaceholder ? '▶' : '${widget.displayIndex}.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: widget.isPlaceholder
                        ? FluentTokens.fontFamilyBase
                        : FluentTokens.fontFamilyMono,
                    fontSize: FluentTokens.fontSize200,
                    fontWeight: FluentTokens.fontWeightSemibold,
                    color: tokens.fg4,
                  ),
                ),
              ),
              const SizedBox(width: FluentTokens.spaceM),
              // ====== 内容体 ======
              Expanded(
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
                    // 空条目提示
                    if (widget.isPlaceholder)
                      Padding(
                        padding: const EdgeInsets.only(top: FluentTokens.spaceXxs),
                        child: Text(
                          '[空条目] 手动编辑卡片',
                          style: TextStyle(
                            fontFamily: FluentTokens.fontFamilyBase,
                            fontSize: FluentTokens.fontSize300,
                            fontStyle: FontStyle.italic,
                            color: tokens.fg4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ====== 操作按钮组 ======
              const SizedBox(width: FluentTokens.spaceM),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FluentButton.outline(
                    label: widget.isPlaceholder ? '添加卡片' : '添加',
                    isSmall: true,
                    onPressed: widget.onAdd,
                  ),
                  const SizedBox(height: FluentTokens.spaceXs),
                  FluentButton.subtle(
                    label: widget.isPlaceholder ? '预览编辑' : '预览',
                    isSmall: true,
                    onPressed: widget.onPreview,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
