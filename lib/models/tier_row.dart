import 'package:flutter/material.dart';
import 'tier_item.dart';

class TierRow {
  final String id;
  final String label;
  final Color labelColor;
  final double rowHeight;
  final List<TierItem> items;
  // null = auto-scale (40% of row height)
  final double? fontSize;

  const TierRow({
    required this.id,
    required this.label,
    required this.labelColor,
    this.rowHeight = 80.0,
    this.items = const [],
    this.fontSize,
  });

  TierRow copyWith({
    String? id,
    String? label,
    Color? labelColor,
    double? rowHeight,
    List<TierItem>? items,
    double? fontSize,
    bool clearFontSize = false,
  }) {
    return TierRow(
      id: id ?? this.id,
      label: label ?? this.label,
      labelColor: labelColor ?? this.labelColor,
      rowHeight: rowHeight ?? this.rowHeight,
      items: items ?? this.items,
      fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
    );
  }
}
