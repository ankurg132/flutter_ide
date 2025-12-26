import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

class OutputPanel extends StatefulWidget {
  final bool isVisible;
  final double height;
  final String? workingDirectory;
  final String? initialCommand;
  final VoidCallback? onCommandExecuted;
  final VoidCallback? onCloseTerminal;

  const OutputPanel({
    super.key,
    required this.isVisible,
    this.height = 250,
    this.workingDirectory,
    this.initialCommand,
    this.onCommandExecuted,
    this.onCloseTerminal,
  });

  @override
  State<OutputPanel> createState() => _OutputPanelState();
}

class _OutputPanelState extends State<OutputPanel> {
  final terminal = Terminal(maxLines: 10000);
  final focusNode = FocusNode();
  Pty? pty;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      // Terminal focus listener
    });
    // Start PTY after first frame if visible
    if (widget.isVisible) {
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) _startPty();
      });
    }
  }

  @override
  void didUpdateWidget(OutputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start or restart PTY when terminal becomes visible
    if (widget.isVisible && !oldWidget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pty == null) {
          _startPty();
        }
        focusNode.requestFocus();
      });
    }
    // Restart PTY if working directory changes
    if (widget.workingDirectory != oldWidget.workingDirectory &&
        widget.workingDirectory != null &&
        widget.isVisible) {
      _restartPty();
    }
    // Run initial command if provided
    if (widget.initialCommand != null &&
        widget.initialCommand != oldWidget.initialCommand) {
      _runCommand(widget.initialCommand!);
    }
  }

  void _runCommand(String command) {
    // Always defer to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pty == null) {
        // PTY not ready yet, try again next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (pty != null && mounted) {
            pty!.write(Uint8List.fromList(utf8.encode('$command\n')));
            widget.onCommandExecuted?.call();
          }
        });
      } else {
        pty!.write(Uint8List.fromList(utf8.encode('$command\n')));
        widget.onCommandExecuted?.call();
      }
    });
  }

  void _startPty() {
    if (pty != null) return;

    // Determine shell based on platform
    final shell = Platform.isWindows
        ? 'cmd.exe'
        : Platform.environment['SHELL'] ?? '/bin/bash';

    try {
      // Use default dimensions if terminal hasn't been laid out yet
      final columns = terminal.viewWidth > 0 ? terminal.viewWidth : 80;
      final rows = terminal.viewHeight > 0 ? terminal.viewHeight : 24;

      pty = Pty.start(
        shell,
        columns: columns,
        rows: rows,
        workingDirectory: widget.workingDirectory,
        environment: Platform.environment,
      );
      // PTY output → display in terminal
      pty!.output.listen((data) {
        final text = utf8.decode(data);
        terminal.write(text);
      });

      // Terminal input (keystrokes) → send to PTY
      terminal.onOutput = (data) {
        pty?.write(Uint8List.fromList(utf8.encode(data)));
      };

      // Handle terminal resize
      terminal.onResize = (width, height, pixelWidth, pixelHeight) {
        pty?.resize(height, width);
      };
    } catch (e) {
      terminal.write('Failed to start terminal: $e\r\n');
    }
  }

  void _restartPty() {
    pty?.kill();
    pty = null;
    terminal.buffer.clear();
    _startPty();
  }

  @override
  void dispose() {
    pty?.kill();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Container(
      height: widget.height,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF3C3C3C), width: 1)),
      ),
      child: Column(
        children: [
          // Terminal header
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  'Terminal',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                _TerminalHeaderButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Clear',
                  onPressed: () {
                    pty?.write(Uint8List.fromList(utf8.encode("clear\n")));
                  },
                ),
                _TerminalHeaderButton(
                  icon: Icons.close,
                  tooltip: 'Close Terminal',
                  onPressed: () {
                    widget.onCloseTerminal?.call();
                    pty?.write(Uint8List.fromList(utf8.encode("clear\n")));
                  },
                ),
              ],
            ),
          ),
          // Terminal view
          Expanded(
            child: TerminalView(
              terminal,
              focusNode: focusNode,
              autofocus: true,
              textStyle: const TerminalStyle(
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TerminalHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.white54),
        ),
      ),
    );
  }
}
