import 'package:flutter/material.dart';

class TextOverlayConfig {
  static TextOverlayConfig fromJson(Map<String, dynamic> json) {
    return TextOverlayConfig(
      text: json['text'] as String,
      textColor: Color(json['textColor'] as int),
      borderColor: Color(json['borderColor'] as int),
      borderWidth: (json['borderWidth'] as num).toDouble(),
      autoScale: json['autoScale'] as bool,
      fontSize: (json['fontSize'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'textColor': textColor.toARGB32(),
        'borderColor': borderColor.toARGB32(),
        'borderWidth': borderWidth,
        'autoScale': autoScale,
        'fontSize': fontSize,
      };
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
