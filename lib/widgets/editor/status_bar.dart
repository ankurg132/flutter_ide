import 'package:flutter/material.dart';

class StatusBarItem extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onPressed;

  const StatusBarItem({
    super.key,
    this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  State<StatusBarItem> createState() => _StatusBarItemState();
}

class _StatusBarItemState extends State<StatusBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: _isHovered ? const Color(0x1FFFFFFF) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.only(
                    right: widget.label != null && widget.label!.isNotEmpty
                        ? 4
                        : 0,
                  ),
                  child: Icon(widget.icon, size: 14, color: Colors.white),
                ),
              if (widget.label != null && widget.label!.isNotEmpty)
                Text(
                  widget.label!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBarDivider extends StatelessWidget {
  const StatusBarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }
}
