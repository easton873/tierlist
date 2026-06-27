import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../providers/video_editor_provider.dart';

class VideoPreviewWidget extends ConsumerStatefulWidget {
  const VideoPreviewWidget({super.key});

  @override
  ConsumerState<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends ConsumerState<VideoPreviewWidget> {
  VideoPlayerController? _controller;
  String? _loadedClipId;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadClip(String clipId, String path, double trimStart) async {
    if (_loadedClipId == clipId) return;
    _loadedClipId = clipId;

    final old = _controller;
    _controller = null;
    _isPlaying = false;

    await old?.dispose();

    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    await controller.seekTo(Duration(milliseconds: (trimStart * 1000).round()));
    controller.addListener(_onPlaybackUpdate);

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    } else {
      await controller.dispose();
    }
  }

  void _onPlaybackUpdate() {
    if (_controller == null) return;
    final playing = _controller!.value.isPlaying;
    if (playing != _isPlaying && mounted) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = ref.watch(videoEditorProvider.select((s) => s.selectedClip));

    if (clip != null) {
      _loadClip(clip.id, clip.path, clip.trimStart);
    } else if (_loadedClipId != null) {
      _loadedClipId = null;
      _controller?.dispose();
      _controller = null;
    }

    if (clip == null || _controller == null) {
      return const Center(
        child: Text(
          'Select a clip to preview',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
      );
    }

    final c = _controller!;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
        ),
        Container(
          color: const Color(0xFF1E1E1E),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.lightBlue,
                  bufferedColor: Color(0xFF2A3A4A),
                  backgroundColor: Color(0xFF2A2A2A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white70),
                    onPressed: () {
                      final pos = c.value.position;
                      c.seekTo(pos - const Duration(seconds: 10));
                    },
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white70),
                    onPressed: () {
                      final pos = c.value.position;
                      c.seekTo(pos + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
