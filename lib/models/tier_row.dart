import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'tier_item.dart';

class TierRow {
  final String id;
  final String label;
  final Color labelColor;
  final List<TierItem> items;
  // null = auto-scale (40% of row height)
  final double? fontSize;
  // non-null = image-background row; image spans full row width
  final Uint8List? backgroundImage;
  // null = use the auto-calculated height (viewport / 6); non-null = fixed px height
  final double? customHeight;

  const TierRow({
    required this.id,
    required this.label,
    required this.labelColor,
    this.items = const [],
    this.fontSize,
    this.backgroundImage,
    this.customHeight,
  });

  bool get isImageRow => backgroundImage != null;

  TierRow copyWith({
    String? id,
    String? label,
    Color? labelColor,
    List<TierItem>? items,
    double? fontSize,
    bool clearFontSize = false,
    Uint8List? backgroundImage,
    bool clearBackgroundImage = false,
    double? customHeight,
    bool clearCustomHeight = false,
  }) {
    return TierRow(
      id: id ?? this.id,
      label: label ?? this.label,
      labelColor: labelColor ?? this.labelColor,
      items: items ?? this.items,
      fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
      backgroundImage: clearBackgroundImage ? null : (backgroundImage ?? this.backgroundImage),
      customHeight: clearCustomHeight ? null : (customHeight ?? this.customHeight),
    );
  }
}
