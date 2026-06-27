import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_editor_provider.dart';
import '../widgets/video_clip_list.dart';
import '../widgets/video_clip_inspector.dart';
import '../widgets/video_preview_widget.dart';

class VideoEditorScreen extends ConsumerWidget {
  const VideoEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportStatus =
        ref.watch(videoEditorProvider.select((s) => s.exportStatus));
    final exportProgress =
        ref.watch(videoEditorProvider.select((s) => s.exportProgress));
    final isExporting = exportStatus == ExportStatus.running;

    ref.listen<VideoEditorState>(videoEditorProvider, (prev, next) {
      if (prev?.exportStatus == ExportStatus.running) {
        if (next.exportStatus == ExportStatus.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Exported to: ${next.lastOutputPath ?? "unknown"}'),
              backgroundColor: Colors.green.shade800,
              duration: const Duration(seconds: 6),
            ),
          );
        } else if (next.exportStatus == ExportStatus.error) {
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text('Export Failed',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: SelectableText(
                    next.exportError ?? 'Unknown error',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace'),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: const Color(0xFF1A2A3A),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Video Editor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Export...'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isExporting ? Colors.white38 : Colors.white70,
                  ),
                  onPressed: isExporting
                      ? null
                      : () => _handleExport(context, ref),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const VideoClipList(),
                const VerticalDivider(
                    width: 1, color: Color(0xFF2A2A2A), thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      const Expanded(child: VideoPreviewWidget()),
                      if (isExporting)
                        Container(
                          color: const Color(0xFF1E1E1E),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: exportProgress,
                                backgroundColor: const Color(0xFF2A2A2A),
                                color: Colors.lightBlue,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Exporting… ${(exportProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(
                    width: 1, color: Color(0xFF2A2A2A), thickness: 1),
                const VideoClipInspector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    final clips = ref.read(videoEditorProvider).clips;
    if (clips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one clip before exporting.')),
      );
      return;
    }

    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Video',
      fileName: 'output.mp4',
      allowedExtensions: ['mp4'],
      type: FileType.custom,
    );
    if (outputPath == null) return;
    if (!outputPath.endsWith('.mp4')) outputPath += '.mp4';

    await ref.read(videoEditorProvider.notifier).exportVideo(outputPath);
  }
}
