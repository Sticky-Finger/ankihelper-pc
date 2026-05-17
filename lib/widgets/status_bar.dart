import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// 状态指示级别
enum StatusLevel { success, warning, danger }

/// 状态条目数据类
class StatusItem {
  final String label;
  final StatusLevel level;

  const StatusItem({required this.label, this.level = StatusLevel.success});
}

/// 状态栏 — 三组状态指示（应用 / AnkiConnect / 词典查询）
class StatusBar extends ConsumerWidget {
  final StatusItem appStatus;
  final StatusItem ankiStatus;
  final StatusItem dictStatus;

  const StatusBar({
    super.key,
    this.appStatus = const StatusItem(label: '就绪'),
    this.ankiStatus = const StatusItem(label: 'AnkiConnect: 已连接'),
    this.dictStatus = const StatusItem(label: '词典查询: 完成 (0条释义)'),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: FluentTokens.spaceL),
      decoration: BoxDecoration(
        color: tokens.bgCard,
        border: Border(
          top: BorderSide(
            color: tokens.stroke3,
            width: FluentTokens.strokeWidthThin,
          ),
        ),
      ),
      child: Row(
        children: [
          _StatusItemWidget(item: appStatus, tokens: tokens),
          _Separator(tokens: tokens),
          _StatusItemWidget(item: ankiStatus, tokens: tokens),
          _Separator(tokens: tokens),
          _StatusItemWidget(item: dictStatus, tokens: tokens),
        ],
      ),
    );
  }
}

class _StatusItemWidget extends StatelessWidget {
  final StatusItem item;
  final FluentTokens tokens;

  const _StatusItemWidget({required this.item, required this.tokens});

  Color _dotColor() {
    switch (item.level) {
      case StatusLevel.success:
        return tokens.statusSuccessFg;
      case StatusLevel.warning:
        return tokens.statusWarningFg;
      case StatusLevel.danger:
        return tokens.statusDangerFg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: _dotColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: FluentTokens.spaceXs),
        Text(
          item.label,
          style: TextStyle(
            fontFamily: FluentTokens.fontFamilyBase,
            fontSize: FluentTokens.fontSize200,
            color: tokens.fg3,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  final FluentTokens tokens;

  const _Separator({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: tokens.stroke3,
      margin: const EdgeInsets.symmetric(horizontal: FluentTokens.spaceL),
    );
  }
}
