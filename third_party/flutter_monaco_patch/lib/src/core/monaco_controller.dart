import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/src/core/monaco_assets.dart';
import 'package:flutter_monaco/src/core/monaco_bridge.dart';
import 'package:flutter_monaco/src/models/editor_options.dart';
import 'package:flutter_monaco/src/models/monaco_enums.dart';
import 'package:flutter_monaco/src/models/monaco_types.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

/// A callback function that provides completion items for a given
/// [CompletionRequest]. It should return a [Future] that resolves to a
/// [CompletionList].
typedef CompletionProvider = Future<CompletionList> Function(
  CompletionRequest request,
);

/// Main controller for a Monaco Editor instance
class MonacoController {
  MonacoController._(this._bridge, this._webViewController) {
    _wireEvents();
  }

  final MonacoBridge _bridge;
  final PlatformWebViewController _webViewController;
  final Completer<void> _onReady = Completer<void>();

  // Event streams
  final _onContentChanged = StreamController<bool>.broadcast();
  final _onSelectionChanged = StreamController<Range?>.broadcast();
  final _onFocus = StreamController<void>.broadcast();
  final _onBlur = StreamController<void>.broadcast();

  // Decoration tracking
  List<String> _decorationIds = const [];

  // Content queuing for pre-ready calls
  String? _queuedValue;
  MonacoLanguage? _queuedLanguage;
  final Map<String, _RegisteredCompletion> _completionSources = {};
  bool _completionListenerWired = false;

  /// Future that completes when the editor is ready
  Future<void> get onReady => _onReady.future;

  /// Live statistics from the editor
  ValueNotifier<LiveStats> get liveStats => _bridge.liveStats;

  /// Stream of content change events (isFlush indicates full content change)
  Stream<bool> get onContentChanged => _onContentChanged.stream;

  /// Stream of selection change events
  Stream<Range?> get onSelectionChanged => _onSelectionChanged.stream;

  /// Stream of focus events
  Stream<void> get onFocus => _onFocus.stream;

  /// Stream of blur events
  Stream<void> get onBlur => _onBlur.stream;

  /// Create a new Monaco Editor controller
  ///
  /// [options] - Editor configuration options
  /// [customCss] - Custom CSS to inject into the editor (e.g., @font-face rules)
  /// [allowCdnFonts] - Whether to allow loading fonts from CDNs (default: false for security)
  /// [readyTimeout] - Maximum time to wait for editor initialization
  static Future<MonacoController> create({
    EditorOptions? options,
    String? customCss,
    bool allowCdnFonts = false,
    Duration? readyTimeout,
  }) async {
    // Ensure Monaco assets are ready
    await MonacoAssets.ensureReady();

    // Create platform-specific WebView controller
    final webViewController = PlatformWebViewFactory.createController();

    // Create and attach bridge
    final bridge = MonacoBridge()..attachWebView(webViewController);

    // Initialize WebView based on platform
    if (Platform.isWindows) {
      await _initializeWindowsWebView(
        webViewController as WindowsWebViewController,
        bridge,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    } else {
      // macOS, iOS, and other platforms use the Flutter WebView
      await _initializeFlutterWebView(
        webViewController as FlutterWebViewController,
        bridge,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    }

    // Wait for editor ready signal with configurable timeout
    await bridge.onReady.future.timeout(
      readyTimeout ?? const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Monaco Editor did not report ready in ${readyTimeout?.inSeconds ?? 20} seconds.',
      ),
    );

    // Create controller
    final controller = MonacoController._(bridge, webViewController);

    // Mark ready BEFORE applying options to avoid deadlock
    if (!controller._onReady.isCompleted) {
      controller._onReady.complete();
    }

    // Apply initial options if provided
    if (options != null) {
      await controller.updateOptions(options);
      await controller.setTheme(options.theme);
      await controller.setLanguage(options.language);
    }

    // Apply any queued content
    if (controller._queuedValue != null) {
      await controller.setValue(controller._queuedValue!);
      controller._queuedValue = null;
    }
    if (controller._queuedLanguage != null) {
      await controller.setLanguage(controller._queuedLanguage!);
      controller._queuedLanguage = null;
    }

    return controller;
  }

  static Future<void> _initializeWindowsWebView(
    WindowsWebViewController controller,
    MonacoBridge bridge, {
    String? customCss,
    bool allowCdnFonts = false,
  }) async {
    // Initialize WebView2
    await controller.initialize();

    // Set up JavaScript channel
    await controller.addJavaScriptChannel(
      'flutterChannel',
      bridge.handleJavaScriptMessage,
    );

    // Load HTML file with custom CSS if provided
    final htmlFilePath = await MonacoAssets.indexHtmlPath(
      customCss: customCss,
      allowCdnFonts: allowCdnFonts,
    );
    debugPrint('[MonacoController] Loading HTML from file: $htmlFilePath');

    final htmlUri = Uri.file(htmlFilePath);
    await controller.loadUrl(htmlUri.toString());
  }

  static Future<void> _initializeFlutterWebView(
    FlutterWebViewController controller,
    MonacoBridge bridge, {
    String? customCss,
    bool allowCdnFonts = false,
  }) async {
    // Configure WebView
    await controller.setJavaScriptMode();

    // Set up JavaScript channel
    await controller.addJavaScriptChannel(
      'flutterChannel',
      bridge.handleJavaScriptMessage,
    );

    // Set up console logging for debugging
    await controller.setOnConsoleMessage((message) {
      debugPrint('[Monaco Console] ${message.level.name}: ${message.message}');
    });

    // Set navigation delegates
    controller.setNavigationDelegate(
      wf.NavigationDelegate(
        onPageFinished: (url) {
          debugPrint('[MonacoController] WebView Page Finished: $url');
        },
        onWebResourceError: (error) {
          debugPrint(
            '[MonacoController] WebView Error: ${error.description} on ${error.url}',
          );
        },
      ),
    );

    // Load HTML file with custom CSS if provided
    final htmlFilePath = await MonacoAssets.indexHtmlPath(
      customCss: customCss,
      allowCdnFonts: allowCdnFonts,
    );
    debugPrint(
        '[MonacoController] Loading HTML from: $htmlFilePath (Platform: ${Platform.operatingSystem})');
    await controller.flutterController.loadFile(htmlFilePath);
  }

  /// Get the platform-specific WebView widget
  /// Supported: Windows (WebView2), macOS/iOS (WKWebView)
  Widget get webViewWidget {
    if (Platform.isWindows) {
      return ww.Webview(
        (_webViewController as WindowsWebViewController).windowsController,
      );
    } else {
      // macOS, iOS use webview_flutter
      return wf.WebViewWidget(
        controller:
            (_webViewController as FlutterWebViewController).flutterController,
      );
    }
  }

  /// Ensure the editor is ready before executing commands
  Future<void> _ensureReady() async {
    if (!_onReady.isCompleted) {
      await _onReady.future;
    }
  }

  /// Set the editor language
  Future<void> setLanguage(MonacoLanguage language) async {
    if (!_onReady.isCompleted) {
      _queuedLanguage = language;
      await _ensureReady();
      if (_queuedLanguage == language) {
        // Only use queued value if it hasn't been overwritten
        _queuedLanguage = null;
      } else {
        return; // A newer language was queued, skip this one
      }
    }
    await _webViewController.runJavaScript(
      'flutterMonaco.setLanguage(${jsonEncode(language.id)})',
    );
  }

  /// Set the editor theme
  Future<void> setTheme(MonacoTheme theme) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setTheme(${jsonEncode(theme.id)})',
    );
  }

  /// Update editor options
  Future<void> updateOptions(EditorOptions options) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.updateOptions(${jsonEncode(options.toMonacoOptions())})',
    );
  }

  /// Register a completion provider for the given languages.
  ///
  /// Provide Monaco language ids (e.g. [MonacoLanguage.typescript.id]) in [languages].
  Future<String> registerCompletionSource({
    String? id,
    required List<String> languages,
    List<String> triggerCharacters = const [],
    required CompletionProvider provider,
  }) async {
    if (languages.isEmpty) {
      throw ArgumentError.value(languages, 'languages', 'Cannot be empty');
    }
    if (id != null && _completionSources.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Completion source already exists');
    }

    await _ensureReady();
    final providerId = id ??
        'flutter_${DateTime.now().millisecondsSinceEpoch}_${_completionSources.length}';
    final entry = _RegisteredCompletion(
      id: providerId,
      languages: List<String>.from(languages),
      triggerCharacters: List<String>.from(triggerCharacters),
      provider: provider,
    );
    _completionSources[providerId] = entry;

    final payload = jsonEncode({
      'id': providerId,
      'languages': entry.languages,
      'triggerCharacters': entry.triggerCharacters,
    });

    try {
      await _webViewController
          .runJavaScript('flutterMonaco.registerCompletionSource($payload)');
    } catch (e) {
      _completionSources.remove(providerId);
      rethrow;
    }

    _wireCompletionListenerOnce();
    return providerId;
  }

  /// Register a static list of completion items.
  Future<String> registerStaticCompletions({
    String? id,
    required List<String> languages,
    List<String> triggerCharacters = const [],
    required List<CompletionItem> items,
    bool isIncomplete = false,
  }) {
    return registerCompletionSource(
      id: id,
      languages: languages,
      triggerCharacters: triggerCharacters,
      provider: (_) async =>
          CompletionList(suggestions: items, isIncomplete: isIncomplete),
    );
  }

  /// Removes a completion provider, if registered.
  Future<void> unregisterCompletionSource(String id) async {
    _completionSources.remove(id);
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.unregisterCompletionSource(${jsonEncode(id)})',
    );
  }

  /// Execute an editor action
  Future<void> executeAction(String actionId, [dynamic args]) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.executeAction(${jsonEncode(actionId)}, ${jsonEncode(args)})',
    );
  }

  /// Request focus on the editor
  Future<void> focus() async {
    await _ensureReady();
    // Use robust in-page helper (waits for visibility, layouts, focuses textarea)
    await _webViewController.runJavaScript(
        'window.flutterMonaco && window.flutterMonaco.forceFocus && window.flutterMonaco.forceFocus()');
  }

  /// Robust focus with retries across a few frames to survive layout transitions
  Future<void> ensureEditorFocus(
      {int attempts = 3,
      Duration interval = const Duration(milliseconds: 24)}) async {
    await _ensureReady();
    for (var i = 0; i < attempts; i++) {
      try {
        await _webViewController.runJavaScript(
            'window.flutterMonaco && window.flutterMonaco.forceFocus && window.flutterMonaco.forceFocus()');
      } catch (_) {}
      if (i + 1 < attempts) {
        await Future<void>.delayed(interval);
      }
    }
  }

  /// Request a layout pass inside Monaco
  Future<void> layout() async {
    await _ensureReady();
    await _webViewController.runJavaScript(
        'window.flutterMonaco && window.flutterMonaco.layout && window.flutterMonaco.layout()');
  }

  /// Scroll to top of the editor
  Future<void> scrollToTop() async {
    await _ensureReady();
    await _webViewController.runJavaScript('''
      if (window.editor) {
        window.editor.setScrollPosition({ scrollTop: 0, scrollLeft: 0 });
        window.editor.setPosition({ lineNumber: 1, column: 1 });
        window.editor.revealLineInCenterIfOutsideViewport(1);
      }
    ''');
  }

  /// Scroll to bottom of the editor
  Future<void> scrollToBottom() async {
    await _ensureReady();
    await _webViewController.runJavaScript('''
      if (window.editor && window.editor.getModel()) {
        const lineCount = window.editor.getModel().getLineCount();
        window.editor.revealLineInCenterIfOutsideViewport(lineCount);
        window.editor.setPosition({ lineNumber: lineCount, column: 1 });
      }
    ''');
  }

  /// Format the document
  Future<void> format() => executeAction('editor.action.formatDocument');

  /// Open find dialog
  Future<void> find() => executeAction('actions.find');

  /// Open replace dialog
  Future<void> replace() =>
      executeAction('editor.action.startFindReplaceAction');

  /// Toggle word wrap
  Future<void> toggleWordWrap() =>
      executeAction('editor.action.toggleWordWrap');

  /// Select all content
  Future<void> selectAll() => executeAction('editor.action.selectAll');

  /// Undo last action
  Future<void> undo() => executeAction('undo');

  /// Redo last undone action
  Future<void> redo() => executeAction('redo');

  /// Cut selected text
  Future<void> cut() => executeAction('editor.action.clipboardCutAction');

  /// Copy selected text
  Future<void> copy() => executeAction('editor.action.clipboardCopyAction');

  /// Paste from clipboard
  Future<void> paste() => executeAction('editor.action.clipboardPasteAction');

  // --- EVENT HANDLING ---

  /// Wire up event listeners with improved conversion
  void _wireEvents() {
    _bridge.addRawListener((Map<String, dynamic> json) {
      // Use safer conversion methods with fallbacks
      final event = json.tryGetString('event',
          altKeys: ['eventType', 'type'], defaultValue: 'unknown');

      switch (event) {
        case 'contentChanged':
          // Use tryGetBool with default value
          _onContentChanged.add(json.tryGetBool('isFlush',
                  altKeys: ['flush', 'fullChange'], defaultValue: false) ??
              false);
          break;
        case 'selectionChanged':
          // Use factory constructor for cleaner conversion
          final selectionMap = json.tryGetMap<String, dynamic>('selection',
              altKeys: ['sel', 'range']);
          final selection =
              selectionMap != null ? Range.fromJson(selectionMap) : null;
          _onSelectionChanged.add(selection);
          break;
        case 'focus':
          _onFocus.add(null);
          break;
        case 'blur':
          _onBlur.add(null);
          break;
        default:
          break;
      }
    });
  }

  void _wireCompletionListenerOnce() {
    if (_completionListenerWired) return;
    _completionListenerWired = true;

    _bridge.addRawListener((Map<String, dynamic> json) {
      if (json.tryGetString('event') != 'completionRequest') return;

      unawaited(() async {
        await _ensureReady();
        final request = CompletionRequest.fromJson(json);
        final registered = _completionSources[request.providerId];
        const emptySuggestions = {
          'suggestions': <Map<String, dynamic>>[],
        };

        Future<void> respond(Map<String, dynamic> payload) {
          return _webViewController.runJavaScript(
            'flutterMonaco.complete(${jsonEncode(request.requestId)}, ${jsonEncode(payload)})',
          );
        }

        if (registered == null) {
          await respond(emptySuggestions);
          return;
        }

        try {
          final result = await registered.provider(request);
          await respond(result.toJson());
        } catch (_) {
          await respond(emptySuggestions);
        }
      }());
    });
  }

  /// Helper method to safely execute JavaScript and convert the result
  Future<T?> _executeJavaScript<T>(
    String script, {
    T? defaultValue,
    bool jsonAware = true,
  }) async {
    try {
      final raw = await _webViewController.runJavaScriptReturningResult(script);

      // Windows WebView2 might auto-decode JSON, handle both cases
      // Only decode if jsonAware is true (for API calls that return JSON)
      final result = (jsonAware &&
              raw is String &&
              (raw.startsWith('{') || raw.startsWith('[')))
          ? (raw.tryDecode() ?? raw)
          : raw;

      // Use tryToType for all type conversions
      return tryToType<T>(result) ?? defaultValue;
    } catch (e) {
      debugPrint('[MonacoController] JavaScript execution error: $e');
      return defaultValue;
    }
  }

  /// Helper to safely parse JSON results with enhanced conversion
  Future<T?> _executeJavaScriptWithJson<T>(
    String script, {
    T? defaultValue,
    T Function(Map<String, dynamic>)? parser,
  }) async {
    try {
      final raw = await _webViewController.runJavaScriptReturningResult(script);

      // Handle Windows auto-decode: raw might already be a Map/List
      final obj = raw is String ? (raw.tryDecode() ?? raw) : raw;

      // Try to convert to Map
      final json = tryToMap<String, dynamic>(obj);
      if (json == null || json.isEmpty) return defaultValue;

      // Use parser if provided, otherwise try direct conversion
      return parser?.call(json) ?? tryToType<T>(json) ?? defaultValue;
    } catch (e) {
      debugPrint('[MonacoController] JSON parsing error: $e');
      return defaultValue;
    }
  }

  // --- CONTENT AND SELECTION ---

  /// Get the current editor content with enhanced error handling
  Future<String> getValue({String defaultValue = ''}) async {
    return await _executeJavaScript<String>(
          'flutterMonaco.getValue()',
          defaultValue: defaultValue,
          jsonAware: false, // Don't decode - this is plain text content
        ) ??
        defaultValue;
  }

  /// Set the editor content with validation
  Future<void> setValue(String value) async {
    if (!_onReady.isCompleted) {
      _queuedValue = value;
      await _ensureReady();
      if (_queuedValue == value) {
        // Only use queued value if it hasn't been overwritten
        _queuedValue = null;
      } else {
        return; // A newer value was queued, skip this one
      }
    }
    await _webViewController.runJavaScript(
      'flutterMonaco.setValue(${jsonEncode(value)})',
    );
  }

  /// Get the current selection with enhanced parsing
  Future<Range?> getSelection() async {
    return _executeJavaScriptWithJson<Range>(
      'JSON.stringify(flutterMonaco.getSelection())',
      parser: Range.fromJson,
    );
  }

  /// Set the selection
  Future<void> setSelection(Range range) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setSelection(${jsonEncode(range.toJson())})',
    );
  }

  // --- NAVIGATION ---

  /// Reveal a line in the editor with validation
  Future<void> revealLine(int line, {bool center = false}) async {
    await _ensureReady();
    // Validate line number
    final lineCount = await getLineCount();
    final int validLine = line.clamp(1, lineCount);

    await _webViewController.runJavaScript(
      'flutterMonaco.revealLine($validLine, $center)',
    );
  }

  /// Reveal a range in the editor
  Future<void> revealRange(Range range, {bool center = false}) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.revealRange(${jsonEncode(range.toJson())}, $center)',
    );
  }

  /// Reveal multiple lines in the editor
  Future<void> revealLines(int startLine, int endLine,
      {bool center = false}) async {
    final range = Range.lines(startLine, endLine);
    await revealRange(range, center: center);
  }

  /// Reveal a position in the editor
  Future<void> revealPosition(Position position, {bool center = false}) async {
    final range = Range.fromPositions(position, position);
    await revealRange(range, center: center);
  }

  // --- LINE OPERATIONS ---

  /// Get the total line count with enhanced conversion
  Future<int> getLineCount({int defaultValue = 0}) async {
    return await _executeJavaScript<int>(
          'flutterMonaco.getLineCount()',
          defaultValue: defaultValue,
        ) ??
        defaultValue;
  }

  /// Get the content of a specific line with validation
  Future<String> getLineContent(int line, {String defaultValue = ''}) async {
    // Validate line number
    final lineCount = await getLineCount();
    if (line < 1 || line > lineCount) return defaultValue;

    return await _executeJavaScript<String>(
          'flutterMonaco.getLineContent($line)',
          defaultValue: defaultValue,
          jsonAware: false, // Don't decode - this is plain text content
        ) ??
        defaultValue;
  }

  /// Get multiple lines content at once
  Future<List<String>> getLinesContent(
    List<int> lines, {
    String lineDefaultValue = '',
  }) async {
    final results = <String>[];
    for (final line in lines) {
      final content =
          await getLineContent(line, defaultValue: lineDefaultValue);
      results.add(content);
    }
    return results;
  }

  // --- EDITS ---

  /// Apply edit operations to the document
  Future<void> applyEdits(List<EditOperation> edits) async {
    if (edits.isEmpty) return;
    await _ensureReady();

    await _webViewController.runJavaScript(
      'flutterMonaco.applyEdits(${jsonEncode(edits.map((e) => e.toJson()).toList())})',
    );
  }

  /// Insert text at a specific position
  Future<void> insertText(Position position, String text) async {
    final edit = EditOperation.insert(position: position, text: text);
    await applyEdits([edit]);
  }

  /// Delete a range of text
  Future<void> deleteRange(Range range) async {
    final edit = EditOperation.delete(range: range);
    await applyEdits([edit]);
  }

  /// Replace text in a range
  Future<void> replaceRange(Range range, String text) async {
    final edit = EditOperation(range: range, text: text);
    await applyEdits([edit]);
  }

  /// Delete a line
  Future<void> deleteLine(int line) async {
    final range = Range.lines(line, line);
    await deleteRange(range);
  }

  // --- DECORATIONS ---

  /// Set decorations in the editor with enhanced conversion
  Future<List<String>> setDecorations(
    List<DecorationOptions> decorations,
  ) async {
    // Don't use JSON.stringify - return array directly
    final ids = await _executeJavaScript<List<dynamic>>(
      'flutterMonaco.deltaDecorations(${jsonEncode(_decorationIds)}, ${jsonEncode(decorations.map((d) => d.toJson()).toList())})',
      defaultValue: const [],
    );

    return _decorationIds = (ids ?? const [])
        .map((e) => e.toString())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Add inline decorations
  Future<List<String>> addInlineDecorations(
    List<Range> ranges,
    String className, {
    String? hoverMessage,
  }) async {
    final decorations = ranges
        .map((range) => DecorationOptions.inlineClass(
              range: range,
              className: className,
              hoverMessage: hoverMessage,
            ))
        .toList();

    return setDecorations(decorations);
  }

  /// Add line decorations
  Future<List<String>> addLineDecorations(
    List<int> lines,
    String className, {
    bool isWholeLine = true,
  }) async {
    final decorations = lines
        .map((line) => DecorationOptions.line(
              range: Range.singleLine(line),
              className: className,
              isWholeLine: isWholeLine,
            ))
        .toList();

    return setDecorations(decorations);
  }

  /// Clear all decorations
  Future<void> clearDecorations() => setDecorations(const []);

  // --- MARKERS (DIAGNOSTICS) ---

  /// Set markers (diagnostics) in the editor
  Future<void> setMarkers(
    List<MarkerData> markers, {
    String owner = 'flutter',
  }) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setModelMarkers(${jsonEncode(owner)}, ${jsonEncode(markers.map((m) => m.toJson()).toList())})',
    );
  }

  /// Set error markers
  Future<void> setErrorMarkers(
    List<MarkerData> errors, {
    String owner = 'flutter-errors',
  }) async {
    await setMarkers(errors, owner: owner);
  }

  /// Set warning markers
  Future<void> setWarningMarkers(
    List<MarkerData> warnings, {
    String owner = 'flutter-warnings',
  }) async {
    await setMarkers(warnings, owner: owner);
  }

  /// Clear all markers
  Future<void> clearMarkers({String owner = 'flutter'}) async {
    await setMarkers([], owner: owner);
  }

  /// Clear all markers from all owners
  Future<void> clearAllMarkers() async {
    await Future.wait([
      clearMarkers(owner: 'flutter'),
      clearMarkers(owner: 'flutter-errors'),
      clearMarkers(owner: 'flutter-warnings'),
    ]);
  }

  // --- FIND AND REPLACE ---

  /// Find matches in the document with enhanced parsing
  Future<List<FindMatch>> findMatches(
    String query, {
    FindOptions options = const FindOptions(),
    int limit = 1000,
  }) async {
    // Don't use JSON.stringify - return array directly
    final matches = await _executeJavaScript<List<dynamic>>(
      'flutterMonaco.findMatches(${jsonEncode(query)}, ${jsonEncode(options.toJson())}, $limit)',
      defaultValue: const [],
    );

    if (matches == null || matches.isEmpty) return [];

    return matches
        .map((match) => tryToMap<String, dynamic>(match))
        .where((map) => map != null)
        .map((map) => FindMatch.fromJson(map!))
        .toList();
  }

  /// Replace all matches in the document
  Future<int> replaceMatches(
    String query,
    String replacement, {
    FindOptions options = const FindOptions(),
    int defaultCount = 0,
  }) async {
    return await _executeJavaScript<int>(
          'flutterMonaco.replaceMatches(${jsonEncode(query)}, ${jsonEncode(replacement)}, ${jsonEncode(options.toJson())})',
          defaultValue: defaultCount,
        ) ??
        defaultCount;
  }

  // --- VIEW STATE ---

  /// Save the current view state with enhanced conversion
  Future<Map<String, dynamic>> saveViewState() async {
    final result = await _executeJavaScriptWithJson<Map<String, dynamic>>(
      'JSON.stringify(flutterMonaco.saveViewState())',
    );
    return result ?? {};
  }

  /// Restore a previously saved view state
  Future<void> restoreViewState(Map<String, dynamic> state) async {
    if (state.isEmpty) return;
    await _ensureReady();

    await _webViewController.runJavaScript(
      'flutterMonaco.restoreViewState(${jsonEncode(state)})',
    );
  }

  // --- MULTI-MODEL ---

  /// Create a new model with enhanced URI handling
  Future<Uri> createModel(
    String value, {
    String language = 'plaintext',
    Uri? uri,
    Uri? defaultUri,
  }) async {
    final script = '''
      flutterMonaco.createModel(
        ${jsonEncode(value)}, 
        ${jsonEncode(language)}, 
        ${uri != null ? jsonEncode(uri.toString()) : 'null'}
      )
    ''';

    final result = await _executeJavaScript<String>(script);

    // Enhanced URI conversion with fallback
    final createdUri = result != null ? tryToUri(result) : null;
    return createdUri ?? defaultUri ?? Uri.parse('file:///untitled');
  }

  /// Set the active model
  Future<void> setModel(Uri uri) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setModel(${jsonEncode(uri.toString())})',
    );
  }

  /// Dispose a model
  Future<void> disposeModel(Uri uri) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.disposeModel(${jsonEncode(uri.toString())})',
    );
  }

  /// List all models with enhanced conversion
  Future<List<Uri>> listModels() async {
    // Don't use JSON.stringify - return array directly
    final list = await _executeJavaScript<List<dynamic>>(
      'flutterMonaco.listModels()',
      defaultValue: const [],
    );

    if (list == null || list.isEmpty) return [];

    // Convert each item to URI and filter out nulls
    return list.map(tryToUri).where((uri) => uri != null).cast<Uri>().toList();
  }

  // --- ADDITIONAL HELPER METHODS ---

  /// Get editor statistics from bridge's live stream
  LiveStats getStatistics() {
    // Use the bridge's liveStats which is already updated via events
    return _bridge.liveStats.value;
  }

  /// Check if the editor has unsaved changes
  Future<bool> hasUnsavedChanges() async {
    return await _executeJavaScript<bool>(
          'flutterMonaco.hasUnsavedChanges()',
          defaultValue: false,
        ) ??
        false;
  }

  /// Mark the current content as saved (baseline for dirty tracking)
  Future<void> markSaved() async {
    await _ensureReady();
    await _webViewController.runJavaScript('flutterMonaco.markSaved()');
  }

  /// Get cursor position with enhanced conversion
  Future<Position?> getCursorPosition() async {
    return _executeJavaScriptWithJson<Position>(
      'JSON.stringify(flutterMonaco.getCursorPosition())',
      parser: Position.fromJson,
    );
  }

  /// Set cursor position
  Future<void> setCursorPosition(Position position) async {
    await _ensureReady();
    await _webViewController.runJavaScript(
      'flutterMonaco.setCursorPosition(${position.line}, ${position.column})',
    );
  }

  /// Set cursor position from zero-based coordinates
  Future<void> setCursorPositionZeroBased(int line, int column) async {
    final position = Position.fromZeroBased(line, column);
    await setCursorPosition(position);
  }

  /// Get word at position
  Future<String?> getWordAtPosition(Position position) async {
    return _executeJavaScript<String>(
      'flutterMonaco.getWordAtPosition(${position.line}, ${position.column})',
      jsonAware: false, // Don't decode - this is plain text content
    );
  }

  // --- BATCH OPERATIONS ---

  /// Execute multiple operations in batch
  Future<void> executeBatch(List<Future<void> Function()> operations) async {
    for (final operation in operations) {
      await operation();
    }
  }

  /// Get multiple editor properties at once
  Future<EditorState> getEditorState() async {
    final content = await getValue();
    final selection = await getSelection();
    final cursorPosition = await getCursorPosition();
    final lineCount = await getLineCount();
    final hasChanges = await hasUnsavedChanges();
    final stats = getStatistics(); // Now synchronous

    return EditorState(
      content: content,
      selection: selection,
      cursorPosition: cursorPosition,
      lineCount: lineCount,
      hasUnsavedChanges: hasChanges,
      language: stats.language,
      theme: null,
      // Would need a separate API call to get theme
      stats: stats,
    );
  }

  // --- HELPERS ---
  /// Dispose the controller and clean up resources
  void dispose() {
    _onContentChanged.close();
    _onSelectionChanged.close();
    _onFocus.close();
    _onBlur.close();
    _bridge.dispose();
    _webViewController.dispose();
  }
}

class _RegisteredCompletion {
  _RegisteredCompletion({
    required this.id,
    required this.languages,
    required this.triggerCharacters,
    required this.provider,
  });

  final String id;
  final List<String> languages;
  final List<String> triggerCharacters;
  final CompletionProvider provider;
}
