import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;
import 'package:webview_windows/webview_windows.dart' as ww;

/// A unified, platform-agnostic interface for controlling a WebView.
///
/// This abstract class provides a common API for interacting with the
/// underlying WebView, whether it's `webview_flutter` on mobile and macOS
/// or `webview_windows` on Windows. This allows the rest of the application
/// to remain platform-independent.
abstract class PlatformWebViewController {
  /// Executes the given JavaScript [script] in the WebView.
  ///
  /// This method does not return a result from the script.
  Future<Object?> runJavaScript(String script);

  /// Executes the given JavaScript [script] and returns its result.
  ///
  /// The result is decoded from JSON if possible.
  Future<Object?> runJavaScriptReturningResult(String script);

  /// Adds a JavaScript channel named [name] that can be used by JavaScript
  /// code to post messages to the Flutter application.
  ///
  /// The [onMessage] callback is invoked when a message is received.
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  );

  /// Removes a previously added JavaScript channel named [name].
  Future<Object?> removeJavaScriptChannel(String name);

  /// Disposes the controller and releases any associated resources.
  void dispose();
}

/// A [PlatformWebViewController] implementation for `webview_flutter`.
///
/// This controller is used on Android, iOS, and macOS.
class FlutterWebViewController implements PlatformWebViewController {
  /// Creates a new `webview_flutter` controller.
  FlutterWebViewController() {
    _controller = wf.WebViewController();
  }

  late final wf.WebViewController _controller;
  bool _disposed = false;

  /// The underlying [wf.WebViewController] from the `webview_flutter` package.
  wf.WebViewController get flutterController => _controller;

  /// Sets the JavaScript mode for the WebView.
  Future<Object?> setJavaScriptMode() async {
    await _controller.setJavaScriptMode(wf.JavaScriptMode.unrestricted);
    return null;
  }

  /// Sets the background color of the WebView.
  Future<Object?> setBackgroundColor(Color color) async {
    await _controller.setBackgroundColor(color);
    return null;
  }

  /// Loads a Flutter asset into the WebView.
  Future<Object?> loadFlutterAsset(String asset) async {
    await _controller.loadFlutterAsset(asset);
    return null;
  }

  /// Loads a local file into the WebView.
  Future<Object?> loadFile(String path) async {
    await _controller.loadFile(path);
    return null;
  }

  /// Sets the navigation delegate for the WebView.
  void setNavigationDelegate(wf.NavigationDelegate delegate) {
    _controller.setNavigationDelegate(delegate);
  }

  /// Sets a callback to be invoked when a JavaScript console message is logged.
  Future<void> setOnConsoleMessage(
    void Function(wf.JavaScriptConsoleMessage) onConsoleMessage,
  ) async {
    await _controller.setOnConsoleMessage(onConsoleMessage);
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      await _controller.runJavaScript(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS execution error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<Object?> runJavaScriptReturningResult(String script) async {
    try {
      return await _controller.runJavaScriptReturningResult(script);
    } catch (e) {
      debugPrint('[FlutterWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    await _controller.addJavaScriptChannel(
      name,
      onMessageReceived: (wf.JavaScriptMessage message) {
        onMessage(message.message);
      },
    );
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    await _controller.removeJavaScriptChannel(name);
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // WebViewController doesn't have an explicit dispose method in webview_flutter
  }
}

/// A [PlatformWebViewController] implementation for `webview_windows`.
///
/// This controller is used on the Windows platform and wraps the
/// `WebviewController` from the `webview_windows` package.
class WindowsWebViewController implements PlatformWebViewController {
  /// Creates a new `webview_windows` controller.
  WindowsWebViewController() {
    _controller = ww.WebviewController();
  }

  late final ww.WebviewController _controller;
  final Map<String, void Function(String)> _channels = {};
  StreamSubscription<dynamic>? _webMessageSubscription;
  bool _isInitialized = false;
  bool _disposed = false;

  /// The underlying [ww.WebviewController] from the `webview_windows` package.
  ww.WebviewController get windowsController => _controller;

  /// Initializes the WebView2 environment and the underlying controller.
  ///
  /// This must be called before any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[WindowsWebViewController] Initializing WebView2...');
    await _controller.initialize();
    _isInitialized = true;

    // Set up default configuration
    await _controller.setBackgroundColor(const Color(0xFF1E1E1E));
    await _controller.setPopupWindowPolicy(ww.WebviewPopupWindowPolicy.deny);

    // Set up message handler BEFORE adding any channels
    _setupWebMessageHandler();

    debugPrint('[WindowsWebViewController] WebView2 initialized successfully');
  }

  void _setupWebMessageHandler() {
    _webMessageSubscription?.cancel();

    _webMessageSubscription = _controller.webMessage.listen((
      dynamic rawMessage,
    ) {
      debugPrint(
        '[WindowsWebViewController] Raw message: $rawMessage (${rawMessage.runtimeType})',
      );

      try {
        String messageStr;

        if (rawMessage is String) {
          messageStr = rawMessage;
        } else if (rawMessage is Map) {
          messageStr = json.encode(rawMessage);
        } else {
          messageStr = rawMessage.toString();
        }

        _channels.forEach((channelName, handler) {
          debugPrint(
            '[WindowsWebViewController] Forwarding to channel: $channelName',
          );
          handler(messageStr);
        });
      } catch (e) {
        debugPrint('[WindowsWebViewController] Error handling message: $e');
      }
    });
  }

  /// Loads the given HTML string into the WebView.
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    debugPrint(
      '[WindowsWebViewController] Loading HTML string (length: ${html.length})',
    );
    await _controller.loadStringContent(html);
  }

  /// Loads the specified URL into the WebView.
  Future<void> loadUrl(String url) async {
    debugPrint('[WindowsWebViewController] Loading URL: $url');
    await _controller.loadUrl(url);
  }

  @override
  Future<Object?> runJavaScript(String script) async {
    try {
      return await _controller.executeScript(script);
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS execution error: $e');
      rethrow;
    }
  }

  @override
  Future<dynamic> runJavaScriptReturningResult(String script) async {
    try {
      final result = await _controller.executeScript(script);

      if (result == null) return null;

      if (result is String) {
        final trimmed = result.trim();
        final looksLikeJson =
            (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
                (trimmed.startsWith('[') && trimmed.endsWith(']'));
        if (looksLikeJson) {
          try {
            return json.decode(result);
          } catch (_) {
            // fall through to raw handling
          }
        }
        if (trimmed.length >= 2 &&
            trimmed.startsWith('"') &&
            trimmed.endsWith('"')) {
          return trimmed.substring(1, trimmed.length - 1);
        }
        return result;
      }

      return result;
    } catch (e) {
      debugPrint('[WindowsWebViewController] JS result error: $e');
      rethrow;
    }
  }

  @override
  Future<Object?> addJavaScriptChannel(
    String name,
    void Function(String) onMessage,
  ) async {
    debugPrint(
        '[WindowsWebViewController] Registering handler for channel: $name');

    // Store the handler - HTML already defines window.flutterChannel
    _channels[name] = onMessage;

    // No need to inject JavaScript - the HTML already has the channel defined
    return null;
  }

  @override
  Future<Object?> removeJavaScriptChannel(String name) async {
    _channels.remove(name);
    return null; // No-op in JS; HTML owns flutterChannel
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    debugPrint('[WindowsWebViewController] Disposing...');
    _webMessageSubscription?.cancel();
    _channels.clear();
    if (_isInitialized) {
      _controller.dispose();
    }
  }
}

/// A factory for creating the appropriate [PlatformWebViewController] for the
/// current operating system.
class PlatformWebViewFactory {
  /// Creates and returns a [PlatformWebViewController].
  ///
  /// This will be a [WindowsWebViewController] on Windows and a
  /// [FlutterWebViewController] on all other platforms.
  static PlatformWebViewController createController() {
    if (Platform.isWindows) {
      return WindowsWebViewController();
    } else {
      return FlutterWebViewController();
    }
  }
}
