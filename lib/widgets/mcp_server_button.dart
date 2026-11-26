import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mcp/mcp_server_controller.dart';

/// Toolbar button that shows MCP server status and opens a control dialog.
class McpServerButton extends ConsumerWidget {
  const McpServerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = ref.watch(mcpServerProvider.select((s) => s.running));
    return Tooltip(
      message: running ? 'MCP server running' : 'MCP server off',
      child: IconButton(
        icon: Icon(
          Icons.hub,
          size: 20,
          color: running ? Colors.greenAccent : Colors.white54,
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _McpDialog(),
        ),
      ),
    );
  }
}

class _McpDialog extends ConsumerWidget {
  const _McpDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mcpServerProvider);
    final controller = ref.read(mcpServerProvider.notifier);
    return AlertDialog(
      title: const Text('MCP server'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.running ? 'Running' : 'Off'),
              subtitle: Text(s.running
                  ? 'Listening on ${s.url} (this Mac only)'
                  : 'Lets Claude Code control this tierlist'),
              value: s.running,
              onChanged: s.busy
                  ? null
                  : (on) => on ? controller.start() : controller.stop(),
            ),
            if (s.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(s.error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            if (s.running) ...[
              const SizedBox(height: 8),
              const Text('Add it to Claude Code (run once in a terminal):'),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  s.claudeCommand,
                  style: const TextStyle(fontFamily: 'Menlo', fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (s.running)
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy command'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: s.claudeCommand));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              }
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
