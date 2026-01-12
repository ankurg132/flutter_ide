import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class MultiEditorExample extends StatefulWidget {
  const MultiEditorExample({super.key});

  @override
  State<MultiEditorExample> createState() => _MultiEditorExampleState();
}

class _MultiEditorExampleState extends State<MultiEditorExample> {
  MonacoController? _leftController;
  MonacoController? _rightController;
  MonacoController? _bottomController;
  bool _isLoading = true;
  String _loadingStatus = 'Initializing editors...';

  @override
  void initState() {
    super.initState();
    _initializeEditors();
  }

  Future<void> _initializeEditors() async {
    try {
      setState(() {
        _loadingStatus = 'Creating left editor (Dart)...';
      });

      // Left editor - Dart code
      _leftController = await MonacoController.create(
        options: const EditorOptions(
          language: MonacoLanguage.dart,
          theme: MonacoTheme.vsDark,
          fontSize: 14,
          wordWrap: false,
          minimap: true,
          automaticLayout: true,
        ),
      );
      await _leftController!.setValue(_dartCode);

      setState(() {
        _loadingStatus = 'Creating right editor (JavaScript)...';
      });

      // Right editor - JavaScript code
      _rightController = await MonacoController.create(
        options: const EditorOptions(
          language: MonacoLanguage.javascript,
          theme: MonacoTheme.vs,
          fontSize: 14,
          wordWrap: false,
          minimap: true,
          automaticLayout: true,
        ),
      );
      await _rightController!.setValue(_jsCode);

      setState(() {
        _loadingStatus = 'Creating bottom editor (Markdown)...';
      });

      // Bottom editor - Markdown
      _bottomController = await MonacoController.create(
        options: const EditorOptions(
          language: MonacoLanguage.markdown,
          theme: MonacoTheme.vsDark,
          fontSize: 15,
          wordWrap: true,
          minimap: false,
          automaticLayout: true,
          lineNumbers: false,
        ),
      );
      await _bottomController!.setValue(_markdownContent);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing editors: $e');
      setState(() {
        _loadingStatus = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _leftController?.dispose();
    _rightController?.dispose();
    _bottomController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Multi-Editor Example'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_loadingStatus),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Editor Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Copy from left to right
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            tooltip: 'Copy Dart → JS',
            onPressed: () async {
              final content = await _leftController!.getValue();
              await _rightController!
                  .setValue('// Copied from Dart editor:\n/*\n$content\n*/');
            },
          ),
          // Copy from right to left
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Copy JS → Dart',
            onPressed: () async {
              final content = await _rightController!.getValue();
              await _leftController!
                  .setValue('// Copied from JS editor:\n/*\n$content\n*/');
            },
          ),
          // Sync themes
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            tooltip: 'Sync Themes',
            onSelected: (theme) async {
              await Future.wait([
                _leftController!.setTheme(MonacoTheme.fromId(theme)),
                _rightController!.setTheme(MonacoTheme.fromId(theme)),
                _bottomController!.setTheme(MonacoTheme.fromId(theme)),
              ]);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'vs-dark', child: Text('All Dark')),
              const PopupMenuItem(value: 'vs', child: Text('All Light')),
              const PopupMenuItem(
                  value: 'hc-black', child: Text('All High Contrast')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top section - Split view
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Left editor with stats
                Expanded(
                  child: Column(
                    children: [
                      _buildEditorHeader(
                        'Dart Code',
                        _leftController!,
                        Colors.blue,
                      ),
                      Expanded(
                        child: _leftController!.webViewWidget,
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                // Right editor with stats
                Expanded(
                  child: Column(
                    children: [
                      _buildEditorHeader(
                        'JavaScript Code',
                        _rightController!,
                        Colors.orange,
                      ),
                      Expanded(
                        child: _rightController!.webViewWidget,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Bottom section - Markdown editor
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildEditorHeader(
                  'Markdown Notes',
                  _bottomController!,
                  Colors.green,
                ),
                Expanded(
                  child: _bottomController!.webViewWidget,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Get content from all editors
          final dartContent = await _leftController!.getValue();
          final jsContent = await _rightController!.getValue();
          final mdContent = await _bottomController!.getValue();

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('All Editor Contents'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Dart (${dartContent.length} chars)'),
                      const SizedBox(height: 8),
                      Text('JavaScript (${jsContent.length} chars)'),
                      const SizedBox(height: 8),
                      Text('Markdown (${mdContent.length} chars)'),
                    ],
                  ),
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
        label: const Text('Get All Content'),
        icon: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildEditorHeader(
    String title,
    MonacoController controller,
    Color color,
  ) {
    return Container(
      height: 32,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.code, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          // Live stats
          ValueListenableBuilder<LiveStats>(
            valueListenable: controller.liveStats,
            builder: (context, stats, _) {
              return Row(
                children: [
                  if (stats.language != null) ...[
                    Chip(
                      label: Text(
                        stats.language!,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'L:${stats.lineCount.value} C:${stats.charCount.value}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  if (stats.hasSelection) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Sel:${stats.selectedCharacters.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static const String _dartCode = '''
// Dart Example - Flutter Widget
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  
  const MyWidget({
    super.key,
    required this.title,
    this.onPressed,
  });

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _counter = 0;
  
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    widget.onPressed?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(widget.title),
        subtitle: Text('Counter: \$_counter'),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _incrementCounter,
        ),
      ),
    );
  }
}
''';

  static const String _jsCode = '''
// JavaScript Example - React Component
import React, { useState, useCallback } from 'react';
import { Card, Button, Badge } from '@/components/ui';

export function CounterWidget({ title, onCountChange }) {
  const [count, setCount] = useState(0);
  
  const handleIncrement = useCallback(() => {
    const newCount = count + 1;
    setCount(newCount);
    onCountChange?.(newCount);
  }, [count, onCountChange]);
  
  const handleDecrement = useCallback(() => {
    const newCount = Math.max(0, count - 1);
    setCount(newCount);
    onCountChange?.(newCount);
  }, [count, onCountChange]);
  
  return (
    <Card className="p-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">{title}</h3>
        <Badge variant="secondary">{count}</Badge>
      </div>
      <div className="mt-4 flex gap-2">
        <Button onClick={handleDecrement} variant="outline">
          Decrement
        </Button>
        <Button onClick={handleIncrement}>
          Increment
        </Button>
      </div>
    </Card>
  );
}
''';

  static const String _markdownContent = '''
# Multi-Editor Demo

This example demonstrates **three independent Monaco editors** running simultaneously:

## Features Demonstrated

1. **Multiple Languages**: Each editor has different syntax highlighting
   - Left: Dart with dark theme
   - Right: JavaScript with light theme  
   - Bottom: Markdown with word wrap

2. **Independent Configuration**: Each editor has its own:
   - Theme settings
   - Font sizes
   - Minimap preferences
   - Line number visibility

3. **Live Statistics**: Each header shows real-time:
   - Line count
   - Character count
   - Selection info
   - Language mode

## Try These Actions

- [ ] Select text in any editor
- [ ] Use the arrow buttons to copy between editors
- [ ] Change all themes at once with the palette button
- [ ] Edit content and watch stats update
- [ ] Resize the window - editors auto-layout

## Performance

Notice how smooth everything runs even with 3 editors! 
Each maintains its own state and WebView instance.
''';
}
