import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tier_item.dart';
import '../models/text_overlay_config.dart';
import '../providers/tierlist_provider.dart';
import '../utils/image_import_util.dart';

const _uuid = Uuid();

class CreateItemToolbar extends ConsumerWidget {
  const CreateItemToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () => _importImage(ref),
          icon: const Icon(Icons.add_photo_alternate, size: 18),
          label: const Text('Import Image'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _addTextItem(context, ref),
          icon: const Icon(Icons.text_fields, size: 18),
          label: const Text('Add Text'),
        ),
      ],
    );
  }

  Future<void> _importImage(WidgetRef ref) async {
    final item = await pickImageItem();
    if (item != null) {
      ref.read(tierlistProvider.notifier).addItemToPool(item);
    }
  }

  Future<void> _addTextItem(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Text Item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Text'),
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      final item = TierItem(
        id: _uuid.v4(),
        type: TierItemType.text,
        text: controller.text,
        overlay: TextOverlayConfig(text: controller.text),
      );
      ref.read(tierlistProvider.notifier).addItemToPool(item);
    }
    controller.dispose();
  }
}
