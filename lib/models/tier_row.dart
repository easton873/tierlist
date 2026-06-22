import 'package:flutter/material.dart';
import 'tier_item.dart';

class TierRow {
  final String id;
  final String label;
  final Color labelColor;
  final double rowHeight;
  final List<TierItem> items;

  const TierRow({
    required this.id,
    required this.label,
    required this.labelColor,
    this.rowHeight = 80.0,
    this.items = const [],
  });

  TierRow copyWith({
    String? id,
    String? label,
    Color? labelColor,
    double? rowHeight,
    List<TierItem>? items,
  }) {
    return TierRow(
      id: id ?? this.id,
      label: label ?? this.label,
      labelColor: labelColor ?? this.labelColor,
      rowHeight: rowHeight ?? this.rowHeight,
      items: items ?? this.items,
    );
  }
}
