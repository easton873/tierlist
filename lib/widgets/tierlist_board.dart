import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tier_row_widget.dart';

class TierlistBoard extends ConsumerStatefulWidget {
  const TierlistBoard({super.key});

  @override
  ConsumerState<TierlistBoard> createState() => _TierlistBoardState();
}

class _TierlistBoardState extends ConsumerState<TierlistBoard> {
  final _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tiers = ref.watch(tierlistProvider).tiers;
    final snap = ref.watch(snapProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const vPad = 50.0;
        const hPad = 12.0;
        const rowGap = 32.0;
        final rowHeight =
            (constraints.maxHeight - vPad * 2 - rowGap * (tiers.length - 1)) /
            tiers.length;

        return DragTarget<TierItem>(
          // Only accepts drops when snap is OFF (tier rows reject in that mode)
          onWillAcceptWithDetails: (_) => !snap,
          onAcceptWithDetails: (details) {
            final rb =
                _stackKey.currentContext?.findRenderObject() as RenderBox?;
            final localPos = rb != null
                ? rb.globalToLocal(details.offset)
                : details.offset;
            ref
                .read(tierlistProvider.notifier)
                .placeFreeItem(details.data, localPos);
          },
          builder: (context, candidates, rejected) {
            return Stack(
              key: _stackKey,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(vPad, vPad, hPad, vPad),
                  child: Column(
                    spacing: rowGap,
                    children: [
                      for (final row in tiers)
                        TierRowWidget(
                          key: ValueKey(row.id),
                          row: row,
                          rowHeight: rowHeight,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
