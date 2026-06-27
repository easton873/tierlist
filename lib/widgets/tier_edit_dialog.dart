import 'dart:typed_data';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tier_row.dart';
import '../utils/image_import_util.dart';

enum TierEditAction { none, delete }

class TierEditResult {
  final String label;
  final Color color;
  final TierEditAction action;
  // null = auto-scale font
  final double? fontSize;
  final Uint8List? backgroundImage;
  final bool clearBackgroundImage;
  final Color? backgroundColor;
  final bool clearBackgroundColor;
  // null = default height (viewport / 6)
  final double? customHeight;
  final bool clearCustomHeight;

  const TierEditResult({
    required this.label,
    required this.color,
    this.action = TierEditAction.none,
    this.fontSize,
    this.backgroundImage,
    this.clearBackgroundImage = false,
    this.backgroundColor,
    this.clearBackgroundColor = false,
    this.customHeight,
    this.clearCustomHeight = false,
  });
}

class TierEditDialog extends StatefulWidget {
  final TierRow row;

  const TierEditDialog({super.key, required this.row});

  @override
  State<TierEditDialog> createState() => _TierEditDialogState();
}

class _TierEditDialogState extends State<TierEditDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _fontSizeController;
  late Color _color;
  double? _fontSize;
  Uint8List? _backgroundImage;
  bool _imageCleared = false;
  Color? _backgroundColor;
  bool _bgColorCleared = false;
  double? _customHeight;
  bool _heightCleared = false;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.row.label);
    _color = widget.row.labelColor;
    _fontSize = widget.row.fontSize;
    _backgroundImage = widget.row.backgroundImage;
    _backgroundColor = widget.row.backgroundColor;
    _customHeight = widget.row.customHeight;
    _fontSizeController = TextEditingController(
      text: _fontSize != null ? _fontSize!.round().toString() : '',
    );
    _heightController = TextEditingController(
      text: _customHeight != null ? _customHeight!.round().toString() : '',
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fontSizeController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  TierEditResult _buildResult({TierEditAction action = TierEditAction.none}) {
    return TierEditResult(
      label: _labelController.text.isEmpty ? widget.row.label : _labelController.text,
      color: _color,
      fontSize: _fontSize,
      action: action,
      backgroundImage: _backgroundImage != widget.row.backgroundImage ? _backgroundImage : null,
      clearBackgroundImage: _imageCleared,
      backgroundColor: _backgroundColor != widget.row.backgroundColor ? _backgroundColor : null,
      clearBackgroundColor: _bgColorCleared,
      customHeight: _customHeight,
      clearCustomHeight: _heightCleared,
    );
  }

  void _submit() => Navigator.pop(context, _buildResult());

  Future<void> _pickColor() async {
    Color picked = _color;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick Color'),
        content: ColorPicker(
          color: _color,
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
        ],
      ),
    );
    if (confirmed == true) setState(() => _color = picked);
  }

  Future<void> _pickBackgroundImage() async {
    final bytes = await pickImageBytes();
    if (bytes != null) {
      setState(() {
        _backgroundImage = bytes;
        _imageCleared = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final itemCount = widget.row.items.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tier?'),
        content: Text(
          itemCount > 0
              ? '$itemCount item(s) in this tier will be returned to the pool.'
              : 'This tier is empty.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red[300])),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, _buildResult(action: TierEditAction.delete));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFullWidthRow = _backgroundImage != null || _backgroundColor != null;

    return AlertDialog(
      title: const Text('Edit Tier'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Background image section
              const Text('Background Image', style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              if (_backgroundImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    _backgroundImage!,
                    height: 60,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _pickBackgroundImage,
                      child: const Text('Replace'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _backgroundImage = null;
                        _imageCleared = true;
                      }),
                      child: Text('Remove', style: TextStyle(color: Colors.red[300])),
                    ),
                  ],
                ),
              ] else if (_backgroundColor != null) ...[
                // Blank row — show color swatch with picker
                GestureDetector(
                  onTap: () async {
                    Color picked = _backgroundColor!;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Pick Color'),
                        content: ColorPicker(
                          color: _backgroundColor!,
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
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
                        ],
                      ),
                    );
                    if (confirmed == true) setState(() => _backgroundColor = picked);
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Use Image Instead'),
                  onPressed: _pickBackgroundImage,
                ),
              ] else ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Upload Image'),
                  onPressed: _pickBackgroundImage,
                ),
              ],

              // Label and color only shown for normal (non-full-width) rows
              if (!isFullWidthRow) ...[
                const SizedBox(height: 16),
                const Text('Label', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                TextField(
                  controller: _labelController,
                  autofocus: !isFullWidthRow,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                const Text('Label Color', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickColor,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Font Size', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    const Spacer(),
                    TextButton(
                      onPressed: _fontSize != null
                          ? () => setState(() {
                                _fontSize = null;
                                _fontSizeController.clear();
                              })
                          : null,
                      child: const Text('Auto', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: (_fontSize ?? 20).clamp(8.0, 120.0),
                        min: 8,
                        max: 120,
                        divisions: 112,
                        onChanged: (val) => setState(() {
                          _fontSize = val.roundToDouble();
                          _fontSizeController.text = _fontSize!.round().toString();
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: TextField(
                        controller: _fontSizeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 1) {
                            setState(() => _fontSize = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Row Height', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const Spacer(),
                  TextButton(
                    onPressed: _customHeight != null
                        ? () => setState(() {
                              _customHeight = null;
                              _heightCleared = true;
                              _heightController.clear();
                            })
                        : null,
                    child: const Text('Default', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: (_customHeight ?? 100).clamp(30.0, 400.0),
                      min: 30,
                      max: 400,
                      divisions: 370,
                      onChanged: (val) => setState(() {
                        _customHeight = val.roundToDouble();
                        _heightCleared = false;
                        _heightController.text = _customHeight!.round().toString();
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        suffixText: 'px',
                        suffixStyle: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onChanged: (val) {
                        final parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 1) {
                          setState(() {
                            _customHeight = parsed.clamp(30, double.infinity);
                            _heightCleared = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                  label: Text('Delete tier', style: TextStyle(color: Colors.red[300])),
                  onPressed: _confirmDelete,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
