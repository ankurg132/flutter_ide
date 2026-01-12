import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'editor_options.freezed.dart';

/// Options for configuring the Monaco Editor
@freezed
sealed class EditorOptions with _$EditorOptions {
  const factory EditorOptions({
    @Default(MonacoLanguage.dart) MonacoLanguage language,
    @Default(MonacoTheme.vsDark) MonacoTheme theme,
    @Default(14) double fontSize,
    @Default('Consolas, "Courier New", monospace') String fontFamily,
    @Default(1.4) double lineHeight,
    @Default(true) bool wordWrap,
    @Default(false) bool minimap,
    @Default(true) bool lineNumbers,
    @Default([]) List<int> rulers,
    @Default(4) int tabSize,
    @Default(true) bool insertSpaces,
    @Default(false) bool readOnly,
    @Default(true) bool automaticLayout,
    Map<String, int>? padding,
    @Default(true) bool scrollBeyondLastLine,
    @Default(false) bool smoothScrolling,
    @Default(CursorBlinking.blink) CursorBlinking cursorBlinking,
    @Default(CursorStyle.line) CursorStyle cursorStyle,
    @Default(RenderWhitespace.selection) RenderWhitespace renderWhitespace,
    @Default(true) bool bracketPairColorization,
    @Default(AutoClosingBehavior.languageDefined)
    AutoClosingBehavior autoClosingBrackets,
    @Default(AutoClosingBehavior.languageDefined)
    AutoClosingBehavior autoClosingQuotes,
    @Default(false) bool formatOnPaste,
    @Default(false) bool formatOnType,
    @Default(true) bool quickSuggestions,
    @Default(false) bool fontLigatures,
    @Default(true) bool parameterHints,
    @Default(true) bool hover,
    @Default(true) bool contextMenu,
    @Default(false) bool mouseWheelZoom,
    @Default(true) bool roundedSelection,
    @Default(true) bool selectionHighlight,
    @Default(true) bool overviewRulerBorder,
    @Default(false) bool renderControlCharacters,
    @Default(false) bool disableLayerHinting,
    @Default(false) bool disableMonospaceOptimizations,
  }) = _EditorOptions;

  const EditorOptions._();

  factory EditorOptions.fromJson(Map<String, dynamic> json) {
    return EditorOptions(
      language: MonacoLanguage.fromId(
          json.getString('language', defaultValue: 'markdown')),
      theme:
          MonacoTheme.fromId(json.getString('theme', defaultValue: 'vs-dark')),
      fontSize: json.getDouble('fontSize', defaultValue: 14),
      fontFamily: json.getString('fontFamily',
          defaultValue: 'Consolas, "Courier New", monospace'),
      lineHeight: json.getDouble('lineHeight', defaultValue: 1.4),
      wordWrap: json.getBool('wordWrap', defaultValue: true),
      minimap: json.getBool('minimap', defaultValue: false),
      lineNumbers: json.getBool('lineNumbers', defaultValue: true),
      rulers: json.getList<int>('rulers', defaultValue: []),
      tabSize: json.getInt('tabSize', defaultValue: 4),
      insertSpaces: json.getBool('insertSpaces', defaultValue: true),
      readOnly: json.getBool('readOnly', defaultValue: false),
      automaticLayout: json.getBool('automaticLayout', defaultValue: true),
      padding: json.tryGetMap<String, int>('padding'),
      scrollBeyondLastLine:
          json.getBool('scrollBeyondLastLine', defaultValue: true),
      smoothScrolling: json.getBool('smoothScrolling', defaultValue: false),
      cursorBlinking: CursorBlinking.fromId(
          json.getString('cursorBlinking', defaultValue: 'blink')),
      cursorStyle: CursorStyle.fromId(
          json.getString('cursorStyle', defaultValue: 'line')),
      renderWhitespace: RenderWhitespace.fromId(
          json.getString('renderWhitespace', defaultValue: 'selection')),
      bracketPairColorization:
          json.getBool('bracketPairColorization', defaultValue: true),
      autoClosingBrackets: AutoClosingBehavior.fromId(json
          .getString('autoClosingBrackets', defaultValue: 'languageDefined')),
      autoClosingQuotes: AutoClosingBehavior.fromId(
          json.getString('autoClosingQuotes', defaultValue: 'languageDefined')),
      formatOnPaste: json.getBool('formatOnPaste', defaultValue: false),
      formatOnType: json.getBool('formatOnType', defaultValue: false),
      quickSuggestions: json.getBool('quickSuggestions', defaultValue: true),
      fontLigatures: json.getBool('fontLigatures', defaultValue: false),
      parameterHints: json.getBool('parameterHints', defaultValue: true),
      hover: json.getBool('hover', defaultValue: true),
      contextMenu: json.getBool('contextMenu', defaultValue: true),
      mouseWheelZoom: json.getBool('mouseWheelZoom', defaultValue: false),
      roundedSelection: json.getBool('roundedSelection', defaultValue: true),
      selectionHighlight:
          json.getBool('selectionHighlight', defaultValue: true),
      overviewRulerBorder:
          json.getBool('overviewRulerBorder', defaultValue: true),
      renderControlCharacters:
          json.getBool('renderControlCharacters', defaultValue: false),
      disableLayerHinting:
          json.getBool('disableLayerHinting', defaultValue: false),
      disableMonospaceOptimizations:
          json.getBool('disableMonospaceOptimizations', defaultValue: false),
    );
  }

  /// Convert to Monaco editor options format
  Map<String, dynamic> toMonacoOptions() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'wordWrap': wordWrap ? 'on' : 'off',
      'minimap': {'enabled': minimap},
      'lineNumbers': lineNumbers ? 'on' : 'off',
      'rulers': rulers,
      'tabSize': tabSize,
      'insertSpaces': insertSpaces,
      'readOnly': readOnly,
      'automaticLayout': automaticLayout,
      if (padding != null) 'padding': padding,
      'scrollBeyondLastLine': scrollBeyondLastLine,
      'smoothScrolling': smoothScrolling,
      'cursorBlinking': cursorBlinking.id,
      'cursorStyle': cursorStyle.id,
      'renderWhitespace': renderWhitespace.id,
      'bracketPairColorization': {'enabled': bracketPairColorization},
      'autoClosingBrackets': autoClosingBrackets.id,
      'autoClosingQuotes': autoClosingQuotes.id,
      'formatOnPaste': formatOnPaste,
      'formatOnType': formatOnType,
      'quickSuggestions': quickSuggestions,
      'fontLigatures': fontLigatures,
      'parameterHints': {'enabled': parameterHints},
      'hover': {'enabled': hover},
      'contextmenu': contextMenu,
      'mouseWheelZoom': mouseWheelZoom,
      'roundedSelection': roundedSelection,
      'selectionHighlight': selectionHighlight,
      'overviewRulerBorder': overviewRulerBorder,
      'renderControlCharacters': renderControlCharacters,
      'disableLayerHinting': disableLayerHinting,
      'disableMonospaceOptimizations': disableMonospaceOptimizations,
    };
  }
}
