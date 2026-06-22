import 'package:flutter/material.dart';

class TextOverlayConfig {
  final String text;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;
  final bool autoScale;
  final double fontSize;

  const TextOverlayConfig({
    required this.text,
    this.textColor = Colors.white,
    this.borderColor = Colors.black,
    this.borderWidth = 4.0,
    this.autoScale = true,
    this.fontSize = 32.0,
  });

  TextOverlayConfig copyWith({
    String? text,
    Color? textColor,
    Color? borderColor,
    double? borderWidth,
    bool? autoScale,
    double? fontSize,
  }) {
    return TextOverlayConfig(
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      autoScale: autoScale ?? this.autoScale,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
