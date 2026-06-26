import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tier_item_widget.dart';

class ItemPoolWidget extends ConsumerWidget {
  final double itemSize;

  const ItemPoolWidget({super.key, required this.itemSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(tierlistProvider).pool;
    final snap = ref.watch(snapProvider);
    final poolPad = ref.watch(layoutSettingsProvider).poolPadding;

    return DragTarget<TierItem>(
      onWillAcceptWithDetails: (_) => snap,
      onAcceptWithDetails: (details) {
        ref
            .read(tierlistProvider.notifier)
            .moveItemToPool(details.data.id);
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(minWidth: 120),
          color: isHovered
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFF121212),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(4, poolPad, poolPad, poolPad),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final item in pool)
                          TierItemWidget(
                            key: ValueKey(item.id),
                            item: item,
                            rowHeight: itemSize,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
