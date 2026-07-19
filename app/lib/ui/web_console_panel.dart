import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../managers/browser/browser_manager.dart';

/// Bottom-docked JavaScript console for the WebView: live console.log /
/// warn / error output with level colors, plus copy/share for bug reports.
class WebConsolePanel extends StatefulWidget {
  const WebConsolePanel({
    super.key,
    required this.browser,
    required this.onClose,
  });

  final BrowserManager browser;
  final VoidCallback onClose;

  @override
  State<WebConsolePanel> createState() => _WebConsolePanelState();
}

class _WebConsolePanelState extends State<WebConsolePanel> {
  final _scroll = ScrollController();
  final _input = TextEditingController();

  static Color _levelColor(BuildContext context, String level) {
    switch (level) {
      case 'error':
        return Colors.red.shade300;
      case 'warn':
        return Colors.amber.shade300;
      case 'debug':
        return Colors.grey.shade500;
      case 'tip':
        return Colors.lightBlue.shade200;
      case 'cmd':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  /// Run typed JavaScript in the page, like the remote admin's web console.
  /// Echo and result go through the console feed itself, so copy/share
  /// capture the whole session and the live stream keeps its order.
  Future<void> _run() async {
    final code = _input.text.trim();
    if (code.isEmpty) return;
    _input.clear();
    widget.browser.onConsoleMessage('cmd', '> $code');
    final result = await widget.browser.eval(code);
    // Statements evaluate to null/undefined (the WebView reports them as
    // those strings); only actual values are worth a line.
    if (result != null && result != 'null' && result != 'undefined') {
      widget.browser.onConsoleMessage('log', result);
    }
  }

  String _export() => [
        for (final e in widget.browser.consoleEntries)
          '${e.time.toIso8601String()} [${e.level}] ${e.message}',
      ].join('\n');

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _export()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Console log copied'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _share() async {
    await Share.share(_export(), subject: 'Kiosk Satellite console log');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.38,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                    bottom:
                        BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.terminal_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Web Console', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy log',
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: _copy,
                    ),
                    IconButton(
                      tooltip: 'Share log',
                      icon: const Icon(Icons.share_outlined, size: 18),
                      onPressed: _share,
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.block_outlined, size: 18),
                      onPressed: widget.browser.clearConsole,
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              // Entries
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.browser.consoleRevision,
                  builder: (context, revision, child) {
                    final entries = widget.browser.consoleEntries;
                    // Keep pinned to the newest entry.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scroll.hasClients) {
                        _scroll.jumpTo(_scroll.position.maxScrollExtent);
                      }
                    });
                    if (entries.isEmpty) {
                      return Center(
                        child: Text('No console output yet',
                            style: theme.textTheme.bodySmall),
                      );
                    }
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text:
                                    '${entry.time.toIso8601String().substring(11, 19)} ',
                                style: TextStyle(
                                    color: theme.colorScheme.outline),
                              ),
                              TextSpan(text: entry.message),
                            ]),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _levelColor(context, entry.level),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // The REPL half, mirroring the remote admin's web console.
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      '>',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _run(),
                        textInputAction: TextInputAction.send,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Run JavaScript in the page',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Run',
                      icon: const Icon(Icons.send, size: 18),
                      onPressed: _run,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }
}
