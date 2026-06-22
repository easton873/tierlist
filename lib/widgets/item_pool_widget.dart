import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../providers/tierlist_provider.dart';
import 'tier_item_widget.dart';

class ItemPoolWidget extends ConsumerWidget {
  const ItemPoolWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(tierlistProvider).pool;

    return DragTarget<TierItem>(
      onAcceptWithDetails: (details) {
        ref
            .read(tierlistProvider.notifier)
            .moveItemToPool(details.data.id);
      },
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;
        return Container(
          constraints: const BoxConstraints(minWidth: 120),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[900],
            border: Border(
              left: BorderSide(color: Colors.grey[700]!, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final item in pool)
                          TierItemWidget(
                            key: ValueKey(item.id),
                            item: item,
                            rowHeight: 80,
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
