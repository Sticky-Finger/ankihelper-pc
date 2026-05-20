import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/deck_provider.dart';
import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// 牌组选择器 — 药丸形容器 + 可搜索输入框 + 下拉菜单
///
/// 匹配 Open Design 设计稿中的 results-section__deck-group 组件
class DeckSelector extends ConsumerStatefulWidget {
  const DeckSelector({super.key});

  @override
  ConsumerState<DeckSelector> createState() => _DeckSelectorState();
}

class _DeckSelectorState extends ConsumerState<DeckSelector> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      // 打开下拉时刷新牌组列表
      ref.read(deckListProvider.notifier).refresh();
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned(
              width: 220,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 28),
                child: GestureDetector(
                  onTap: () {},
                  child: Consumer(
                    builder: (context, ref, _) {
                      final tokens = ref.watch(fluentTokensProvider);
                      final deckListAsync = ref.watch(deckListProvider);
                      final selectedDeck = ref.watch(selectedDeckProvider);

                      return Material(
                        elevation: 4,
                        borderRadius:
                            BorderRadius.circular(FluentTokens.radiusMd),
                        color: tokens.bgCard,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(FluentTokens.radiusMd),
                            border: Border.all(color: tokens.stroke1),
                          ),
                          child: deckListAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(FluentTokens.spaceM),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            error: (e, _) => Padding(
                              padding:
                                  const EdgeInsets.all(FluentTokens.spaceM),
                              child: Text(
                                '加载失败: $e',
                                style: TextStyle(
                                  fontSize: FluentTokens.fontSize200,
                                  color: tokens.statusDangerFg,
                                ),
                              ),
                            ),
                            data: (decks) {
                              final query = _controller.text.toLowerCase();
                              final filtered = query.isEmpty
                                  ? decks
                                  : decks
                                      .where((d) =>
                                          d.toLowerCase().contains(query))
                                      .toList();
                              if (filtered.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(
                                      FluentTokens.spaceM),
                                  child: Text(
                                    '无匹配牌组',
                                    style: TextStyle(
                                      fontSize: FluentTokens.fontSize200,
                                      color: tokens.fg4,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: FluentTokens.spaceXs,
                                ),
                                shrinkWrap: true,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final deck = filtered[index];
                                  final isSelected = deck == selectedDeck;
                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(
                                              selectedDeckProvider.notifier)
                                          .select(deck);
                                      _controller.clear();
                                      _removeOverlay();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: FluentTokens.spaceM,
                                        vertical: FluentTokens.spaceSNudge,
                                      ),
                                      color: isSelected
                                          ? tokens.bgSubtleSelected
                                          : Colors.transparent,
                                      child: Text(
                                        deck,
                                        style: TextStyle(
                                          fontFamily:
                                              FluentTokens.fontFamilyBase,
                                          fontSize:
                                              FluentTokens.fontSize200,
                                          color: isSelected
                                              ? tokens.fgBrand
                                              : tokens.fg2,
                                          fontWeight: isSelected
                                              ? FluentTokens.fontWeightMedium
                                              : FluentTokens
                                                  .fontWeightRegular,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
    _focusNode.requestFocus();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);
    final selectedDeck = ref.watch(selectedDeckProvider);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '选择Anki牌组',
                style: TextStyle(
                  fontFamily: FluentTokens.fontFamilyBase,
                  fontSize: FluentTokens.fontSize200,
                  color: tokens.fg4,
                ),
              ),
              const SizedBox(width: FluentTokens.spaceXxs),
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontFamily: FluentTokens.fontFamilyBase,
                    fontSize: FluentTokens.fontSize200,
                    color: tokens.fg2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: selectedDeck,
                    hintStyle: TextStyle(
                      fontFamily: FluentTokens.fontFamilyBase,
                      fontSize: FluentTokens.fontSize200,
                      color: tokens.fg2,
                    ),
                  ),
                  onChanged: (_) {
                    if (_isOpen) {
                      _removeOverlay();
                      _showOverlay();
                    }
                  },
                  onTap: () {
                    if (!_isOpen) {
                      _showOverlay();
                    } else {
                      // 输入框获焦时刷新牌组列表
                      ref.read(deckListProvider.notifier).refresh();
                    }
                  },
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: tokens.fg3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
