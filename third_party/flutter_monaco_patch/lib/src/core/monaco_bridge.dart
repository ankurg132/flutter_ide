import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/src/models/monaco_types.dart';
import 'package:flutter_monaco/src/platform/platform_webview.dart';

/// A communication bridge between Flutter and the Monaco Editor in a WebView.
class MonacoBridge extends ChangeNotifier {
  // Kept for potential future use
  // ignore: unused_field
  PlatformWebViewController? _webViewController;

  // --- State Management ---
  /// A completer that notifies when the Monaco editor is initialized and ready.
  final Completer<void> onReady = Completer<void>();

  /// A [ValueNotifier] that provides real-time statistics from the editor,
  /// such as line count, character count, and selection details.
  final ValueNotifier<LiveStats> liveStats =
      ValueNotifier(LiveStats.defaults());

  // Raw event listeners for typed API
  final List<void Function(Map<String, dynamic>)> _rawListeners = [];

  // --- Lifecycle and WebView Integration ---
  /// Attaches the underlying [PlatformWebViewController] to this bridge,
  /// enabling communication with the editor.
  void attachWebView(PlatformWebViewController controller) {
    _webViewController = controller;
    debugPrint('[MonacoBridge] WebView controller attached.');
  }

  /// Handles incoming messages from the JavaScript side of the editor.
  ///
  /// This method processes raw messages, decodes them if necessary, and
  /// routes them to the appropriate handlers.
  void handleJavaScriptMessage(dynamic message) {
    // Keep platform-agnostic by handling various message types
    final String msg;
    if (message is String) {
      msg = message;
    } else if (message is Map || message is List) {
      msg = jsonEncode(message);
    } else if (message != null) {
      msg = message.toString();
    } else {
      msg = '';
    }
    _handleJavaScriptMessage(msg);
  }

  // Bridge only handles WebView attachment and event routing
  // All editor operations are handled by MonacoController directly

  /// Add a raw listener for all JS events
  void addRawListener(void Function(Map<String, dynamic>) listener) {
    _rawListeners.add(listener);
  }

  /// Remove a raw listener
  void removeRawListener(void Function(Map<String, dynamic>) listener) {
    _rawListeners.remove(listener);
  }

  @override
  void dispose() {
    debugPrint('[MonacoBridge] Disposing bridge.');
    if (!onReady.isCompleted) {
      onReady.completeError(
        Exception('Bridge disposed before the editor became ready.'),
      );
    }
    _rawListeners.clear();
    liveStats.dispose();
    // Don't dispose WebView here - let the controller own it
    super.dispose();
  }

  // --- Private Helpers ---
  void _handleJavaScriptMessage(String message) {
    if (message.startsWith('log:')) {
      debugPrint('[Monaco JS] ${message.substring(4)}');
      return;
    }

    try {
      final Map<String, dynamic> json = ConvertObject.toMap(message);

      switch (json) {
        case {'event': 'onEditorReady'} when !onReady.isCompleted:
          debugPrint('[MonacoBridge] ✅ "onEditorReady" event received.');
          onReady.complete();

        case {'event': 'onEditorReady'}:
          // Already handled; ignore duplicate
          break;

        case {'event': 'stats'}:
          liveStats.value = LiveStats.fromJson(json);

        case {'event': 'error', 'message': final String message}:
          debugPrint('❌ [Monaco JS Error] $message');

        // Swallow chatty events (controller listens via raw listeners)
        case {'event': 'contentChanged'}:
        case {'event': 'selectionChanged'}:
        case {'event': 'focus'}:
        case {'event': 'blur'}:
        case {'event': 'completionRequest'}:
          // These are handled by the controller's raw listener
          break;

        case {'event': final String event}:
          debugPrint('[MonacoBridge] Unhandled JS event type: "$event"');

        default:
          debugPrint('[MonacoBridge] Unhandled or malformed JS message.');
      }

      // Notify raw listeners
      for (final listener in _rawListeners) {
        try {
          listener(json);
        } catch (e) {
          debugPrint('[MonacoBridge] Error in raw listener: $e');
        }
      }
    } catch (e) {
      debugPrint(
          '[MonacoBridge] Could not process JS message. Raw: "$message". Error: $e');
    }
  }
}
