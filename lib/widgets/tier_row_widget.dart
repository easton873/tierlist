import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../models/tier_row.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tier_item_widget.dart';
import 'tier_label_widget.dart';

class TierRowWidget extends ConsumerWidget {
  final TierRow row;
  final double rowHeight;

  const TierRowWidget({super.key, required this.row, required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(snapProvider);

    return DragTarget<TierItem>(
      onWillAcceptWithDetails: (_) => snap,
      onAcceptWithDetails: (details) {
        final insertIndex = _computeInsertIndex(context, details.offset, row);
        ref
            .read(tierlistProvider.notifier)
            .moveItemToTier(details.data.id, row.id, insertIndex);
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return Container(
          height: rowHeight,
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: Colors.grey[800]!, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TierLabelWidget(
                  label: row.label, color: row.labelColor, size: rowHeight),
              Container(width: 1, color: Colors.grey[800]),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in row.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: TierItemWidget(
                            key: ValueKey(item.id),
                            item: item,
                            rowHeight: rowHeight,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _computeInsertIndex(
      BuildContext context, Offset dropOffset, TierRow row) {
    // Simple heuristic: count items whose center X is left of drop X.
    // Since we don't have exact render positions here, default to end.
    return row.items.length;
  }
}
