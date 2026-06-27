import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CanvasTool { pointer, hand }

class CanvasState {
  final CanvasTool tool;
  final Offset panOffset;

  const CanvasState({
    this.tool = CanvasTool.pointer,
    this.panOffset = Offset.zero,
  });

  CanvasState copyWith({CanvasTool? tool, Offset? panOffset}) => CanvasState(
        tool: tool ?? this.tool,
        panOffset: panOffset ?? this.panOffset,
      );
}

class CanvasNotifier extends StateNotifier<CanvasState> {
  CanvasNotifier() : super(const CanvasState());

  void setTool(CanvasTool tool) {
    state = state.copyWith(tool: tool);
  }

  void pan(Offset delta, {required double maxDown}) {
    final nextY = (state.panOffset.dy + delta.dy).clamp(0.0, maxDown);
    state = state.copyWith(panOffset: Offset(0, nextY));
  }

  void resetPan() {
    state = state.copyWith(panOffset: Offset.zero);
  }
}

final canvasProvider =
    StateNotifierProvider<CanvasNotifier, CanvasState>((ref) => CanvasNotifier());
