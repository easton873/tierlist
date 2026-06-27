import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tier_item.dart';
import '../models/app_mode.dart';
import '../painters/tier_item_painter.dart';
import '../providers/app_mode_provider.dart';
import '../providers/canvas_provider.dart';
import '../providers/selection_provider.dart';

class TierItemWidget extends ConsumerStatefulWidget {
  final TierItem item;
  final double rowHeight;

  const TierItemWidget({
    super.key,
    required this.item,
    required this.rowHeight,
  });

  @override
  ConsumerState<TierItemWidget> createState() => _TierItemWidgetState();
}

class _TierItemWidgetState extends ConsumerState<TierItemWidget> {
  static final Map<String, ui.Image> _imageCache = {};

  ui.Image? _cachedImage;

  @override
  void initState() {
    super.initState();
    _cachedImage = _imageCache[widget.item.id];
    if (_cachedImage == null) _loadImage();
  }

  @override
  void didUpdateWidget(TierItemWidget old) {
    super.didUpdateWidget(old);
    if (old.item.imageBytes != widget.item.imageBytes) {
      _imageCache.remove(widget.item.id);
      _cachedImage = null;
      _loadImage();
    }
  }

  void _loadImage() {
    if (widget.item.imageBytes == null) return;
    ui.decodeImageFromList(widget.item.imageBytes!, (img) {
      _imageCache[widget.item.id] = img;
      if (mounted) setState(() => _cachedImage = img);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final canvasTool = ref.watch(canvasProvider.select((s) => s.tool));
    final selectedId = ref.watch(selectionProvider);
    final isSelected = selectedId == widget.item.id;
    final itemHeight = widget.rowHeight - 2;

    Widget child = _buildItemContent(itemHeight);

    if (isSelected && mode == AppMode.edit) {
      child = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: child,
      );
    }

    // In hand tool mode items are not draggable
    if (canvasTool == CanvasTool.hand) {
      return child;
    }

    final dragData = widget.item;

    if (mode == AppMode.performance) {
      return Draggable<TierItem>(
        data: dragData,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.75, child: _buildItemContent(itemHeight)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildItemContent(itemHeight)),
        child: GestureDetector(child: child),
      );
    } else {
      return LongPressDraggable<TierItem>(
        data: dragData,
        delay: const Duration(milliseconds: 200),
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.75, child: _buildItemContent(itemHeight)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: _buildItemContent(itemHeight)),
        child: GestureDetector(
          onTap: () {
            ref.read(selectionProvider.notifier).state = widget.item.id;
          },
          child: child,
        ),
      );
    }
  }

  Widget _buildItemContent(double itemHeight) {
    if (widget.item.type == TierItemType.image) {
      if (_cachedImage == null) {
        return Container(
          height: itemHeight,
          width: itemHeight,
          color: Colors.grey[800],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      final aspectRatio =
          _cachedImage!.width / _cachedImage!.height;
      final displayWidth = itemHeight * aspectRatio;

      return SizedBox(
        height: itemHeight,
        width: displayWidth,
        child: CustomPaint(
          painter: TierItemPainter(
            image: _cachedImage,
            overlay: widget.item.overlay,
          ),
        ),
      );
    } else {
      // Text item — explicit size so CustomPaint gets proper constraints
      return SizedBox(
        height: itemHeight,
        width: itemHeight * 1.5,
        child: CustomPaint(
          painter: TierItemPainter(overlay: widget.item.overlay),
        ),
      );
    }
  }

}
