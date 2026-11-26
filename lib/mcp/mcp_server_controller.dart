import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mcp_dart/mcp_dart.dart';

import 'tierlist_mcp_tools.dart';

const mcpHost = '127.0.0.1';
const mcpPort = 7861;
const mcpPath = '/mcp';

class McpServerState {
  const McpServerState({
    this.running = false,
    this.busy = false,
    this.token,
    this.error,
  });

  final bool running;
  final bool busy;
  final String? token;
  final String? error;

  String get url => 'http://$mcpHost:$mcpPort$mcpPath';

  /// Ready-to-paste command for Claude Code.
  String get claudeCommand =>
      'claude mcp add --transport http tierlist $url '
      '--header "Authorization: Bearer ${token ?? '<token>'}"';
}

/// Starts/stops the local MCP server. Off by default; the user turns it on
/// from the toolbar. Binds to 127.0.0.1 only and requires a bearer token.
class McpServerController extends StateNotifier<McpServerState> {
  McpServerController(this._ref) : super(const McpServerState());

  final Ref _ref;
  StreamableMcpServer? _server;

  Future<void> start() async {
    if (state.running || state.busy) return;
    state = McpServerState(busy: true, token: state.token);
    try {
      final token = await _loadOrCreateToken();
      final server = StreamableMcpServer(
        serverFactory: (_) => buildTierlistMcpServer(_ref),
        host: mcpHost,
        port: mcpPort,
        path: mcpPath,
        allowedHosts: const {'localhost', '127.0.0.1'},
        authenticator: (request) =>
            request.headers.value('authorization') == 'Bearer $token',
      );
      await server.start();
      _server = server;
      state = McpServerState(running: true, token: token);
    } on SocketException catch (e) {
      state = McpServerState(
        token: state.token,
        error: 'Could not listen on port $mcpPort (${e.osError?.message ?? e.message}). '
            'Is another copy of the app running?',
      );
    } catch (e) {
      state = McpServerState(token: state.token, error: 'Failed to start: $e');
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    state = McpServerState(token: state.token, busy: server != null);
    try {
      await server?.stop();
    } catch (_) {}
    state = McpServerState(token: state.token);
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  /// The token is stored in the app's own (sandbox container) home so the
  /// `claude mcp add` command keeps working across launches.
  Future<String> _loadOrCreateToken() async {
    final home = Platform.environment['HOME'];
    final file = home == null ? null : File('$home/.tierlist_mcp_token');
    try {
      if (file != null && await file.exists()) {
        final existing = (await file.readAsString()).trim();
        if (existing.length >= 32) return existing;
      }
    } catch (_) {}
    final rng = Random.secure();
    final token = List.generate(
        32, (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    try {
      await file?.writeAsString(token, flush: true);
    } catch (_) {
      // Fall back to an in-memory token; it just changes each launch.
    }
    return token;
  }
}

final mcpServerProvider =
    StateNotifierProvider<McpServerController, McpServerState>(
  (ref) => McpServerController(ref),
);
