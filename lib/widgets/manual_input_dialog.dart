import 'package:flutter/material.dart';

/// 显示手动输入弹窗（骨架）
void showManualInputDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _ManualInputDialog(),
  );
}

class _ManualInputDialog extends StatefulWidget {
  const _ManualInputDialog();

  @override
  State<_ManualInputDialog> createState() => _ManualInputDialogState();
}

class _ManualInputDialogState extends State<_ManualInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动输入'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入英文文本...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          minLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              // TODO: 处理手动输入的文本
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
