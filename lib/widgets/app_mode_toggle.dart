import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../providers/app_mode_provider.dart';

class AppModeToggle extends ConsumerWidget {
  const AppModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);

    return SegmentedButton<AppMode>(
      segments: const [
        ButtonSegment(
          value: AppMode.edit,
          label: Text('Edit'),
          icon: Icon(Icons.edit, size: 16),
        ),
        ButtonSegment(
          value: AppMode.performance,
          label: Text('Perform'),
          icon: Icon(Icons.videocam, size: 16),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selected) {
        ref.read(appModeProvider.notifier).state = selected.first;
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
