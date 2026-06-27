import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_clip.dart';
import '../utils/ffmpeg_util.dart';

enum ExportStatus { idle, running, done, error }

class VideoEditorState {
  final List<VideoClip> clips;
  final String? selectedClipId;
  final ExportStatus exportStatus;
  final double exportProgress;
  final String? exportError;
  final String? lastOutputPath;

  const VideoEditorState({
    this.clips = const [],
    this.selectedClipId,
    this.exportStatus = ExportStatus.idle,
    this.exportProgress = 0.0,
    this.exportError,
    this.lastOutputPath,
  });

  VideoEditorState copyWith({
    List<VideoClip>? clips,
    Object? selectedClipId = _sentinel,
    ExportStatus? exportStatus,
    double? exportProgress,
    Object? exportError = _sentinel,
    Object? lastOutputPath = _sentinel,
  }) {
    return VideoEditorState(
      clips: clips ?? this.clips,
      selectedClipId: selectedClipId == _sentinel
          ? this.selectedClipId
          : selectedClipId as String?,
      exportStatus: exportStatus ?? this.exportStatus,
      exportProgress: exportProgress ?? this.exportProgress,
      exportError:
          exportError == _sentinel ? this.exportError : exportError as String?,
      lastOutputPath: lastOutputPath == _sentinel
          ? this.lastOutputPath
          : lastOutputPath as String?,
    );
  }

  VideoClip? get selectedClip =>
      selectedClipId == null
          ? null
          : clips.where((c) => c.id == selectedClipId).firstOrNull;

  double get totalOutputDuration {
    if (clips.isEmpty) return 0;
    double total = clips.fold(0.0, (sum, c) => sum + c.trimmedDuration);
    for (int i = 0; i < clips.length - 1; i++) {
      total -= clips[i].fadeDuration;
    }
    return total.clamp(0.0, double.infinity);
  }
}

const _sentinel = Object();

class VideoEditorNotifier extends StateNotifier<VideoEditorState> {
  VideoEditorNotifier() : super(const VideoEditorState());

  Future<void> addClip(String path) async {
    final name = path.split('/').last;
    final duration = await FfmpegUtil.probeDuration(path);
    final clip = VideoClip.create(
      path: path,
      name: name,
      sourceDuration: duration,
    );
    state = state.copyWith(clips: [...state.clips, clip]);
  }

  void removeClip(String id) {
    final newClips = state.clips.where((c) => c.id != id).toList();
    final newSelected =
        state.selectedClipId == id ? null : state.selectedClipId;
    state = state.copyWith(clips: newClips, selectedClipId: newSelected);
  }

  void reorderClip(int oldIndex, int newIndex) {
    final clips = List<VideoClip>.from(state.clips);
    final clip = clips.removeAt(oldIndex);
    final insertAt = newIndex > oldIndex ? newIndex - 1 : newIndex;
    clips.insert(insertAt, clip);
    state = state.copyWith(clips: clips);
  }

  void selectClip(String? id) {
    state = state.copyWith(selectedClipId: id);
  }

  void updateTrimStart(String id, double v) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == id ? c.copyWith(trimStart: v) : c)
          .toList(),
    );
  }

  void updateTrimEnd(String id, double v) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == id ? c.copyWith(trimEnd: v) : c)
          .toList(),
    );
  }

  void updateFadeDuration(String id, double v) {
    state = state.copyWith(
      clips: state.clips
          .map((c) => c.id == id ? c.copyWith(fadeDuration: v) : c)
          .toList(),
    );
  }

  Future<void> exportVideo(String outputPath) async {
    state = state.copyWith(
      exportStatus: ExportStatus.running,
      exportProgress: 0.0,
      exportError: null,
    );

    final args = await FfmpegUtil.buildArgs(state.clips, outputPath);
    if (args.isEmpty) {
      state = state.copyWith(
        exportStatus: ExportStatus.error,
        exportError: 'No clips to export.',
      );
      return;
    }

    final totalDuration = state.totalOutputDuration;

    // Print command for debugging
    // ignore: avoid_print
    print('ffmpeg ${args.join(' ')}');

    try {
      final process = await Process.start('ffmpeg', args);
      final stderrLines = <String>[];

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            stderrLines.add(line);
            final t = FfmpegUtil.parseProgressTime(line);
            if (t != null && totalDuration > 0) {
              final progress = (t / totalDuration).clamp(0.0, 1.0);
              state = state.copyWith(exportProgress: progress);
            }
          });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        state = state.copyWith(
          exportStatus: ExportStatus.done,
          exportProgress: 1.0,
          lastOutputPath: outputPath,
        );
      } else {
        // Show the last 8 lines of stderr — that's where FFmpeg puts the error
        final tail = stderrLines.reversed.take(8).toList().reversed.join('\n');
        state = state.copyWith(
          exportStatus: ExportStatus.error,
          exportError: 'FFmpeg exited with code $exitCode:\n\n$tail',
        );
      }
    } catch (e) {
      state = state.copyWith(
        exportStatus: ExportStatus.error,
        exportError:
            'Failed to run ffmpeg. Is it installed? (brew install ffmpeg)\n$e',
      );
    }
  }

  void resetExportStatus() {
    state = state.copyWith(exportStatus: ExportStatus.idle);
  }
}

final videoEditorProvider =
    StateNotifierProvider<VideoEditorNotifier, VideoEditorState>(
      (_) => VideoEditorNotifier(),
    );
