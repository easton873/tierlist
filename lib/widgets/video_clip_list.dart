import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/video_editor_provider.dart';

class VideoClipList extends ConsumerWidget {
  const VideoClipList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clips = ref.watch(videoEditorProvider.select((s) => s.clips));
    final selectedId =
        ref.watch(videoEditorProvider.select((s) => s.selectedClipId));
    final notifier = ref.read(videoEditorProvider.notifier);

    return Container(
      width: 240,
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.video_library_outlined,
                    size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                const Text(
                  'Clips',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${clips.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Expanded(
            child: clips.isEmpty
                ? const Center(
                    child: Text(
                      'No clips yet',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: clips.length,
                    onReorder: notifier.reorderClip,
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, i) {
                      final clip = clips[i];
                      final selected = clip.id == selectedId;
                      return ReorderableDragStartListener(
                        key: ValueKey(clip.id),
                        index: i,
                        child: _ClipTile(
                          name: clip.name,
                          duration: clip.trimmedDuration,
                          selected: selected,
                          onTap: () => notifier.selectClip(clip.id),
                          onDelete: () => notifier.removeClip(clip.id),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2A2A)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Clip'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
                onPressed: () => _addClip(context, notifier),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addClip(
    BuildContext context,
    VideoEditorNotifier notifier,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'mkv', 'm4v', 'avi'],
      allowMultiple: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      if (file.path != null) {
        await notifier.addClip(file.path!);
      }
    }
  }
}

class _ClipTile extends StatelessWidget {
  final String name;
  final double duration;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClipTile({
    required this.name,
    required this.duration,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDuration(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFF1A2A3A) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.video_file_outlined,
              size: 16,
              color: selected ? Colors.lightBlue : Colors.white54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
