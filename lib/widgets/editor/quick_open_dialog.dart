import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../models/file_system_entity.dart';

class QuickOpenDialog extends StatefulWidget {
  final List<FileNodeFile> files;
  final String rootPath;
  final Function(FileNodeFile) onFileSelected;

  const QuickOpenDialog({
    super.key,
    required this.files,
    required this.rootPath,
    required this.onFileSelected,
  });

  @override
  State<QuickOpenDialog> createState() => _QuickOpenDialogState();
}

class _QuickOpenDialogState extends State<QuickOpenDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FileNodeFile> _filteredFiles = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredFiles = _sortFiles(List.from(widget.files));
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<FileNodeFile> results;
      if (query.isEmpty) {
        results = List.from(widget.files);
      } else {
        results = widget.files.where((file) {
          return file.name.toLowerCase().contains(query) ||
              file.path.toLowerCase().contains(query);
        }).toList();
      }
      _filteredFiles = _sortFiles(results);
      _selectedIndex = 0;
    });
  }

  List<FileNodeFile> _sortFiles(List<FileNodeFile> files) {
    // Priority: Dart files first, build folder last, alphabetical within groups
    files.sort((a, b) {
      final aInBuild = a.path.contains('/build/');
      final bInBuild = b.path.contains('/build/');
      final aIsDart = a.name.endsWith('.dart');
      final bIsDart = b.name.endsWith('.dart');

      // Build folder files go last
      if (aInBuild && !bInBuild) return 1;
      if (!aInBuild && bInBuild) return -1;

      // Dart files go first (unless in build folder)
      if (aIsDart && !bIsDart) return -1;
      if (!aIsDart && bIsDart) return 1;

      // Alphabetical by name within same priority
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return files;
  }

  String _getRelativePath(String fullPath) {
    if (fullPath.startsWith(widget.rootPath)) {
      return fullPath.substring(widget.rootPath.length + 1);
    }
    return fullPath;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _filteredFiles.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _filteredFiles.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredFiles.isNotEmpty) {
        widget.onFileSelected(_filteredFiles[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  Icon _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData icon = Icons.insert_drive_file_outlined;
    Color color = Colors.grey;

    switch (ext) {
      case '.dart':
        icon = Icons.code;
        color = const Color(0xFF42A5F5);
        break;
      case '.yaml':
      case '.yml':
        icon = Icons.settings;
        color = const Color(0xFFEF5350);
        break;
      case '.json':
        icon = Icons.data_object;
        color = const Color(0xFF66BB6A);
        break;
      case '.md':
        icon = Icons.description;
        color = Colors.white70;
        break;
      case '.html':
        icon = Icons.html;
        color = const Color(0xFFE65100);
        break;
      case '.css':
        icon = Icons.css;
        color = const Color(0xFF1E88E5);
        break;
      case '.js':
      case '.ts':
        icon = Icons.javascript;
        color = const Color(0xFFFFCA28);
        break;
    }
    return Icon(icon, size: 18, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: const Color(0xFF252526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search files by name...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF3C3C3C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // File list
              Flexible(
                child: _filteredFiles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No files found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          final isSelected = index == _selectedIndex;
                          final relativePath = _getRelativePath(file.path);

                          return InkWell(
                            onTap: () => widget.onFileSelected(file),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: isSelected ? const Color(0xFF094771) : null,
                              child: Row(
                                children: [
                                  _getFileIcon(file.name),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          relativePath,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF3C3C3C), width: 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      '↑↓ to navigate  ',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      '↵ to open  ',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      'esc to close',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
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
}
