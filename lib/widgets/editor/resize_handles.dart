import 'package:flutter/material.dart';

class HorizontalResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const HorizontalResizeHandle({
    super.key,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          onDrag(details.delta.dx);
        },
        child: Container(
          width: 4,
          color: const Color(0xFF3C3C3C),
          child: Center(
            child: Container(
              width: 2,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VerticalResizeHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;

  const VerticalResizeHandle({
    super.key,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          onDrag(details.delta.dy);
        },
        child: Container(
          height: 4,
          color: const Color(0xFF3C3C3C),
          child: Center(
            child: Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
