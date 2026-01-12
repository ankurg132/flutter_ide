import 'package:flutter/material.dart';

class SearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SearchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.search, color: Colors.white54, size: 20),
      tooltip: 'Search in files (Cmd/Ctrl+Shift+F)',
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
    );
  }
}
