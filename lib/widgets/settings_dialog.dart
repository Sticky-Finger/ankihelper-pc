import 'package:flutter/material.dart';

/// 显示设置弹窗（骨架）
void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: const SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '词典管理',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('（暂无词典 — 功能即将上线）',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text(
              '牌组选择',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('（默认牌组 — 功能即将上线）',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text(
              '翻译 API 配置',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('（未配置 — 功能即将上线）',
                style: TextStyle(color: Colors.grey)),
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
