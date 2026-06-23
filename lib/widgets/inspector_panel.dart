import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/text_overlay_config.dart';
import '../providers/selection_provider.dart';
import '../providers/tierlist_provider.dart';

const _uuid = Uuid();

class InspectorPanel extends ConsumerStatefulWidget {
  const InspectorPanel({super.key});

  @override
  ConsumerState<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends ConsumerState<InspectorPanel> {
  final _textController = TextEditingController();
  final _fontSizeController = TextEditingController();
  String? _lastSelectedId;

  @override
  void dispose() {
    _textController.dispose();
    _fontSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectionProvider);
    final state = ref.watch(tierlistProvider);

    if (selectedId == null) return _empty();

    final item = [
      ...state.pool,
      ...state.tiers.expand((r) => r.items),
    ].where((i) => i.id == selectedId).firstOrNull;

    if (item == null) return _empty();

    final overlay = item.overlay ?? const TextOverlayConfig(text: '');

    if (selectedId != _lastSelectedId) {
      _lastSelectedId = selectedId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_textController.text != overlay.text) {
          _textController.text = overlay.text;
          _textController.selection =
              TextSelection.collapsed(offset: overlay.text.length);
        }
        final sizeStr = overlay.fontSize.round().toString();
        if (_fontSizeController.text != sizeStr) {
          _fontSizeController.text = sizeStr;
        }
      });
    }

    return Container(
      width: 260,
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF2A2A2A),
            child: const Row(
              children: [
                Icon(Icons.tune, size: 16, color: Colors.white70),
                SizedBox(width: 8),
                Text('Inspector',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.content_copy, size: 15),
                      label: const Text('Duplicate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        ref
                            .read(tierlistProvider.notifier)
                            .addItemToPool(item.copyWith(id: _uuid.v4()));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('Overlay Text'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter text overlay…',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      ref
                          .read(tierlistProvider.notifier)
                          .updateItemOverlay(
                              selectedId, overlay.copyWith(text: val));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Auto-scale checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: overlay.autoScale,
                          onChanged: (val) {
                            ref
                                .read(tierlistProvider.notifier)
                                .updateItemOverlay(selectedId,
                                    overlay.copyWith(autoScale: val ?? true));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Auto-scale text',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),

                  // Font size controls (only when not autoscaling)
                  if (!overlay.autoScale) ...[
                    const SizedBox(height: 12),
                    _label('Font Size'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: overlay.fontSize.clamp(8.0, 200.0),
                            min: 8,
                            max: 200,
                            onChanged: (val) {
                              final rounded = val.roundToDouble();
                              _fontSizeController.text =
                                  rounded.round().toString();
                              ref
                                  .read(tierlistProvider.notifier)
                                  .updateItemOverlay(selectedId,
                                      overlay.copyWith(fontSize: rounded));
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 52,
                          child: TextField(
                            controller: _fontSizeController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF2A2A2A),
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                ref
                                    .read(tierlistProvider.notifier)
                                    .updateItemOverlay(selectedId,
                                        overlay.copyWith(fontSize: parsed));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  _label('Text Color'),
                  const SizedBox(height: 6),
                  _colorButton(context, ref, selectedId, overlay,
                      overlay.textColor,
                      (color) => overlay.copyWith(textColor: color)),
                  const SizedBox(height: 16),
                  _label('Border Color'),
                  const SizedBox(height: 6),
                  _colorButton(context, ref, selectedId, overlay,
                      overlay.borderColor,
                      (color) => overlay.copyWith(borderColor: color)),
                  const SizedBox(height: 16),
                  _label(
                      'Border Width: ${overlay.borderWidth.toStringAsFixed(1)}'),
                  Slider(
                    value: overlay.borderWidth,
                    min: 1,
                    max: 12,
                    divisions: 22,
                    onChanged: (val) {
                      ref
                          .read(tierlistProvider.notifier)
                          .updateItemOverlay(
                              selectedId, overlay.copyWith(borderWidth: val));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      );

  Widget _empty() => Container(
        width: 260,
        color: const Color(0xFF1E1E1E),
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Select an item to edit',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      );

  Widget _colorButton(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    TextOverlayConfig overlay,
    Color currentColor,
    TextOverlayConfig Function(Color) updater,
  ) {
    return GestureDetector(
      onTap: () async {
        Color picked = currentColor;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pick Color'),
            content: ColorPicker(
              color: currentColor,
              onColorChanged: (c) => picked = c,
              pickersEnabled: const {
                ColorPickerType.both: false,
                ColorPickerType.primary: true,
                ColorPickerType.accent: false,
                ColorPickerType.bw: true,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true,
              },
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('OK')),
            ],
          ),
        );
        if (confirmed == true) {
          ref
              .read(tierlistProvider.notifier)
              .updateItemOverlay(itemId, updater(picked));
        }
      },
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }
}
