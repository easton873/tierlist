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
  final double leftPad;

  const TierRowWidget({
    super.key,
    required this.row,
    required this.rowHeight,
    required this.leftPad,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isEdit = mode == AppMode.edit;

    return row.isFullWidthRow
        ? _buildFullWidthRow(context, ref, isEdit)
        : _buildNormalRow(context, ref, isEdit);
  }

  // ── Full-width row (image or solid color) ────────────────────────────────

  Widget _buildFullWidthRow(BuildContext context, WidgetRef ref, bool isEdit) {
    final snap = ref.watch(snapProvider);

    BoxDecoration decoration;
    if (row.backgroundImage != null) {
      decoration = BoxDecoration(
        image: DecorationImage(
          image: MemoryImage(row.backgroundImage!),
          fit: BoxFit.fill,
        ),
      );
    } else {
      decoration = BoxDecoration(color: row.backgroundColor);
    }

    Widget imageContent = Container(
      height: rowHeight,
      decoration: decoration,
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
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
    );

    // Wrap in left padding
    Widget content = Padding(
      padding: EdgeInsets.only(left: leftPad),
      child: imageContent,
    );

    // Edit-mode pencil overlay
    if (isEdit) {
      content = Stack(
        children: [
          content,
          Positioned(
            top: 4,
            left: leftPad + 4,
            child: GestureDetector(
              onTap: () => _openEditDialog(context, ref),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    // Drag-to-reorder wrapper (edit mode)
    if (isEdit) {
      content = Draggable<TierRow>(
        data: row,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(
              width: 300,
              height: rowHeight,
              child: Container(decoration: decoration),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        child: content,
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
          builder: (context, candidate, rejected) {
            return Stack(
              children: [
                content,
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

  // ── Normal (label-based) row ─────────────────────────────────────────────

  Widget _buildNormalRow(BuildContext context, WidgetRef ref, bool isEdit) {
    final snap = ref.watch(snapProvider);
    final labelGap = ref.watch(layoutSettingsProvider).labelGap;

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
                Padding(
                  padding: EdgeInsets.only(left: leftPad),
                  child: SizedBox(
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

    if (result.clearBackgroundImage) {
      notifier.updateTierBackgroundImage(row.id, null);
    } else if (result.backgroundImage != null) {
      notifier.updateTierBackgroundImage(row.id, result.backgroundImage);
    }

    if (result.clearBackgroundColor) {
      notifier.updateTierBackgroundColor(row.id, null);
    } else if (result.backgroundColor != null && result.backgroundColor != row.backgroundColor) {
      notifier.updateTierBackgroundColor(row.id, result.backgroundColor);
    }

    if (result.clearCustomHeight) {
      notifier.updateTierHeight(row.id, null);
    } else if (result.customHeight != null && result.customHeight != row.customHeight) {
      notifier.updateTierHeight(row.id, result.customHeight);
    }

    if (result.action == TierEditAction.delete) {
      notifier.deleteTier(row.id);
    }
  }
}
