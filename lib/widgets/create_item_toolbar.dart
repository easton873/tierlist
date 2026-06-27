import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/tier_item.dart';
import '../utils/tierlist_file_ops.dart';
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
          onPressed: () => TierlistFileOps.export(context, ref),
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Export'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => TierlistFileOps.import(context, ref),
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Import'),
        ),
        const SizedBox(width: 8),
        _ImportImageButton(onItemPicked: (item) {
          ref.read(tierlistProvider.notifier).addItemToPool(item);
        }),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _addTextItem(context, ref),
          icon: const Icon(Icons.text_fields, size: 18),
          label: const Text('Add Text'),
        ),
      ],
    );
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

enum _ImageSource { file, clipboard }

class _ImportImageButton extends StatelessWidget {
  const _ImportImageButton({required this.onItemPicked});

  final void Function(TierItem item) onItemPicked;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ImageSource>(
      tooltip: '',
      onSelected: (source) => _handle(context, source),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ImageSource.file,
          child: ListTile(
            leading: Icon(Icons.folder_open, size: 18),
            title: Text('From File'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: _ImageSource.clipboard,
          child: ListTile(
            leading: Icon(Icons.content_paste, size: 18),
            title: Text('From Clipboard'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate, size: 18),
            SizedBox(width: 6),
            Text('Import Image'),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handle(BuildContext context, _ImageSource source) async {
    final TierItem? item;
    if (source == _ImageSource.file) {
      item = await pickImageItem();
    } else {
      item = await clipboardImageItem();
      if (item == null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image found on clipboard')),
        );
      }
    }
    if (item != null) onItemPicked(item);
  }
}
