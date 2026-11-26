import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:uuid/uuid.dart';

import '../models/text_overlay_config.dart';
import '../models/tier_item.dart';
import '../models/tier_row.dart';
import '../providers/tierlist_provider.dart';
import 'capture.dart';

const _uuid = Uuid();
const _maxImageBytes = 30 * 1024 * 1024;

/// Thrown by tool handlers for problems the caller (the LLM) can fix.
class ToolError implements Exception {
  ToolError(this.message);
  final String message;
}

/// Builds an MCP server exposing the tierlist as tools. Every tool is a thin
/// wrapper over an existing [TierlistNotifier] method, so MCP and the UI
/// always go through the same code path.
McpServer buildTierlistMcpServer(Ref ref) {
  final server = McpServer(
    const Implementation(name: 'tierlist', version: '1.0.0'),
    options: const McpServerOptions(protocol: McpProtocol.stable),
  );
  _Tools(ref, server).registerAll();
  return server;
}

class _Tools {
  _Tools(this.ref, this.server);

  final Ref ref;
  final McpServer server;

  TierlistNotifier get _notifier => ref.read(tierlistProvider.notifier);
  TierlistState get _state => ref.read(tierlistProvider);

  void registerAll() {
    _registerInspection();
    _registerItemTools();
    _registerTierTools();
  }

  // ---------------------------------------------------------------- helpers

  void _tool(
    String name,
    String description,
    FutureOr<Object?> Function(Map<String, dynamic> args) handler, {
    Map<String, JsonSchema> properties = const {},
    List<String> required = const [],
    bool readOnly = false,
    bool destructive = false,
  }) {
    server.registerTool(
      name,
      description: description,
      inputSchema: JsonSchema.object(
        properties: properties,
        required: required.isEmpty ? null : required,
      ),
      annotations: ToolAnnotations(
        readOnlyHint: readOnly,
        destructiveHint: destructive,
        openWorldHint: false,
      ),
      callback: (args, extra) async {
        try {
          final result = await handler(args);
          if (result is CallToolResult) return result;
          return CallToolResult.fromContent([
            TextContent(
              text: const JsonEncoder.withIndent('  ')
                  .convert(result ?? {'ok': true}),
            ),
          ]);
        } on ToolError catch (e) {
          return CallToolResult(
              content: [TextContent(text: e.message)], isError: true);
        } catch (e) {
          return CallToolResult(
              content: [TextContent(text: 'Unexpected error: $e')],
              isError: true);
        }
      },
    );
  }

  static const _tierRefDesc =
      'Tier id or tier label (case-insensitive). Use get_state to see both.';

  JsonSchema get _tierRef => JsonSchema.string(description: _tierRefDesc);

  TierRow _resolveTier(Object? ref) {
    if (ref is! String || ref.trim().isEmpty) {
      throw ToolError('A tier id or label is required.');
    }
    final tiers = _state.tiers;
    final byId = tiers.where((t) => t.id == ref).toList();
    if (byId.length == 1) return byId.first;
    final lower = ref.trim().toLowerCase();
    final byLabel =
        tiers.where((t) => t.label.trim().toLowerCase() == lower).toList();
    if (byLabel.length == 1) return byLabel.first;
    if (byLabel.length > 1) {
      throw ToolError(
          'Tier label "$ref" matches ${byLabel.length} tiers; use the tier id '
          'instead: ${byLabel.map((t) => t.id).join(', ')}');
    }
    throw ToolError(
        'No tier matches "$ref". Existing tiers: '
        '${tiers.map((t) => '${t.id} ("${t.label}")').join(', ')}');
  }

  TierItem _findItem(Object? id) {
    if (id is! String || id.isEmpty) throw ToolError('item_id is required.');
    final s = _state;
    for (final row in s.tiers) {
      for (final i in row.items) {
        if (i.id == id) return i;
      }
    }
    for (final i in s.pool) {
      if (i.id == id) return i;
    }
    for (final f in s.freeItems) {
      if (f.item.id == id) return f.item;
    }
    throw ToolError('No item with id "$id". Use get_state to list items.');
  }

  String _requireString(Map<String, dynamic> a, String key) {
    final v = a[key];
    if (v is! String) throw ToolError('"$key" is required and must be a string.');
    return v;
  }

  double? _optNumber(Map<String, dynamic> a, String key) {
    final v = a[key];
    if (v == null) return null;
    if (v is! num) throw ToolError('"$key" must be a number.');
    return v.toDouble();
  }

  Color _parseColor(String raw) {
    var s = raw.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final v = s.length == 8 ? int.tryParse(s, radix: 16) : null;
    if (v == null) {
      throw ToolError(
          'Invalid color "$raw". Use "#RRGGBB" or "#AARRGGBB" (hex).');
    }
    return Color(v);
  }

  String _hex(Color c) {
    final argb = c.toARGB32();
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    if ((argb >> 24) == 0xFF) return '#${rgb.toUpperCase()}';
    final a = (argb >> 24).toRadixString(16).padLeft(2, '0');
    return '#${(a + rgb).toUpperCase()}';
  }

  /// Reads and validates an image from an absolute file path.
  Future<Uint8List> _readImage(String path) async {
    var p = path.trim();
    if (p.startsWith('file://')) p = Uri.parse(p).toFilePath();
    if (!p.startsWith('/')) {
      throw ToolError(
          'Image path must be absolute (got "$path"). "~" and relative paths '
          'are not supported because the app is sandboxed.');
    }
    final file = File(p);
    final Uint8List bytes;
    try {
      if (!await file.exists()) throw ToolError('File not found: $p');
      if (await file.length() > _maxImageBytes) {
        throw ToolError('Image is larger than 30 MB: $p');
      }
      bytes = await file.readAsBytes();
    } on FileSystemException catch (e) {
      throw ToolError(
          'Could not read $p (${e.osError?.message ?? e.message}). If this is '
          'a permission error, the macOS sandbox is blocking the path; see the '
          'entitlements notes in CLAUDE.md.');
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      codec.dispose();
    } catch (_) {
      throw ToolError('Not a decodable image (png/jpg/gif/webp/bmp): $p');
    }
    return bytes;
  }

  Map<String, dynamic> _itemJson(TierItem i) => {
        'id': i.id,
        'type': i.type.name,
        if (i.imageName != null) 'name': i.imageName,
        if (i.overlay != null && i.overlay!.text.isNotEmpty)
          'text': i.overlay!.text,
      };

  Map<String, dynamic> _tierJson(TierRow r, int index) => {
        'id': r.id,
        'index': index,
        'label': r.label,
        'color': _hex(r.labelColor),
        if (r.customHeight != null) 'height': r.customHeight,
        if (r.fontSize != null) 'font_size': r.fontSize,
        if (r.backgroundColor != null)
          'background_color': _hex(r.backgroundColor!),
        if (r.backgroundImage != null) 'has_background_image': true,
        'items': r.items.map(_itemJson).toList(),
      };

  void _moveTierToIndex(String tierId, int index) {
    final tiers = _state.tiers;
    final from = tiers.indexWhere((t) => t.id == tierId);
    final to = index.clamp(0, tiers.length - 1);
    for (var i = from; i > to; i--) {
      _notifier.moveTierUp(tierId);
    }
  }

  int? _optIndex(Map<String, dynamic> a) {
    final v = a['index'];
    if (v == null) return null;
    if (v is! num) throw ToolError('"index" must be an integer.');
    return v.toInt();
  }

  // ------------------------------------------------------------- inspection

  void _registerInspection() {
    _tool(
      'get_state',
      'Returns the whole tierlist: every tier (id, index, label, color, '
      'height, background) with its items, the unplaced item pool, and the '
      'number of free-floating items. Call this first to learn ids.',
      readOnly: true,
      (_) {
        final s = _state;
        return {
          'tiers': [
            for (var i = 0; i < s.tiers.length; i++) _tierJson(s.tiers[i], i)
          ],
          'pool': s.pool.map(_itemJson).toList(),
          'free_items': s.freeItems.map((f) => _itemJson(f.item)).toList(),
        };
      },
    );

    _tool(
      'get_screenshot',
      'Returns a PNG screenshot of the tierlist as currently shown in the '
      'app, so you can check your work visually.',
      readOnly: true,
      properties: {
        'scale': JsonSchema.number(
          description: 'Pixel ratio, 0.25 to 2. Default 1.',
          minimum: 0.25,
          maximum: 2,
        ),
      },
      (a) async {
        final scale = (_optNumber(a, 'scale') ?? 1.0).clamp(0.25, 2.0);
        final boundary = tierlistCaptureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          throw ToolError('The tierlist view is not on screen right now.');
        }
        final image = await boundary.toImage(pixelRatio: scale);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        if (data == null) throw ToolError('Failed to encode screenshot.');
        return CallToolResult.fromContent([
          ImageContent(
            data: base64Encode(data.buffer.asUint8List()),
            mimeType: 'image/png',
          ),
        ]);
      },
    );
  }

  // ------------------------------------------------------------------ items

  void _registerItemTools() {
    _tool(
      'add_image_items',
      'Adds one or more images from absolute file paths. Each image becomes '
      'an item, optionally with a text label drawn over it. Items go to the '
      'item pool unless "tier" is given. Unreadable files are reported in '
      '"errors" and the rest are still added.',
      properties: {
        'paths': JsonSchema.array(
          items: JsonSchema.string(),
          minItems: 1,
          description: 'Absolute paths to image files.',
        ),
        'labels': JsonSchema.array(
          items: JsonSchema.string(),
          description: 'Optional text overlay per image, same order as paths. '
              'Use "" for no label. Omit entirely for no labels.',
        ),
        'tier': JsonSchema.string(
            description: 'Optional destination tier (id or label). '
                'Default: the item pool.'),
      },
      required: ['paths'],
      (a) async {
        final paths = a['paths'];
        if (paths is! List || paths.isEmpty) {
          throw ToolError('"paths" must be a non-empty array of strings.');
        }
        final labels = a['labels'];
        if (labels != null && (labels is! List || labels.length != paths.length)) {
          throw ToolError(
              '"labels" must have exactly one entry per path (use "" for none).');
        }
        final tier = a['tier'] != null ? _resolveTier(a['tier']) : null;

        final added = <Map<String, dynamic>>[];
        final errors = <Map<String, dynamic>>[];
        for (var i = 0; i < paths.length; i++) {
          final path = paths[i].toString();
          try {
            final bytes = await _readImage(path);
            final label = labels == null ? '' : (labels[i]?.toString() ?? '');
            final item = TierItem(
              id: _uuid.v4(),
              type: TierItemType.image,
              imageBytes: bytes,
              imageName: path.split('/').last,
              overlay: label.isEmpty ? null : TextOverlayConfig(text: label),
            );
            _notifier.addItemToPool(item);
            if (tier != null) {
              _notifier.moveItemToTier(item.id, tier.id, 1 << 30);
            }
            added.add(_itemJson(item));
          } on ToolError catch (e) {
            errors.add({'path': path, 'error': e.message});
          }
        }
        final result = {
          'added': added,
          if (errors.isNotEmpty) 'errors': errors,
        };
        if (added.isEmpty) {
          return CallToolResult(
            content: [TextContent(text: jsonEncode(result))],
            isError: true,
          );
        }
        return result;
      },
    );

    _tool(
      'add_text_item',
      'Adds a text-only item. Goes to the item pool unless "tier" is given.',
      properties: {
        'text': JsonSchema.string(description: 'Text to show (may contain newlines).'),
        'tier': JsonSchema.string(description: 'Optional destination tier.'),
      },
      required: ['text'],
      (a) {
        final text = _requireString(a, 'text');
        if (text.isEmpty) throw ToolError('"text" must not be empty.');
        final tier = a['tier'] != null ? _resolveTier(a['tier']) : null;
        final item = TierItem(
          id: _uuid.v4(),
          type: TierItemType.text,
          text: text,
          overlay: TextOverlayConfig(text: text),
        );
        _notifier.addItemToPool(item);
        if (tier != null) _notifier.moveItemToTier(item.id, tier.id, 1 << 30);
        return _itemJson(item);
      },
    );

    _tool(
      'set_item_text',
      'Sets, changes or clears the text label drawn over an item. Pass an '
      'empty string to remove the label from an image item.',
      properties: {
        'item_id': JsonSchema.string(),
        'text': JsonSchema.string(description: 'New label; "" to clear.'),
      },
      required: ['item_id', 'text'],
      (a) {
        final item = _findItem(a['item_id']);
        final text = _requireString(a, 'text');
        if (text.isEmpty && item.type == TierItemType.image) {
          _notifier.updateItemOverlay(item.id, null);
        } else {
          final base = item.overlay ?? TextOverlayConfig(text: text);
          _notifier.updateItemOverlay(item.id, base.copyWith(text: text));
        }
        return _itemJson(_findItem(item.id));
      },
    );

    _tool(
      'move_item',
      'Moves an item into a tier (optionally at a position) or back to the pool.',
      properties: {
        'item_id': JsonSchema.string(),
        'destination': JsonSchema.string(
            description: 'Tier id/label, or the word "pool".'),
        'index': JsonSchema.integer(
            description: 'Position within the tier (0 = first). Default: end.'),
      },
      required: ['item_id', 'destination'],
      (a) {
        final item = _findItem(a['item_id']);
        final dest = _requireString(a, 'destination');
        // A tier labelled "pool" wins over the keyword only if it matches by id.
        final isPool = dest.trim().toLowerCase() == 'pool' &&
            !_state.tiers.any((t) => t.id == dest);
        if (isPool) {
          _notifier.moveItemToPool(item.id);
          return {'item_id': item.id, 'destination': 'pool'};
        }
        final tier = _resolveTier(dest);
        _notifier.moveItemToTier(item.id, tier.id, _optIndex(a) ?? (1 << 30));
        return {'item_id': item.id, 'destination': tier.id};
      },
    );

    _tool(
      'remove_item',
      'Permanently deletes an item from the tierlist.',
      destructive: true,
      properties: {'item_id': JsonSchema.string()},
      required: ['item_id'],
      (a) {
        final item = _findItem(a['item_id']);
        _notifier.deleteItem(item.id);
        return {'removed': item.id};
      },
    );
  }

  // ------------------------------------------------------------------ tiers

  void _registerTierTools() {
    _tool(
      'add_tier',
      'Adds a normal labeled tier row. Appended at the bottom unless "index" '
      'is given.',
      properties: {
        'label': JsonSchema.string(description: 'Default: "New".'),
        'color': JsonSchema.string(description: 'Label color, "#RRGGBB".'),
        'index': JsonSchema.integer(
            description: 'Position (0 = top). Default: bottom.'),
      },
      (a) {
        final color = a['color'] is String ? _parseColor(a['color']) : null;
        _notifier.addTier();
        final id = _state.tiers.last.id;
        if (a['label'] is String) _notifier.renameTier(id, a['label']);
        if (color != null) _notifier.recolorTier(id, color);
        final index = _optIndex(a);
        if (index != null) _moveTierToIndex(id, index);
        final tiers = _state.tiers;
        final i = tiers.indexWhere((t) => t.id == id);
        return _tierJson(tiers[i], i);
      },
    );

    _tool(
      'add_image_row',
      'Adds a full-width row whose background is a single image (no label). '
      'Appended at the bottom unless "index" is given.',
      properties: {
        'path': JsonSchema.string(description: 'Absolute path to an image.'),
        'height': JsonSchema.number(
            description: 'Row height in px. Default: automatic.'),
        'index': JsonSchema.integer(
            description: 'Position (0 = top). Default: bottom.'),
      },
      required: ['path'],
      (a) async {
        final bytes = await _readImage(_requireString(a, 'path'));
        final height = _optNumber(a, 'height');
        _notifier.addImageTier(bytes);
        final id = _state.tiers.last.id;
        if (height != null) _notifier.updateTierHeight(id, height);
        final index = _optIndex(a);
        if (index != null) _moveTierToIndex(id, index);
        final tiers = _state.tiers;
        final i = tiers.indexWhere((t) => t.id == id);
        return _tierJson(tiers[i], i);
      },
    );

    _tool(
      'rename_tier',
      'Changes a tier\'s label.',
      properties: {'tier': _tierRef, 'label': JsonSchema.string()},
      required: ['tier', 'label'],
      (a) {
        final t = _resolveTier(a['tier']);
        _notifier.renameTier(t.id, _requireString(a, 'label'));
        return {'id': t.id, 'label': a['label']};
      },
    );

    _tool(
      'set_tier_color',
      'Changes the color of a tier\'s label box.',
      properties: {
        'tier': _tierRef,
        'color': JsonSchema.string(description: '"#RRGGBB" or "#AARRGGBB".'),
      },
      required: ['tier', 'color'],
      (a) {
        final t = _resolveTier(a['tier']);
        final c = _parseColor(_requireString(a, 'color'));
        _notifier.recolorTier(t.id, c);
        return {'id': t.id, 'color': _hex(c)};
      },
    );

    _tool(
      'remove_tier',
      'Deletes a tier. Its items are moved back to the item pool, not lost. '
      'The last remaining tier cannot be deleted.',
      destructive: true,
      properties: {'tier': _tierRef},
      required: ['tier'],
      (a) {
        final t = _resolveTier(a['tier']);
        if (_state.tiers.length <= 1) {
          throw ToolError('Cannot delete the last remaining tier.');
        }
        _notifier.deleteTier(t.id);
        return {'removed': t.id, 'items_returned_to_pool': t.items.length};
      },
    );

    _tool(
      'reorder_tiers',
      'Sets the top-to-bottom order of all tiers. "order" must list every '
      'tier exactly once.',
      properties: {
        'order': JsonSchema.array(
          items: JsonSchema.string(),
          description: 'Tier ids or labels, top first.',
        ),
      },
      required: ['order'],
      (a) {
        final order = a['order'];
        if (order is! List) throw ToolError('"order" must be an array.');
        final ids = order.map((o) => _resolveTier(o).id).toList();
        final current = _state.tiers.map((t) => t.id).toSet();
        if (ids.length != current.length ||
            ids.toSet().length != ids.length ||
            !ids.toSet().containsAll(current)) {
          throw ToolError(
              'order must contain every tier exactly once '
              '(${current.length} tiers).');
        }
        for (var i = 0; i < ids.length; i++) {
          _notifier.reorderTier(ids[i], _state.tiers[i].id);
        }
        return {'order': _state.tiers.map((t) => t.id).toList()};
      },
    );

    _tool(
      'set_tier_height',
      'Sets a fixed row height in px. Omit "height" to go back to automatic.',
      properties: {
        'tier': _tierRef,
        'height': JsonSchema.number(minimum: 20),
      },
      required: ['tier'],
      (a) {
        final t = _resolveTier(a['tier']);
        final h = _optNumber(a, 'height');
        _notifier.updateTierHeight(t.id, h);
        return {'id': t.id, 'height': h ?? 'auto'};
      },
    );

    _tool(
      'set_tier_font_size',
      'Sets the tier label font size. Omit "font_size" to go back to '
      'automatic (scales with row height).',
      properties: {
        'tier': _tierRef,
        'font_size': JsonSchema.number(minimum: 4),
      },
      required: ['tier'],
      (a) {
        final t = _resolveTier(a['tier']);
        final f = _optNumber(a, 'font_size');
        _notifier.updateTierFontSize(t.id, f);
        return {'id': t.id, 'font_size': f ?? 'auto'};
      },
    );

    _tool(
      'set_tier_background_color',
      'Sets a solid background color for a row. NOTE: in this app a row with '
      'a background color becomes a full-width row and its label is hidden. '
      'Omit "color" to remove the background and restore the normal row.',
      properties: {
        'tier': _tierRef,
        'color': JsonSchema.string(description: '"#RRGGBB" or "#AARRGGBB".'),
      },
      required: ['tier'],
      (a) {
        final t = _resolveTier(a['tier']);
        final c = a['color'] is String ? _parseColor(a['color']) : null;
        _notifier.updateTierBackgroundColor(t.id, c);
        return {'id': t.id, 'background_color': c == null ? 'none' : _hex(c)};
      },
    );

    _tool(
      'set_tier_background_image',
      'Sets a background image for a row from an absolute file path. NOTE: '
      'the row becomes full-width and its label is hidden. Omit "path" to '
      'remove the image.',
      properties: {
        'tier': _tierRef,
        'path': JsonSchema.string(description: 'Absolute path to an image.'),
      },
      required: ['tier'],
      (a) async {
        final t = _resolveTier(a['tier']);
        final path = a['path'];
        final bytes = path is String ? await _readImage(path) : null;
        _notifier.updateTierBackgroundImage(t.id, bytes);
        return {'id': t.id, 'background_image': bytes != null};
      },
    );
  }
}
