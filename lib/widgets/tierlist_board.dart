import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../providers/app_mode_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/tierlist_provider.dart';
import '../utils/image_import_util.dart';
import 'tier_row_widget.dart';

class TierlistBoard extends ConsumerStatefulWidget {
  const TierlistBoard({super.key});

  @override
  ConsumerState<TierlistBoard> createState() => _TierlistBoardState();
}

class _TierlistBoardState extends ConsumerState<TierlistBoard> {
  @override
  Widget build(BuildContext context) {
    final tiers = ref.watch(tierlistProvider).tiers;
    final s = ref.watch(layoutSettingsProvider);
    final canvasState = ref.watch(canvasProvider);
    final isHand = canvasState.tool == CanvasTool.hand;
    final panOffset = canvasState.panOffset;

    return LayoutBuilder(
      builder: (context, constraints) {
        const hPad = 12.0;
        const baseRowCount = 6;

        final autoRowHeight = (constraints.maxHeight -
                s.boardTopPad -
                s.boardBottomPad -
                s.rowGap * (baseRowCount - 1)) /
            baseRowCount;
        final rowHeight = s.defaultRowHeight ?? autoRowHeight;

        // Each row uses its custom height if set, otherwise the calculated default
        double effectiveHeight(row) => row.customHeight ?? rowHeight;

        final tierContentHeight = tiers.fold(0.0, (sum, r) => sum + effectiveHeight(r)) +
            s.rowGap * max(0, tiers.length - 1);
        final totalContentHeight = s.boardTopPad +
            s.boardBottomPad +
            tierContentHeight +
            s.rowGap +
            rowHeight; // for the add-tier button row
        final maxDown =
            (totalContentHeight - constraints.maxHeight).clamp(0.0, double.infinity);

        Widget content = Padding(
          // boardLeftPad is now applied per-row so image rows can go edge-to-edge
          padding: EdgeInsets.fromLTRB(0, s.boardTopPad, hPad, s.boardBottomPad),
          child: Column(
            spacing: s.rowGap,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in tiers)
                TierRowWidget(
                  key: ValueKey(row.id),
                  row: row,
                  rowHeight: effectiveHeight(row),
                  leftPad: row.isFullWidthRow ? 0.0 : s.boardLeftPad,
                ),
              _AddTierButton(rowHeight: rowHeight),
            ],
          ),
        );

        Widget clipped = ClipRect(
          child: OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(0, -panOffset.dy),
              child: content,
            ),
          ),
        );

        if (isHand) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              ref.read(canvasProvider.notifier).pan(
                    Offset(0, -details.delta.dy),
                    maxDown: maxDown,
                  );
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: clipped,
            ),
          );
        }

        return clipped;
      },
    );
  }
}

enum _AddTierType { normal, image, blank }

class _AddTierButton extends ConsumerWidget {
  final double rowHeight;
  const _AddTierButton({required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = ref.watch(appModeProvider) == AppMode.edit;
    if (!isEdit) return const SizedBox.shrink();

    final s = ref.watch(layoutSettingsProvider);

    return SizedBox(
      height: rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: s.boardLeftPad),
          child: SizedBox(
            width: rowHeight,
            height: rowHeight,
            child: PopupMenuButton<_AddTierType>(
              tooltip: 'Add tier',
              offset: const Offset(0, 4),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _AddTierType.normal,
                  child: Text('Normal Tier'),
                ),
                PopupMenuItem(
                  value: _AddTierType.image,
                  child: Text('Image Tier'),
                ),
                PopupMenuItem(
                  value: _AddTierType.blank,
                  child: Text('Blank Row'),
                ),
              ],
              onSelected: (type) async {
                final notifier = ref.read(tierlistProvider.notifier);
                switch (type) {
                  case _AddTierType.normal:
                    notifier.addTier();
                  case _AddTierType.image:
                    final bytes = await pickImageBytes();
                    if (bytes != null) notifier.addImageTier(bytes);
                  case _AddTierType.blank:
                    notifier.addBlankTier();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white54, size: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
