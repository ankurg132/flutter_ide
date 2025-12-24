import 'package:flutter/material.dart';

class ActivityBarItem extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const ActivityBarItem({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<ActivityBarItem> createState() => _ActivityBarItemState();
}

class _ActivityBarItemState extends State<ActivityBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0x1AFFFFFF) : null,
              border: Border(
                left: BorderSide(
                  color: widget.isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: widget.isSelected || _isHovered
                  ? Colors.white
                  : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const SidebarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0x1AFFFFFF) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? Colors.white : Colors.white70,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
