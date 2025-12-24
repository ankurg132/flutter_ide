import 'package:flutter/material.dart';

class WelcomeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final VoidCallback onPressed;

  const WelcomeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onPressed,
  });

  @override
  State<WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<WelcomeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF007ACC)
                : const Color(0xFF0E639C),
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0x4D007ACC),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.shortcut,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final String? rootName;
  final VoidCallback onPickDirectory;
  final VoidCallback? onCreateNewFile;

  const WelcomeScreen({
    super.key,
    this.rootName,
    required this.onPickDirectory,
    this.onCreateNewFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 64, color: Color(0x1AFFFFFF)),
            const SizedBox(height: 24),
            const Text(
              'Flutter IDE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a file or folder to get started',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WelcomeButton(
                  icon: Icons.folder_open,
                  label: 'Open Folder',
                  shortcut: '⌘O',
                  onPressed: onPickDirectory,
                ),
                const SizedBox(width: 16),
                if (onCreateNewFile != null)
                  WelcomeButton(
                    icon: Icons.note_add,
                    label: 'New File',
                    shortcut: '⌘N',
                    onPressed: onCreateNewFile!,
                  ),
              ],
            ),
            const SizedBox(height: 48),
            if (rootName != null) ...[
              const Text(
                'Recent',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.folder,
                      size: 16,
                      color: Color(0xFF90A4AE),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rootName!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
