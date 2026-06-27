import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_editor_provider.dart';

class VideoClipInspector extends ConsumerStatefulWidget {
  const VideoClipInspector({super.key});

  @override
  ConsumerState<VideoClipInspector> createState() =>
      _VideoClipInspectorState();
}

class _VideoClipInspectorState extends ConsumerState<VideoClipInspector> {
  final _trimStartController = TextEditingController();
  final _trimEndController = TextEditingController();
  final _fadeDurationController = TextEditingController();
  String? _lastClipId;

  @override
  void dispose() {
    _trimStartController.dispose();
    _trimEndController.dispose();
    _fadeDurationController.dispose();
    super.dispose();
  }

  void _syncControllers(VideoEditorState state) {
    final clip = state.selectedClip;
    if (clip == null) return;
    if (clip.id == _lastClipId) return;
    _lastClipId = clip.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trimStartController.text = clip.trimStart.toStringAsFixed(2);
      _trimEndController.text = clip.trimEnd.toStringAsFixed(2);
      _fadeDurationController.text = clip.fadeDuration.toStringAsFixed(2);
    });
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      );

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required TextEditingController controller,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  activeTrackColor: Colors.lightBlue,
                  inactiveTrackColor: const Color(0xFF2A2A2A),
                  thumbColor: Colors.lightBlue,
                  overlayColor: Colors.lightBlue.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max == min ? min + 0.001 : max,
                  onChanged: (v) {
                    onChanged(v);
                    controller.text = v.toStringAsFixed(2);
                  },
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  filled: true,
                  fillColor: Color(0xFF2A2A2A),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                onSubmitted: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) {
                    onChanged(parsed.clamp(min, max));
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(videoEditorProvider);
    _syncControllers(editorState);
    final clip = editorState.selectedClip;
    final notifier = ref.read(videoEditorProvider.notifier);

    return Container(
      width: 280,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                const Text(
                  'Inspector',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Expanded(
            child: clip == null
                ? const Center(
                    child: Text(
                      'Select a clip to edit',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('FILE'),
                        Text(
                          clip.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        _sliderRow(
                          label: 'TRIM START (s)',
                          value: clip.trimStart,
                          min: 0,
                          max: clip.trimEnd,
                          controller: _trimStartController,
                          onChanged: (v) =>
                              notifier.updateTrimStart(clip.id, v),
                        ),
                        _sliderRow(
                          label: 'TRIM END (s)',
                          value: clip.trimEnd,
                          min: clip.trimStart,
                          max: clip.sourceDuration,
                          controller: _trimEndController,
                          onChanged: (v) =>
                              notifier.updateTrimEnd(clip.id, v),
                        ),
                        const Divider(
                            height: 1,
                            color: Color(0xFF2A2A2A),
                            thickness: 1),
                        const SizedBox(height: 12),
                        _sliderRow(
                          label: 'FADE DURATION (s)',
                          value: clip.fadeDuration,
                          min: 0.0,
                          max: 5.0,
                          controller: _fadeDurationController,
                          onChanged: (v) =>
                              notifier.updateFadeDuration(clip.id, v),
                        ),
                        Text(
                          'Trimmed: ${clip.trimmedDuration.toStringAsFixed(2)}s',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
