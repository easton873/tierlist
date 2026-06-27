import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../models/tier_item.dart';
import '../models/tier_row.dart';
import '../providers/app_mode_provider.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import 'tier_edit_dialog.dart';
import 'tier_item_widget.dart';
import 'tier_label_widget.dart';

class TierRowWidget extends ConsumerWidget {
  final TierRow row;
  final double rowHeight;

  const TierRowWidget({super.key, required this.row, required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(snapProvider);
    final labelGap = ref.watch(layoutSettingsProvider).labelGap;
    final mode = ref.watch(appModeProvider);
    final isEdit = mode == AppMode.edit;

    Widget label = TierLabelWidget(
      label: row.label,
      color: row.labelColor,
      size: rowHeight,
      fontSize: row.fontSize,
      onTap: isEdit ? () => _openEditDialog(context, ref) : null,
    );

    if (isEdit) {
      label = Draggable<TierRow>(
        data: row,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: TierLabelWidget(
              label: row.label,
              color: row.labelColor,
              size: rowHeight,
              fontSize: row.fontSize,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: TierLabelWidget(
            label: row.label,
            color: row.labelColor,
            size: rowHeight,
            fontSize: row.fontSize,
          ),
        ),
        child: label,
      );
    }

    return DragTarget<TierRow>(
      onWillAcceptWithDetails: (details) => details.data.id != row.id,
      onAcceptWithDetails: (details) {
        ref.read(tierlistProvider.notifier).reorderTier(details.data.id, row.id);
      },
      builder: (context, tierCandidates, _) {
        final isReorderTarget = tierCandidates.isNotEmpty;
        return DragTarget<TierItem>(
          onWillAcceptWithDetails: (_) => snap,
          onAcceptWithDetails: (details) {
            ref
                .read(tierlistProvider.notifier)
                .moveItemToTier(details.data.id, row.id, row.items.length);
          },
          builder: (context, itemCandidates, _) {
            final isItemHovered = itemCandidates.isNotEmpty;
            return Stack(
              children: [
                SizedBox(
                  height: rowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      label,
                      SizedBox(width: labelGap),
                      Expanded(
                        child: Container(
                          color: isItemHovered
                              ? const Color(0xFF222522)
                              : const Color(0xFF181B18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                        ),
                      ),
                    ],
                  ),
                ),
                if (isReorderTarget)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(height: 3, color: Colors.blueAccent),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<TierEditResult>(
      context: context,
      builder: (_) => TierEditDialog(row: row),
    );

    if (result == null) return;

    final notifier = ref.read(tierlistProvider.notifier);

    if (result.label != row.label) notifier.renameTier(row.id, result.label);
    if (result.color != row.labelColor) notifier.recolorTier(row.id, result.color);
    if (result.fontSize != row.fontSize) notifier.updateTierFontSize(row.id, result.fontSize);

    if (result.action == TierEditAction.delete) {
      notifier.deleteTier(row.id);
    }
  }
}
