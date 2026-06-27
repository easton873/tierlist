import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tierlist/models/free_item.dart';
import 'package:tierlist/models/tier_item.dart';
import 'package:tierlist/models/tier_row.dart';
import 'package:tierlist/models/text_overlay_config.dart';
import 'package:tierlist/models/tierlist_file.dart';
import 'package:tierlist/providers/layout_settings_provider.dart';
import 'package:tierlist/providers/tierlist_provider.dart';
import 'package:tierlist/utils/tierlist_migration.dart';

void main() {
  group('TextOverlayConfig serialization', () {
    test('round-trips all fields', () {
      const cfg = TextOverlayConfig(
        text: 'hello',
        textColor: Color(0xFFFF0000),
        borderColor: Color(0xFF00FF00),
        borderWidth: 6.5,
        autoScale: false,
        fontSize: 48.0,
      );
      final rt = TextOverlayConfig.fromJson(cfg.toJson());
      expect(rt.text, cfg.text);
      expect(rt.textColor, cfg.textColor);
      expect(rt.borderColor, cfg.borderColor);
      expect(rt.borderWidth, cfg.borderWidth);
      expect(rt.autoScale, cfg.autoScale);
      expect(rt.fontSize, cfg.fontSize);
    });
  });

  group('TierItem serialization', () {
    test('round-trips image item with overlay', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final item = TierItem(
        id: 'item-1',
        type: TierItemType.image,
        imageBytes: bytes,
        imageName: 'photo.png',
        overlay: const TextOverlayConfig(
          text: 'S',
          autoScale: true,
          fontSize: 32.0,
        ),
        autoSize: false,
        customSize: 120.0,
      );
      final rt = TierItem.fromJson(item.toJson());
      expect(rt.id, item.id);
      expect(rt.type, item.type);
      expect(rt.imageBytes, bytes);
      expect(rt.imageName, item.imageName);
      expect(rt.overlay?.text, 'S');
      expect(rt.autoSize, false);
      expect(rt.customSize, 120.0);
    });

    test('round-trips text item with no overlay and no customSize', () {
      const item = TierItem(
        id: 'item-2',
        type: TierItemType.text,
        text: 'Dragon Ball Z',
        autoSize: true,
      );
      final rt = TierItem.fromJson(item.toJson());
      expect(rt.id, item.id);
      expect(rt.type, TierItemType.text);
      expect(rt.text, item.text);
      expect(rt.imageBytes, isNull);
      expect(rt.overlay, isNull);
      expect(rt.customSize, isNull);
      expect(rt.autoSize, true);
    });
  });

  group('TierRow serialization', () {
    test('round-trips row with all optional fields', () {
      final bgBytes = Uint8List.fromList([10, 20, 30]);
      final row = TierRow(
        id: 'row-1',
        label: 'S',
        labelColor: const Color(0xFFFF5722),
        items: [
          const TierItem(
            id: 'item-3',
            type: TierItemType.text,
            text: 'test',
            autoSize: true,
          ),
        ],
        fontSize: 24.0,
        backgroundImage: bgBytes,
        backgroundColor: const Color(0xFF121212),
        customHeight: 150.0,
      );
      final rt = TierRow.fromJson(row.toJson());
      expect(rt.id, row.id);
      expect(rt.label, row.label);
      expect(rt.labelColor, row.labelColor);
      expect(rt.items.length, 1);
      expect(rt.items.first.id, 'item-3');
      expect(rt.fontSize, 24.0);
      expect(rt.backgroundImage, bgBytes);
      expect(rt.backgroundColor, const Color(0xFF121212));
      expect(rt.customHeight, 150.0);
    });

    test('round-trips row with all nullable fields null', () {
      const row = TierRow(
        id: 'row-2',
        label: 'A',
        labelColor: Color(0xFF4CAF50),
      );
      final rt = TierRow.fromJson(row.toJson());
      expect(rt.fontSize, isNull);
      expect(rt.backgroundImage, isNull);
      expect(rt.backgroundColor, isNull);
      expect(rt.customHeight, isNull);
      expect(rt.items, isEmpty);
    });
  });

  group('FreeItem serialization', () {
    test('round-trips position and nested item', () {
      const fi = FreeItem(
        item: TierItem(
          id: 'free-1',
          type: TierItemType.text,
          text: 'floating',
          autoSize: true,
        ),
        position: Offset(123.45, 678.9),
      );
      final rt = FreeItem.fromJson(fi.toJson());
      expect(rt.item.id, 'free-1');
      expect(rt.position.dx, closeTo(123.45, 0.001));
      expect(rt.position.dy, closeTo(678.9, 0.001));
    });
  });

  group('LayoutSettings serialization', () {
    test('round-trips all fields', () {
      const s = LayoutSettings(
        boardTopPad: 10.0,
        boardBottomPad: 20.0,
        boardLeftPad: 30.0,
        rowGap: 8.0,
        labelGap: 12.0,
        poolPadding: 5.0,
        defaultRowHeight: 200.0,
      );
      final rt = LayoutSettings.fromJson(s.toJson());
      expect(rt.boardTopPad, 10.0);
      expect(rt.boardBottomPad, 20.0);
      expect(rt.boardLeftPad, 30.0);
      expect(rt.rowGap, 8.0);
      expect(rt.labelGap, 12.0);
      expect(rt.poolPadding, 5.0);
      expect(rt.defaultRowHeight, 200.0);
    });

    test('round-trips null defaultRowHeight', () {
      const s = LayoutSettings();
      final rt = LayoutSettings.fromJson(s.toJson());
      expect(rt.defaultRowHeight, isNull);
    });
  });

  group('TierlistFile full round-trip', () {
    TierlistFile _buildSampleFile() {
      final imageBytes = Uint8List.fromList(List.generate(16, (i) => i));
      final state = TierlistState(
        tiers: [
          TierRow(
            id: 'row-a',
            label: 'S',
            labelColor: const Color(0xFFFF0000),
            customHeight: 180.0,
            items: [
              TierItem(
                id: 'item-a',
                type: TierItemType.image,
                imageBytes: imageBytes,
                imageName: 'dragon.png',
                overlay: const TextOverlayConfig(
                  text: 'Dragon',
                  autoScale: false,
                  fontSize: 40.0,
                ),
                autoSize: false,
                customSize: 160.0,
              ),
            ],
          ),
          const TierRow(
            id: 'row-b',
            label: 'F',
            labelColor: Color(0xFF0000FF),
          ),
        ],
        pool: [
          const TierItem(
            id: 'item-b',
            type: TierItemType.text,
            text: 'pool text',
            autoSize: true,
          ),
        ],
        freeItems: [
          const FreeItem(
            item: TierItem(
              id: 'item-c',
              type: TierItemType.text,
              text: 'free',
              autoSize: true,
            ),
            position: Offset(50.0, 100.0),
          ),
        ],
      );
      return TierlistFile.fromState(
        tierlistState: state,
        layoutSettings: const LayoutSettings(
          boardTopPad: 40.0,
          boardBottomPad: 40.0,
          boardLeftPad: 60.0,
          rowGap: 16.0,
          labelGap: 20.0,
          poolPadding: 8.0,
          defaultRowHeight: 140.0,
        ),
        snap: false,
      );
    }

    test('round-trips via toJson/fromJson', () {
      final original = _buildSampleFile();
      final json = original.toJson();
      final loaded = TierlistFile.fromJson(json);

      expect(loaded.version, currentTierlistVersion);
      expect(loaded.snap, false);

      // tiers
      expect(loaded.tiers.length, 2);
      final rowA = loaded.tiers.first;
      expect(rowA.id, 'row-a');
      expect(rowA.label, 'S');
      expect(rowA.customHeight, 180.0);
      expect(rowA.items.length, 1);
      final itemA = rowA.items.first;
      expect(itemA.id, 'item-a');
      expect(itemA.autoSize, false);
      expect(itemA.customSize, 160.0);
      expect(itemA.overlay?.text, 'Dragon');
      expect(itemA.overlay?.autoScale, false);
      expect(itemA.overlay?.fontSize, 40.0);
      expect(itemA.imageBytes, isNotNull);
      expect(itemA.imageBytes!.length, 16);

      // pool
      expect(loaded.pool.length, 1);
      expect(loaded.pool.first.text, 'pool text');

      // freeItems
      expect(loaded.freeItems.length, 1);
      expect(loaded.freeItems.first.item.text, 'free');
      expect(loaded.freeItems.first.position.dx, closeTo(50.0, 0.001));
      expect(loaded.freeItems.first.position.dy, closeTo(100.0, 0.001));

      // layoutSettings
      expect(loaded.layoutSettings.boardTopPad, 40.0);
      expect(loaded.layoutSettings.boardLeftPad, 60.0);
      expect(loaded.layoutSettings.defaultRowHeight, 140.0);
    });

    test('round-trips via JSON string encoding', () {
      final original = _buildSampleFile();
      final jsonStr = jsonEncode(original.toJson());
      final loaded =
          TierlistFile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      expect(loaded.tiers.length, original.tiers.length);
      expect(loaded.pool.length, original.pool.length);
      expect(loaded.freeItems.length, original.freeItems.length);
    });

    test('toTierlistState returns correct state', () {
      final file = _buildSampleFile();
      final state = file.toTierlistState();
      expect(state.tiers.length, 2);
      expect(state.pool.length, 1);
      expect(state.freeItems.length, 1);
    });
  });

  group('Migration', () {
    test('v1 passes through unchanged', () {
      final json = <String, dynamic>{
        'version': 1,
        'tiers': <dynamic>[],
        'pool': <dynamic>[],
        'freeItems': <dynamic>[],
        'layoutSettings': const LayoutSettings().toJson(),
        'snap': true,
      };
      final migrated = migrateTierlistJson(json);
      expect(migrated['version'], 1);
    });

    test('unknown version throws FormatException', () {
      final json = <String, dynamic>{
        'version': 999,
        'tiers': <dynamic>[],
        'pool': <dynamic>[],
        'freeItems': <dynamic>[],
        'layoutSettings': const LayoutSettings().toJson(),
        'snap': true,
      };
      expect(() => migrateTierlistJson(json), throwsA(isA<FormatException>()));
    });

    test('missing version field throws FormatException', () {
      final json = <String, dynamic>{
        'tiers': <dynamic>[],
        'pool': <dynamic>[],
        'freeItems': <dynamic>[],
        'layoutSettings': const LayoutSettings().toJson(),
        'snap': true,
      };
      // version defaults to 0 which != currentTierlistVersion (1)
      expect(() => migrateTierlistJson(json), throwsA(isA<FormatException>()));
    });
  });
}
