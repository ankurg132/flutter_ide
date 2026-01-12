import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Monaco asset manager - Single source of truth for all Monaco-related assets
class MonacoAssets {
  static const String _assetBaseDir = 'packages/flutter_monaco/assets/monaco';
  static const String _cacheSubDir = 'monaco_editor_cache';
  static const String _htmlFileName = 'index.html';
  static const String _relativePath = 'min/vs';

  /// The version of the Monaco Editor assets embedded in the package.
  static const String monacoVersion = '0.54.0';

  static Completer<void>? _initCompleter;

  // HTML cache to avoid regenerating the same HTML multiple times
  static final Map<int, String> _htmlCache = {};

  /// Ensures Monaco assets are ready. Thread-safe with re-entrant protection.
  static Future<void> ensureReady() {
    if (_initCompleter != null) return _initCompleter!.future;

    final c = _initCompleter = Completer<void>();

    () async {
      try {
        final targetDir = await _getTargetDir();
        final loader = File(p.join(targetDir, 'min', 'vs', 'loader.js'));
        final sentinel = File(p.join(targetDir, '.monaco_complete'));

        final ok = loader.existsSync() &&
            sentinel.existsSync() &&
            (await sentinel.readAsString()).trim() == monacoVersion;

        if (!ok) {
          debugPrint(
              '[MonacoAssets] Monaco not found or incomplete, copying assets...');
          await _copyAllAssets(targetDir);
        } else {
          debugPrint(
              '[MonacoAssets] Monaco already extracted at: $targetDir (version $monacoVersion)');
        }

        // Create default HTML file without custom CSS
        await _ensureHtmlFile(targetDir);
        c.complete();
      } catch (e, st) {
        c.completeError(e, st);
      }
    }();

    return c.future;
  }

  /// Get the path to the HTML file
  ///
  /// [customCss] - Custom CSS to inject into the editor
  /// [allowCdnFonts] - Whether to allow loading fonts from CDNs
  static Future<String> indexHtmlPath({
    String? customCss,
    bool allowCdnFonts = false,
  }) async {
    await ensureReady();
    final targetDir = await _getTargetDir();

    // Generate cache key based on parameters
    final cacheKey = Object.hash(customCss, allowCdnFonts);

    // Check if we already have this HTML cached
    if (_htmlCache.containsKey(cacheKey)) {
      return _htmlCache[cacheKey]!;
    }

    // Generate new HTML with custom CSS if provided
    await _ensureHtmlFile(
      targetDir,
      customCss: customCss,
      allowCdnFonts: allowCdnFonts,
      cacheKey: cacheKey,
    );

    // Cache and return the path
    final htmlPath = p.join(targetDir, 'monaco_$cacheKey.html');
    _htmlCache[cacheKey] = htmlPath;
    return htmlPath;
  }

  /// Get information about extracted Monaco assets
  static Future<Map<String, dynamic>> assetInfo() async {
    final targetDir = await _getTargetDir();
    final directory = Directory(targetDir);

    if (!directory.existsSync()) {
      return {
        'exists': false,
        'path': targetDir,
        'version': monacoVersion,
      };
    }

    // Count files and calculate size
    var fileCount = 0;
    var totalSize = 0;
    var hasHtmlFile = false;

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        fileCount++;
        totalSize += await entity.length();

        if (p.basename(entity.path) == _htmlFileName) {
          hasHtmlFile = true;
        }
      }
    }

    return {
      'exists': true,
      'path': targetDir,
      'version': monacoVersion,
      'fileCount': fileCount,
      'totalSize': totalSize,
      'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'hasHtmlFile': hasHtmlFile,
      'htmlPath': p.join(targetDir, _htmlFileName),
    };
  }

  /// Clean up all Monaco assets
  static Future<void> clearCache() async {
    final targetDir = await _getTargetDir();
    final directory = Directory(targetDir);

    if (directory.existsSync()) {
      await directory.delete(recursive: true);
      debugPrint('[MonacoAssets] Monaco assets cleaned');
    }

    // Reset the init completer and HTML cache
    _initCompleter = null;
    _htmlCache.clear();
  }

  // --- Private Helpers ---

  static Future<String> _getTargetDir() async {
    return p.join(
      (await getApplicationSupportDirectory()).path,
      _cacheSubDir,
      'monaco-$monacoVersion',
    );
  }

  static Future<void> _ensureHtmlFile(
    String targetDir, {
    String? customCss,
    bool allowCdnFonts = false,
    int? cacheKey,
  }) async {
    // Use cache key in filename to avoid conflicts
    final fileName = cacheKey != null ? 'monaco_$cacheKey.html' : _htmlFileName;
    final htmlFile = File(p.join(targetDir, fileName));

    // Skip if file already exists (cached)
    if (htmlFile.existsSync() && cacheKey != null) {
      debugPrint('[MonacoAssets] Using cached HTML file: ${htmlFile.path}');
      return;
    }

    // Generate platform-specific HTML
    String htmlContent;

    if (Platform.isWindows) {
      // Windows needs absolute paths since we load from file://
      final vsPath = p.join(targetDir, 'min', 'vs');
      final absoluteVsPath = Uri.file(vsPath).toString();
      htmlContent = _generateIndexHtml(
        absoluteVsPath,
        isWindows: true,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    } else {
      // macOS uses relative paths since HTML is in the same directory
      htmlContent = _generateIndexHtml(
        _relativePath,
        isWindows: false,
        customCss: customCss,
        allowCdnFonts: allowCdnFonts,
      );
    }

    // Write the HTML file
    await htmlFile.writeAsString(htmlContent);

    debugPrint('[MonacoAssets] HTML file created at: ${htmlFile.path}');
  }

  static Future<void> _copyAllAssets(String targetDir) async {
    final stopwatch = Stopwatch()..start();

    // Clean and create target directory
    final directory = Directory(targetDir);
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
    await directory.create(recursive: true);

    // Get all assets from the manifest
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final monacoAssets = manifest
        .listAssets()
        .where((key) => key.startsWith(_assetBaseDir))
        .where((key) => !key.endsWith('.DS_Store')) // Skip macOS metadata files
        .toList();

    debugPrint(
      '[MonacoAssets] Found ${monacoAssets.length} Monaco assets to copy',
    );

    // Copy each asset maintaining directory structure
    var copiedCount = 0;
    for (final assetKey in monacoAssets) {
      try {
        // Calculate relative path (skip index.html from assets if it exists)
        final relativePath = assetKey.substring('$_assetBaseDir/'.length);
        if (relativePath.isEmpty || relativePath == _htmlFileName) continue;

        // Create target file path
        final targetFile = File(p.join(targetDir, relativePath));

        // Ensure parent directory exists
        await targetFile.parent.create(recursive: true);

        // Load and write asset
        final bytes = await rootBundle.load(assetKey);
        await targetFile.writeAsBytes(bytes.buffer.asUint8List());

        copiedCount++;

        // Log progress every 100 files
        if (copiedCount % 100 == 0) {
          debugPrint(
            '[MonacoAssets] Progress: $copiedCount/${monacoAssets.length} files copied',
          );
        }
      } catch (e) {
        debugPrint('[MonacoAssets] Error copying $assetKey: $e');
      }
    }

    stopwatch.stop();
    debugPrint(
      '[MonacoAssets] Completed: $copiedCount files copied in ${stopwatch.elapsedMilliseconds}ms',
    );

    // Write sentinel file to mark successful completion
    final sentinelFile = File(p.join(targetDir, '.monaco_complete'));
    await sentinelFile.writeAsString(monacoVersion);
    debugPrint(
        '[MonacoAssets] Sentinel file written for version $monacoVersion');
  }

  static String _generateIndexHtml(
    String vsPath, {
    required bool isWindows,
    String? customCss,
    bool allowCdnFonts = false,
  }) {
    // Platform-specific initialization scripts
    String platformScript = '';

    if (isWindows) {
      platformScript = '''
<script>
  // Windows: Create flutterChannel immediately when document is created
  console.log('[Windows Init] Creating flutterChannel on document creation');
  window.flutterChannel = {
    postMessage: function(msg) {
      console.log('[flutterChannel] Posting message:', msg);
      if (window.chrome && window.chrome.webview) {
        window.chrome.webview.postMessage(msg);
      } else {
        console.error('[flutterChannel] WebView2 API not available!');
      }
    }
  };
  console.log('[Windows Init] flutterChannel created successfully');
</script>
''';
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS and macOS need blob worker shim for WKWebView + file:// protocol
      platformScript = '''
<script>
  (function () {
    console.log('[Init] Setting up worker shim for WKWebView');
    const vsRel = '$vsPath'; // e.g., "min/vs"
    let absVs;
    try { absVs = new URL(vsRel, window.location.href).toString(); }
    catch (_) { absVs = vsRel; }

    // Ensure baseUrl points to the ".../min/" folder (not ".../min/vs")
    const idx = absVs.lastIndexOf('/vs');
    const baseUrl = idx >= 0 ? absVs.substring(0, idx + 1) : absVs; // e.g., ".../min/"

    // Set baseUrl so Monaco can resolve URLs before workers start
    self.MonacoEnvironment = {
      baseUrl: baseUrl,
      getWorkerUrl: function (moduleId, label) {
        // Include the label for better worker resolution and debugging
        const src =
          "self.MonacoEnvironment = { baseUrl: '" + baseUrl + "' };\n" +
          "self.monacoLabel = '" + label + "';\n" +
          "importScripts('" + absVs + "/base/worker/workerMain.js');\n";
        return URL.createObjectURL(new Blob([src], { type: 'application/javascript' }));
      }
    };
    console.log('[Init] Worker shim configured. baseUrl=' + baseUrl);
  })();
</script>
''';
    } else {
      // Linux and other platforms: just set baseUrl
      final baseUrl = vsPath.replaceAll('/vs', '/');
      platformScript = '''
<script>
  // Linux/Other: Set base URL for worker resolution
  console.log('[Init] Setting Monaco base URL');
  self.MonacoEnvironment = { baseUrl: '$baseUrl' };
</script>
''';
    }

    const jsEscapePattern = r'[.*+?^${}()|[\]\\]';

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta
      http-equiv="Content-Security-Policy"
      content="default-src 'self' file: 'unsafe-inline' 'unsafe-eval'; script-src 'self' file: 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'${allowCdnFonts ? ' https:' : ''}; font-src 'self' file: data:${allowCdnFonts ? ' https:' : ''}; img-src 'self' data: blob: file:; worker-src 'self' blob:; connect-src 'self' blob:;"
    />
    <!-- NOTE: connect-src intentionally limits in-page requests to self/blob.
         If you need the embedded JS to call remote APIs directly, add https: to connect-src. -->
    <style>
      html, body, #editor-container {
        width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden;
      }
      
      /* Enable font ligatures in Monaco editor if supported by the font */
      .monaco-editor {
        font-variant-ligatures: contextual;
        -webkit-font-feature-settings: "liga" on, "calt" on;
        font-feature-settings: "liga" on, "calt" on;
      }
    </style>
    ${customCss != null ? '<style id="flutter-monaco-custom">\n$customCss\n</style>' : ''}
    $platformScript
  </head>
  <body>
    <div id="editor-container"></div>

    <script>
      var require = { paths: { vs: '$vsPath' } };
      console.log('[Monaco HTML] Require config set. VS_PATH is: ' + '$vsPath');
    </script>

    <script src="$vsPath/loader.js"
            onload="console.log('[Monaco HTML] loader.js successfully loaded.')"
            onerror="console.error('[Monaco HTML] FATAL: loader.js FAILED TO LOAD.')"
    ></script>

    <script>
      console.log('[Monaco HTML] Attempting to require editor.main...');
      try {
        require(
          ['vs/editor/editor.main'],
          function () {
            console.log('[Monaco] SUCCESS: editor.main.js has loaded. Initializing editor...');

            function postMessageToFlutter(message) {
              if (typeof message !== 'string') {
                message = JSON.stringify(message);
              }
              if (window.flutterChannel && window.flutterChannel.postMessage) {
                window.flutterChannel.postMessage(message);
              } else {
                console.error('[Monaco] Flutter communication channel is not available.');
              }
            }

            monaco.editor.onDidCreateEditor(function (editor) {
              window.editor = editor;

              // Send live statistics updates
              const sendStats = () => {
                if (!editor.getModel() || !editor.getSelection()) return;
                const model = editor.getModel(), selection = editor.getSelection(), selections = editor.getSelections() || [];
                const position = editor.getPosition();
                postMessageToFlutter({
                  event: 'stats',
                  lineCount: model.getLineCount(),
                  charCount: model.getValueLength(),
                  selLines: selection.isEmpty() ? 0 : (selection.endLineNumber - selection.startLineNumber + 1),
                  selChars: selection.isEmpty() ? 0 : model.getValueInRange(selection).length,
                  caretCount: selections.length,
                  language: model.getLanguageId ? model.getLanguageId() : monaco.editor.getModelLanguage(model),
                  cursorLine: position?.lineNumber,
                  cursorColumn: position?.column,
                });
              };
              editor.onDidChangeModelContent(sendStats);
              editor.onDidChangeCursorSelection(sendStats);
              sendStats();

              postMessageToFlutter({ event: 'onEditorReady' });
              console.log('[Monaco] Editor is ready and has sent the onEditorReady event.');
              
              // Set up typed API
              (function () {
                const E = () => window.editor;
                const serialize = (obj) => JSON.stringify(obj);
                

                // Events -> Flutter
                const post = (event, payload) =>
                  window.flutterChannel?.postMessage(serialize({ event, ...payload }));

                E().onDidChangeModelContent(e => post('contentChanged', { isFlush: e.isFlush }));
                E().onDidChangeCursorSelection(e => post('selectionChanged', {
                  selection: e.selection && {
                    startLineNumber: e.selection.startLineNumber,
                    startColumn: e.selection.startColumn,
                    endLineNumber: e.selection.endLineNumber,
                    endColumn: e.selection.endColumn
                  }
                }));
                E().onDidFocusEditorWidget(() => post('focus', {}));
                E().onDidBlurEditorWidget(() => post('blur', {}));

                // Typed helpers Flutter will call
                const escapeRegExp = (value) =>
                  (value ?? '').replace(/$jsEscapePattern/g, '\\\\\$&');

                window.flutterMonaco = {

                  // Basic editor operations
                  focus: () => E().focus(),
                  layout: () => { try { E().layout(); } catch (_) {} },
                  // Force focus robustly: wait for visibility, layout, focus editor and hidden textarea
                  forceFocus: () => {
                    try {
                      const ed = E();
                      if (!ed) return;
                      const node = (ed.getDomNode && ed.getDomNode()) || (ed.getContainerDomNode && ed.getContainerDomNode());
                      if (!node) return;
                      const attempt = () => {
                        const rect = node.getBoundingClientRect();
                        if (!rect.width || !rect.height) {
                          // Defer until container has size
                          return requestAnimationFrame(attempt);
                        }
                        // Try to ensure the page/window is active (helps WKWebView on macOS)
                        try { window.focus && window.focus(); } catch (_) {}
                        try {
                          if (document.body && !document.body.hasAttribute('tabindex')) {
                            document.body.setAttribute('tabindex', '-1');
                          }
                          document.body?.focus?.();
                        } catch (_) {}
                        try { ed.layout && ed.layout(); } catch (_) {}
                        try { ed.focus && ed.focus(); } catch (_) {}
                        // Ensure the hidden textarea owns focus for keyboard input
                        try {
                          const ta = node.querySelector('textarea.inputarea');
                          if (ta && document.activeElement !== ta) {
                            ta.focus({ preventScroll: true });
                            // One more tick for WKWebView
                            setTimeout(() => { try { ta.focus({ preventScroll: true }); } catch (_) {} }, 16);
                          }
                        } catch (_) {}
                      };
                      // Defer past any mousedown handlers
                      setTimeout(() => requestAnimationFrame(attempt), 0);
                    } catch (_) {}
                  },
                  getValue: () => E().getValue(),
                  setValue: (v) => E().setValue(v || ''),
                  setTheme: (theme) => monaco.editor.setTheme(theme),
                  setLanguage: (lang) => monaco.editor.setModelLanguage(E().getModel(), lang),
                  updateOptions: (opts) => E().updateOptions(opts),
                  executeAction: (actionId, args) => E().trigger('flutter-bridge', actionId, args),
                  
                  // Selection
                  getSelection: () => {
                    const s = E().getSelection();
                    return s ? {
                      startLineNumber: s.startLineNumber, startColumn: s.startColumn,
                      endLineNumber: s.endLineNumber, endColumn: s.endColumn
                    } : null;
                  },
                  setSelection: (r) => E().setSelection(r),
                  
                  // Cursor
                  getCursorPosition: () => {
                    const p = E().getPosition();
                    return p ? { lineNumber: p.lineNumber, column: p.column } : null;
                  },
                  setCursorPosition: (line, column) => {
                    E().setPosition({ lineNumber: line, column: column });
                  },
                  
                  // Navigation
                  revealLine: (ln, center) =>
                    center ? E().revealLineInCenter(ln) : E().revealLine(ln),
                  revealRange: (r, center) =>
                    center ? E().revealRangeInCenter(r) : E().revealRange(r),

                  // Line operations
                  getLineCount: () => E().getModel().getLineCount(),
                  getLineContent: (ln) => E().getModel().getLineContent(ln),
                  
                  // Word lookup
                  getWordAtPosition: (line, column) => {
                    const m = E().getModel();
                    if (!m) return null;
                    const w = m.getWordAtPosition(new monaco.Position(line, column));
                    return w ? w.word : null;
                  },

                  // Edits
                  applyEdits: (edits, opts) =>
                    E().getModel().applyEdits(edits || [], opts || {}),

                  // Decorations
                  deltaDecorations: (oldIds, newDecos) =>
                    E().deltaDecorations(oldIds || [], newDecos || []),

                  // Markers (diagnostics)
                  setModelMarkers: (owner, markers) =>
                    monaco.editor.setModelMarkers(E().getModel(), owner || 'flutter', markers || []),

                  // Find & replace (programmatic)
                  findMatches: (q, options, limit) => {
                    const m = E().getModel();
                    if (!m) return [];
                    const isRegex = !!(options && options.isRegex);
                    const matchCase = !!(options && options.matchCase);
                    const wholeWord = !!(options && options.wholeWord);

                    let search = q ?? '';
                    let useRegex = isRegex;
                    if (wholeWord && !isRegex) {
                      search = '\\\\b' + escapeRegExp(String(q ?? '')) + '\\\\b';
                      useRegex = true;
                    }

                    const matches = m.findMatches(
                      search,
                      null,                 // searchScope: null = whole model (FIX: was 'false')
                      useRegex,
                      matchCase,
                      null,
                      false,                // captureMatches
                      limit || 9999
                    );
                    return matches.map(mm => ({ range: mm.range, match: m.getValueInRange(mm.range) }));
                  },

                  replaceMatches: (q, repl, options) => {
                    const m = E().getModel();
                    if (!m) return 0;
                    const isRegex = !!(options && options.isRegex);
                    const matchCase = !!(options && options.matchCase);
                    const wholeWord = !!(options && options.wholeWord);

                    let search = q ?? '';
                    let useRegex = isRegex;
                    if (wholeWord && !isRegex) {
                      search = '\\\\b' + escapeRegExp(String(q ?? '')) + '\\\\b';
                      useRegex = true;
                    }

                    const matches = m.findMatches(
                      search,
                      null,                 // searchScope: null = whole model (FIX: was 'false')
                      useRegex,
                      matchCase,
                      null,
                      false,                // captureMatches
                      9999
                    );
                    const edits = matches.map(mm => ({ range: mm.range, text: repl }));
                    m.pushEditOperations([], edits, () => null);
                    return edits.length;
                  },

                  // View state
                  saveViewState: () => E().saveViewState(),
                  restoreViewState: (s) => E().restoreViewState(s),

                  // Stats
                  getStatistics: () => {
                    const e = E(), m = e.getModel(), s = e.getSelection();
                    const position = e.getPosition(); // FIX: Define position in this scope
                    const selections = e.getSelections() || [];
                    return {
                      lineCount: m ? m.getLineCount() : 0,
                      charCount: m ? m.getValueLength() : 0,
                      selLines: (s && !s.isEmpty()) ? (s.endLineNumber - s.startLineNumber + 1) : 0, // FIX: Return 0 for empty selection
                      selChars: (m && s && !s.isEmpty()) ? m.getValueInRange(s).length : 0,
                      caretCount: selections.length,
                      language: m ? (m.getLanguageId ? m.getLanguageId() : monaco.editor.getModelLanguage(m)) : undefined,
                      cursorLine: position?.lineNumber,
                      cursorColumn: position?.column,
                    };
                  },
                  
                  // Dirty tracking
                  _hasBaseline: false,
                  _baselineVersionId: null,
                  _markBaseline() {
                    const m = E().getModel();
                    if (m) {
                      this._baselineVersionId = m.getAlternativeVersionId();
                      this._hasBaseline = true;
                    }
                  },
                  hasUnsavedChanges: () => {
                    const m = E().getModel();
                    if (!m) return false;
                    if (!window.flutterMonaco._hasBaseline) window.flutterMonaco._markBaseline();
                    return m.getAlternativeVersionId() !== window.flutterMonaco._baselineVersionId;
                  },
                  markSaved: () => window.flutterMonaco._markBaseline(),

                  // Models
                  createModel: (value, language, uri) =>
                    monaco.editor.createModel(value || '', language || 'plaintext', 
                      uri ? monaco.Uri.parse(uri) : undefined).uri.toString(),
                  setModel: (uri) => {
                    const m = monaco.editor.getModel(monaco.Uri.parse(uri));
                    if (m) E().setModel(m);
                  },
                  disposeModel: (uri) => {
                    const m = monaco.editor.getModel(monaco.Uri.parse(uri));
                    if (m) m.dispose();
                  },
                  listModels: () => monaco.editor.getModels().map(m => m.uri.toString()),
                };

                // Completion bridge: JS stays dumb, Flutter drives the data
                (function () {
                  const completion = {
                    resolvers: Object.create(null),
                    providers: Object.create(null),
                    nextId: 1,
                  };

                  function toIRange(r) {
                    if (!r) return undefined;
                    const sL = r.startLineNumber ?? r.startLine ?? r.from_line ?? r.start ?? 1;
                    const sC = r.startColumn ?? r.startCol ?? r.sc ?? 1;
                    const eL = r.endLineNumber ?? r.endLine ?? r.to_line ?? r.end ?? sL;
                    const eC = r.endColumn ?? r.endCol ?? r.ec ?? sC;
                    return {
                      startLineNumber: sL,
                      startColumn: sC,
                      endLineNumber: eL,
                      endColumn: eC,
                    };
                  }

                  // cfg: { id?: string, languages: string[]|string, triggerCharacters?: string[] }
                  window.flutterMonaco.registerCompletionSource = function (cfg) {
                    const id = cfg?.id || 'flutter_' + completion.nextId++;
                    const langs = Array.isArray(cfg?.languages)
                      ? cfg.languages
                      : [cfg?.languages ?? 'plaintext'];
                    const triggerCharacters = cfg?.triggerCharacters || [];

                    const provider = {
                      triggerCharacters,
                      provideCompletionItems: (model, position, context, token) =>
                        new Promise((resolve) => {
                          const reqId =
                            id + ':' + Date.now() + ':' + Math.random().toString(36).slice(2);
                          completion.resolvers[reqId] = resolve;

                          const lang =
                            (model.getLanguageId && model.getLanguageId()) ||
                            monaco.editor.getModelLanguage(model);
                          const word = model.getWordUntilPosition(position);
                          const defaultRange = {
                            startLineNumber: position.lineNumber,
                            startColumn: word.startColumn,
                            endLineNumber: position.lineNumber,
                            endColumn: word.endColumn,
                          };

                          const payload = {
                            event: 'completionRequest',
                            providerId: id,
                            requestId: reqId,
                            language: lang,
                            uri: model.uri?.toString(),
                            position: {
                              lineNumber: position.lineNumber,
                              column: position.column,
                            },
                            defaultRange,
                            lineText: model.getLineContent(position.lineNumber),
                            triggerKind: context?.triggerKind ?? null,
                            triggerCharacter: context?.triggerCharacter ?? null,
                          };
                          window.flutterChannel?.postMessage(JSON.stringify(payload));

                          token?.onCancellationRequested?.(() => {
                            delete completion.resolvers[reqId];
                            try {
                              resolve({ suggestions: [] });
                            } catch (_) {}
                          });
                        }),
                    };

                    const disposables = langs.map((l) =>
                      monaco.languages.registerCompletionItemProvider(l, provider),
                    );
                    completion.providers[id] = { disposables };
                    return id;
                  };

                  window.flutterMonaco.unregisterCompletionSource = function (id) {
                    const p = completion.providers[id];
                    if (p?.disposables) {
                      for (const d of p.disposables) {
                        try {
                          d.dispose();
                        } catch (_) {}
                      }
                    }
                    delete completion.providers[id];
                  };

                  // Flutter -> JS: deliver completion results
                  window.flutterMonaco.complete = function (requestId, payload) {
                    const resolve = completion.resolvers[requestId];
                    if (!resolve) return;
                    try {
                      const items = (payload && payload.suggestions) || [];
                      const mapped = items.map((it) => {
                        let kind = it.kind;
                        if (typeof kind === 'string') {
                          kind = monaco.languages.CompletionItemKind[kind] ??
                            monaco.languages.CompletionItemKind.Text;
                        }
                        let insertTextRules = it.insertTextRules;
                        if (Array.isArray(insertTextRules)) {
                          insertTextRules = insertTextRules.reduce((mask, rule) => {
                            const value = monaco.languages.CompletionItemInsertTextRule[rule];
                            return typeof value === 'number' ? (mask | value) : mask;
                          }, 0);
                        }
                        return {
                          label: it.label,
                          insertText: it.insertText || it.label,
                          kind: kind || monaco.languages.CompletionItemKind.Text,
                          detail: it.detail,
                          documentation: it.documentation,
                          sortText: it.sortText,
                          filterText: it.filterText,
                          commitCharacters: it.commitCharacters,
                          insertTextRules: insertTextRules || undefined,
                          range: toIRange(it.range) || toIRange(payload?.defaultRange),
                        };
                      });
                      resolve({
                        suggestions: mapped,
                        incomplete: !!payload?.isIncomplete,
                      });
                    } finally {
                      delete completion.resolvers[requestId];
                    }
                  };
                })();
              })();
            });

            monaco.editor.create(document.getElementById('editor-container'), {
              value: '// Monaco Editor is ready',
              language: 'markdown',
              theme: 'vs-dark',
              automaticLayout: true,
              wordWrap: 'on',
              padding: { top: 10 },
              minimap: { enabled: false }
            });
          },
          function (error) {
            console.error('[Monaco] FATAL: require() failed to load editor.main.js. Error:', error);
          }
        );
      } catch (e) {
        console.error('[Monaco] FATAL: A critical error occurred trying to call require(). Error:', e);
      }
    </script>
  </body>
</html>
''';
  }
}
