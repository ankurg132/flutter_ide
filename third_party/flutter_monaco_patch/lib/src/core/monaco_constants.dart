import 'package:flutter_monaco/flutter_monaco.dart';

/// Unified constants for the Monaco editor
class MonacoConstants {
  // Prevent instantiation
  MonacoConstants._();

  /// The minimum configurable font size for the editor.
  static const double minFontSize = 8;

  /// The maximum configurable font size for the editor.
  static const double maxFontSize = 48;

  /// The default font size used by the editor.
  static const double defaultFontSize = 14;

  /// Tab size range
  /// The minimum configurable tab size.
  static const int minTabSize = 1;

  /// The maximum configurable tab size.
  static const int maxTabSize = 8;

  /// The default tab size.
  static const int defaultTabSize = 2;

  /// Common ruler positions
  /// A list of common ruler positions for code formatting guidelines.
  static const List<List<int>> commonRulers = [
    [],
    [80],
    [100],
    [120],
    [80, 120],
    [80, 100, 120],
  ];

  /// File size limits
  /// The maximum recommended file size in bytes (10MB) to avoid performance issues.
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB

  /// The file size in bytes (1MB) at which a performance warning may be shown.
  static const int warningFileSize = 1 * 1024 * 1024; // 1 MB

  /// Default settings
  /// The identifier for the default editor theme ('vs-dark').
  static const String defaultTheme = 'vs-dark';

  /// The identifier for the default editor language ('markdown').
  static const String defaultLanguage = 'markdown';

  /// Default EditorOptions configuration
  /// A set of default [EditorOptions] for a standard, out-of-the-box experience.
  static const defaultOptions = EditorOptions(
    fontSize: defaultFontSize,
    theme: MonacoTheme.vsDark,
    language: MonacoLanguage.markdown,
    wordWrap: true,
    lineNumbers: true,
    minimap: false,
    automaticLayout: true,
    tabSize: defaultTabSize,
    insertSpaces: true,
    bracketPairColorization: true,
    formatOnPaste: false,
    formatOnType: false,
    smoothScrolling: true,
    mouseWheelZoom: true,
    cursorBlinking: CursorBlinking.blink,
    cursorStyle: CursorStyle.line,
    fontFamily: 'Cascadia Code, Fira Code, Consolas, monospace',
  );
}
