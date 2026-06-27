import 'package:flutter/material.dart';
import 'tier_item.dart';

class FreeItem {
  static FreeItem fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>;
    return FreeItem(
      item: TierItem.fromJson(json['item'] as Map<String, dynamic>),
      position: Offset(
        (pos['dx'] as num).toDouble(),
        (pos['dy'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'position': {'dx': position.dx, 'dy': position.dy},
      };
  final TierItem item;
  final Offset position;

  const FreeItem({required this.item, required this.position});

  FreeItem copyWith({TierItem? item, Offset? position}) => FreeItem(
        item: item ?? this.item,
        position: position ?? this.position,
      );
}
