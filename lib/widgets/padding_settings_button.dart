import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/layout_settings_provider.dart';

class PaddingSettingsButton extends ConsumerStatefulWidget {
  const PaddingSettingsButton({super.key});

  @override
  ConsumerState<PaddingSettingsButton> createState() =>
      _PaddingSettingsButtonState();
}

class _PaddingSettingsButtonState extends ConsumerState<PaddingSettingsButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _open() {
    _overlayEntry = OverlayEntry(
      builder: (_) => _LayoutPanel(
        layerLink: _layerLink,
        onClose: _close,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _close() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggle() {
    if (_overlayEntry != null) {
      _close();
    } else {
      _open();
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Tooltip(
        message: 'Layout',
        child: IconButton(
          icon: const Icon(Icons.tune, size: 20, color: Colors.white),
          onPressed: _toggle,
        ),
      ),
    );
  }
}

class _LayoutPanel extends ConsumerStatefulWidget {
  final LayerLink layerLink;
  final VoidCallback onClose;

  const _LayoutPanel({
    required this.layerLink,
    required this.onClose,
  });

  @override
  ConsumerState<_LayoutPanel> createState() => _LayoutPanelState();
}

class _LayoutPanelState extends ConsumerState<_LayoutPanel> {
  late final Map<String, TextEditingController> _controllers;
  late final TextEditingController _defaultHeightController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(layoutSettingsProvider);
    _controllers = {
      'boardTopPad': TextEditingController(text: _fmt(s.boardTopPad)),
      'boardBottomPad': TextEditingController(text: _fmt(s.boardBottomPad)),
      'boardLeftPad': TextEditingController(text: _fmt(s.boardLeftPad)),
      'rowGap': TextEditingController(text: _fmt(s.rowGap)),
      'labelGap': TextEditingController(text: _fmt(s.labelGap)),
      'poolPadding': TextEditingController(text: _fmt(s.poolPadding)),
    };
    _defaultHeightController = TextEditingController(
      text: s.defaultRowHeight != null ? _fmt(s.defaultRowHeight!) : '',
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) { c.dispose(); }
    _defaultHeightController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _set(String field, double value) {
    ref.read(layoutSettingsProvider.notifier).update((s) {
      switch (field) {
        case 'boardTopPad': return s.copyWith(boardTopPad: value);
        case 'boardBottomPad': return s.copyWith(boardBottomPad: value);
        case 'boardLeftPad': return s.copyWith(boardLeftPad: value);
        case 'rowGap': return s.copyWith(rowGap: value);
        case 'labelGap': return s.copyWith(labelGap: value);
        case 'poolPadding': return s.copyWith(poolPadding: value);
        default: return s;
      }
    });
    _controllers[field]?.text = _fmt(value);
  }

  void _onTextSubmit(String field, String text, double max) {
    final parsed = double.tryParse(text);
    if (parsed == null) {
      final current = _currentValue(field);
      _controllers[field]?.text = _fmt(current);
      return;
    }
    final clamped = parsed.clamp(0.0, max);
    _set(field, clamped);
  }

  double _currentValue(String field) {
    final s = ref.read(layoutSettingsProvider);
    switch (field) {
      case 'boardTopPad': return s.boardTopPad;
      case 'boardBottomPad': return s.boardBottomPad;
      case 'boardLeftPad': return s.boardLeftPad;
      case 'rowGap': return s.rowGap;
      case 'labelGap': return s.labelGap;
      case 'poolPadding': return s.poolPadding;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(layoutSettingsProvider);
    final hasCustomHeight = s.defaultRowHeight != null;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onClose,
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: Card(
              color: const Color(0xFF1E1E1E),
              elevation: 8,
              child: SizedBox(
                width: 360,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Layout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: const Icon(Icons.close, size: 16, color: Colors.white54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _row('Top padding', 'boardTopPad', s.boardTopPad, 120),
                      _row('Bottom padding', 'boardBottomPad', s.boardBottomPad, 120),
                      _row('Left padding', 'boardLeftPad', s.boardLeftPad, 120),
                      _row('Row gap', 'rowGap', s.rowGap, 80),
                      _row('Label gap', 'labelGap', s.labelGap, 80),
                      _row('Pool padding', 'poolPadding', s.poolPadding, 60),
                      const Divider(color: Colors.white12, height: 20),
                      // Default row height
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 100,
                              child: Text(
                                'Default height',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                ),
                                child: Slider(
                                  value: (s.defaultRowHeight ?? 100).clamp(30.0, 400.0),
                                  min: 30,
                                  max: 400,
                                  onChanged: (v) {
                                    final rounded = v.roundToDouble();
                                    ref.read(layoutSettingsProvider.notifier).update(
                                          (s) => s.copyWith(defaultRowHeight: rounded),
                                        );
                                    _defaultHeightController.text = _fmt(rounded);
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 52,
                              child: TextField(
                                controller: _defaultHeightController,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54),
                                  ),
                                ),
                                onSubmitted: (v) {
                                  final parsed = double.tryParse(v);
                                  if (parsed != null && parsed >= 1) {
                                    final clamped = parsed.clamp(30.0, double.infinity);
                                    ref.read(layoutSettingsProvider.notifier).update(
                                          (s) => s.copyWith(defaultRowHeight: clamped),
                                        );
                                    _defaultHeightController.text = _fmt(clamped);
                                  } else {
                                    _defaultHeightController.text =
                                        s.defaultRowHeight != null ? _fmt(s.defaultRowHeight!) : '';
                                  }
                                },
                                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: hasCustomHeight
                              ? () {
                                  ref.read(layoutSettingsProvider.notifier).update(
                                        (s) => s.copyWith(clearDefaultRowHeight: true),
                                      );
                                  _defaultHeightController.clear();
                                }
                              : null,
                          child: const Text(
                            'Auto (default)',
                            style: TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ref.read(layoutSettingsProvider.notifier).resetToDefaults();
                            const d = LayoutSettings();
                            _controllers['boardTopPad']!.text = _fmt(d.boardTopPad);
                            _controllers['boardBottomPad']!.text = _fmt(d.boardBottomPad);
                            _controllers['boardLeftPad']!.text = _fmt(d.boardLeftPad);
                            _controllers['rowGap']!.text = _fmt(d.rowGap);
                            _controllers['labelGap']!.text = _fmt(d.labelGap);
                            _controllers['poolPadding']!.text = _fmt(d.poolPadding);
                            _defaultHeightController.clear();
                          },
                          child: const Text(
                            'Restore defaults',
                            style: TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String field, double value, double max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(0.0, max),
                min: 0,
                max: max,
                onChanged: (v) {
                  _set(field, v.roundToDouble());
                  _controllers[field]?.text = _fmt(v.roundToDouble());
                },
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: TextField(
              controller: _controllers[field],
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
              onSubmitted: (v) => _onTextSubmit(field, v, max),
              onTapOutside: (_) {
                _onTextSubmit(field, _controllers[field]!.text, max);
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}
