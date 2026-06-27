import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/free_item.dart';
import '../models/tier_item.dart';
import '../models/tier_row.dart';
import '../models/text_overlay_config.dart';
import '../utils/default_tiers.dart';

const _uuid = Uuid();

class TierlistState {
  final List<TierRow> tiers;
  final List<TierItem> pool;
  final List<FreeItem> freeItems;

  const TierlistState({
    required this.tiers,
    required this.pool,
    this.freeItems = const [],
  });

  TierlistState copyWith({
    List<TierRow>? tiers,
    List<TierItem>? pool,
    List<FreeItem>? freeItems,
  }) {
    return TierlistState(
      tiers: tiers ?? this.tiers,
      pool: pool ?? this.pool,
      freeItems: freeItems ?? this.freeItems,
    );
  }
}

class TierlistNotifier extends StateNotifier<TierlistState> {
  TierlistNotifier()
      : super(TierlistState(tiers: defaultTiers(), pool: []));

  void addItemToPool(TierItem item) {
    state = state.copyWith(pool: [...state.pool, item]);
  }

  void moveItemToTier(String itemId, String tierRowId, int insertIndex) {
    final item = _findItem(itemId);
    if (item == null) return;

    final newTiers = state.tiers.map((row) {
      final withoutItem = row.items.where((i) => i.id != itemId).toList();
      if (row.id == tierRowId) {
        final clamped = insertIndex.clamp(0, withoutItem.length);
        final newItems = [...withoutItem]..insert(clamped, item);
        return row.copyWith(items: newItems);
      }
      return row.copyWith(items: withoutItem);
    }).toList();

    final newPool = state.pool.where((i) => i.id != itemId).toList();
    final newFree = state.freeItems.where((f) => f.item.id != itemId).toList();
    state = state.copyWith(tiers: newTiers, pool: newPool, freeItems: newFree);
  }

  void moveItemToPool(String itemId) {
    final item = _findItem(itemId);
    if (item == null) return;

    final newTiers = state.tiers
        .map((row) => row.copyWith(
              items: row.items.where((i) => i.id != itemId).toList(),
            ))
        .toList();
    final newFree = state.freeItems.where((f) => f.item.id != itemId).toList();

    if (!state.pool.any((i) => i.id == itemId)) {
      state = state.copyWith(
          tiers: newTiers, pool: [...state.pool, item], freeItems: newFree);
    } else {
      state = state.copyWith(tiers: newTiers, freeItems: newFree);
    }
  }

  void placeFreeItem(TierItem item, Offset position) {
    final newTiers = state.tiers
        .map((row) => row.copyWith(
              items: row.items.where((i) => i.id != item.id).toList(),
            ))
        .toList();
    final newPool = state.pool.where((i) => i.id != item.id).toList();
    final newFree = [
      ...state.freeItems.where((f) => f.item.id != item.id),
      FreeItem(item: item, position: position),
    ];
    state = state.copyWith(tiers: newTiers, pool: newPool, freeItems: newFree);
  }

  void deleteItem(String itemId) {
    state = state.copyWith(
      tiers: state.tiers
          .map((row) => row.copyWith(
                items: row.items.where((i) => i.id != itemId).toList(),
              ))
          .toList(),
      pool: state.pool.where((i) => i.id != itemId).toList(),
      freeItems: state.freeItems.where((f) => f.item.id != itemId).toList(),
    );
  }

  void updateItemOverlay(String itemId, TextOverlayConfig? overlay) {
    state = state.copyWith(
      tiers: state.tiers.map((row) {
        return row.copyWith(
          items: row.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(
                  overlay: overlay, clearOverlay: overlay == null);
            }
            return item;
          }).toList(),
        );
      }).toList(),
      pool: state.pool.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
              overlay: overlay, clearOverlay: overlay == null);
        }
        return item;
      }).toList(),
      freeItems: state.freeItems.map((fi) {
        if (fi.item.id == itemId) {
          return fi.copyWith(
              item: fi.item.copyWith(
                  overlay: overlay, clearOverlay: overlay == null));
        }
        return fi;
      }).toList(),
    );
  }

  void addTier() {
    const defaultColors = [
      Color(0xFFB0BEC5),
      Color(0xFFCE93D8),
      Color(0xFF80CBC4),
      Color(0xFFFFCC80),
      Color(0xFFEF9A9A),
    ];
    final color = defaultColors[state.tiers.length % defaultColors.length];
    final newTier = TierRow(
      id: _uuid.v4(),
      label: 'New',
      labelColor: color,
    );
    state = state.copyWith(tiers: [...state.tiers, newTier]);
  }

  void deleteTier(String tierId) {
    if (state.tiers.length <= 1) return;
    final tier = state.tiers.firstWhere((r) => r.id == tierId);
    state = state.copyWith(
      tiers: state.tiers.where((r) => r.id != tierId).toList(),
      pool: [...state.pool, ...tier.items],
    );
  }

  void renameTier(String tierId, String newLabel) {
    state = state.copyWith(
      tiers: state.tiers
          .map((r) => r.id == tierId ? r.copyWith(label: newLabel) : r)
          .toList(),
    );
  }

  void recolorTier(String tierId, Color newColor) {
    state = state.copyWith(
      tiers: state.tiers
          .map((r) => r.id == tierId ? r.copyWith(labelColor: newColor) : r)
          .toList(),
    );
  }

  void addImageTier(Uint8List bytes) {
    final newTier = TierRow(
      id: _uuid.v4(),
      label: '',
      labelColor: Colors.transparent,
      backgroundImage: bytes,
    );
    state = state.copyWith(tiers: [...state.tiers, newTier]);
  }

  void updateTierHeight(String tierId, double? height) {
    state = state.copyWith(
      tiers: state.tiers
          .map((r) => r.id == tierId
              ? r.copyWith(customHeight: height, clearCustomHeight: height == null)
              : r)
          .toList(),
    );
  }

  void updateTierBackgroundImage(String tierId, Uint8List? bytes) {
    state = state.copyWith(
      tiers: state.tiers
          .map((r) => r.id == tierId
              ? r.copyWith(backgroundImage: bytes, clearBackgroundImage: bytes == null)
              : r)
          .toList(),
    );
  }

  void reorderTier(String movedId, String targetId) {
    final list = [...state.tiers];
    final fromIdx = list.indexWhere((r) => r.id == movedId);
    final toIdx = list.indexWhere((r) => r.id == targetId);
    if (fromIdx == -1 || toIdx == -1 || fromIdx == toIdx) return;
    final moved = list.removeAt(fromIdx);
    list.insert(toIdx, moved);
    state = state.copyWith(tiers: list);
  }

  void moveTierUp(String tierId) {
    final idx = state.tiers.indexWhere((r) => r.id == tierId);
    if (idx <= 0) return;
    final list = [...state.tiers];
    final tmp = list[idx - 1];
    list[idx - 1] = list[idx];
    list[idx] = tmp;
    state = state.copyWith(tiers: list);
  }

  void updateTierFontSize(String tierId, double? fontSize) {
    state = state.copyWith(
      tiers: state.tiers
          .map((r) => r.id == tierId
              ? r.copyWith(fontSize: fontSize, clearFontSize: fontSize == null)
              : r)
          .toList(),
    );
  }

  void moveTierDown(String tierId) {
    final idx = state.tiers.indexWhere((r) => r.id == tierId);
    if (idx < 0 || idx >= state.tiers.length - 1) return;
    final list = [...state.tiers];
    final tmp = list[idx + 1];
    list[idx + 1] = list[idx];
    list[idx] = tmp;
    state = state.copyWith(tiers: list);
  }

  TierItem? _findItem(String itemId) {
    for (final row in state.tiers) {
      for (final item in row.items) {
        if (item.id == itemId) return item;
      }
    }
    for (final item in state.pool) {
      if (item.id == itemId) return item;
    }
    for (final fi in state.freeItems) {
      if (fi.item.id == itemId) return fi.item;
    }
    return null;
  }
}

final tierlistProvider =
    StateNotifierProvider<TierlistNotifier, TierlistState>(
  (ref) => TierlistNotifier(),
);
