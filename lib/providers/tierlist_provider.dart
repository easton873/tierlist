import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../models/tier_row.dart';
import '../models/text_overlay_config.dart';
import '../utils/default_tiers.dart';

class TierlistState {
  final List<TierRow> tiers;
  final List<TierItem> pool;

  const TierlistState({required this.tiers, required this.pool});

  TierlistState copyWith({List<TierRow>? tiers, List<TierItem>? pool}) {
    return TierlistState(
      tiers: tiers ?? this.tiers,
      pool: pool ?? this.pool,
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
      // Remove from any tier it currently occupies
      final withoutItem = row.items.where((i) => i.id != itemId).toList();
      if (row.id == tierRowId) {
        final clamped = insertIndex.clamp(0, withoutItem.length);
        final newItems = [...withoutItem]..insert(clamped, item);
        return row.copyWith(items: newItems);
      }
      return row.copyWith(items: withoutItem);
    }).toList();

    final newPool = state.pool.where((i) => i.id != itemId).toList();
    state = state.copyWith(tiers: newTiers, pool: newPool);
  }

  void moveItemToPool(String itemId) {
    final item = _findItem(itemId);
    if (item == null) return;

    final newTiers = state.tiers
        .map((row) => row.copyWith(
              items: row.items.where((i) => i.id != itemId).toList(),
            ))
        .toList();

    if (!state.pool.any((i) => i.id == itemId)) {
      state = state.copyWith(tiers: newTiers, pool: [...state.pool, item]);
    } else {
      state = state.copyWith(tiers: newTiers);
    }
  }

  void updateItemOverlay(String itemId, TextOverlayConfig? overlay) {
    state = state.copyWith(
      tiers: state.tiers.map((row) {
        return row.copyWith(
          items: row.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(
                overlay: overlay,
                clearOverlay: overlay == null,
              );
            }
            return item;
          }).toList(),
        );
      }).toList(),
      pool: state.pool.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            overlay: overlay,
            clearOverlay: overlay == null,
          );
        }
        return item;
      }).toList(),
    );
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
    return null;
  }

  double rowHeightFor(String tierRowId) {
    return state.tiers
        .firstWhere((r) => r.id == tierRowId,
            orElse: () => state.tiers.first)
        .rowHeight;
  }
}

final tierlistProvider =
    StateNotifierProvider<TierlistNotifier, TierlistState>(
  (ref) => TierlistNotifier(),
);
