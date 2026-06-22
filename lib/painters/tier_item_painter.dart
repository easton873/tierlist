import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/text_overlay_config.dart';

class TierItemPainter extends CustomPainter {
  final ui.Image? image;
  final TextOverlayConfig? overlay;

  const TierItemPainter({this.image, this.overlay});

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      final src = Rect.fromLTWH(
          0, 0, image!.width.toDouble(), image!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(image!, src, dst, Paint());
    }

    if (overlay != null && overlay!.text.isNotEmpty) {
      _paintBorderedText(canvas, size, overlay!);
    }
  }

  void _paintBorderedText(
      Canvas canvas, Size size, TextOverlayConfig config) {
    double fontSize = size.height * 0.75;
    TextPainter? tp;

    for (int i = 0; i < 20; i++) {
      tp = _buildFillPainter(config.text, fontSize, config.textColor);
      tp.layout(maxWidth: size.width * 0.95);
      if (tp.size.width <= size.width * 0.95 &&
          tp.size.height <= size.height * 0.9) {
        break;
      }
      fontSize *= 0.88;
    }

    if (tp == null) return;

    final borderPainter = _buildStrokePainter(
        config.text, fontSize, config.borderColor, config.borderWidth);
    borderPainter.layout(maxWidth: size.width * 0.95);

    final dx = (size.width - tp.size.width) / 2;
    final dy = (size.height - tp.size.height) / 2;
    final offset = Offset(dx, dy);

    borderPainter.paint(canvas, offset);
    tp.paint(canvas, offset);
  }

  TextPainter _buildFillPainter(String text, double fontSize, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }

  TextPainter _buildStrokePainter(
      String text, double fontSize, Color color, double borderWidth) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = borderWidth * 2
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
  }

  @override
  bool shouldRepaint(TierItemPainter old) {
    return old.image != image || old.overlay != overlay;
  }
}
