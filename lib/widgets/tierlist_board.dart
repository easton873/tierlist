import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tier_row_widget.dart';

class TierlistBoard extends ConsumerWidget {
  const TierlistBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(tierlistProvider).tiers;
    final s = ref.watch(layoutSettingsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const hPad = 12.0;
        final rowHeight =
            (constraints.maxHeight - s.boardTopPad - s.boardBottomPad -
                s.rowGap * (tiers.length - 1)) /
            tiers.length;

        return Padding(
          padding: EdgeInsets.fromLTRB(
              s.boardLeftPad, s.boardTopPad, hPad, s.boardBottomPad),
          child: Column(
            spacing: s.rowGap,
            children: [
              for (final row in tiers)
                TierRowWidget(
                  key: ValueKey(row.id),
                  row: row,
                  rowHeight: rowHeight,
                ),
            ],
          ),
        );
      },
    );
  }
}
