# Flutter Monaco

[![pub package](https://img.shields.io/pub/v/flutter_monaco.svg?label=pub)](https://pub.dev/packages/flutter_monaco)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows-blue)](#platform-support)

A Flutter plugin for integrating the Monaco Editor (VS Code's editor) into Flutter applications via WebView.

<p align="center">
  <img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/macos.png?raw=true" alt="Flutter Monaco Editor on macOS" width="90%">
</p>

## Features

- 🎨 **Full Monaco Editor** - The same editor that powers VS Code
- 🌐 **100+ Language Support** - Syntax highlighting for all major languages
- 🎭 **Multiple Themes** - Dark, Light, and High Contrast themes
- 💾 **Versioned Asset Caching** - Efficient one-time asset installation
- 🖥️ **Cross-Platform** - Works on Android, iOS, macOS, and Windows
- ⚡ **Multiple Editors** - Support for unlimited independent editor instances
- 📊 **Live Statistics** - Real-time line/character counts and selection info
- 🎯 **Type-safe API** - Comprehensive typed bindings for Monaco's JavaScript API
- 🧠 **Custom IntelliSense** - Register multiple completion providers (static or remote)
- 🔍 **Find & Replace** - Full programmatic find/replace with regex support
- 🎭 **Decorations & Markers** - Add highlights, errors, warnings to your code
- 📡 **Event Streams** - Listen to content changes, selection, focus events

> **⚠️ Platform Support:** Currently supports **Android**, **iOS**, **macOS**, and **Windows**. Web and Linux are **not supported** at this time.

## Screenshots

<table>
  <tr>
    <td align="center" colspan="2"><b>Windows</b></td>
  </tr>
  <tr>
    <td colspan="2"><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/windows.png?raw=true" alt="Windows Screenshot" width="100%"></td>
  </tr>
  <tr>
    <td align="center" width="50%"><b>iOS</b></td>
    <td align="center" width="50%"><b>Android</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/ios.jpg?raw=true" alt="iOS Screenshot" width="100%"></td>
    <td><img src="https://github.com/omar-hanafy/flutter_monaco/blob/main/screenshots/android.jpg?raw=true" alt="Android Screenshot" width="100%"></td>
  </tr>
</table>

## Known Issues

- **Windows window focus flicker.** When clicking inside the embedded WebView (Monaco) on Windows, the host Flutter window may momentarily lose activation, which disables global keyboard shortcuts until the next click. This is a `flutter_webview_windows`/WebView2 quirk tracked upstream in [jnschulze/flutter-webview-windows#230](https://github.com/jnschulze/flutter-webview-windows/issues/230). We are monitoring that issue and will adopt the upstream fix as soon as it lands. Other platforms are unaffected.

## Installation

Add `flutter_monaco` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_monaco: ^<latest version>
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Monaco',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monaco Editor'),
        ),
        body: const MonacoEditor(
          showStatusBar: true,
        ),
      ),
    ),
  );
}
```

## Type-Safe Enums

Flutter Monaco provides type-safe enums for all configuration options, preventing runtime errors from invalid string values:

```dart
// Languages - 70+ programming languages supported
const EditorOptions(
  language: MonacoLanguage.typescript,  // Instead of 'typescript'
  theme: MonacoTheme.vsDark,           // Instead of 'vs-dark'
  cursorBlinking: CursorBlinking.smooth,
  cursorStyle: CursorStyle.block,
  renderWhitespace: RenderWhitespace.boundary,
  autoClosingBehavior: AutoClosingBehavior.languageDefined,
);

// Dynamic language selection (when loading from user preferences, etc.)
final language = MonacoLanguage.fromId('python');  // Convert string to enum
await controller.setLanguage(language);

// Theme selection with dynamic conversion
final theme = MonacoTheme.fromId('vs-dark');  // Convert string to enum
await controller.setTheme(theme);
```

### Available Enums

**MonacoTheme**
- `MonacoTheme.vs` - Light theme
- `MonacoTheme.vsDark` - Dark theme  
- `MonacoTheme.hcBlack` - High contrast dark
- `MonacoTheme.hcLight` - High contrast light

**MonacoLanguage** (70+ languages including)
- `MonacoLanguage.javascript`, `MonacoLanguage.typescript`, `MonacoLanguage.python`
- `MonacoLanguage.dart`, `MonacoLanguage.java`, `MonacoLanguage.csharp`
- `MonacoLanguage.go`, `MonacoLanguage.rust`, `MonacoLanguage.swift`
- `MonacoLanguage.html`, `MonacoLanguage.css`, `MonacoLanguage.scss`
- `MonacoLanguage.json`, `MonacoLanguage.yaml`, `MonacoLanguage.xml`
- `MonacoLanguage.markdown`, `MonacoLanguage.sql`, `MonacoLanguage.dockerfile`
- And many more...

**CursorBlinking**
- `CursorBlinking.blink` - Default blinking
- `CursorBlinking.smooth` - Smooth fade animation
- `CursorBlinking.phase` - Phase animation
- `CursorBlinking.expand` - Expand animation
- `CursorBlinking.solid` - No blinking

**CursorStyle**
- `CursorStyle.line` - Vertical line (default)
- `CursorStyle.block` - Block cursor
- `CursorStyle.underline` - Underline cursor
- `CursorStyle.lineThin` - Thin vertical line
- `CursorStyle.blockOutline` - Outlined block
- `CursorStyle.underlineThin` - Thin underline

**RenderWhitespace**
- `RenderWhitespace.none` - Don't render whitespace
- `RenderWhitespace.boundary` - Render whitespace at word boundaries
- `RenderWhitespace.selection` - Render whitespace in selection
- `RenderWhitespace.trailing` - Render trailing whitespace
- `RenderWhitespace.all` - Render all whitespace

**AutoClosingBehavior**
- `AutoClosingBehavior.always` - Always auto-close brackets
- `AutoClosingBehavior.languageDefined` - Use language defaults
- `AutoClosingBehavior.beforeWhitespace` - Auto-close before whitespace
- `AutoClosingBehavior.never` - Never auto-close

## Custom IntelliSense Completions

Monaco already knows how to merge results from multiple completion providers. Flutter Monaco now exposes this capability with a tiny, type-safe API that keeps all of the heavy lifting in Dart. Register static keyword/snippet lists or dynamic providers that call your own services.

```dart
final controller = await MonacoController.create(
  options: const EditorOptions(
    language: MonacoLanguage.typescript,
    theme: MonacoTheme.vsDark,
  ),
);

// Static completions (keywords/snippets/etc.)
await controller.registerStaticCompletions(
  id: 'keywords',
  languages: [
    MonacoLanguage.typescript.id,
    MonacoLanguage.javascript.id,
  ],
  triggerCharacters: const [' ', '.'],
  items: const [
    CompletionItem(
      label: 'pipeline',
      kind: CompletionItemKind.snippet,
      detail: 'Begin a pipeline section',
      documentation: 'Expands to a snippet with placeholders.',
      insertText: 'pipeline(${1:source}) {\n  ${2:// body}\n}',
      insertTextRules: {InsertTextRule.insertAsSnippet},
    ),
    CompletionItem(
      label: 'logger.info',
      kind: CompletionItemKind.method,
      detail: 'Log a message at INFO level',
      documentation: 'Simple helper around window.logger',
    ),
  ],
);

// Dynamic completions - call your own API or local data
await controller.registerCompletionSource(
  id: 'acme-api',
  languages: [MonacoLanguage.typescript.id],
  triggerCharacters: const ['.', '_'],
  provider: (CompletionRequest request) async {
    // You get request.language, uri, cursor position, current line, etc.
    final token = _currentWord(request);

    // Call your service (HTTP, database, anything)
    final response = await _completionClient.fetch(
      language: request.language,
      word: token,
      contextLine: request.lineText,
    );

    return CompletionList(
      suggestions: response.suggestions
          .map(
            (result) => CompletionItem(
              label: result.label,
              insertText: result.insertText,
              detail: result.detail,
              documentation: result.documentation,
              kind: CompletionItemKind.method,
              range: request.defaultRange,
            ),
          )
          .toList(),
      isIncomplete: response.hasMore,
    );
  },
);
```

Helper to grab the token before the cursor:

```dart
String _currentWord(CompletionRequest request) {
  final line = request.lineText ?? '';
  if (line.isEmpty) return '';
  final cursor = (request.position.column - 1).clamp(0, line.length);
  final prefix = line.substring(0, cursor);
  final match = RegExp(r'([a-zA-Z0-9_.]+)$').firstMatch(prefix);
  return match?.group(0) ?? '';
}
```

`CompletionRequest` includes useful metadata:

- `providerId`, `requestId` – identify the provider and respond to Monaco.
- `language`, `uri` – the model that triggered the request.
- `position`, `defaultRange`, `lineText` – cursor info plus the word range Monaco wants you to replace.
- `triggerKind`, `triggerCharacter` – what caused the completion (manual `Ctrl+Space`, character, etc.).

Need to remove a provider? Call `controller.unregisterCompletionSource(id)` at any time. You can register as many providers as you need—Monaco merges them and sorts via each item's `sortText`.

## Multiple Editors Example

Create a sophisticated multi-editor layout with different languages and themes:

```dart
class MultiEditorView extends StatefulWidget {
  @override
  State<MultiEditorView> createState() => _MultiEditorViewState();
}

class _MultiEditorViewState extends State<MultiEditorView> {
  MonacoController? _dartController;
  MonacoController? _jsController;
  MonacoController? _markdownController;

  @override
  void initState() {
    super.initState();
    _initializeEditors();
  }

  Future<void> _initializeEditors() async {
    // Create three independent editors with type-safe configurations
    _dartController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.dart,
        theme: MonacoTheme.vsDark,
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _jsController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.javascript,
        theme: MonacoTheme.vs,  // Light theme
        fontSize: 14,
        minimap: true,
      ),
    );
    
    _markdownController = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.markdown,
        theme: MonacoTheme.vsDark,
        fontSize: 15,
        wordWrap: true,
        minimap: false,
        lineNumbers: false,
      ),
    );
    
    // Set initial content
    await _dartController!.setValue('// Dart code');
    await _jsController!.setValue('// JavaScript code');
    await _markdownController!.setValue('# Markdown content');
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_dartController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Top row - Dart and JavaScript side by side
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _dartController!.webViewWidget),
              const VerticalDivider(width: 1),
              Expanded(child: _jsController!.webViewWidget),
            ],
          ),
        ),
        const Divider(height: 1),
        // Bottom - Markdown editor
        Expanded(
          child: _markdownController!.webViewWidget,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _dartController?.dispose();
    _jsController?.dispose();
    _markdownController?.dispose();
    super.dispose();
  }
}
```

## API Reference

### MonacoController

Main controller for interacting with the editor:

```dart
// Content management
await controller.setValue('const x = 42;');
String content = await controller.getValue();

// Language and theme (type-safe enums)
await controller.setLanguage(MonacoLanguage.javascript);
await controller.setTheme(MonacoTheme.vsDark);

// Editor actions
await controller.format();           // Format document
await controller.find();             // Open find dialog
await controller.replace();          // Open replace dialog
await controller.selectAll();        // Select all text
await controller.undo();             // Undo last action
await controller.redo();             // Redo last undone action

// Clipboard
await controller.cut();
await controller.copy();
await controller.paste();

// Navigation
await controller.scrollToTop();
await controller.scrollToBottom();
await controller.revealLine(100);    // Jump to line 100
await controller.focus();            // Request focus

// Custom actions
await controller.executeAction('editor.action.commentLine');

// Live statistics
controller.liveStats.addListener(() {
  final stats = controller.liveStats.value;
  print('Lines: ${stats.lineCount.value}');
  print('Characters: ${stats.charCount.value}');
  print('Selected: ${stats.selectedCharacters.value}');
});

// Event streams
controller.onContentChanged.listen((isFlush) {
  print('Content changed (full replace: $isFlush)');
});

controller.onSelectionChanged.listen((range) {
  print('Selection: $range');
});

controller.onFocus.listen((_) => print('Editor focused'));
controller.onBlur.listen((_) => print('Editor blurred'));
```

### Advanced Features

```dart
// Find and replace
final matches = await controller.findMatches(
  'TODO',
  options: const FindOptions(
    isRegex: false,
    matchCase: true,
    wholeWord: true,
  ),
);
print('Found ${matches.length} TODOs');

// Add error markers
await controller.setErrorMarkers([
  MarkerData.error(
    range: Range.lines(10, 10),
    message: 'Undefined variable',
    code: 'E001',
  ),
]);

// Add decorations (highlights)
await controller.addLineDecorations(
  [5, 10, 15],  // Line numbers
  'highlight-line',  // CSS class
);

// Work with multiple models
final uri = await controller.createModel(
  'console.log("New file");',
  language: MonacoLanguage.javascript,
);
await controller.setModel(uri);
```

### EditorOptions

Configure the editor appearance and behavior with type-safe enums:

```dart
const EditorOptions(
  language: MonacoLanguage.javascript,
  theme: MonacoTheme.vsDark,      // vs, vsDark, hcBlack, hcLight
  fontSize: 14,
  fontFamily: 'Consolas, monospace',
  lineHeight: 1.4,
  wordWrap: true,                  // or false
  minimap: false,
  lineNumbers: true,               // or false
  rulers: [80, 120],
  tabSize: 2,
  insertSpaces: true,
  readOnly: false,
  automaticLayout: true,           // Auto-resize with container
  scrollBeyondLastLine: true,
  smoothScrolling: false,
  cursorBlinking: CursorBlinking.blink,    // blink, smooth, phase, expand, solid
  cursorStyle: CursorStyle.line,           // line, block, underline, lineThin, blockOutline, underlineThin
  renderWhitespace: RenderWhitespace.selection,  // none, boundary, selection, trailing, all
  bracketPairColorization: true,
  formatOnPaste: false,
  formatOnType: false,
  quickSuggestions: true,
  parameterHints: true,
  hover: true,
  contextMenu: true,
  mouseWheelZoom: false,
  autoClosingBehavior: AutoClosingBehavior.languageDefined,  // always, languageDefined, beforeWhitespace, never
);
```

### MonacoAssets

Manage Monaco Editor assets:

```dart
// One-time initialization (called automatically)
await MonacoAssets.ensureReady();

// Get asset information
final info = await MonacoAssets.assetInfo();
print('Monaco cache: ${info['path']}');
print('Total size: ${info['totalSizeMB']} MB');
print('File count: ${info['fileCount']}');

// Clear cache (forces re-extraction on next use)
await MonacoAssets.clearCache();
```

## Architecture

### Asset Management

The plugin uses a versioned cache system:
- Monaco assets (~30MB) are bundled with the plugin in `assets/monaco/min/`
- Assets are extracted once to the app's support directory
- Assets are versioned (e.g., `monaco-0.52.2/`) for clean updates
- Multiple editors share the same asset installation
- Thread-safe initialization with re-entrant protection

### Platform Support

**Supported Platforms:**
- **Android**: WebView via `webview_flutter`
- **iOS**: WKWebView with automatic blob worker shim for file:// protocol
- **macOS**: WKWebView via `webview_flutter` with blob worker shim
- **Windows**: WebView2 via `webview_windows` (requires WebView2 Runtime)

**Not Supported:**
- **Web**: Not supported (asset bundling limitations)
- **Linux**: Not currently supported (WebKitGTK integration pending)

### Performance

- **Memory**: Each editor instance uses ~30-100MB depending on content
- **Startup**: First launch extracts assets (one-time ~1-2 seconds)
- **Multiple Editors**: Tested with 4+ simultaneous editors on desktop
- **Workers**: Web Workers run in separate threads for syntax highlighting

## Requirements

### macOS
- macOS 10.13 or later
- Xcode (for development)

### Windows
- Windows 10 version 1809 or later
- Microsoft Edge WebView2 Runtime (auto-installed on most Windows 10/11 systems)

### Android
- Android 5.0 (API level 21) or later
- WebView support (included by default)

### iOS
- iOS 11.0 or later
- Info.plist must allow local file access


## Example App

The [example](example/) directory contains a full demonstration app with:
- Basic single editor setup
- Language and theme switching
- Multi-editor layout (3 editors simultaneously)
- Live statistics display
- Content extraction and manipulation
- Cross-editor content copying

Run the example:
```bash
cd example
flutter run -d macos  # or android, ios, windows
```

## Important Notes

### Asset Management
Monaco Editor assets are **automatically bundled** with this plugin. You do not need to add any assets to your application. The plugin handles:
- Asset extraction on first launch
- Versioned caching for fast subsequent loads
- Automatic cleanup when updating versions

### Content Queuing
The controller automatically queues content and language changes made before the editor is ready. Your content won't be lost even if you call `setValue()` immediately after creating the controller.

### Event Handling
For advanced users, you can listen to raw JavaScript events:
```dart
controller.onContentChanged.listen((isFlush) { });
controller.onSelectionChanged.listen((range) { });
controller.onFocus.listen((_) { });
controller.onBlur.listen((_) { });
```

### Marker Owners
When using markers (diagnostics), the `clearAllMarkers()` method only clears markers from known owners ('flutter', 'flutter-errors', 'flutter-warnings'). Custom owners must be tracked and cleared separately.

## Troubleshooting

If you are seeing issues where the editor loses keyboard focus after navigating away and back, or after switching apps on macOS/Windows, see the comprehensive guide:

- Focus, First Responder, and Keyboard on Platform Views (macOS/Windows): doc/focus-and-platform-views.md

### Desktop Focus Helper (optional)
For apps that frequently switch routes or windows, you can drop in a tiny helper to reassert focus automatically:

```dart
// Once you have a MonacoController instance
MonacoFocusGuard(
  controller: controller,
  // optionally provide a RouteObserver to re-focus on route return
  // routeObserver: myRouteObserver,
);
```
See the guide above for details and best practices.

### Windows: WebView2 not found
If you get a WebView2 error on Windows, install the WebView2 Runtime:
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### macOS/iOS: Workers not loading
The plugin automatically configures a blob worker shim. If you still have issues:
1. Check the console output for errors
2. Ensure file:// access is allowed in your WebView configuration

### Assets not loading
If Monaco assets fail to load:
1. Check the console for error messages
2. Try clearing the cache: `await MonacoAssets.clearCache()`
3. Ensure your app has file system permissions

### Editor not responding
If the editor becomes unresponsive:
1. Check that JavaScript is enabled in the WebView
2. Verify the HTML file was generated correctly
3. Look for JavaScript errors in the console output

### Multiple editors performance
If performance degrades with multiple editors:
1. Limit to 3-4 editors on mobile devices
2. Disable minimap for better performance
3. Consider lazy initialization of editors

## Limitations

- **No Web/Linux Support**: The plugin currently only supports Android, iOS, macOS, and Windows.
- **Performance**: While optimized, running multiple editor instances (4+) can be resource-intensive, especially on older hardware. Each instance runs in a separate WebView, consuming 30-100MB of memory depending on content.
- **Startup Time**: The first time the app is launched, Monaco's assets (~30MB) are extracted, which can take 1-2 seconds. Subsequent launches are much faster.
- **WebView Dependencies**: The plugin relies on platform-specific WebView implementations (WebView2 on Windows, WKWebView on Apple platforms). Ensure the target system has the necessary dependencies.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request``

## Support

If you find this package useful, please consider giving it a star on [GitHub](https://github.com/omar-hanafy/flutter_monaco) and sharing it with the Flutter community.

## License

This plugin is licensed under the MIT License. See LICENSE file for details.

Monaco Editor is licensed under the MIT License by Microsoft.
