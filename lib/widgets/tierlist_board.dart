import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tierlist_provider.dart';
import 'tier_row_widget.dart';

class TierlistBoard extends ConsumerWidget {
  const TierlistBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(tierlistProvider).tiers;

    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 12.0;
        final rowHeight =
            (constraints.maxHeight - verticalPadding * 2) / tiers.length;

        return Padding(
          padding: const EdgeInsets.symmetric(
              vertical: verticalPadding, horizontal: verticalPadding),
          child: Column(
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
