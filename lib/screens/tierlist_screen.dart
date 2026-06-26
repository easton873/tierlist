import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_mode.dart';
import '../models/tier_item.dart';
import '../providers/app_mode_provider.dart';
import '../providers/layout_settings_provider.dart';
import '../providers/snap_provider.dart';
import '../providers/tierlist_provider.dart';
import '../widgets/app_mode_toggle.dart';
import '../widgets/create_item_toolbar.dart';
import '../widgets/inspector_panel.dart';
import '../widgets/item_pool_widget.dart';
import '../widgets/padding_settings_button.dart';
import '../widgets/tier_item_widget.dart';
import '../widgets/tierlist_board.dart';

class TierlistScreen extends ConsumerStatefulWidget {
  const TierlistScreen({super.key});

  @override
  ConsumerState<TierlistScreen> createState() => _TierlistScreenState();
}

class _TierlistScreenState extends ConsumerState<TierlistScreen> {
  bool _headerVisible = true;
  final _bodyStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  Widget _buildBody(WidgetRef ref, bool isEdit) {
    final freeItems = ref.watch(tierlistProvider).freeItems;
    final tierCount = ref.watch(tierlistProvider).tiers.length;
    final snap = ref.watch(snapProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final s = ref.watch(layoutSettingsProvider);
        final itemSize =
            (constraints.maxHeight - s.boardTopPad - s.boardBottomPad -
                s.rowGap * (tierCount - 1)) /
            tierCount;

        return DragTarget<TierItem>(
          onWillAcceptWithDetails: (_) => !snap,
          onAcceptWithDetails: (details) {
            final rb =
                _bodyStackKey.currentContext?.findRenderObject() as RenderBox?;
            final localPos = rb != null
                ? rb.globalToLocal(details.offset)
                : details.offset;
            ref.read(tierlistProvider.notifier).placeFreeItem(details.data, localPos);
          },
          builder: (context, candidates, rejected) {
            return Stack(
              key: _bodyStackKey,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(child: TierlistBoard()),
                    SizedBox(width: 220, child: ItemPoolWidget(itemSize: itemSize)),
                    if (isEdit) const InspectorPanel(),
                  ],
                ),
                for (final fi in freeItems)
                  Positioned(
                    left: fi.position.dx,
                    top: fi.position.dy,
                    child: TierItemWidget(
                      key: ValueKey(fi.item.id),
                      item: fi.item,
                      rowHeight: itemSize,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final context = FocusManager.instance.primaryFocus?.context;
    final inTextField = context != null && _isInTextField(context);

    if (event.logicalKey == LogicalKeyboardKey.tab) {
      setState(() => _headerVisible = !_headerVisible);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyS && !inTextField) {
      ref.read(snapProvider.notifier).update((s) => !s);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyE && !inTextField) {
      ref.read(appModeProvider.notifier).update((_) => AppMode.edit);
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyP && !inTextField) {
      ref.read(appModeProvider.notifier).update((_) => AppMode.performance);
      return true;
    }

    return false;
  }

  bool _isInTextField(BuildContext context) {
    if (context.widget is EditableText) return true;
    bool found = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(appModeProvider);
    final snap = ref.watch(snapProvider);
    final isEdit = mode == AppMode.edit;

    final appBarColor = isEdit
        ? const Color(0xFF1A3A1A)
        : const Color(0xFF3A2A0A);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _headerVisible ? AppBar(
        backgroundColor: appBarColor,
        title: const Text('Tierlist', style: TextStyle(color: Colors.white)),
        actions: [
          if (isEdit) ...[
            const CreateItemToolbar(),
            const SizedBox(width: 8),
            Tooltip(
              message: snap ? 'Snap on (S)' : 'Snap off (S)',
              child: IconButton(
                icon: Text(
                  '🧲',
                  style: TextStyle(
                    fontSize: 18,
                    color: snap ? null : const Color(0x44FFFFFF),
                  ),
                ),
                onPressed: () =>
                    ref.read(snapProvider.notifier).update((s) => !s),
              ),
            ),
            const PaddingSettingsButton(),
          ],
          const SizedBox(width: 8),
          const AppModeToggle(),
          const SizedBox(width: 16),
        ],
      ) : null,
      body: _buildBody(ref, isEdit),
    );
  }
}
