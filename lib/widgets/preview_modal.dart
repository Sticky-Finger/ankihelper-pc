import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// 展示卡片预览弹窗（动态字段）
///
/// [fields] - 模板字段名列表，按此顺序渲染输入框
/// [initialValues] — 字段名 → 预填充值（可选）
/// 返回字段名到用户输入值的映射，取消返回 null
Future<Map<String, String>?> showPreviewModal(
  BuildContext context, {
  required List<String> fields,
  Map<String, String> initialValues = const {},
}) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PreviewModal(
      fields: fields,
      initialValues: initialValues,
    ),
  );
}

class _PreviewModal extends ConsumerStatefulWidget {
  final List<String> fields;
  final Map<String, String> initialValues;

  const _PreviewModal({
    required this.fields,
    required this.initialValues,
  });

  @override
  ConsumerState<_PreviewModal> createState() => _PreviewModalState();
}

class _PreviewModalState extends ConsumerState<_PreviewModal> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.fields.map((field) {
      return TextEditingController(
        text: widget.initialValues[field] ?? '',
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    final result = <String, String>{};
    for (int i = 0; i < widget.fields.length; i++) {
      result[widget.fields[i]] = _controllers[i].text.trim();
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(fluentTokensProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 0.8 * 1200),
        decoration: BoxDecoration(
          color: tokens.bgCard,
          border: Border.all(
            color: tokens.stroke2,
            width: FluentTokens.strokeWidthThin,
          ),
          borderRadius: BorderRadius.circular(FluentTokens.radiusXl),
          boxShadow: tokens.shadow8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====== 头部 ======
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FluentTokens.spaceXl,
                vertical: FluentTokens.spaceL,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.stroke3,
                    width: FluentTokens.strokeWidthThin,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '卡片预览',
                    style: TextStyle(
                      fontFamily: FluentTokens.fontFamilyBase,
                      fontSize: FluentTokens.fontSize500,
                      fontWeight: FluentTokens.fontWeightSemibold,
                      color: tokens.fg1,
                      letterSpacing: -0.01,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: _CloseIcon(color: tokens.fg2),
                  ),
                ],
              ),
            ),
            // ====== 内容体：动态字段 ======
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(FluentTokens.spaceXl),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < widget.fields.length; i++) ...[
                        if (i > 0)
                          const SizedBox(height: FluentTokens.spaceL),
                        _EditableField(
                          label: widget.fields[i],
                          controller: _controllers[i],
                          tokens: tokens,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // ====== 底部按钮 ======
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FluentTokens.spaceXl,
                vertical: FluentTokens.spaceL,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: tokens.stroke3,
                    width: FluentTokens.strokeWidthThin,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(null),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FluentTokens.spaceM,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(FluentTokens.radiusMd),
                        border: Border.all(
                          color: tokens.stroke1,
                          width: FluentTokens.strokeWidthThin,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontFamily: FluentTokens.fontFamilyBase,
                            fontSize: FluentTokens.fontSize300,
                            color: tokens.fg2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: FluentTokens.spaceS),
                  GestureDetector(
                    onTap: _confirm,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FluentTokens.spaceM,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.bgBrand,
                        borderRadius:
                            BorderRadius.circular(FluentTokens.radiusMd),
                        border: Border.all(
                          color: tokens.bgBrand,
                          width: FluentTokens.strokeWidthThin,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '添加到 Anki',
                          style: TextStyle(
                            fontFamily: FluentTokens.fontFamilyBase,
                            fontSize: FluentTokens.fontSize300,
                            color: tokens.fgOnBrand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹窗可编辑字段组件
class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FluentTokens tokens;

  const _EditableField({
    required this.label,
    required this.controller,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: FluentTokens.fontFamilyBase,
            fontSize: FluentTokens.fontSize200,
            fontWeight: FluentTokens.fontWeightMedium,
            color: tokens.fg3,
            letterSpacing: 0.04,
          ),
        ),
        const SizedBox(height: FluentTokens.spaceXs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: FluentTokens.spaceM,
            vertical: FluentTokens.spaceMNudge,
          ),
          decoration: BoxDecoration(
            color: tokens.bgInput,
            border: Border.all(
              color: tokens.stroke3,
              width: FluentTokens.strokeWidthThin,
            ),
            borderRadius: BorderRadius.circular(FluentTokens.radiusMd),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontFamily: FluentTokens.fontFamilyBase,
              fontSize: FluentTokens.fontSize400,
              color: tokens.fg1,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: null,
            textInputAction: TextInputAction.newline,
          ),
        ),
      ],
    );
  }
}

/// 关闭图标 (X)
class _CloseIcon extends StatelessWidget {
  final Color color;

  const _CloseIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _CloseIconPainter(color: color),
      ),
    );
  }
}

class _CloseIconPainter extends CustomPainter {
  final Color color;

  _CloseIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(10, 10), const Offset(22, 22), paint);
    canvas.drawLine(const Offset(22, 10), const Offset(10, 22), paint);
  }

  @override
  bool shouldRepaint(_CloseIconPainter oldDelegate) => oldDelegate.color != color;
}
