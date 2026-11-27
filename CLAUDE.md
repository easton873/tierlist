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

## MCP Server (lets Claude Code control the tierlist)
- Off by default. Toggle with the hub icon in the header (green = running). The dialog shows a ready-to-paste
  `claude mcp add --transport http tierlist http://127.0.0.1:7861/mcp --header "Authorization: Bearer <token>"`.
- Package: `mcp_dart` (`StreamableMcpServer`). Binds to 127.0.0.1 only, bearer token required; the token is stored in
  `~/.tierlist_mcp_token` inside the sandbox container so the command keeps working across launches.
- Every tool is a thin wrapper over a `TierlistNotifier` method — add new tools in `lib/mcp/tierlist_mcp_tools.dart`.
- Images are passed as **absolute file paths** (no base64). Reading arbitrary paths needs the
  `temporary-exception.files.absolute-path.read-only` entitlement, which is in `DebugProfile.entitlements` only.
  Release builds can run the server (`network.server`) but cannot read arbitrary paths.
- Tiers can be referenced by id or by label (case-insensitive).
- `get_screenshot` captures the `RepaintBoundary` keyed by `tierlistCaptureKey` (`lib/mcp/capture.dart`) in `TierlistScreen`.
- Tests: `flutter test test/mcp_server_test.dart` starts the real server and drives it with an MCP client (uses port 7861).
- Tools: get_state, get_screenshot, add_image_items, add_text_item, set_item_text, move_item, remove_item, add_tier,
  add_image_row, rename_tier, set_tier_color, remove_tier, reorder_tiers, set_tier_height, set_tier_font_size,
  set_tier_background_color, set_tier_background_image.
- Note: a tier with a background color/image is a full-width row and its label is hidden (existing app behavior).

## Wishlist
Done (verified in code): tier add/rename/recolor/reorder/delete, image-only background tiers, per-item and per-tier sizing
(multi-tier image sizing), export/import of versioned `.tierlist` files with migrations, hand/pointer pan tool, MCP server.

Not yet implemented, in priority order:
- Snap-to-position within a row (drops currently always append: `row.items.length` in `tier_row_widget.dart`)
- Zoom (numeric input) on top of the existing pan tool; optionally lock the view
- Persistent autosave of the current scene (export/import to `.tierlist` exists, but nothing is saved automatically)
- Screen recording (nice to have; the built-in macOS recorder works)
- Intro/outro on recordings, toggleable

Future packages to add when needed: `path_provider`, `shared_preferences`, `archive`
