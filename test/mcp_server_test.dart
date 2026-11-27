import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:tierlist/mcp/capture.dart';
import 'package:tierlist/mcp/mcp_server_controller.dart';
import 'package:tierlist/providers/tierlist_provider.dart';

// 1x1 PNG
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // allow real localhost sockets in tests

  late ProviderContainer container;
  late McpClient client;
  late String pngPath;
  late McpServerState server;

  TierlistState tl() => container.read(tierlistProvider);

  Future<CallToolResult> call(String name, [Map<String, dynamic>? args]) =>
      client.callTool(CallToolRequest(name: name, arguments: args ?? {}));

  Map<String, dynamic> json(CallToolResult r) =>
      jsonDecode((r.content.first as TextContent).text) as Map<String, dynamic>;

  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('tierlist_mcp');
    pngPath = '${dir.path}/pixel.png';
    File(pngPath).writeAsBytesSync(base64Decode(_png));

    container = ProviderContainer();
    await container.read(mcpServerProvider.notifier).start();
    server = container.read(mcpServerProvider);
    expect(server.running, isTrue, reason: server.error);

    client = McpClient(const Implementation(name: 'test', version: '1'));
    await client.connect(StreamableHttpClientTransport(
      Uri.parse(server.url),
      opts: StreamableHttpClientTransportOptions(requestInit: {
        'headers': {'Authorization': 'Bearer ${server.token}'},
      }),
    ));
  });

  tearDownAll(() async {
    await client.close();
    await container.read(mcpServerProvider.notifier).stop();
    container.dispose();
  });

  test('rejects requests without the token', () async {
    final http = HttpClient();
    final req = await http.postUrl(Uri.parse(server.url));
    req.headers.contentType = ContentType.json;
    req.write('{}');
    final res = await req.close();
    await res.drain();
    expect(res.statusCode, anyOf(401, 403));
    http.close();
  });

  test('lists all tools', () async {
    final names = (await client.listTools()).tools.map((t) => t.name).toSet();
    expect(names, containsAll([
      'get_state', 'get_screenshot', 'add_image_items', 'add_text_item',
      'set_item_text', 'move_item', 'remove_item', 'add_tier', 'add_image_row',
      'rename_tier', 'set_tier_color', 'remove_tier', 'reorder_tiers',
      'set_tier_height', 'set_tier_font_size', 'set_tier_background_color',
      'set_tier_background_image',
    ]));
  });

  test('add images with and without labels, into a tier by label', () async {
    final r = await call('add_image_items', {
      'paths': [pngPath, pngPath],
      'labels': ['Hello', ''],
      'tier': 's', // label, case-insensitive
    });
    expect(r.isError, isFalse);
    final items = tl().tiers.firstWhere((t) => t.id == 'S').items;
    expect(items.length, 2);
    expect(items[0].overlay?.text, 'Hello');
    expect(items[1].overlay, isNull);
  });

  test('bad path / relative path report errors without crashing', () async {
    final missing = await call('add_image_items', {'paths': ['/no/such.png']});
    expect(missing.isError, isTrue);
    final rel = await call('add_image_items', {'paths': ['~/x.png']});
    expect(rel.isError, isTrue);
    expect((rel.content.first as TextContent).text, contains('absolute'));
  });

  test('partial failure still adds the good images', () async {
    final before = tl().pool.length;
    final r = await call('add_image_items', {'paths': [pngPath, '/nope.png']});
    expect(r.isError, isFalse);
    expect(json(r)['errors'], hasLength(1));
    expect(tl().pool.length, before + 1);
  });

  test('set_item_text sets and clears; move_item to pool and back', () async {
    final id = tl().tiers.firstWhere((t) => t.id == 'S').items.first.id;
    await call('set_item_text', {'item_id': id, 'text': 'Changed'});
    expect(tl().tiers.first.items.first.overlay?.text, 'Changed');
    await call('set_item_text', {'item_id': id, 'text': ''});
    expect(tl().tiers.first.items.first.overlay, isNull);

    await call('move_item', {'item_id': id, 'destination': 'pool'});
    expect(tl().pool.any((i) => i.id == id), isTrue);
    await call('move_item', {'item_id': id, 'destination': 'A', 'index': 0});
    expect(tl().tiers.firstWhere((t) => t.id == 'A').items.first.id, id);
  });

  test('tier management: add at index, rename, recolor, reorder, remove',
      () async {
    final added = json(await call(
        'add_tier', {'label': 'Z', 'color': '#112233', 'index': 1}));
    expect(added['index'], 1);
    expect(tl().tiers[1].label, 'Z');
    expect(tl().tiers[1].labelColor.toARGB32(), 0xFF112233);

    await call('rename_tier', {'tier': 'Z', 'label': 'Zed'});
    expect(tl().tiers[1].label, 'Zed');
    await call('set_tier_color', {'tier': 'Zed', 'color': 'ff0000'});
    expect(tl().tiers[1].labelColor.toARGB32(), 0xFFFF0000);

    final ids = tl().tiers.map((t) => t.id).toList();
    final reversed = ids.reversed.toList();
    await call('reorder_tiers', {'order': reversed});
    expect(tl().tiers.map((t) => t.id).toList(), reversed);

    final bad = await call('reorder_tiers', {'order': ids.take(2).toList()});
    expect(bad.isError, isTrue);

    // Removing a tier with items returns them to the pool.
    final aItems = tl().tiers.firstWhere((t) => t.id == 'A').items.length;
    final poolBefore = tl().pool.length;
    final rm = json(await call('remove_tier', {'tier': 'A'}));
    expect(rm['items_returned_to_pool'], aItems);
    expect(tl().pool.length, poolBefore + aItems);
    expect(tl().tiers.any((t) => t.id == 'A'), isFalse);
  });

  test('image row and tier styling tools', () async {
    final row = json(await call('add_image_row',
        {'path': pngPath, 'height': 120, 'index': 0}));
    expect(row['index'], 0);
    expect(row['has_background_image'], isTrue);
    expect(tl().tiers.first.customHeight, 120);

    await call('set_tier_height', {'tier': 'B', 'height': 90});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').customHeight, 90);
    await call('set_tier_height', {'tier': 'B'});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').customHeight, isNull);

    await call('set_tier_font_size', {'tier': 'B', 'font_size': 30});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').fontSize, 30);

    await call('set_tier_background_color', {'tier': 'B', 'color': '#00FF00'});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').backgroundColor,
        isNotNull);
    await call('set_tier_background_color', {'tier': 'B'});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').backgroundColor, isNull);

    await call('set_tier_background_image', {'tier': 'B', 'path': pngPath});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').backgroundImage,
        isNotNull);
    await call('set_tier_background_image', {'tier': 'B'});
    expect(tl().tiers.firstWhere((t) => t.id == 'B').backgroundImage, isNull);
  });

  test('remove_item, unknown ids, and last tier protection', () async {
    final id = tl().pool.first.id;
    await call('remove_item', {'item_id': id});
    expect(tl().pool.any((i) => i.id == id), isFalse);

    expect((await call('remove_item', {'item_id': 'nope'})).isError, isTrue);
    expect((await call('rename_tier', {'tier': 'nope', 'label': 'x'})).isError,
        isTrue);

    for (final t in tl().tiers.skip(1).toList()) {
      await call('remove_tier', {'tier': t.id});
    }
    expect(tl().tiers.length, 1);
    expect((await call('remove_tier', {'tier': tl().tiers.first.id})).isError,
        isTrue);
  });

  test('get_state reflects the model', () async {
    final state = json(await call('get_state'));
    expect(state['tiers'], hasLength(1));
  });

  test('get_screenshot errors gracefully when the view is not on screen',
      () async {
    final shot = await call('get_screenshot');
    expect(shot.isError, isTrue);
  });

  testWidgets('get_screenshot returns a PNG of the captured view',
      (tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: tierlistCaptureKey,
        child: const SizedBox(
            width: 200, height: 100, child: ColoredBox(color: Color(0xFFFF0000))),
      ),
    ));
    await tester.runAsync(() async {
      final shot = await call('get_screenshot', {'scale': 1});
      expect(shot.isError, isFalse);
      final img = shot.content.first as ImageContent;
      expect(img.mimeType, 'image/png');
      final bytes = base64Decode(img.data);
      expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]); // PNG magic
    });
  });
}
