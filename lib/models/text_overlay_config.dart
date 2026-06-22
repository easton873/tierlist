import 'package:flutter/material.dart';

class TextOverlayConfig {
  final String text;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;

  const TextOverlayConfig({
    required this.text,
    this.textColor = Colors.white,
    this.borderColor = Colors.black,
    this.borderWidth = 4.0,
  });

  TextOverlayConfig copyWith({
    String? text,
    Color? textColor,
    Color? borderColor,
    double? borderWidth,
  }) {
    return TextOverlayConfig(
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }
}
