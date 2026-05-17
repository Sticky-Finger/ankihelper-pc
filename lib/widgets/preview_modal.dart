import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/fluent_tokens.dart';
import '../theme/theme_provider.dart';

/// 卡片预览数据
class PreviewCardData {
  final String front;
  final String phonetic;
  final String back;
  final String example;

  const PreviewCardData({
    required this.front,
    this.phonetic = '',
    required this.back,
    this.example = '',
  });
}

/// 展示卡片预览弹窗
Future<bool?> showPreviewModal(
  BuildContext context, {
  required PreviewCardData data,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PreviewModal(data: data),
  );
}

class _PreviewModal extends ConsumerWidget {
  final PreviewCardData data;

  const _PreviewModal({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // 关闭按钮
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: _CloseIcon(color: tokens.fg2),
                  ),
                ],
              ),
            ),
            // ====== 内容体 ======
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(FluentTokens.spaceXl),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: '正面 (单词)',
                        value: data.front,
                        tokens: tokens,
                      ),
                      const SizedBox(height: FluentTokens.spaceL),
                      _Field(
                        label: '音标',
                        value: data.phonetic.isNotEmpty ? data.phonetic : '—',
                        isMono: true,
                        tokens: tokens,
                      ),
                      const SizedBox(height: FluentTokens.spaceL),
                      _Field(
                        label: '背面 (释义)',
                        value: data.back.isNotEmpty ? data.back : '—',
                        tokens: tokens,
                      ),
                      const SizedBox(height: FluentTokens.spaceL),
                      _Field(
                        label: '例句',
                        value: data.example.isNotEmpty ? data.example : '—',
                        tokens: tokens,
                      ),
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
                    onTap: () => Navigator.of(context).pop(false),
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
                    onTap: () => Navigator.of(context).pop(true),
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

/// 弹窗字段组件
class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final FluentTokens tokens;

  const _Field({
    required this.label,
    required this.value,
    this.isMono = false,
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
          child: Text(
            value,
            style: TextStyle(
              fontFamily:
                  isMono ? FluentTokens.fontFamilyMono : FluentTokens.fontFamilyBase,
              fontSize: isMono ? FluentTokens.fontSize300 : FluentTokens.fontSize400,
              color: isMono ? tokens.fg2 : tokens.fg1,
            ),
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
