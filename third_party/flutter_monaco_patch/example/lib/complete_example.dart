import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

import 'custom_font_example.dart';
import 'focus_test_example.dart';
import 'multi_editor_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Monaco Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MonacoExamplePage(),
    );
  }
}

class MonacoExamplePage extends StatefulWidget {
  const MonacoExamplePage({super.key});

  @override
  State<MonacoExamplePage> createState() => _MonacoExamplePageState();
}

class _MonacoExamplePageState extends State<MonacoExamplePage> {
  MonacoController? _controller;
  bool _isLoading = true;
  String _currentLanguage = 'dart';
  String _currentTheme = 'vs-dark';

  static const List<CompletionItem> _keywordCompletions = [
    CompletionItem(
      label: 'todo',
      kind: CompletionItemKind.snippet,
      detail: 'Insert a TODO reminder',
      documentation: 'Adds a TODO comment with placeholders for owner/details.',
      insertText: '// TODO(\${1:owner}): \${2:details}\n',
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    CompletionItem(
      label: 'logger.info',
      kind: CompletionItemKind.method,
      detail: 'Structured info log',
      documentation: 'Writes an info log with payload placeholders.',
      insertText: "logger.info('\${1:message}', data: \${2:payload});",
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    CompletionItem(
      label: 'defer',
      kind: CompletionItemKind.keyword,
      detail: 'Run code after the current frame',
      documentation: 'Wraps a callback inside Future.microtask.',
      insertText: 'Future.microtask(() {\n  \${1:// work}\n});',
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
  ];

  static const List<_ApiCompletion> _cloudApiCompletions = [
    _ApiCompletion(
      label: 'acme.auth.signIn',
      detail: 'Authenticate a user',
      documentation: 'Calls POST /v1/auth/sign-in on Acme Cloud.',
      insertText:
          "acme.auth.signIn(email: '\${1:email}', password: '\${2:password}')",
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    _ApiCompletion(
      label: 'acme.storage.listBuckets',
      detail: 'List storage buckets',
      documentation: 'Returns the buckets available for the active project.',
    ),
    _ApiCompletion(
      label: 'acme.storage.object',
      detail: 'Reference a storage object',
      documentation: 'Reads metadata for a storage object.',
      kind: CompletionItemKind.property,
    ),
    _ApiCompletion(
      label: 'acme.analytics.logEvent',
      detail: 'Emit analytics event',
      documentation: 'Log a custom event with attributes.',
      insertText: "acme.analytics.logEvent('\${1:event}', data: \${2:{}});",
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    try {
      final controller = await MonacoController.create(
        options: const EditorOptions(
          language: MonacoLanguage.dart,
          theme: MonacoTheme.vsDark,
          fontSize: 14,
          wordWrap: true,
          minimap: false,
        ),
      );

      await controller.setValue(_sampleCode);
      await _registerCompletionSources(controller);

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing Monaco: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerCompletionSources(MonacoController controller) async {
    await controller.registerStaticCompletions(
      id: 'keywords',
      languages: [
        MonacoLanguage.dart.id,
        MonacoLanguage.javascript.id,
      ],
      triggerCharacters: const [' ', '.'],
      items: _keywordCompletions,
    );

    await controller.registerCompletionSource(
      id: 'acme-api',
      languages: [MonacoLanguage.dart.id],
      triggerCharacters: const ['.', '_'],
      provider: (request) async {
        final token = _extractCurrentWord(request);

        // Simulate a remote lookup
        await Future<void>.delayed(const Duration(milliseconds: 120));

        final suggestions = _cloudApiCompletions
            .where((entry) => token.isEmpty || entry.label.startsWith(token))
            .map((entry) => entry.toCompletionItem(request.defaultRange))
            .toList();

        return CompletionList(
          suggestions: suggestions,
          isIncomplete: token.isEmpty,
        );
      },
    );
  }

  String _extractCurrentWord(CompletionRequest request) {
    final line = request.lineText ?? '';
    if (line.isEmpty) return '';
    final cursor = (request.position.column - 1).clamp(0, line.length);
    final prefix = line.substring(0, cursor);
    final match = RegExp(r'([a-zA-Z0-9_.]+)$').firstMatch(prefix);
    return match?.group(0) ?? '';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Monaco Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.code),
            tooltip: 'Language',
            onSelected: (language) async {
              setState(() {
                _currentLanguage = language;
              });
              await _controller?.setLanguage(MonacoLanguage.fromId(language));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'dart', child: Text('Dart')),
              const PopupMenuItem(
                  value: 'javascript', child: Text('JavaScript')),
              const PopupMenuItem(value: 'python', child: Text('Python')),
              const PopupMenuItem(value: 'markdown', child: Text('Markdown')),
              const PopupMenuItem(value: 'json', child: Text('JSON')),
            ],
          ),
          // Theme selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Theme',
            onSelected: (theme) async {
              setState(() {
                _currentTheme = theme;
              });
              await _controller?.setTheme(MonacoTheme.fromId(theme));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'vs-dark', child: Text('Dark')),
              const PopupMenuItem(value: 'vs', child: Text('Light')),
              const PopupMenuItem(
                  value: 'hc-black', child: Text('High Contrast')),
            ],
          ),
          // Format button
          IconButton(
            icon: const Icon(Icons.format_align_left),
            tooltip: 'Format Document',
            onPressed: () async {
              await _controller?.format();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Editor toolbar
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Language: $_currentLanguage'),
                const SizedBox(width: 16),
                Text('Theme: $_currentTheme'),
                const Spacer(),
                // Live stats
                if (_controller != null)
                  ValueListenableBuilder<LiveStats>(
                    valueListenable: _controller!.liveStats,
                    builder: (context, stats, _) {
                      return Text(
                        'Lines: ${stats.lineCount.value} | '
                        'Chars: ${stats.charCount.value}',
                      );
                    },
                  ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _controller != null
                    ? MonacoEditor(
                        controller: _controller!,
                        onReady: (controller) {
                          debugPrint('Monaco Editor is ready!');
                        },
                      )
                    : const Center(
                        child: Text('Failed to initialize editor'),
                      ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Focus test button
          FloatingActionButton(
            heroTag: 'focus',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FocusTestExample(),
                ),
              );
            },
            backgroundColor: Colors.purple,
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(width: 8),
          // Multi-editor demo button
          FloatingActionButton.extended(
            heroTag: 'multi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MultiEditorExample(),
                ),
              );
            },
            label: const Text('Multi-Editor'),
            icon: const Icon(Icons.view_column),
            backgroundColor: Colors.green,
          ),
          const SizedBox(width: 8),
          // Custom font demo button
          FloatingActionButton.extended(
            heroTag: 'font',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomFontExample(),
                ),
              );
            },
            label: const Text('Custom Fonts'),
            icon: const Icon(Icons.font_download),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(width: 16),
          // Get content button
          FloatingActionButton.extended(
            heroTag: 'content',
            onPressed: () async {
              final content = await _controller?.getValue();
              if (content != null && context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Editor Content'),
                    content: SingleChildScrollView(
                      child: Text(content.substring(
                          0, content.length > 500 ? 500 : content.length)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
            label: const Text('Get Content'),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }

  static const String _sampleCode = r'''
// Welcome to Monaco Editor for Flutter!
// This is a fully-featured code editor based on VS Code's Monaco Editor.

void main() {
  print('Hello, Monaco!');
  
  // Features:
  // - Syntax highlighting for 100+ languages
  // - IntelliSense and auto-completion
  // - Multiple themes (Dark, Light, High Contrast)
  // - Find and replace
  // - Code formatting
  // - And much more!
  
  final languages = [
    'dart',
    'javascript', 
    'typescript',
    'python',
    'java',
    'csharp',
    'go',
    'rust',
    'markdown',
    'json',
    'yaml',
    'html',
    'css',
  ];
  
  for (final lang in languages) {
    print('Monaco supports: \$lang');
  }
}
''';
}

class _ApiCompletion {
  const _ApiCompletion({
    required this.label,
    required this.detail,
    required this.documentation,
    this.insertText,
    this.kind = CompletionItemKind.method,
    this.insertTextRules,
  });

  final String label;
  final String detail;
  final String documentation;
  final String? insertText;
  final CompletionItemKind kind;
  final Set<InsertTextRule>? insertTextRules;

  CompletionItem toCompletionItem(Range defaultRange) {
    return CompletionItem(
      label: label,
      insertText: insertText ?? label,
      kind: kind,
      detail: detail,
      documentation: documentation,
      sortText: '100_$label',
      filterText: label,
      range: defaultRange,
      insertTextRules: insertTextRules,
    );
  }
}
