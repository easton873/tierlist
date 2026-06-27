import '../models/free_item.dart';
import '../models/tier_row.dart';
import '../models/tier_item.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/tierlist_provider.dart';
import '../utils/tierlist_migration.dart';

class TierlistFile {
  final int version;
  final List<TierRow> tiers;
  final List<TierItem> pool;
  final List<FreeItem> freeItems;
  final LayoutSettings layoutSettings;
  final bool snap;

  const TierlistFile({
    required this.version,
    required this.tiers,
    required this.pool,
    required this.freeItems,
    required this.layoutSettings,
    required this.snap,
  });

  factory TierlistFile.fromState({
    required TierlistState tierlistState,
    required LayoutSettings layoutSettings,
    required bool snap,
  }) {
    return TierlistFile(
      version: currentTierlistVersion,
      tiers: tierlistState.tiers,
      pool: tierlistState.pool,
      freeItems: tierlistState.freeItems,
      layoutSettings: layoutSettings,
      snap: snap,
    );
  }

  static TierlistFile fromJson(Map<String, dynamic> raw) {
    final json = migrateTierlistJson(raw);
    return TierlistFile(
      version: json['version'] as int,
      tiers: (json['tiers'] as List<dynamic>)
          .map((e) => TierRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      pool: (json['pool'] as List<dynamic>)
          .map((e) => TierItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      freeItems: (json['freeItems'] as List<dynamic>)
          .map((e) => FreeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      layoutSettings: LayoutSettings.fromJson(
          json['layoutSettings'] as Map<String, dynamic>),
      snap: json['snap'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'tiers': tiers.map((r) => r.toJson()).toList(),
        'pool': pool.map((i) => i.toJson()).toList(),
        'freeItems': freeItems.map((f) => f.toJson()).toList(),
        'layoutSettings': layoutSettings.toJson(),
        'snap': snap,
      };

  TierlistState toTierlistState() => TierlistState(
        tiers: tiers,
        pool: pool,
        freeItems: freeItems,
      );
}
