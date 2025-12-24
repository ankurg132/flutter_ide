import 'package:flutter/material.dart';
import '../../models/file_system_entity.dart';
import '../../models/web_tab.dart';

class EditorTab extends StatefulWidget {
  final FileNodeFile file;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Icon icon;

  const EditorTab({
    super.key,
    required this.file,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.icon,
  });

  @override
  State<EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<EditorTab> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 4),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF1E1E1E)
                : _isHovered
                ? const Color(0xFF2D2D2D)
                : const Color(0xFF252526),
            border: widget.isActive
                ? const Border(
                    top: BorderSide(color: Color(0xFF007ACC), width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.file.name,
                  style: TextStyle(
                    color: widget.isActive || _isHovered
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                onEnter: (_) => setState(() => _isCloseHovered = true),
                onExit: (_) => setState(() => _isCloseHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isCloseHovered ? const Color(0x33FFFFFF) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: _isHovered || widget.isActive
                          ? Colors.white70
                          : Colors.transparent,
                    ),
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

class WebEditorTab extends StatefulWidget {
  final WebTab webTab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const WebEditorTab({
    super.key,
    required this.webTab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<WebEditorTab> createState() => _WebEditorTabState();
}

class _WebEditorTabState extends State<WebEditorTab> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 4),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF1E1E1E)
                : _isHovered
                ? const Color(0xFF2D2D2D)
                : const Color(0xFF252526),
            border: widget.isActive
                ? const Border(
                    top: BorderSide(color: Color(0xFF007ACC), width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 14, color: Color(0xFF42A5F5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.webTab.title,
                  style: TextStyle(
                    color: widget.isActive || _isHovered
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                onEnter: (_) => setState(() => _isCloseHovered = true),
                onExit: (_) => setState(() => _isCloseHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isCloseHovered ? const Color(0x33FFFFFF) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: _isHovered || widget.isActive
                          ? Colors.white70
                          : Colors.transparent,
                    ),
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
