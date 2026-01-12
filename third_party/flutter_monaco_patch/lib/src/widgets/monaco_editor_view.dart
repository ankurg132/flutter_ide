import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// An enumeration representing the connection state of the Monaco Editor.
enum _ConnectionState {
  /// The editor is currently initializing and not yet ready for interaction.
  connecting,

  /// The editor has successfully initialized and is ready.
  ready,

  /// An error occurred during the initialization of the editor.
  error,
}

/// {@template flutter_monaco.editor.controller}
/// The controller for this editor instance.
///
/// If a controller is not provided, one will be created and managed internally
/// by this widget. The internally created controller can be accessed via the
/// [onReady] callback.
///
/// **Warning**: If you provide your own controller, you are responsible for
/// its lifecycle, including calling `dispose()` when it's no longer needed.
/// {@endtemplate}
///
/// {@template flutter_monaco.editor.initialValue}
/// The initial text content to be loaded into the editor.
///
/// This value is only used when the widget is first initialized or when the
/// [controller] instance is changed. Subsequent changes to this property
/// will be ignored. To update the content programmatically after initialization,
/// use the methods available on the [MonacoController].
/// {@endtemplate}
///
/// Highly customizable Monaco Editor widget for Flutter.
///
/// This widget provides a comprehensive API with sensible defaults, allowing for
/// both simple and advanced use cases. It manages the editor's lifecycle,
/// offers pluggable UI for loading and error states, and includes an optional,
/// performance-optimized status bar.
///
/// ### Example
///
/// ```dart
/// MonacoEditor(
///   options: EditorOptions(
///     language: MonacoLanguage.typescript,
///     theme: MonacoTheme.vsDark,
///     minimap: false,
///   ),
///   initialValue: 'console.log("Hello, Monaco!");',
///   onReady: (controller) {
///     print('Editor is ready!');
///     // You can now use the controller to interact with the editor.
///   },
///   onContentChanged: (value) {
///     print('Content changed: $value');
///   },
/// )
/// ```
class MonacoEditor extends StatefulWidget {
  /// Creates a new [MonacoEditor] widget.
  const MonacoEditor({
    super.key,
    this.controller,
    this.initialValue,
    this.options = const EditorOptions(),
    this.initialSelection,
    this.autofocus = false,
    this.customCss,
    this.allowCdnFonts = false,
    this.readyTimeout,
    this.onReady,
    this.onContentChanged,
    this.onRawContentChanged,
    this.fullTextOnFlushOnly = false,
    this.contentDebounce = const Duration(milliseconds: 120),
    this.onSelectionChanged,
    this.onFocus,
    this.onBlur,
    this.onLiveStats,
    this.loadingBuilder,
    this.errorBuilder,
    this.showStatusBar = false,
    this.statusBarBuilder,
    this.backgroundColor,
    this.padding,
    this.constraints,
  });

  /// {@macro flutter_monaco.editor.controller}
  final MonacoController? controller;

  /// {@macro flutter_monaco.editor.initialValue}
  final String? initialValue;

  /// Configuration options for the Monaco Editor instance.
  ///
  /// The editor will be updated if this object changes.
  /// See [EditorOptions] for a full list of available settings.
  final EditorOptions options;

  /// An optional text range to select after the [initialValue] is set.
  final Range? initialSelection;

  /// If `true`, focuses the editor as soon as it becomes ready.
  final bool autofocus;

  /// Custom CSS to inject into the editor's web view.
  ///
  /// This is particularly useful for defining `@font-face` rules to load
  /// custom fonts for the editor.
  final String? customCss;

  /// If `true`, allows the WebView to load fonts from CDN sources (`https:`).
  ///
  /// Defaults to `false` for a stricter Content Security Policy (CSP).
  final bool allowCdnFonts;

  /// An optional timeout for the editor to report that it is ready.
  ///
  /// If the editor fails to initialize within this duration, an error
  /// state will be triggered.
  final Duration? readyTimeout;

  /// A callback invoked when the editor is fully initialized and ready.
  ///
  /// The [MonacoController] for the editor instance is passed to this callback,
  /// whether it was provided externally or created internally.
  final ValueChanged<MonacoController>? onReady;

  /// A callback invoked whenever the content of the editor changes.
  final ValueChanged<String>? onContentChanged;

  /// Raw signal from Monaco: was this a flush change?
  final ValueChanged<bool>? onRawContentChanged;

  /// If true, only call [onContentChanged] on flush events.
  final bool fullTextOnFlushOnly;

  /// Debounce duration for non-flush text updates.
  final Duration contentDebounce;

  /// A callback invoked whenever the editor's selection changes.
  final ValueChanged<Range?>? onSelectionChanged;

  /// Callbacks invoked when the editor gains or loses focus.
  final VoidCallback? onFocus;

  /// A callback invoked when the editor loses focus.
  final VoidCallback? onBlur;

  /// A callback that provides live statistics from the editor, such as
  /// cursor position, line count, and selection details.
  final ValueChanged<LiveStats>? onLiveStats;

  /// A builder for the widget to display while the editor is loading.
  /// If `null`, a default circular progress indicator is shown.
  final WidgetBuilder? loadingBuilder;

  /// A builder for the widget to display when an initialization error occurs.
  final Widget Function(BuildContext context, Object error, StackTrace? st)?
      errorBuilder;

  /// If `true`, shows a status bar at the bottom of the editor.
  final bool showStatusBar;

  /// A builder to create a custom status bar widget.
  /// If provided, this overrides the default status bar.
  final Widget Function(BuildContext context, LiveStats stats)?
      statusBarBuilder;

  /// The background color for the container behind the editor's WebView.
  ///
  /// Defaults to a theme-appropriate color (`#1E1E1E` for dark, `white` for light).
  final Color? backgroundColor;

  /// Optional padding around the editor container.
  final EdgeInsetsGeometry? padding;

  /// Optional constraints for the editor container.
  final BoxConstraints? constraints;

  /// Creates the mutable state for this widget.
  @override
  State<MonacoEditor> createState() => _MonacoEditorState();
}

class _MonacoEditorState extends State<MonacoEditor> {
  /// The current state of the editor connection.
  _ConnectionState _connectionState = _ConnectionState.connecting;

  /// The controller for the editor. Can be external or internal.
  MonacoController? _controller;

  /// `true` if this widget is responsible for creating and disposing the controller.
  bool _ownsController = false;

  /// Holds any error that occurred during bootstrap.
  Object? _error;
  StackTrace? _stack;

  /// Subscriptions to controller events to be managed across the widget lifecycle.
  final List<StreamSubscription<dynamic>> _streamSubscriptions = [];
  StreamSubscription<bool>? _contentSub;
  VoidCallback? _statsListener;

  /// Content sequence number for race condition prevention.
  int _contentSeq = 0;

  /// Timer for debouncing content changes.
  Timer? _contentDebounceTimer;

  /// FocusNode to explicitly request platform view focus for the WebView.
  final FocusNode _webFocusNode = FocusNode(debugLabel: 'MonacoWebViewFocus');

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant MonacoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller is swapped externally, we need to re-bootstrap.
    if (oldWidget.controller != widget.controller) {
      _teardown(disposeOldController: _ownsController);
      _bootstrap();
      return;
    }

    // If we OWN the controller and HTML-affecting knobs changed, rebuild.
    final htmlKnobsChanged = (oldWidget.customCss != widget.customCss) ||
        (oldWidget.allowCdnFonts != widget.allowCdnFonts);
    if (_ownsController && htmlKnobsChanged) {
      _teardown(disposeOldController: true);
      _bootstrap();
      return;
    }

    if (_connectionState != _ConnectionState.ready || _controller == null) {
      return;
    }

    // If options change, apply them to the existing controller.
    if (widget.options != oldWidget.options) {
      _controller!.updateOptions(widget.options);
      // Explicitly update theme and language as they require separate bridge calls.
      _controller!.setTheme(widget.options.theme);
      _controller!.setLanguage(widget.options.language);
    }

    // If the content change callback has been updated, we need to rewire the listener.
    if (widget.onContentChanged != oldWidget.onContentChanged) {
      _wireContentListener();
    }
  }

  /// Initializes the editor controller and sets up listeners.
  Future<void> _bootstrap() async {
    setState(() {
      _connectionState = _ConnectionState.connecting;
      _error = null;
      _stack = null;
    });

    try {
      if (widget.controller != null) {
        _controller = widget.controller;
        _ownsController = false;
      } else {
        _ownsController = true;
        _controller = await MonacoController.create(
          options: widget.options,
          customCss: widget.customCss,
          allowCdnFonts: widget.allowCdnFonts,
          readyTimeout: widget.readyTimeout,
        );
      }

      // Wait for the underlying web view to be ready.
      await _controller!.onReady;

      // Apply initial values and settings post-readiness.
      if (widget.initialValue != null) {
        await _controller!.setValue(widget.initialValue!);
      }
      if (widget.initialSelection != null) {
        await _controller!.setSelection(widget.initialSelection!);
      }
      if (widget.autofocus) {
        // Defer to next frame to ensure visibility, request Flutter focus, and then enforce Monaco focus
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _webFocusNode.requestFocus();
          // Retry a few times to survive competing focus layout
          unawaited(_controller!.ensureEditorFocus(attempts: 3));
        });
      }

      _wireListeners();

      if (mounted) {
        setState(() => _connectionState = _ConnectionState.ready);
        widget.onReady?.call(_controller!);
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _connectionState = _ConnectionState.error;
          _error = e;
          _stack = st;
        });
      }
    }
  }

  /// Subscribes to all relevant event streams from the controller.
  void _wireListeners() {
    if (_controller == null) return;

    // Clear any existing subscriptions before wiring new ones.
    _teardownListeners();

    _wireContentListener();
    if (widget.onSelectionChanged != null) {
      final selectionSub = _controller!.onSelectionChanged
          .listen((r) => widget.onSelectionChanged?.call(r));
      _streamSubscriptions.add(selectionSub);
    }
    final focusSub = _controller!.onFocus.listen((_) => widget.onFocus?.call());
    _streamSubscriptions.add(focusSub);
    final blurSub = _controller!.onBlur.listen((_) => widget.onBlur?.call());
    _streamSubscriptions.add(blurSub);

    _statsListener =
        () => widget.onLiveStats?.call(_controller!.liveStats.value);
    _controller!.liveStats.addListener(_statsListener!);
  }

  /// Wires only the content changed listener, allowing it to be updated separately.
  void _wireContentListener() {
    // Cancel any previous content subscription first.
    _contentSub?.cancel();
    _contentSub = null;

    _contentSub = _controller!.onContentChanged.listen((isFlush) async {
      // 1) Always surface raw signal if requested.
      widget.onRawContentChanged?.call(isFlush);

      // 2) Nothing else to do?
      if (widget.onContentChanged == null) return;
      if (widget.fullTextOnFlushOnly && !isFlush) return;

      // 3) Flush = immediate fetch (no debounce), else debounced.
      Future<void> pullAndEmit() async {
        final seq = ++_contentSeq;
        final text = await _controller!.getValue();
        if (!mounted || seq != _contentSeq) return; // drop stale
        widget.onContentChanged!(text);
      }

      if (isFlush) {
        _contentDebounceTimer?.cancel();
        await pullAndEmit();
        return;
      }

      _contentDebounceTimer?.cancel();
      _contentDebounceTimer = Timer(widget.contentDebounce, pullAndEmit);
    });
  }

  /// Cancels all active event subscriptions.
  void _teardownListeners() {
    for (final sub in _streamSubscriptions) {
      sub.cancel();
    }
    _streamSubscriptions.clear();

    _contentSub?.cancel();
    _contentSub = null;

    _contentDebounceTimer?.cancel();
    _contentDebounceTimer = null;

    if (_controller != null && _statsListener != null) {
      _controller!.liveStats.removeListener(_statsListener!);
      _statsListener = null;
    }
  }

  /// Cleans up all resources, including listeners and the controller if owned.
  void _teardown({required bool disposeOldController}) {
    _teardownListeners();
    if (disposeOldController) {
      _controller?.dispose();
    }
    _controller = null;
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ??
        (context.themeData.brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white);

    return Container(
      color: bg,
      constraints: widget.constraints,
      padding: widget.padding,
      child: _buildChild(context),
    );
  }

  /// Builds the main content based on the current connection state.
  Widget _buildChild(BuildContext context) {
    switch (_connectionState) {
      case _ConnectionState.connecting:
        return widget.loadingBuilder?.call(context) ?? const _DefaultLoading();

      case _ConnectionState.error:
        return widget.errorBuilder?.call(context, _error!, _stack) ??
            _DefaultError(
              error: _error!,
              onRetry: _ownsController ? _bootstrap : null,
            );

      case _ConnectionState.ready:
        final webView = SizedBox.expand(
          child: Focus(
            focusNode: _webFocusNode,
            canRequestFocus: true,
            autofocus: widget.autofocus,
            onKeyEvent: (node, event) {
              // Forward key events to the native platform view (WKWebView/WebView2)
              if (event is KeyDownEvent) {
                return KeyEventResult.skipRemainingHandlers;
              }
              return KeyEventResult.ignored;
            },
            child: Listener(
              // Let the native WKWebView/WebView2 also receive the click.
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                if (!_webFocusNode.hasFocus) {
                  _webFocusNode.requestFocus();
                }
                if (_controller != null) {
                  // Encourage DOM focus to land on Monaco's textarea promptly.
                  unawaited(_controller!.ensureEditorFocus(attempts: 1));
                }
              },
              child: _controller!.webViewWidget,
            ),
          ),
        );
        final showBar = widget.showStatusBar || widget.statusBarBuilder != null;

        if (!showBar) {
          return webView;
        }

        // The status bar is built here, listening to the controller's stats.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: webView),
            if (widget.statusBarBuilder != null)
              ValueListenableBuilder<LiveStats>(
                valueListenable: _controller!.liveStats,
                builder: (context, stats, _) =>
                    widget.statusBarBuilder!(context, stats),
              )
            else
              _MonacoStatusBar(controller: _controller!),
          ],
        );
    }
  }

  @override
  void dispose() {
    _webFocusNode.dispose();
    _teardown(disposeOldController: _ownsController);
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// DEFAULT UI COMPONENTS
// -----------------------------------------------------------------------------

/// The default status bar, optimized to only rebuild when stats change.
class _MonacoStatusBar extends StatelessWidget {
  const _MonacoStatusBar({required this.controller});

  final MonacoController controller;

  @override
  Widget build(BuildContext context) {
    final theme = context.themeData;
    final style = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return ValueListenableBuilder<LiveStats>(
      valueListenable: controller.liveStats,
      builder: (context, stats, _) {
        final entries = [
          if (stats.cursorPosition != null) 'Ln ${stats.cursorPosition!.label}',
          'Ch ${stats.charCount.value}',
          if (stats.selectedLines.value > 0)
            'Sel Ln ${stats.selectedLines.value}',
          if (stats.selectedCharacters.value > 0)
            'Sel Ch ${stats.selectedCharacters.value}',
          if (stats.language != null) stats.language!,
        ].where((s) => s.isNotEmpty).toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.setOpacity(0.95),
            border:
                Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final entry in entries) Text(entry, style: style),
            ],
          ),
        );
      },
    );
  }
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.themeData;
    final style = theme.textTheme.bodyMedium;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
            const SizedBox(height: 16),
            Text(
              'Failed to Initialize Editor',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: style?.copyWith(color: theme.colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
