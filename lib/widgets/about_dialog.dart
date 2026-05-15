import 'package:flutter/material.dart';

/// 显示关于弹窗
void showAboutDialog_(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _AboutDialog(),
  );
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('关于 Anki划词助手'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('版本：v0.1'),
          SizedBox(height: 12),
          Text(
            'Anki划词助手是一款桌面工具，帮助用户快速将查词结果添加到 Anki 中。'
            '支持自动剪贴板监听、智能分词、多词典查询、一键制卡。',
          ),
        ],
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
