# Tierlist App — Claude Context

## What This Is
A macOS + web Flutter desktop app for creating tierlist videos. The user records their screen while dragging items into tiers live.

## Running / Building
```
# Hot reload (preferred during development):
flutter run -d macos
# then press 'r' to reload, 'R' for full restart
```

Do NOT run `flutter build` — the user tests via hot reload only.

## Architecture

**State management:** Riverpod (`StateNotifier` pattern, no code generation)

**Key providers:**
- `tierlistProvider` — owns all tiers, pool items, and free-floating items
- `appModeProvider` — `AppMode.edit` | `AppMode.performance`
- `snapProvider` — bool, whether items snap into tier rows on drop
- `selectionProvider` — currently selected item id (edit mode only)

**Key models:**
- `TierRow` — id, label, labelColor, rowHeight, items
- `TierItem` — id, type (image/text), imageBytes, imageName, text, overlay
- `TextOverlayConfig` — text, textColor, borderColor, borderWidth, autoScale, fontSize
- `FreeItem` — item + Offset position (body-local coordinates)

**Rendering:**
- `TierItemPainter` (CustomPainter) handles all item drawing: image via `drawImageRect`, bordered text via two-pass stroke+fill `TextPainter`
- Text autoscales by iterating fontSize *= 0.88 until text fits, with a word-boundary check so words are never broken mid-word
- When `autoScale` is false, uses fixed `fontSize` and allows overflow

**Layout:**
- Tiers fill full screen height via `LayoutBuilder` in `TierlistBoard` — rowHeight = (available - 24px padding) / tierCount
- Tier labels are square (width = rowHeight)
- Free items (snap OFF) render at the body level in `TierlistScreen` so they appear above both the board and the item pool

**Drag and drop:**
- Snap ON: `TierRowWidget` `DragTarget`s accept drops, items slot into rows
- Snap OFF: `TierlistBoard` board-level `DragTarget` accepts drops, items placed as `FreeItem` at drop coordinates
- Edit mode: `LongPressDraggable` (tap = select item, hold = drag)
- Performance mode: `Draggable` (immediate drag)
- `childWhenDragging` shows item at 30% opacity so it stays visible

## Keyboard Shortcuts
- `Tab` — toggle Edit / Performance mode (not in text inputs)
- `S` — toggle snap on/off (not in text inputs)

## macOS Entitlements
Both `DebugProfile.entitlements` and `Release.entitlements` have:
- `com.apple.security.files.user-selected.read-only` (required for file picker)

## Key Files
```
lib/
  main.dart                        # ProviderScope + MaterialApp
  models/
    app_mode.dart
    tier_item.dart                 # TierItem + TierItemType enum
    tier_row.dart
    text_overlay_config.dart       # autoScale + fontSize added
    free_item.dart                 # for snap-off floating items
  providers/
    app_mode_provider.dart
    tierlist_provider.dart         # TierlistState + TierlistNotifier
    selection_provider.dart
    snap_provider.dart
  widgets/
    tierlist_board.dart            # LayoutBuilder, board DragTarget, StatefulWidget
    tier_row_widget.dart           # per-row DragTarget (rejects when snap=OFF)
    tier_label_widget.dart         # square label, black text, w300 weight
    tier_item_widget.dart          # Draggable/LongPressDraggable, ui.Image cache
    item_pool_widget.dart          # right sidebar DragTarget
    inspector_panel.dart           # text/color/font size editor, StatefulWidget
    app_mode_toggle.dart
    create_item_toolbar.dart       # Import Image + Add Text buttons
  painters/
    tier_item_painter.dart         # image + bordered text, autoscale loop
  screens/
    tierlist_screen.dart           # keyboard handlers, free item overlay, StatefulWidget
  utils/
    default_tiers.dart             # S/A/B/C/D/F with colors
    image_import_util.dart         # file_picker wrapper
```

## Wishlist (not yet implemented)
In priority order from notes.txt:
- Tier add / edit / reorder / delete
- Snap-to-position within a row (currently always appends to end)
- Save/export/import as `.tierlist` files (JSON + base64 images)
- Multi-tier image sizing
- Pan/zoom canvas (`InteractiveViewer`)
- Image-only background tiers
- Screen recording

Future packages to add when needed: `path_provider`, `shared_preferences`, `archive`
