# Tierlist

A macOS and web desktop app for creating tierlist videos. Drag images and text into S/A/B/C/D/F tiers while screen recording.

## Running

```bash
# Development (hot reload with 'r', full restart with 'R'):
flutter run -d macos

# Build and launch:
flutter build macos --debug && open build/macos/Build/Products/Debug/tierlist.app
```

## Features

### Modes
- **Edit mode** — import images, create text items, select items to edit overlays
- **Performance mode** — clean drag-and-drop interface with no creation tools visible, safe for screen recording
- Toggle with the segmented button in the toolbar, or press **Tab**

### Items
- **Import Image** — picks any image file, auto-scales to fit tier row height while preserving aspect ratio
- **Add Text** — creates a draggable text label with a transparent hitbox
- Both support text overlays with customizable color, border color, border width, and font size

### Text Overlays
- White text with thick black border by default (both colors customizable)
- **Auto-scale** (default on) — text shrinks to fit the item without ever breaking a word mid-word
- **Manual size** — uncheck auto-scale to use a slider or type an exact font size; text overflows freely

### Tiers
- Default tiers: S, A, B, C, D, F with colored labels
- Labels are square, use a thin black font, and fill the full screen height with small padding

### Snap
- **Snap on** (default) — items dropped onto a tier row slot into it
- **Snap off** — items stay exactly where you drop them as floating overlays, drawing on top of everything including the item pool
- Toggle with the 🧲 button in the toolbar (edit mode) or press **S**

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Tab | Toggle Edit / Performance mode |
| S | Toggle snap on / off |

Both shortcuts are suppressed while typing in a text field.

## Project Structure

Built with Flutter + Riverpod. See `CLAUDE.md` for full architecture details and remaining wishlist items.
