import 'package:flutter/material.dart';
import 'tier_item.dart';

class FreeItem {
  final TierItem item;
  final Offset position;

  const FreeItem({required this.item, required this.position});

  FreeItem copyWith({TierItem? item, Offset? position}) => FreeItem(
        item: item ?? this.item,
        position: position ?? this.position,
      );
}
