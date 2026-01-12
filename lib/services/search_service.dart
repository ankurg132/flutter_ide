import 'dart:async';

import 'package:meta/meta.dart';

@immutable
class SearchOptions {
  final bool caseSensitive;
  final bool regex;
  final int maxResults;

  const SearchOptions({
    this.caseSensitive = false,
    this.regex = false,
    this.maxResults = 500,
  });
}

@immutable
class SearchMatch {
  final String filePath;
  final String fileName;
  final int lineNumber; // 1-based
  final int columnNumber; // 1-based
  final String lineText;
  final int matchStartColumn; // 1-based
  final int matchLength;

  const SearchMatch({
    required this.filePath,
    required this.fileName,
    required this.lineNumber,
    required this.columnNumber,
    required this.lineText,
    required this.matchStartColumn,
    required this.matchLength,
  });
}

@immutable
class SearchFileResult {
  final String filePath;
  final String fileName;
  final List<SearchMatch> matches;

  const SearchFileResult({
    required this.filePath,
    required this.fileName,
    required this.matches,
  });
}

class SearchCancelled implements Exception {
  final String message;
  SearchCancelled([this.message = 'Search cancelled']);

  @override
  String toString() => message;
}

class SearchService {
  static const List<String> defaultIgnoredPathFragments = <String>[
    '/build/',
    '/.dart_tool/',
    '/.git/',
    '/node_modules/',
    '/.idea/',
    '/.vscode/',
    '/ios/Pods/',
    '/macos/Pods/',
    '/android/app/src/main/res/',
  ];

  bool isIgnoredPath(String path, {List<String> extraIgnoredFragments = const []}) {
    for (final frag in [...defaultIgnoredPathFragments, ...extraIgnoredFragments]) {
      if (path.contains(frag)) return true;
    }
    return false;
  }

  /// Searches [contentByFilePath] for [query].
  ///
  /// This method is pure and testable; call-sites can provide file content
  /// loaded through the platform-specific file service.
  List<SearchFileResult> searchInMemory({
    required Map<String, String> contentByFilePath,
    required String query,
    SearchOptions options = const SearchOptions(),
  }) {
    if (query.isEmpty) return const <SearchFileResult>[];

    final results = <SearchFileResult>[];
    final pattern = options.regex
        ? RegExp(query, caseSensitive: options.caseSensitive)
        : null;
    final needle = options.caseSensitive ? query : query.toLowerCase();

    int totalMatches = 0;

    for (final entry in contentByFilePath.entries) {
      if (totalMatches >= options.maxResults) break;

      final path = entry.key;
      final content = entry.value;

      final fileName = _basename(path);

      final lines = content.split('\n');
      final matches = <SearchMatch>[];

      for (int i = 0; i < lines.length; i++) {
        if (totalMatches >= options.maxResults) break;

        final line = lines[i];

        if (options.regex) {
          for (final m in pattern!.allMatches(line)) {
            if (totalMatches >= options.maxResults) break;

            final start0 = m.start;
            final length = m.end - m.start;

            matches.add(
              SearchMatch(
                filePath: path,
                fileName: fileName,
                lineNumber: i + 1,
                columnNumber: start0 + 1,
                lineText: line,
                matchStartColumn: start0 + 1,
                matchLength: length,
              ),
            );
            totalMatches++;
          }
        } else {
          final haystack = options.caseSensitive ? line : line.toLowerCase();
          int from = 0;
          while (from <= haystack.length) {
            if (totalMatches >= options.maxResults) break;
            final idx = haystack.indexOf(needle, from);
            if (idx == -1) break;

            matches.add(
              SearchMatch(
                filePath: path,
                fileName: fileName,
                lineNumber: i + 1,
                columnNumber: idx + 1,
                lineText: line,
                matchStartColumn: idx + 1,
                matchLength: query.length,
              ),
            );
            totalMatches++;
            from = idx + (query.isEmpty ? 1 : query.length);
          }
        }
      }

      if (matches.isNotEmpty) {
        results.add(
          SearchFileResult(filePath: path, fileName: fileName, matches: matches),
        );
      }
    }

    return results;
  }

  /// Helper for incremental, cancellable search.
  Stream<SearchFileResult> searchStream({
    required FutureOr<Iterable<MapEntry<String, String>>> Function() loadAllContent,
    required String query,
    SearchOptions options = const SearchOptions(),
    bool Function()? isCancelled,
  }) async* {
    if (query.isEmpty) return;

    final entries = await loadAllContent();
    if (isCancelled?.call() == true) throw SearchCancelled();

    final results = searchInMemory(
      contentByFilePath: Map<String, String>.fromEntries(entries),
      query: query,
      options: options,
    );

    for (final r in results) {
      if (isCancelled?.call() == true) throw SearchCancelled();
      yield r;
      await Future<void>.delayed(Duration.zero);
    }
  }

  String _basename(String path) {
    final idx = path.lastIndexOf('/');
    if (idx == -1) return path;
    return path.substring(idx + 1);
  }
}
