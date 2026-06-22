import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../providers/app_mode_provider.dart';
import '../widgets/app_mode_toggle.dart';
import '../widgets/create_item_toolbar.dart';
import '../widgets/inspector_panel.dart';
import '../widgets/item_pool_widget.dart';
import '../widgets/tierlist_board.dart';

class TierlistScreen extends ConsumerWidget {
  const TierlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isEdit = mode == AppMode.edit;

    final appBarColor = isEdit
        ? const Color(0xFF1A3A1A)
        : const Color(0xFF3A2A0A);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Tierlist', style: TextStyle(color: Colors.white)),
        actions: [
          if (isEdit) const CreateItemToolbar(),
          const SizedBox(width: 16),
          const AppModeToggle(),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: TierlistBoard(),
          ),
          SizedBox(
            width: 220,
            child: const ItemPoolWidget(),
          ),
          if (isEdit) const InspectorPanel(),
        ],
      ),
    );
  }
}
