import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/file_system_entity.dart';
import '../../services/file_service.dart';
import '../../services/search_service.dart';

class GlobalSearchDialog extends StatefulWidget {
  final FileNodeDirectory root;
  final List<FileNodeFile> files;
  final void Function(SearchMatch match) onMatchSelected;

  const GlobalSearchDialog({
    super.key,
    required this.root,
    required this.files,
    required this.onMatchSelected,
  });

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  bool _caseSensitive = false;
  bool _regex = false;

  bool _isSearching = false;
  int _searchGeneration = 0;

  final _search = SearchService();

  List<SearchFileResult> _results = <SearchFileResult>[];
  int _flatSelectedIndex = 0;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      _startSearch();
    });
  }

  Future<void> _startSearch() async {
    final query = _queryController.text;

    // 1️⃣ Handle empty query FIRST (do not bump generation)
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = <SearchFileResult>[];
        _flatSelectedIndex = 0;
        _isSearching = false;
      });
      return;
    }

    // 2️⃣ Now bump generation (cancels previous searches safely)
    final generation = ++_searchGeneration;

    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _results = <SearchFileResult>[];
      _flatSelectedIndex = 0;
    });

    // 3️⃣ Loader: load file contents safely
    Future<Iterable<MapEntry<String, String>>> loader() async {
      final entries = <MapEntry<String, String>>[];

      for (final f in widget.files) {
        if (generation != _searchGeneration) break;

        if (_search.isIgnoredPath(f.path)) {
          continue;
        }

        final content = await fileService.readFile(f);

        if (generation != _searchGeneration) break;

        if (content == null || content.isEmpty) {
          continue;
        }

        // Optional size cap
        if (content.length > 1024 * 1024) continue;

        entries.add(MapEntry(f.path, content));
      }

      return entries;
    }

    try {
      final stream = _search.searchStream(
        loadAllContent: loader,
        query: query,
        options: SearchOptions(
          caseSensitive: _caseSensitive,
          regex: _regex,
          maxResults: 500,
        ),
        isCancelled: () => generation != _searchGeneration,
      );

      await for (final fileResult in stream) {
        if (!mounted || generation != _searchGeneration) break;

        setState(() {
          _results = [..._results, fileResult];
        });
      }
    } on SearchCancelled {
      // Expected (e.g., fast typing). Keep silent.
    } catch (_) {
      // Keep silent in UI; just show "No matches".
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = <SearchFileResult>[];
      });
    }

    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _isSearching = false;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return;
    }

    final flatMatches = _flattenMatches();
    if (flatMatches.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _flatSelectedIndex = (_flatSelectedIndex + 1).clamp(0, flatMatches.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _flatSelectedIndex = (_flatSelectedIndex - 1).clamp(0, flatMatches.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      widget.onMatchSelected(flatMatches[_flatSelectedIndex]);
    }
  }

  List<SearchMatch> _flattenMatches() {
    final out = <SearchMatch>[];
    for (final r in _results) {
      out.addAll(r.matches);
    }
    return out;
  }

  String _relativePath(String fullPath) {
    final rootPath = widget.root.path;
    if (fullPath.startsWith(rootPath)) {
      final start = (rootPath.endsWith('/') ? rootPath.length : rootPath.length + 1);
      if (fullPath.length >= start) return fullPath.substring(start);
    }
    return fullPath;
  }

  TextSpan _buildHighlightedLineSpan(String line, SearchMatch match) {
    final start0 = (match.matchStartColumn - 1).clamp(0, line.length);
    final end0 = (start0 + match.matchLength).clamp(start0, line.length);

    final before = line.substring(0, start0);
    final hit = line.substring(start0, end0);
    final after = line.substring(end0);

    const baseStyle = TextStyle(color: Colors.white70, fontSize: 12);

    return TextSpan(
      children: [
        TextSpan(text: before, style: baseStyle),
        TextSpan(
          text: hit,
          style: baseStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFF8B6B00),
          ),
        ),
        TextSpan(text: after, style: baseStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatMatches = _flattenMatches();

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: const Color(0xFF252526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 720,
          height: 520,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        focusNode: _focusNode,
                        onSubmitted: (_) => _startSearch(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search in files…',
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
                    const SizedBox(width: 10),
                    _toggle(
                      label: 'Aa',
                      tooltip: 'Case sensitive',
                      value: _caseSensitive,
                      onChanged: (v) {
                        setState(() => _caseSensitive = v);
                        _startSearch();
                      },
                    ),
                    const SizedBox(width: 6),
                    _toggle(
                      label: '.*',
                      tooltip: 'Regex',
                      value: _regex,
                      onChanged: (v) {
                        setState(() => _regex = v);
                        _startSearch();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: const Color(0xFF3C3C3C),
              ),

              if (widget.files.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No files loaded. Open a folder first (Cmd/Ctrl+O).',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),

              Expanded(
                child: _queryController.text.isEmpty
                    ? const Center(
                        child: Text('Type to search', style: TextStyle(color: Colors.white38)),
                      )
                    : flatMatches.isEmpty && !_isSearching
                        ? const Center(
                            child: Text('No matches', style: TextStyle(color: Colors.white38)),
                          )
                        : ListView.builder(
                            itemCount: flatMatches.length,
                            itemBuilder: (context, index) {
                              final m = flatMatches[index];
                              final selected = index == _flatSelectedIndex;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _flatSelectedIndex = index;
                                  });
                                  widget.onMatchSelected(m);
                                },
                                child: Container(
                                  color: selected ? const Color(0xFF094771) : null,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.insert_drive_file_outlined,
                                              size: 16, color: Colors.white54),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _relativePath(m.filePath),
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${m.lineNumber}:${m.columnNumber}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      RichText(
                                        text: _buildHighlightedLineSpan(m.lineText, m),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF3C3C3C), width: 1)),
                ),
                child: Row(
                  children: [
                    if (_isSearching)
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF42A5F5)),
                      ),
                    if (_isSearching) const SizedBox(width: 10),
                    Text(
                      _isSearching
                          ? 'Searching…'
                          : '${flatMatches.length} match${flatMatches.length == 1 ? '' : 'es'}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const Spacer(),
                    const Text(
                      'Esc to close · ↑/↓ navigate · Enter open',
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

  Widget _toggle({
    required String label,
    required String tooltip,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bg = value ? const Color(0xFF094771) : const Color(0xFF3C3C3C);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onChanged(!value),
        child: Container(
          height: 38,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
