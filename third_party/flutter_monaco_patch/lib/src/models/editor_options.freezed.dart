// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'editor_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EditorOptions {
  MonacoLanguage get language;
  MonacoTheme get theme;
  double get fontSize;
  String get fontFamily;
  double get lineHeight;
  bool get wordWrap;
  bool get minimap;
  bool get lineNumbers;
  List<int> get rulers;
  int get tabSize;
  bool get insertSpaces;
  bool get readOnly;
  bool get automaticLayout;
  Map<String, int>? get padding;
  bool get scrollBeyondLastLine;
  bool get smoothScrolling;
  CursorBlinking get cursorBlinking;
  CursorStyle get cursorStyle;
  RenderWhitespace get renderWhitespace;
  bool get bracketPairColorization;
  AutoClosingBehavior get autoClosingBrackets;
  AutoClosingBehavior get autoClosingQuotes;
  bool get formatOnPaste;
  bool get formatOnType;
  bool get quickSuggestions;
  bool get fontLigatures;
  bool get parameterHints;
  bool get hover;
  bool get contextMenu;
  bool get mouseWheelZoom;
  bool get roundedSelection;
  bool get selectionHighlight;
  bool get overviewRulerBorder;
  bool get renderControlCharacters;
  bool get disableLayerHinting;
  bool get disableMonospaceOptimizations;

  /// Create a copy of EditorOptions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EditorOptionsCopyWith<EditorOptions> get copyWith =>
      _$EditorOptionsCopyWithImpl<EditorOptions>(
          this as EditorOptions, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EditorOptions &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.lineHeight, lineHeight) ||
                other.lineHeight == lineHeight) &&
            (identical(other.wordWrap, wordWrap) ||
                other.wordWrap == wordWrap) &&
            (identical(other.minimap, minimap) || other.minimap == minimap) &&
            (identical(other.lineNumbers, lineNumbers) ||
                other.lineNumbers == lineNumbers) &&
            const DeepCollectionEquality().equals(other.rulers, rulers) &&
            (identical(other.tabSize, tabSize) || other.tabSize == tabSize) &&
            (identical(other.insertSpaces, insertSpaces) ||
                other.insertSpaces == insertSpaces) &&
            (identical(other.readOnly, readOnly) ||
                other.readOnly == readOnly) &&
            (identical(other.automaticLayout, automaticLayout) ||
                other.automaticLayout == automaticLayout) &&
            const DeepCollectionEquality().equals(other.padding, padding) &&
            (identical(other.scrollBeyondLastLine, scrollBeyondLastLine) ||
                other.scrollBeyondLastLine == scrollBeyondLastLine) &&
            (identical(other.smoothScrolling, smoothScrolling) ||
                other.smoothScrolling == smoothScrolling) &&
            (identical(other.cursorBlinking, cursorBlinking) ||
                other.cursorBlinking == cursorBlinking) &&
            (identical(other.cursorStyle, cursorStyle) ||
                other.cursorStyle == cursorStyle) &&
            (identical(other.renderWhitespace, renderWhitespace) ||
                other.renderWhitespace == renderWhitespace) &&
            (identical(
                    other.bracketPairColorization, bracketPairColorization) ||
                other.bracketPairColorization == bracketPairColorization) &&
            (identical(other.autoClosingBrackets, autoClosingBrackets) ||
                other.autoClosingBrackets == autoClosingBrackets) &&
            (identical(other.autoClosingQuotes, autoClosingQuotes) ||
                other.autoClosingQuotes == autoClosingQuotes) &&
            (identical(other.formatOnPaste, formatOnPaste) ||
                other.formatOnPaste == formatOnPaste) &&
            (identical(other.formatOnType, formatOnType) ||
                other.formatOnType == formatOnType) &&
            (identical(other.quickSuggestions, quickSuggestions) ||
                other.quickSuggestions == quickSuggestions) &&
            (identical(other.fontLigatures, fontLigatures) ||
                other.fontLigatures == fontLigatures) &&
            (identical(other.parameterHints, parameterHints) ||
                other.parameterHints == parameterHints) &&
            (identical(other.hover, hover) || other.hover == hover) &&
            (identical(other.contextMenu, contextMenu) ||
                other.contextMenu == contextMenu) &&
            (identical(other.mouseWheelZoom, mouseWheelZoom) ||
                other.mouseWheelZoom == mouseWheelZoom) &&
            (identical(other.roundedSelection, roundedSelection) ||
                other.roundedSelection == roundedSelection) &&
            (identical(other.selectionHighlight, selectionHighlight) ||
                other.selectionHighlight == selectionHighlight) &&
            (identical(other.overviewRulerBorder, overviewRulerBorder) ||
                other.overviewRulerBorder == overviewRulerBorder) &&
            (identical(
                    other.renderControlCharacters, renderControlCharacters) ||
                other.renderControlCharacters == renderControlCharacters) &&
            (identical(other.disableLayerHinting, disableLayerHinting) ||
                other.disableLayerHinting == disableLayerHinting) &&
            (identical(other.disableMonospaceOptimizations,
                    disableMonospaceOptimizations) ||
                other.disableMonospaceOptimizations ==
                    disableMonospaceOptimizations));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        language,
        theme,
        fontSize,
        fontFamily,
        lineHeight,
        wordWrap,
        minimap,
        lineNumbers,
        const DeepCollectionEquality().hash(rulers),
        tabSize,
        insertSpaces,
        readOnly,
        automaticLayout,
        const DeepCollectionEquality().hash(padding),
        scrollBeyondLastLine,
        smoothScrolling,
        cursorBlinking,
        cursorStyle,
        renderWhitespace,
        bracketPairColorization,
        autoClosingBrackets,
        autoClosingQuotes,
        formatOnPaste,
        formatOnType,
        quickSuggestions,
        fontLigatures,
        parameterHints,
        hover,
        contextMenu,
        mouseWheelZoom,
        roundedSelection,
        selectionHighlight,
        overviewRulerBorder,
        renderControlCharacters,
        disableLayerHinting,
        disableMonospaceOptimizations
      ]);

  @override
  String toString() {
    return 'EditorOptions(language: $language, theme: $theme, fontSize: $fontSize, fontFamily: $fontFamily, lineHeight: $lineHeight, wordWrap: $wordWrap, minimap: $minimap, lineNumbers: $lineNumbers, rulers: $rulers, tabSize: $tabSize, insertSpaces: $insertSpaces, readOnly: $readOnly, automaticLayout: $automaticLayout, padding: $padding, scrollBeyondLastLine: $scrollBeyondLastLine, smoothScrolling: $smoothScrolling, cursorBlinking: $cursorBlinking, cursorStyle: $cursorStyle, renderWhitespace: $renderWhitespace, bracketPairColorization: $bracketPairColorization, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, quickSuggestions: $quickSuggestions, fontLigatures: $fontLigatures, parameterHints: $parameterHints, hover: $hover, contextMenu: $contextMenu, mouseWheelZoom: $mouseWheelZoom, roundedSelection: $roundedSelection, selectionHighlight: $selectionHighlight, overviewRulerBorder: $overviewRulerBorder, renderControlCharacters: $renderControlCharacters, disableLayerHinting: $disableLayerHinting, disableMonospaceOptimizations: $disableMonospaceOptimizations)';
  }
}

/// @nodoc
abstract mixin class $EditorOptionsCopyWith<$Res> {
  factory $EditorOptionsCopyWith(
          EditorOptions value, $Res Function(EditorOptions) _then) =
      _$EditorOptionsCopyWithImpl;
  @useResult
  $Res call(
      {MonacoLanguage language,
      MonacoTheme theme,
      double fontSize,
      String fontFamily,
      double lineHeight,
      bool wordWrap,
      bool minimap,
      bool lineNumbers,
      List<int> rulers,
      int tabSize,
      bool insertSpaces,
      bool readOnly,
      bool automaticLayout,
      Map<String, int>? padding,
      bool scrollBeyondLastLine,
      bool smoothScrolling,
      CursorBlinking cursorBlinking,
      CursorStyle cursorStyle,
      RenderWhitespace renderWhitespace,
      bool bracketPairColorization,
      AutoClosingBehavior autoClosingBrackets,
      AutoClosingBehavior autoClosingQuotes,
      bool formatOnPaste,
      bool formatOnType,
      bool quickSuggestions,
      bool fontLigatures,
      bool parameterHints,
      bool hover,
      bool contextMenu,
      bool mouseWheelZoom,
      bool roundedSelection,
      bool selectionHighlight,
      bool overviewRulerBorder,
      bool renderControlCharacters,
      bool disableLayerHinting,
      bool disableMonospaceOptimizations});
}

/// @nodoc
class _$EditorOptionsCopyWithImpl<$Res>
    implements $EditorOptionsCopyWith<$Res> {
  _$EditorOptionsCopyWithImpl(this._self, this._then);

  final EditorOptions _self;
  final $Res Function(EditorOptions) _then;

  /// Create a copy of EditorOptions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? language = null,
    Object? theme = null,
    Object? fontSize = null,
    Object? fontFamily = null,
    Object? lineHeight = null,
    Object? wordWrap = null,
    Object? minimap = null,
    Object? lineNumbers = null,
    Object? rulers = null,
    Object? tabSize = null,
    Object? insertSpaces = null,
    Object? readOnly = null,
    Object? automaticLayout = null,
    Object? padding = freezed,
    Object? scrollBeyondLastLine = null,
    Object? smoothScrolling = null,
    Object? cursorBlinking = null,
    Object? cursorStyle = null,
    Object? renderWhitespace = null,
    Object? bracketPairColorization = null,
    Object? autoClosingBrackets = null,
    Object? autoClosingQuotes = null,
    Object? formatOnPaste = null,
    Object? formatOnType = null,
    Object? quickSuggestions = null,
    Object? fontLigatures = null,
    Object? parameterHints = null,
    Object? hover = null,
    Object? contextMenu = null,
    Object? mouseWheelZoom = null,
    Object? roundedSelection = null,
    Object? selectionHighlight = null,
    Object? overviewRulerBorder = null,
    Object? renderControlCharacters = null,
    Object? disableLayerHinting = null,
    Object? disableMonospaceOptimizations = null,
  }) {
    return _then(_self.copyWith(
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as MonacoLanguage,
      theme: null == theme
          ? _self.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as MonacoTheme,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
      fontFamily: null == fontFamily
          ? _self.fontFamily
          : fontFamily // ignore: cast_nullable_to_non_nullable
              as String,
      lineHeight: null == lineHeight
          ? _self.lineHeight
          : lineHeight // ignore: cast_nullable_to_non_nullable
              as double,
      wordWrap: null == wordWrap
          ? _self.wordWrap
          : wordWrap // ignore: cast_nullable_to_non_nullable
              as bool,
      minimap: null == minimap
          ? _self.minimap
          : minimap // ignore: cast_nullable_to_non_nullable
              as bool,
      lineNumbers: null == lineNumbers
          ? _self.lineNumbers
          : lineNumbers // ignore: cast_nullable_to_non_nullable
              as bool,
      rulers: null == rulers
          ? _self.rulers
          : rulers // ignore: cast_nullable_to_non_nullable
              as List<int>,
      tabSize: null == tabSize
          ? _self.tabSize
          : tabSize // ignore: cast_nullable_to_non_nullable
              as int,
      insertSpaces: null == insertSpaces
          ? _self.insertSpaces
          : insertSpaces // ignore: cast_nullable_to_non_nullable
              as bool,
      readOnly: null == readOnly
          ? _self.readOnly
          : readOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      automaticLayout: null == automaticLayout
          ? _self.automaticLayout
          : automaticLayout // ignore: cast_nullable_to_non_nullable
              as bool,
      padding: freezed == padding
          ? _self.padding
          : padding // ignore: cast_nullable_to_non_nullable
              as Map<String, int>?,
      scrollBeyondLastLine: null == scrollBeyondLastLine
          ? _self.scrollBeyondLastLine
          : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
              as bool,
      smoothScrolling: null == smoothScrolling
          ? _self.smoothScrolling
          : smoothScrolling // ignore: cast_nullable_to_non_nullable
              as bool,
      cursorBlinking: null == cursorBlinking
          ? _self.cursorBlinking
          : cursorBlinking // ignore: cast_nullable_to_non_nullable
              as CursorBlinking,
      cursorStyle: null == cursorStyle
          ? _self.cursorStyle
          : cursorStyle // ignore: cast_nullable_to_non_nullable
              as CursorStyle,
      renderWhitespace: null == renderWhitespace
          ? _self.renderWhitespace
          : renderWhitespace // ignore: cast_nullable_to_non_nullable
              as RenderWhitespace,
      bracketPairColorization: null == bracketPairColorization
          ? _self.bracketPairColorization
          : bracketPairColorization // ignore: cast_nullable_to_non_nullable
              as bool,
      autoClosingBrackets: null == autoClosingBrackets
          ? _self.autoClosingBrackets
          : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
              as AutoClosingBehavior,
      autoClosingQuotes: null == autoClosingQuotes
          ? _self.autoClosingQuotes
          : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
              as AutoClosingBehavior,
      formatOnPaste: null == formatOnPaste
          ? _self.formatOnPaste
          : formatOnPaste // ignore: cast_nullable_to_non_nullable
              as bool,
      formatOnType: null == formatOnType
          ? _self.formatOnType
          : formatOnType // ignore: cast_nullable_to_non_nullable
              as bool,
      quickSuggestions: null == quickSuggestions
          ? _self.quickSuggestions
          : quickSuggestions // ignore: cast_nullable_to_non_nullable
              as bool,
      fontLigatures: null == fontLigatures
          ? _self.fontLigatures
          : fontLigatures // ignore: cast_nullable_to_non_nullable
              as bool,
      parameterHints: null == parameterHints
          ? _self.parameterHints
          : parameterHints // ignore: cast_nullable_to_non_nullable
              as bool,
      hover: null == hover
          ? _self.hover
          : hover // ignore: cast_nullable_to_non_nullable
              as bool,
      contextMenu: null == contextMenu
          ? _self.contextMenu
          : contextMenu // ignore: cast_nullable_to_non_nullable
              as bool,
      mouseWheelZoom: null == mouseWheelZoom
          ? _self.mouseWheelZoom
          : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
              as bool,
      roundedSelection: null == roundedSelection
          ? _self.roundedSelection
          : roundedSelection // ignore: cast_nullable_to_non_nullable
              as bool,
      selectionHighlight: null == selectionHighlight
          ? _self.selectionHighlight
          : selectionHighlight // ignore: cast_nullable_to_non_nullable
              as bool,
      overviewRulerBorder: null == overviewRulerBorder
          ? _self.overviewRulerBorder
          : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
              as bool,
      renderControlCharacters: null == renderControlCharacters
          ? _self.renderControlCharacters
          : renderControlCharacters // ignore: cast_nullable_to_non_nullable
              as bool,
      disableLayerHinting: null == disableLayerHinting
          ? _self.disableLayerHinting
          : disableLayerHinting // ignore: cast_nullable_to_non_nullable
              as bool,
      disableMonospaceOptimizations: null == disableMonospaceOptimizations
          ? _self.disableMonospaceOptimizations
          : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [EditorOptions].
extension EditorOptionsPatterns on EditorOptions {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_EditorOptions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EditorOptions() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_EditorOptions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EditorOptions():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_EditorOptions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EditorOptions() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            MonacoLanguage language,
            MonacoTheme theme,
            double fontSize,
            String fontFamily,
            double lineHeight,
            bool wordWrap,
            bool minimap,
            bool lineNumbers,
            List<int> rulers,
            int tabSize,
            bool insertSpaces,
            bool readOnly,
            bool automaticLayout,
            Map<String, int>? padding,
            bool scrollBeyondLastLine,
            bool smoothScrolling,
            CursorBlinking cursorBlinking,
            CursorStyle cursorStyle,
            RenderWhitespace renderWhitespace,
            bool bracketPairColorization,
            AutoClosingBehavior autoClosingBrackets,
            AutoClosingBehavior autoClosingQuotes,
            bool formatOnPaste,
            bool formatOnType,
            bool quickSuggestions,
            bool fontLigatures,
            bool parameterHints,
            bool hover,
            bool contextMenu,
            bool mouseWheelZoom,
            bool roundedSelection,
            bool selectionHighlight,
            bool overviewRulerBorder,
            bool renderControlCharacters,
            bool disableLayerHinting,
            bool disableMonospaceOptimizations)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EditorOptions() when $default != null:
        return $default(
            _that.language,
            _that.theme,
            _that.fontSize,
            _that.fontFamily,
            _that.lineHeight,
            _that.wordWrap,
            _that.minimap,
            _that.lineNumbers,
            _that.rulers,
            _that.tabSize,
            _that.insertSpaces,
            _that.readOnly,
            _that.automaticLayout,
            _that.padding,
            _that.scrollBeyondLastLine,
            _that.smoothScrolling,
            _that.cursorBlinking,
            _that.cursorStyle,
            _that.renderWhitespace,
            _that.bracketPairColorization,
            _that.autoClosingBrackets,
            _that.autoClosingQuotes,
            _that.formatOnPaste,
            _that.formatOnType,
            _that.quickSuggestions,
            _that.fontLigatures,
            _that.parameterHints,
            _that.hover,
            _that.contextMenu,
            _that.mouseWheelZoom,
            _that.roundedSelection,
            _that.selectionHighlight,
            _that.overviewRulerBorder,
            _that.renderControlCharacters,
            _that.disableLayerHinting,
            _that.disableMonospaceOptimizations);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            MonacoLanguage language,
            MonacoTheme theme,
            double fontSize,
            String fontFamily,
            double lineHeight,
            bool wordWrap,
            bool minimap,
            bool lineNumbers,
            List<int> rulers,
            int tabSize,
            bool insertSpaces,
            bool readOnly,
            bool automaticLayout,
            Map<String, int>? padding,
            bool scrollBeyondLastLine,
            bool smoothScrolling,
            CursorBlinking cursorBlinking,
            CursorStyle cursorStyle,
            RenderWhitespace renderWhitespace,
            bool bracketPairColorization,
            AutoClosingBehavior autoClosingBrackets,
            AutoClosingBehavior autoClosingQuotes,
            bool formatOnPaste,
            bool formatOnType,
            bool quickSuggestions,
            bool fontLigatures,
            bool parameterHints,
            bool hover,
            bool contextMenu,
            bool mouseWheelZoom,
            bool roundedSelection,
            bool selectionHighlight,
            bool overviewRulerBorder,
            bool renderControlCharacters,
            bool disableLayerHinting,
            bool disableMonospaceOptimizations)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EditorOptions():
        return $default(
            _that.language,
            _that.theme,
            _that.fontSize,
            _that.fontFamily,
            _that.lineHeight,
            _that.wordWrap,
            _that.minimap,
            _that.lineNumbers,
            _that.rulers,
            _that.tabSize,
            _that.insertSpaces,
            _that.readOnly,
            _that.automaticLayout,
            _that.padding,
            _that.scrollBeyondLastLine,
            _that.smoothScrolling,
            _that.cursorBlinking,
            _that.cursorStyle,
            _that.renderWhitespace,
            _that.bracketPairColorization,
            _that.autoClosingBrackets,
            _that.autoClosingQuotes,
            _that.formatOnPaste,
            _that.formatOnType,
            _that.quickSuggestions,
            _that.fontLigatures,
            _that.parameterHints,
            _that.hover,
            _that.contextMenu,
            _that.mouseWheelZoom,
            _that.roundedSelection,
            _that.selectionHighlight,
            _that.overviewRulerBorder,
            _that.renderControlCharacters,
            _that.disableLayerHinting,
            _that.disableMonospaceOptimizations);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            MonacoLanguage language,
            MonacoTheme theme,
            double fontSize,
            String fontFamily,
            double lineHeight,
            bool wordWrap,
            bool minimap,
            bool lineNumbers,
            List<int> rulers,
            int tabSize,
            bool insertSpaces,
            bool readOnly,
            bool automaticLayout,
            Map<String, int>? padding,
            bool scrollBeyondLastLine,
            bool smoothScrolling,
            CursorBlinking cursorBlinking,
            CursorStyle cursorStyle,
            RenderWhitespace renderWhitespace,
            bool bracketPairColorization,
            AutoClosingBehavior autoClosingBrackets,
            AutoClosingBehavior autoClosingQuotes,
            bool formatOnPaste,
            bool formatOnType,
            bool quickSuggestions,
            bool fontLigatures,
            bool parameterHints,
            bool hover,
            bool contextMenu,
            bool mouseWheelZoom,
            bool roundedSelection,
            bool selectionHighlight,
            bool overviewRulerBorder,
            bool renderControlCharacters,
            bool disableLayerHinting,
            bool disableMonospaceOptimizations)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EditorOptions() when $default != null:
        return $default(
            _that.language,
            _that.theme,
            _that.fontSize,
            _that.fontFamily,
            _that.lineHeight,
            _that.wordWrap,
            _that.minimap,
            _that.lineNumbers,
            _that.rulers,
            _that.tabSize,
            _that.insertSpaces,
            _that.readOnly,
            _that.automaticLayout,
            _that.padding,
            _that.scrollBeyondLastLine,
            _that.smoothScrolling,
            _that.cursorBlinking,
            _that.cursorStyle,
            _that.renderWhitespace,
            _that.bracketPairColorization,
            _that.autoClosingBrackets,
            _that.autoClosingQuotes,
            _that.formatOnPaste,
            _that.formatOnType,
            _that.quickSuggestions,
            _that.fontLigatures,
            _that.parameterHints,
            _that.hover,
            _that.contextMenu,
            _that.mouseWheelZoom,
            _that.roundedSelection,
            _that.selectionHighlight,
            _that.overviewRulerBorder,
            _that.renderControlCharacters,
            _that.disableLayerHinting,
            _that.disableMonospaceOptimizations);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EditorOptions extends EditorOptions {
  const _EditorOptions(
      {this.language = MonacoLanguage.dart,
      this.theme = MonacoTheme.vsDark,
      this.fontSize = 14,
      this.fontFamily = 'Consolas, "Courier New", monospace',
      this.lineHeight = 1.4,
      this.wordWrap = true,
      this.minimap = false,
      this.lineNumbers = true,
      final List<int> rulers = const [],
      this.tabSize = 4,
      this.insertSpaces = true,
      this.readOnly = false,
      this.automaticLayout = true,
      final Map<String, int>? padding,
      this.scrollBeyondLastLine = true,
      this.smoothScrolling = false,
      this.cursorBlinking = CursorBlinking.blink,
      this.cursorStyle = CursorStyle.line,
      this.renderWhitespace = RenderWhitespace.selection,
      this.bracketPairColorization = true,
      this.autoClosingBrackets = AutoClosingBehavior.languageDefined,
      this.autoClosingQuotes = AutoClosingBehavior.languageDefined,
      this.formatOnPaste = false,
      this.formatOnType = false,
      this.quickSuggestions = true,
      this.fontLigatures = false,
      this.parameterHints = true,
      this.hover = true,
      this.contextMenu = true,
      this.mouseWheelZoom = false,
      this.roundedSelection = true,
      this.selectionHighlight = true,
      this.overviewRulerBorder = true,
      this.renderControlCharacters = false,
      this.disableLayerHinting = false,
      this.disableMonospaceOptimizations = false})
      : _rulers = rulers,
        _padding = padding,
        super._();

  @override
  @JsonKey()
  final MonacoLanguage language;
  @override
  @JsonKey()
  final MonacoTheme theme;
  @override
  @JsonKey()
  final double fontSize;
  @override
  @JsonKey()
  final String fontFamily;
  @override
  @JsonKey()
  final double lineHeight;
  @override
  @JsonKey()
  final bool wordWrap;
  @override
  @JsonKey()
  final bool minimap;
  @override
  @JsonKey()
  final bool lineNumbers;
  final List<int> _rulers;
  @override
  @JsonKey()
  List<int> get rulers {
    if (_rulers is EqualUnmodifiableListView) return _rulers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rulers);
  }

  @override
  @JsonKey()
  final int tabSize;
  @override
  @JsonKey()
  final bool insertSpaces;
  @override
  @JsonKey()
  final bool readOnly;
  @override
  @JsonKey()
  final bool automaticLayout;
  final Map<String, int>? _padding;
  @override
  Map<String, int>? get padding {
    final value = _padding;
    if (value == null) return null;
    if (_padding is EqualUnmodifiableMapView) return _padding;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final bool scrollBeyondLastLine;
  @override
  @JsonKey()
  final bool smoothScrolling;
  @override
  @JsonKey()
  final CursorBlinking cursorBlinking;
  @override
  @JsonKey()
  final CursorStyle cursorStyle;
  @override
  @JsonKey()
  final RenderWhitespace renderWhitespace;
  @override
  @JsonKey()
  final bool bracketPairColorization;
  @override
  @JsonKey()
  final AutoClosingBehavior autoClosingBrackets;
  @override
  @JsonKey()
  final AutoClosingBehavior autoClosingQuotes;
  @override
  @JsonKey()
  final bool formatOnPaste;
  @override
  @JsonKey()
  final bool formatOnType;
  @override
  @JsonKey()
  final bool quickSuggestions;
  @override
  @JsonKey()
  final bool fontLigatures;
  @override
  @JsonKey()
  final bool parameterHints;
  @override
  @JsonKey()
  final bool hover;
  @override
  @JsonKey()
  final bool contextMenu;
  @override
  @JsonKey()
  final bool mouseWheelZoom;
  @override
  @JsonKey()
  final bool roundedSelection;
  @override
  @JsonKey()
  final bool selectionHighlight;
  @override
  @JsonKey()
  final bool overviewRulerBorder;
  @override
  @JsonKey()
  final bool renderControlCharacters;
  @override
  @JsonKey()
  final bool disableLayerHinting;
  @override
  @JsonKey()
  final bool disableMonospaceOptimizations;

  /// Create a copy of EditorOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EditorOptionsCopyWith<_EditorOptions> get copyWith =>
      __$EditorOptionsCopyWithImpl<_EditorOptions>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EditorOptions &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize) &&
            (identical(other.fontFamily, fontFamily) ||
                other.fontFamily == fontFamily) &&
            (identical(other.lineHeight, lineHeight) ||
                other.lineHeight == lineHeight) &&
            (identical(other.wordWrap, wordWrap) ||
                other.wordWrap == wordWrap) &&
            (identical(other.minimap, minimap) || other.minimap == minimap) &&
            (identical(other.lineNumbers, lineNumbers) ||
                other.lineNumbers == lineNumbers) &&
            const DeepCollectionEquality().equals(other._rulers, _rulers) &&
            (identical(other.tabSize, tabSize) || other.tabSize == tabSize) &&
            (identical(other.insertSpaces, insertSpaces) ||
                other.insertSpaces == insertSpaces) &&
            (identical(other.readOnly, readOnly) ||
                other.readOnly == readOnly) &&
            (identical(other.automaticLayout, automaticLayout) ||
                other.automaticLayout == automaticLayout) &&
            const DeepCollectionEquality().equals(other._padding, _padding) &&
            (identical(other.scrollBeyondLastLine, scrollBeyondLastLine) ||
                other.scrollBeyondLastLine == scrollBeyondLastLine) &&
            (identical(other.smoothScrolling, smoothScrolling) ||
                other.smoothScrolling == smoothScrolling) &&
            (identical(other.cursorBlinking, cursorBlinking) ||
                other.cursorBlinking == cursorBlinking) &&
            (identical(other.cursorStyle, cursorStyle) ||
                other.cursorStyle == cursorStyle) &&
            (identical(other.renderWhitespace, renderWhitespace) ||
                other.renderWhitespace == renderWhitespace) &&
            (identical(
                    other.bracketPairColorization, bracketPairColorization) ||
                other.bracketPairColorization == bracketPairColorization) &&
            (identical(other.autoClosingBrackets, autoClosingBrackets) ||
                other.autoClosingBrackets == autoClosingBrackets) &&
            (identical(other.autoClosingQuotes, autoClosingQuotes) ||
                other.autoClosingQuotes == autoClosingQuotes) &&
            (identical(other.formatOnPaste, formatOnPaste) ||
                other.formatOnPaste == formatOnPaste) &&
            (identical(other.formatOnType, formatOnType) ||
                other.formatOnType == formatOnType) &&
            (identical(other.quickSuggestions, quickSuggestions) ||
                other.quickSuggestions == quickSuggestions) &&
            (identical(other.fontLigatures, fontLigatures) ||
                other.fontLigatures == fontLigatures) &&
            (identical(other.parameterHints, parameterHints) ||
                other.parameterHints == parameterHints) &&
            (identical(other.hover, hover) || other.hover == hover) &&
            (identical(other.contextMenu, contextMenu) ||
                other.contextMenu == contextMenu) &&
            (identical(other.mouseWheelZoom, mouseWheelZoom) ||
                other.mouseWheelZoom == mouseWheelZoom) &&
            (identical(other.roundedSelection, roundedSelection) ||
                other.roundedSelection == roundedSelection) &&
            (identical(other.selectionHighlight, selectionHighlight) ||
                other.selectionHighlight == selectionHighlight) &&
            (identical(other.overviewRulerBorder, overviewRulerBorder) ||
                other.overviewRulerBorder == overviewRulerBorder) &&
            (identical(
                    other.renderControlCharacters, renderControlCharacters) ||
                other.renderControlCharacters == renderControlCharacters) &&
            (identical(other.disableLayerHinting, disableLayerHinting) ||
                other.disableLayerHinting == disableLayerHinting) &&
            (identical(other.disableMonospaceOptimizations,
                    disableMonospaceOptimizations) ||
                other.disableMonospaceOptimizations ==
                    disableMonospaceOptimizations));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        language,
        theme,
        fontSize,
        fontFamily,
        lineHeight,
        wordWrap,
        minimap,
        lineNumbers,
        const DeepCollectionEquality().hash(_rulers),
        tabSize,
        insertSpaces,
        readOnly,
        automaticLayout,
        const DeepCollectionEquality().hash(_padding),
        scrollBeyondLastLine,
        smoothScrolling,
        cursorBlinking,
        cursorStyle,
        renderWhitespace,
        bracketPairColorization,
        autoClosingBrackets,
        autoClosingQuotes,
        formatOnPaste,
        formatOnType,
        quickSuggestions,
        fontLigatures,
        parameterHints,
        hover,
        contextMenu,
        mouseWheelZoom,
        roundedSelection,
        selectionHighlight,
        overviewRulerBorder,
        renderControlCharacters,
        disableLayerHinting,
        disableMonospaceOptimizations
      ]);

  @override
  String toString() {
    return 'EditorOptions(language: $language, theme: $theme, fontSize: $fontSize, fontFamily: $fontFamily, lineHeight: $lineHeight, wordWrap: $wordWrap, minimap: $minimap, lineNumbers: $lineNumbers, rulers: $rulers, tabSize: $tabSize, insertSpaces: $insertSpaces, readOnly: $readOnly, automaticLayout: $automaticLayout, padding: $padding, scrollBeyondLastLine: $scrollBeyondLastLine, smoothScrolling: $smoothScrolling, cursorBlinking: $cursorBlinking, cursorStyle: $cursorStyle, renderWhitespace: $renderWhitespace, bracketPairColorization: $bracketPairColorization, autoClosingBrackets: $autoClosingBrackets, autoClosingQuotes: $autoClosingQuotes, formatOnPaste: $formatOnPaste, formatOnType: $formatOnType, quickSuggestions: $quickSuggestions, fontLigatures: $fontLigatures, parameterHints: $parameterHints, hover: $hover, contextMenu: $contextMenu, mouseWheelZoom: $mouseWheelZoom, roundedSelection: $roundedSelection, selectionHighlight: $selectionHighlight, overviewRulerBorder: $overviewRulerBorder, renderControlCharacters: $renderControlCharacters, disableLayerHinting: $disableLayerHinting, disableMonospaceOptimizations: $disableMonospaceOptimizations)';
  }
}

/// @nodoc
abstract mixin class _$EditorOptionsCopyWith<$Res>
    implements $EditorOptionsCopyWith<$Res> {
  factory _$EditorOptionsCopyWith(
          _EditorOptions value, $Res Function(_EditorOptions) _then) =
      __$EditorOptionsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {MonacoLanguage language,
      MonacoTheme theme,
      double fontSize,
      String fontFamily,
      double lineHeight,
      bool wordWrap,
      bool minimap,
      bool lineNumbers,
      List<int> rulers,
      int tabSize,
      bool insertSpaces,
      bool readOnly,
      bool automaticLayout,
      Map<String, int>? padding,
      bool scrollBeyondLastLine,
      bool smoothScrolling,
      CursorBlinking cursorBlinking,
      CursorStyle cursorStyle,
      RenderWhitespace renderWhitespace,
      bool bracketPairColorization,
      AutoClosingBehavior autoClosingBrackets,
      AutoClosingBehavior autoClosingQuotes,
      bool formatOnPaste,
      bool formatOnType,
      bool quickSuggestions,
      bool fontLigatures,
      bool parameterHints,
      bool hover,
      bool contextMenu,
      bool mouseWheelZoom,
      bool roundedSelection,
      bool selectionHighlight,
      bool overviewRulerBorder,
      bool renderControlCharacters,
      bool disableLayerHinting,
      bool disableMonospaceOptimizations});
}

/// @nodoc
class __$EditorOptionsCopyWithImpl<$Res>
    implements _$EditorOptionsCopyWith<$Res> {
  __$EditorOptionsCopyWithImpl(this._self, this._then);

  final _EditorOptions _self;
  final $Res Function(_EditorOptions) _then;

  /// Create a copy of EditorOptions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? language = null,
    Object? theme = null,
    Object? fontSize = null,
    Object? fontFamily = null,
    Object? lineHeight = null,
    Object? wordWrap = null,
    Object? minimap = null,
    Object? lineNumbers = null,
    Object? rulers = null,
    Object? tabSize = null,
    Object? insertSpaces = null,
    Object? readOnly = null,
    Object? automaticLayout = null,
    Object? padding = freezed,
    Object? scrollBeyondLastLine = null,
    Object? smoothScrolling = null,
    Object? cursorBlinking = null,
    Object? cursorStyle = null,
    Object? renderWhitespace = null,
    Object? bracketPairColorization = null,
    Object? autoClosingBrackets = null,
    Object? autoClosingQuotes = null,
    Object? formatOnPaste = null,
    Object? formatOnType = null,
    Object? quickSuggestions = null,
    Object? fontLigatures = null,
    Object? parameterHints = null,
    Object? hover = null,
    Object? contextMenu = null,
    Object? mouseWheelZoom = null,
    Object? roundedSelection = null,
    Object? selectionHighlight = null,
    Object? overviewRulerBorder = null,
    Object? renderControlCharacters = null,
    Object? disableLayerHinting = null,
    Object? disableMonospaceOptimizations = null,
  }) {
    return _then(_EditorOptions(
      language: null == language
          ? _self.language
          : language // ignore: cast_nullable_to_non_nullable
              as MonacoLanguage,
      theme: null == theme
          ? _self.theme
          : theme // ignore: cast_nullable_to_non_nullable
              as MonacoTheme,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
      fontFamily: null == fontFamily
          ? _self.fontFamily
          : fontFamily // ignore: cast_nullable_to_non_nullable
              as String,
      lineHeight: null == lineHeight
          ? _self.lineHeight
          : lineHeight // ignore: cast_nullable_to_non_nullable
              as double,
      wordWrap: null == wordWrap
          ? _self.wordWrap
          : wordWrap // ignore: cast_nullable_to_non_nullable
              as bool,
      minimap: null == minimap
          ? _self.minimap
          : minimap // ignore: cast_nullable_to_non_nullable
              as bool,
      lineNumbers: null == lineNumbers
          ? _self.lineNumbers
          : lineNumbers // ignore: cast_nullable_to_non_nullable
              as bool,
      rulers: null == rulers
          ? _self._rulers
          : rulers // ignore: cast_nullable_to_non_nullable
              as List<int>,
      tabSize: null == tabSize
          ? _self.tabSize
          : tabSize // ignore: cast_nullable_to_non_nullable
              as int,
      insertSpaces: null == insertSpaces
          ? _self.insertSpaces
          : insertSpaces // ignore: cast_nullable_to_non_nullable
              as bool,
      readOnly: null == readOnly
          ? _self.readOnly
          : readOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      automaticLayout: null == automaticLayout
          ? _self.automaticLayout
          : automaticLayout // ignore: cast_nullable_to_non_nullable
              as bool,
      padding: freezed == padding
          ? _self._padding
          : padding // ignore: cast_nullable_to_non_nullable
              as Map<String, int>?,
      scrollBeyondLastLine: null == scrollBeyondLastLine
          ? _self.scrollBeyondLastLine
          : scrollBeyondLastLine // ignore: cast_nullable_to_non_nullable
              as bool,
      smoothScrolling: null == smoothScrolling
          ? _self.smoothScrolling
          : smoothScrolling // ignore: cast_nullable_to_non_nullable
              as bool,
      cursorBlinking: null == cursorBlinking
          ? _self.cursorBlinking
          : cursorBlinking // ignore: cast_nullable_to_non_nullable
              as CursorBlinking,
      cursorStyle: null == cursorStyle
          ? _self.cursorStyle
          : cursorStyle // ignore: cast_nullable_to_non_nullable
              as CursorStyle,
      renderWhitespace: null == renderWhitespace
          ? _self.renderWhitespace
          : renderWhitespace // ignore: cast_nullable_to_non_nullable
              as RenderWhitespace,
      bracketPairColorization: null == bracketPairColorization
          ? _self.bracketPairColorization
          : bracketPairColorization // ignore: cast_nullable_to_non_nullable
              as bool,
      autoClosingBrackets: null == autoClosingBrackets
          ? _self.autoClosingBrackets
          : autoClosingBrackets // ignore: cast_nullable_to_non_nullable
              as AutoClosingBehavior,
      autoClosingQuotes: null == autoClosingQuotes
          ? _self.autoClosingQuotes
          : autoClosingQuotes // ignore: cast_nullable_to_non_nullable
              as AutoClosingBehavior,
      formatOnPaste: null == formatOnPaste
          ? _self.formatOnPaste
          : formatOnPaste // ignore: cast_nullable_to_non_nullable
              as bool,
      formatOnType: null == formatOnType
          ? _self.formatOnType
          : formatOnType // ignore: cast_nullable_to_non_nullable
              as bool,
      quickSuggestions: null == quickSuggestions
          ? _self.quickSuggestions
          : quickSuggestions // ignore: cast_nullable_to_non_nullable
              as bool,
      fontLigatures: null == fontLigatures
          ? _self.fontLigatures
          : fontLigatures // ignore: cast_nullable_to_non_nullable
              as bool,
      parameterHints: null == parameterHints
          ? _self.parameterHints
          : parameterHints // ignore: cast_nullable_to_non_nullable
              as bool,
      hover: null == hover
          ? _self.hover
          : hover // ignore: cast_nullable_to_non_nullable
              as bool,
      contextMenu: null == contextMenu
          ? _self.contextMenu
          : contextMenu // ignore: cast_nullable_to_non_nullable
              as bool,
      mouseWheelZoom: null == mouseWheelZoom
          ? _self.mouseWheelZoom
          : mouseWheelZoom // ignore: cast_nullable_to_non_nullable
              as bool,
      roundedSelection: null == roundedSelection
          ? _self.roundedSelection
          : roundedSelection // ignore: cast_nullable_to_non_nullable
              as bool,
      selectionHighlight: null == selectionHighlight
          ? _self.selectionHighlight
          : selectionHighlight // ignore: cast_nullable_to_non_nullable
              as bool,
      overviewRulerBorder: null == overviewRulerBorder
          ? _self.overviewRulerBorder
          : overviewRulerBorder // ignore: cast_nullable_to_non_nullable
              as bool,
      renderControlCharacters: null == renderControlCharacters
          ? _self.renderControlCharacters
          : renderControlCharacters // ignore: cast_nullable_to_non_nullable
              as bool,
      disableLayerHinting: null == disableLayerHinting
          ? _self.disableLayerHinting
          : disableLayerHinting // ignore: cast_nullable_to_non_nullable
              as bool,
      disableMonospaceOptimizations: null == disableMonospaceOptimizations
          ? _self.disableMonospaceOptimizations
          : disableMonospaceOptimizations // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
