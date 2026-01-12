/// A Flutter plugin for integrating the Monaco Editor into Flutter applications.
///
/// Flutter Monaco provides a full-featured code editor powered by the same engine
/// that drives Visual Studio Code. It supports syntax highlighting for 100+ languages,
/// multiple themes, and a comprehensive API for editor manipulation.
///
/// ## Features
///
/// - **100+ Language Support** - Syntax highlighting for all major programming languages
/// - **Multiple Themes** - VS Light, VS Dark, High Contrast themes
/// - **Rich API** - Full programmatic control over the editor
/// - **Multi-Editor Support** - Run multiple independent editor instances
/// - **Cross-Platform** - Works on Android, iOS, macOS, and Windows
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter_monaco/flutter_monaco.dart';
///
/// // Simple usage with the widget
/// MonacoEditor(
///   options: EditorOptions(
///     language: MonacoLanguage.javascript,
///     theme: MonacoTheme.vsDark,
///   ),
/// )
///
/// // Advanced usage with controller
/// final controller = await MonacoController.create(
///   options: EditorOptions(
///     language: MonacoLanguage.python,
///     fontSize: 16,
///   ),
/// );
///
/// await controller.setValue('print("Hello, World!")');
/// final content = await controller.getValue();
/// ```
///
/// ## Platform Support
///
/// - ✅ Android (5.0+)
/// - ✅ iOS (11.0+)
/// - ✅ macOS (10.13+)
/// - ✅ Windows (10 version 1809+)
/// - ❌ Web (not supported)
/// - ❌ Linux (not supported)
///
/// ## Additional Resources
///
/// - [GitHub Repository](https://github.com/omar-hanafy/flutter_monaco)
/// - [API Documentation](https://pub.dev/documentation/flutter_monaco/latest/)
/// - [Example App](https://github.com/omar-hanafy/flutter_monaco/tree/main/example)
/// - [Issue Tracker](https://github.com/omar-hanafy/flutter_monaco/issues)
library;

// Core exports
export 'src/core/monaco_assets.dart' show MonacoAssets;
export 'src/core/monaco_constants.dart' show MonacoConstants;
export 'src/core/monaco_controller.dart' show MonacoController;
// Model exports
export 'src/models/editor_options.dart' show EditorOptions;
export 'src/models/monaco_enums.dart'
    show
        AutoClosingBehavior,
        CursorBlinking,
        CursorStyle,
        MonacoFont,
        MonacoLanguage,
        MonacoTheme,
        RenderWhitespace;
export 'src/models/monaco_types.dart'
    show
        CompletionItem,
        CompletionItemKind,
        CompletionList,
        CompletionRequest,
        DecorationOptions,
        EditOperation,
        EditorState,
        FindMatch,
        FindOptions,
        InsertTextRule,
        LiveStats,
        MarkerData,
        MarkerSeverity,
        Position,
        Range,
        RelatedInformation;
// Widget exports
export 'src/widgets/monaco_editor_view.dart' show MonacoEditor;
export 'src/widgets/monaco_focus_guard.dart' show MonacoFocusGuard;
