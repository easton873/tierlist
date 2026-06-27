import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../providers/app_mode_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/tierlist_provider.dart';
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

        final rowHeight = (constraints.maxHeight -
                s.boardTopPad -
                s.boardBottomPad -
                s.rowGap * (baseRowCount - 1)) /
            baseRowCount;

        final tierContentHeight = rowHeight * tiers.length +
            s.rowGap * max(0, tiers.length - 1);
        final totalContentHeight = s.boardTopPad +
            s.boardBottomPad +
            tierContentHeight +
            s.rowGap +
            rowHeight; // for the add-tier button row
        final maxDown =
            (totalContentHeight - constraints.maxHeight).clamp(0.0, double.infinity);

        Widget content = Padding(
          padding: EdgeInsets.fromLTRB(
              s.boardLeftPad, s.boardTopPad, hPad, s.boardBottomPad),
          child: Column(
            spacing: s.rowGap,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in tiers)
                TierRowWidget(
                  key: ValueKey(row.id),
                  row: row,
                  rowHeight: rowHeight,
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
              // dragging down (positive delta.dy) pans canvas up (reveals content below)
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

class _AddTierButton extends ConsumerWidget {
  final double rowHeight;
  const _AddTierButton({required this.rowHeight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = ref.watch(appModeProvider) == AppMode.edit;
    if (!isEdit) return const SizedBox.shrink();

    return SizedBox(
      height: rowHeight,
      child: Center(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Tier'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white24),
          ),
          onPressed: () => ref.read(tierlistProvider.notifier).addTier(),
        ),
      ),
    );
  }
}
