import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tierlist_file.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tierlist_io.dart';

abstract class TierlistFileOps {
  static Future<void> export(BuildContext context, WidgetRef ref) async {
    final tierlistState = ref.read(tierlistProvider);
    final layoutSettings = ref.read(layoutSettingsProvider);
    final snap = ref.read(snapProvider);

    final file = TierlistFile.fromState(
      tierlistState: tierlistState,
      layoutSettings: layoutSettings,
      snap: snap,
    );

    await saveTierlistFile(context, file);
  }

  static Future<void> import(BuildContext context, WidgetRef ref) async {
    final file = await loadTierlistFile(context);
    if (file == null) return;

    ref.read(tierlistProvider.notifier).loadFromFile(file.toTierlistState());
    ref.read(layoutSettingsProvider.notifier).loadFromFile(file.layoutSettings);
    ref.read(snapProvider.notifier).update((_) => file.snap);
  }
}
