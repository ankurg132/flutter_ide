import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'monaco_types.freezed.dart';

/// Represents a position in the editor, using 1-based indexing for lines and
/// columns.
@freezed
sealed class Position with _$Position {
  /// Creates a position with the given 1-based [line] and [column].
  const factory Position({
    /// The 1-based line number.
    required int line,

    /// The 1-based column number.
    required int column,
  }) = _Position;

  const Position._();

  /// Creates a [Position] from a JSON map.
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      line: json.getInt(
        'lineNumber',
        altKeys: ['line', 'ln', 'row'],
        defaultValue: 1,
      ),
      column: json.getInt(
        'column',
        altKeys: ['col', 'character', 'ch'],
        defaultValue: 1,
      ),
    );
  }

  /// Creates a [Position] from 0-based [line] and [column] indices.
  factory Position.fromZeroBased(int line, int column) {
    return Position(line: line + 1, column: column + 1);
  }

  /// The 0-based line number.
  int get lineZeroBased => line - 1;

  /// The 0-based column number.
  int get columnZeroBased => column - 1;

  /// Converts the position to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'lineNumber': line,
        'column': column,
      };
}

/// Represents a range in the editor, defined by a start and end [Position].
///
/// The range is inclusive of the start and end positions.
@freezed
sealed class Range with _$Range {
  /// Creates a range with the given 1-based start and end coordinates.
  const factory Range({
    /// The 1-based line number where the range starts.
    required int startLine,

    /// The 1-based column number where the range starts.
    required int startColumn,

    /// The 1-based line number where the range ends.
    required int endLine,

    /// The 1-based column number where the range ends.
    required int endColumn,
  }) = _Range;

  const Range._();

  /// Creates a [Range] from a start and end [Position].
  factory Range.fromPositions(Position start, Position end) {
    return Range(
      startLine: start.line,
      startColumn: start.column,
      endLine: end.line,
      endColumn: end.column,
    );
  }

  /// Creates a [Range] that covers a single line.
  ///
  /// If [endColumn] is not provided, it defaults to [startColumn], creating a
  /// collapsed range at that position.
  factory Range.singleLine(int line, {int startColumn = 1, int? endColumn}) {
    return Range(
      startLine: line,
      startColumn: startColumn,
      endLine: line,
      endColumn: endColumn ?? startColumn,
    );
  }

  /// Creates a [Range] that covers one or more entire lines, from the beginning
  /// of the [startLine] to the end of the [endLine].
  factory Range.lines(int startLine, int endLine) {
    return Range(
      startLine: startLine,
      startColumn: 1,
      endLine: endLine,
      endColumn: 2147483647, // Max int32, effectively end of line
    );
  }

  /// Creates a [Range] from a JSON map.
  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      startLine: json.getInt(
        'startLineNumber',
        altKeys: ['startLine', 'start_line', 'from_line'],
        defaultValue: 1,
      ),
      startColumn: json.getInt(
        'startColumn',
        altKeys: ['startCol', 'start_column', 'from_column'],
        defaultValue: 1,
      ),
      endLine: json.getInt(
        'endLineNumber',
        altKeys: ['endLine', 'end_line', 'to_line'],
        defaultValue: 1,
      ),
      endColumn: json.getInt(
        'endColumn',
        altKeys: ['endCol', 'end_column', 'to_column'],
        defaultValue: 1,
      ),
    );
  }

  /// Converts the range to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'startLineNumber': startLine,
        'startColumn': startColumn,
        'endLineNumber': endLine,
        'endColumn': endColumn,
      };

  /// The starting position of the range.
  Position get startPosition => Position(line: startLine, column: startColumn);

  /// The ending position of the range.
  Position get endPosition => Position(line: endLine, column: endColumn);

  /// Returns `true` if the range is collapsed (i.e., has zero length).
  bool get isCollapsed => startLine == endLine && startColumn == endColumn;

  /// Checks if the given [position] is inside this range.
  bool containsPosition(Position position) {
    if (position.line < startLine || position.line > endLine) {
      return false;
    }
    if (position.line == startLine && position.column < startColumn) {
      return false;
    }
    if (position.line == endLine && position.column > endColumn) {
      return false;
    }
    return true;
  }

  /// Checks if this range intersects with another [range].
  bool intersects(Range other) {
    return !(endLine < other.startLine ||
        other.endLine < startLine ||
        (endLine == other.startLine && endColumn < other.startColumn) ||
        (other.endLine == startLine && other.endColumn < startColumn));
  }
}

/// Defines the severity levels for markers (diagnostics) in the editor.
enum MarkerSeverity {
  /// A hint, typically rendered with a subtle indicator.
  hint(1),

  /// An informational message.
  info(2),

  /// A warning, typically rendered with a yellow underline.
  warning(4),

  /// An error, typically rendered with a red underline.
  error(8);

  const MarkerSeverity(this.value);

  /// The integer value used by the Monaco Editor.
  final int value;

  /// Creates a [MarkerSeverity] from its integer [value].
  static MarkerSeverity fromValue(int value) {
    return MarkerSeverity.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MarkerSeverity.info,
    );
  }
}

/// Represents a marker, such as a warning or error, displayed in the editor.
@freezed
sealed class MarkerData with _$MarkerData {
  /// Creates a marker with the specified properties.
  const factory MarkerData({
    /// The range in the document where the marker should be displayed.
    required Range range,

    /// The message to display when hovering over the marker.
    required String message,

    /// The severity level of the marker.
    @Default(MarkerSeverity.info) MarkerSeverity severity,

    /// An optional error code.
    String? code,

    /// The source of the marker (e.g., 'linter').
    String? source,

    /// Optional tags, such as `unnecessary` or `deprecated`.
    List<String>? tags,

    /// Optional related information, providing links to other locations.
    List<RelatedInformation>? relatedInformation,
  }) = _MarkerData;

  /// A convenience factory for creating an error marker.
  factory MarkerData.error({
    required Range range,
    required String message,
    String? code,
    String? source,
  }) {
    return MarkerData(
      range: range,
      message: message,
      severity: MarkerSeverity.error,
      code: code,
      source: source,
    );
  }

  /// A convenience factory for creating a warning marker.
  factory MarkerData.warning({
    required Range range,
    required String message,
    String? code,
    String? source,
  }) {
    return MarkerData(
      range: range,
      message: message,
      severity: MarkerSeverity.warning,
      code: code,
      source: source,
    );
  }

  const MarkerData._();

  /// Creates a [MarkerData] object from a JSON map.
  factory MarkerData.fromJson(Map<String, dynamic> json) {
    return MarkerData(
      range: Range.fromJson(json),
      message: json.getString(
        'message',
        altKeys: ['msg', 'text'],
        defaultValue: '',
      ),
      severity: MarkerSeverity.fromValue(
        json.getInt('severity', defaultValue: 2),
      ),
      code: json.tryGetString('code', altKeys: ['errorCode']),
      source: json.tryGetString('source', altKeys: ['src']),
      tags: json.tryGetList<String>('tags'),
      relatedInformation: json
          .tryGetList<Map<String, dynamic>>('relatedInformation')
          ?.map(RelatedInformation.fromJson)
          .toList(),
    );
  }

  /// Converts the marker data to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      ...range.toJson(),
      'message': message,
      'severity': severity.value,
    };

    if (code != null) json['code'] = code;
    if (source != null) json['source'] = source;
    if (tags != null && tags!.isNotEmpty) json['tags'] = tags;
    if (relatedInformation != null && relatedInformation!.isNotEmpty) {
      json['relatedInformation'] =
          relatedInformation!.map((info) => info.toJson()).toList();
    }

    return json;
  }
}

/// Represents related information for a [MarkerData], allowing navigation to
/// other parts of the code.
@freezed
sealed class RelatedInformation with _$RelatedInformation {
  /// Creates a related information object.
  const factory RelatedInformation({
    /// The URI of the resource to link to.
    required Uri resource,

    /// The range within the resource to highlight.
    required Range range,

    /// The message to display for this piece of information.
    required String message,
  }) = _RelatedInformation;

  const RelatedInformation._();

  /// Creates a [RelatedInformation] object from a JSON map.
  factory RelatedInformation.fromJson(Map<String, dynamic> json) {
    return RelatedInformation(
      resource: json.getUri(
        'resource',
        altKeys: ['uri', 'file'],
        defaultValue: Uri.parse('file:///unknown'),
      ),
      range: Range.fromJson(json),
      message: json.getString('message', defaultValue: ''),
    );
  }

  /// Converts the related information to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'resource': resource.toString(),
        ...range.toJson(),
        'message': message,
      };
}

/// Defines options for applying decorations to text in the editor.
@freezed
sealed class DecorationOptions with _$DecorationOptions {
  /// Creates a decoration with a specified [range] and a map of [options].
  const factory DecorationOptions({
    /// The range to which the decoration should be applied.
    required Range range,

    /// A map of Monaco-specific decoration options.
    @Default({}) Map<String, dynamic> options,
  }) = _DecorationOptions;

  /// A convenience factory for creating a decoration with an inline CSS class.
  factory DecorationOptions.inlineClass({
    required Range range,
    required String className,
    String? hoverMessage,
    Map<String, dynamic>? additionalOptions,
  }) {
    return DecorationOptions(
      range: range,
      options: {
        'inlineClassName': className,
        if (hoverMessage != null) 'hoverMessage': hoverMessage,
        ...?additionalOptions,
      },
    );
  }

  /// A convenience factory for creating a decoration in the glyph margin.
  factory DecorationOptions.glyphMargin({
    required Range range,
    required String className,
    String? hoverMessage,
    Map<String, dynamic>? additionalOptions,
  }) {
    return DecorationOptions(
      range: range,
      options: {
        'glyphMarginClassName': className,
        if (hoverMessage != null) 'glyphMarginHoverMessage': hoverMessage,
        ...?additionalOptions,
      },
    );
  }

  /// A convenience factory for applying a CSS class to an entire line.
  factory DecorationOptions.line({
    required Range range,
    required String className,
    bool isWholeLine = true,
    Map<String, dynamic>? additionalOptions,
  }) {
    return DecorationOptions(
      range: range,
      options: {
        'className': className,
        'isWholeLine': isWholeLine,
        ...?additionalOptions,
      },
    );
  }

  const DecorationOptions._();

  /// Creates a [DecorationOptions] object from a JSON map.
  factory DecorationOptions.fromJson(Map<String, dynamic> json) {
    return DecorationOptions(
      range: json.parse('range', Range.fromJson),
      options: json.getMap<String, dynamic>(
        'options',
        defaultValue: {},
      ),
    );
  }

  /// Converts the decoration options to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'range': range.toJson(),
        'options': options,
      };
}

/// Represents a single text edit operation to be applied to the editor.
@freezed
sealed class EditOperation with _$EditOperation {
  /// Creates an edit operation.
  const factory EditOperation({
    /// The range of text to be replaced.
    required Range range,

    /// The new text to insert. An empty string results in a deletion.
    required String text,

    /// If `true`, forces markers to move with the text.
    bool? forceMoveMarkers,
  }) = _EditOperation;

  const EditOperation._();

  /// A convenience factory for creating an insertion operation at a [position].
  factory EditOperation.insert({
    required Position position,
    required String text,
    bool? forceMoveMarkers,
  }) {
    return EditOperation(
      range: Range.fromPositions(position, position),
      text: text,
      forceMoveMarkers: forceMoveMarkers,
    );
  }

  /// A convenience factory for creating a deletion operation over a [range].
  factory EditOperation.delete({
    required Range range,
    bool? forceMoveMarkers,
  }) {
    return EditOperation(
      range: range,
      text: '',
      forceMoveMarkers: forceMoveMarkers,
    );
  }

  /// Creates an [EditOperation] from a JSON map.
  factory EditOperation.fromJson(Map<String, dynamic> json) {
    return EditOperation(
      range: json.parse('range', Range.fromJson),
      text: json.getString(
        'text',
        altKeys: ['newText', 'value'],
        defaultValue: '',
      ),
      forceMoveMarkers: json.tryGetBool('forceMoveMarkers'),
    );
  }

  /// Converts the edit operation to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'range': range.toJson(),
      'text': text,
    };
    if (forceMoveMarkers != null) {
      json['forceMoveMarkers'] = forceMoveMarkers;
    }
    return json;
  }
}

/// Represents a suggestion item for code completion.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionItem with _$CompletionItem {
  /// Creates a completion item.
  const factory CompletionItem({
    /// The label of this completion item.
    required String label,

    /// The text to be inserted into the document. If `null`, [label] is used.
    String? insertText,

    /// The kind of this completion item (e.g., method, function).
    CompletionItemKind? kind,

    /// A human-readable string with additional information about this item.
    String? detail,

    /// A human-readable string that represents a doc-comment.
    String? documentation,

    /// A string that should be used when comparing this item with other items.
    String? sortText,

    /// A string that should be used when filtering a set of completion items.
    String? filterText,

    /// The range of text to be replaced by this completion item.
    Range? range,

    /// Characters that trigger the commit of this completion.
    List<String>? commitCharacters,

    /// Rules that control how the [insertText] is formatted.
    Set<InsertTextRule>? insertTextRules,
  }) = _CompletionItem;

  const CompletionItem._();

  /// Creates a [CompletionItem] from a JSON map.
  factory CompletionItem.fromJson(Map<String, dynamic> json) => CompletionItem(
        label: json.getString('label', defaultValue: ''),
        insertText: json.tryGetString('insertText'),
        kind: CompletionItemKind.maybeFromJsonValue(
          json.tryGetString('kind'),
        ),
        detail: json.tryGetString('detail'),
        documentation: json.tryGetString('documentation'),
        sortText: json.tryGetString('sortText'),
        filterText: json.tryGetString('filterText'),
        range: json.tryParse('range', Range.fromJson),
        commitCharacters: json.tryGetList<String>('commitCharacters'),
        insertTextRules: json
            .tryGetList<String>('insertTextRules')
            ?.map(InsertTextRule.fromJsonValue)
            .toSet(),
      );

  /// Converts the completion item to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'label': label,
        if (insertText != null) 'insertText': insertText,
        if (kind != null) 'kind': kind!.jsonValue,
        if (detail != null) 'detail': detail,
        if (documentation != null) 'documentation': documentation,
        if (sortText != null) 'sortText': sortText,
        if (filterText != null) 'filterText': filterText,
        if (range != null) 'range': range!.toJson(),
        if (commitCharacters != null) 'commitCharacters': commitCharacters,
        if (insertTextRules != null && insertTextRules!.isNotEmpty)
          'insertTextRules':
              insertTextRules!.map((rule) => rule.jsonValue).toList(),
      };
}

/// A list of completion items to be returned to the editor.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionList with _$CompletionList {
  /// Creates a completion list.
  const factory CompletionList({
    /// The list of completion suggestions.
    required List<CompletionItem> suggestions,

    /// If `true`, indicates that this is not the full list of suggestions.
    @Default(false) bool isIncomplete,
  }) = _CompletionList;

  const CompletionList._();

  /// Creates a [CompletionList] from a JSON map.
  factory CompletionList.fromJson(Map<String, dynamic> json) => CompletionList(
        suggestions: json
            .getList<Map<String, dynamic>>('suggestions', defaultValue: [])
            .map(CompletionItem.fromJson)
            .toList(),
        isIncomplete: json.getBool('isIncomplete', defaultValue: false),
      );

  /// Converts the completion list to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'suggestions': suggestions.map((item) => item.toJson()).toList(),
        'isIncomplete': isIncomplete,
      };
}

/// Represents a request for completion items from the editor.
@Freezed(fromJson: false, toJson: false)
sealed class CompletionRequest with _$CompletionRequest {
  /// Creates a completion request.
  const factory CompletionRequest({
    /// The unique ID of the completion provider that was invoked.
    required String providerId,

    /// A unique ID for this specific request.
    required String requestId,

    /// The language ID of the document.
    required String language,

    /// The URI of the document.
    Uri? uri,

    /// The position in the document where the request was triggered.
    required Position position,

    /// The default range to be replaced by a completion item.
    required Range defaultRange,

    /// The text of the line where the request was triggered.
    String? lineText,

    /// The kind of trigger that initiated the completion request.
    int? triggerKind,

    /// The character that triggered the completion request.
    String? triggerCharacter,
  }) = _CompletionRequest;

  const CompletionRequest._();

  /// Creates a [CompletionRequest] from a JSON map.
  factory CompletionRequest.fromJson(Map<String, dynamic> json) =>
      CompletionRequest(
        providerId: json.getString('providerId', defaultValue: ''),
        requestId: json.getString('requestId', defaultValue: ''),
        language: json.getString('language', defaultValue: 'plaintext'),
        uri: json.tryGetUri('uri'),
        position: Position.fromJson(
          json.getMap('position', defaultValue: const <String, dynamic>{}),
        ),
        defaultRange: Range.fromJson(
          json.getMap('defaultRange', defaultValue: const <String, dynamic>{}),
        ),
        lineText: json.tryGetString('lineText'),
        triggerKind: json.tryGetInt('triggerKind'),
        triggerCharacter: json.tryGetString('triggerCharacter'),
      );

  /// Converts the completion request to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'requestId': requestId,
        'language': language,
        if (uri != null) 'uri': uri.toString(),
        'position': position.toJson(),
        'defaultRange': defaultRange.toJson(),
        if (lineText != null) 'lineText': lineText,
        if (triggerKind != null) 'triggerKind': triggerKind,
        if (triggerCharacter != null) 'triggerCharacter': triggerCharacter,
      };
}

/// Defines the kind of a [CompletionItem] for icon and sorting purposes.
enum CompletionItemKind {
  /// A text completion.
  text('Text'),

  /// A method completion.
  method('Method'),

  /// A function completion.
  functionType('Function'),

  /// A constructor completion.
  constructor('Constructor'),

  /// A field completion.
  field('Field'),

  /// A variable completion.
  variable('Variable'),

  /// A class completion.
  classType('Class'),

  /// An interface completion.
  interfaceType('Interface'),

  /// A module completion.
  module('Module'),

  /// A property completion.
  property('Property'),

  /// A unit completion.
  unit('Unit'),

  /// A value completion.
  value('Value'),

  /// An enum completion.
  enumType('Enum'),

  /// A keyword completion.
  keyword('Keyword'),

  /// A snippet completion.
  snippet('Snippet'),

  /// A color completion.
  color('Color'),

  /// A file completion.
  file('File'),

  /// A reference completion.
  reference('Reference'),

  /// A folder completion.
  folder('Folder'),

  /// An enum member completion.
  enumMember('EnumMember'),

  /// A constant completion.
  constant('Constant'),

  /// A struct completion.
  struct('Struct'),

  /// An event completion.
  event('Event'),

  /// An operator completion.
  operatorType('Operator'),

  /// A type parameter completion.
  typeParameter('TypeParameter');

  const CompletionItemKind(this.jsonValue);

  /// The string value used in JSON serialization.
  final String jsonValue;

  /// Creates a [CompletionItemKind] from its JSON string value.
  static CompletionItemKind fromJsonValue(String value) {
    return maybeFromJsonValue(value) ?? CompletionItemKind.text;
  }

  /// Tries to create a [CompletionItemKind] from its JSON string value.
  ///
  /// Returns `null` if the value is not recognized.
  static CompletionItemKind? maybeFromJsonValue(String? value) {
    if (value == null) return null;
    for (final kind in CompletionItemKind.values) {
      if (kind.jsonValue == value) return kind;
    }
    return null;
  }
}

/// Defines rules for how the `insertText` of a [CompletionItem] is handled.
enum InsertTextRule {
  /// The editor should keep the whitespace of the replaced range.
  keepWhitespace('KeepWhitespace'),

  /// The `insertText` is a snippet and should be parsed accordingly.
  insertAsSnippet('InsertAsSnippet');

  const InsertTextRule(this.jsonValue);

  /// The string value used in JSON serialization.
  final String jsonValue;

  /// Creates an [InsertTextRule] from its JSON string value.
  static InsertTextRule fromJsonValue(String value) {
    return InsertTextRule.values.firstWhere(
      (rule) => rule.jsonValue == value,
      orElse: () => InsertTextRule.insertAsSnippet,
    );
  }
}

/// Defines options for programmatic find operations.
@freezed
sealed class FindOptions with _$FindOptions {
  /// Creates find options.
  const factory FindOptions({
    /// If `true`, treats the search query as a regular expression.
    @Default(false) bool isRegex,

    /// If `true`, performs a case-sensitive search.
    @Default(false) bool matchCase,

    /// If `true`, only matches whole words.
    @Default(false) bool wholeWord,

    /// If `true`, searches only within the editable range of the document.
    bool? searchOnlyEditableRange,

    /// The maximum number of matches to find.
    int? limitResultCount,
  }) = _FindOptions;

  /// A convenience factory for creating case-sensitive find options.
  factory FindOptions.caseSensitive({
    bool isRegex = false,
    bool wholeWord = false,
  }) {
    return FindOptions(
      isRegex: isRegex,
      matchCase: true,
      wholeWord: wholeWord,
    );
  }

  /// A convenience factory for creating regular expression find options.
  factory FindOptions.regex({
    bool matchCase = false,
  }) {
    return FindOptions(
      isRegex: true,
      matchCase: matchCase,
      wholeWord: false,
    );
  }

  const FindOptions._();

  /// Creates [FindOptions] from a JSON map.
  factory FindOptions.fromJson(Map<String, dynamic> json) {
    return FindOptions(
      isRegex: json.getBool(
        'isRegex',
        altKeys: ['regex', 'useRegex'],
        defaultValue: false,
      ),
      matchCase: json.getBool(
        'matchCase',
        altKeys: ['caseSensitive'],
        defaultValue: false,
      ),
      wholeWord: json.getBool(
        'wholeWord',
        altKeys: ['word'],
        defaultValue: false,
      ),
      searchOnlyEditableRange: json.tryGetBool('searchOnlyEditableRange'),
      limitResultCount: json.tryGetInt(
        'limitResultCount',
        altKeys: ['limit', 'maxResults'],
      ),
    );
  }

  /// Converts the find options to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'isRegex': isRegex,
      'matchCase': matchCase,
      'wholeWord': wholeWord,
    };
    if (searchOnlyEditableRange != null) {
      json['searchOnlyEditableRange'] = searchOnlyEditableRange;
    }
    if (limitResultCount != null) {
      json['limitResultCount'] = limitResultCount;
    }
    return json;
  }
}

/// A snapshot of live statistics from the editor.
@freezed
sealed class LiveStats with _$LiveStats {
  /// Creates a live statistics object.
  const factory LiveStats({
    /// The total number of lines in the document.
    required ({int value, String label}) lineCount,

    /// The total number of characters in the document.
    required ({int value, String label}) charCount,

    /// The number of lines in the current selection.
    required ({int value, String label}) selectedLines,

    /// The number of characters in the current selection.
    required ({int value, String label}) selectedCharacters,

    /// The number of active cursors/selections.
    required ({int value, String label}) caretCount,

    /// The current cursor position, formatted as "line:column".
    ({int value, String label})? cursorPosition,

    /// The language ID of the current document.
    String? language,
  }) = _LiveStats;

  const LiveStats._();

  /// Creates a [LiveStats] object with default zero values.
  factory LiveStats.defaults() {
    return const LiveStats(
      lineCount: (value: 0, label: 'Ln'),
      charCount: (value: 0, label: 'Ch'),
      selectedLines: (value: 0, label: 'Sel Ln'),
      selectedCharacters: (value: 0, label: 'Sel Ch'),
      caretCount: (value: 1, label: 'Cursors'),
    );
  }

  /// Creates a [LiveStats] object from a JSON map.
  factory LiveStats.fromJson(Map<String, dynamic> json) {
    return LiveStats(
      lineCount: (
        value: json.getInt(
          'lineCount',
          altKeys: ['lines', 'totalLines', 'linesCount'],
          defaultValue: 0,
        ),
        label: 'Ln',
      ),
      charCount: (
        value: json.getInt(
          'charCount',
          altKeys: ['chars', 'characters', 'totalChars'],
          defaultValue: 0,
        ),
        label: 'Ch',
      ),
      selectedLines: (
        value: json.getInt(
          'selLines',
          altKeys: ['selectedLines', 'selectionLines'],
          defaultValue: 0,
        ),
        label: 'Sel Ln',
      ),
      selectedCharacters: (
        value: json.getInt(
          'selChars',
          altKeys: ['selectedChars', 'selectionLength', 'selectedCharacters'],
          defaultValue: 0,
        ),
        label: 'Sel Ch',
      ),
      caretCount: (
        value: json.getInt(
          'caretCount',
          altKeys: ['cursors', 'cursorCount', 'carets'],
          defaultValue: 1,
        ),
        label: 'Cursors',
      ),
      cursorPosition: _extractCursorPosition(json),
      language: json.tryGetString(
        'language',
        altKeys: ['lang', 'mode', 'languageId'],
      ),
    );
  }

  static ({int value, String label})? _extractCursorPosition(
      Map<String, dynamic> json) {
    final line = json.tryGetInt(
      'cursorLine',
      altKeys: ['line', 'currentLine'],
    );
    final column = json.tryGetInt(
      'cursorColumn',
      altKeys: ['column', 'col', 'currentColumn'],
    );

    if (line != null && column != null) {
      return (value: line * 1000 + column, label: '$line:$column');
    }
    return null;
  }

  /// Returns `true` if there is an active selection.
  bool get hasSelection => selectedCharacters.value > 0;

  /// Returns `true` if there are multiple cursors.
  bool get hasMultipleCursors => caretCount.value > 1;

  /// Returns all statistics as a list of labeled values, suitable for UI iteration.
  List<({int value, String label})> get allStats => [
        lineCount,
        charCount,
        selectedLines,
        selectedCharacters,
        caretCount,
        if (cursorPosition != null) cursorPosition!,
      ];

  /// Converts the live stats to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'lineCount': lineCount.value,
        'charCount': charCount.value,
        'selLines': selectedLines.value,
        'selChars': selectedCharacters.value,
        'caretCount': caretCount.value,
        if (cursorPosition != null) 'cursorPosition': cursorPosition!.label,
        if (language != null) 'language': language,
      };
}

/// A snapshot of the editor's complete state.
@freezed
sealed class EditorState with _$EditorState {
  /// Creates an editor state snapshot.
  const factory EditorState({
    /// The full text content of the editor.
    required String content,

    /// The current selection range.
    Range? selection,

    /// The primary cursor position.
    Position? cursorPosition,

    /// The total number of lines in the document.
    required int lineCount,

    /// `true` if the content has been modified since the last save.
    required bool hasUnsavedChanges,

    /// The language ID of the document.
    String? language,

    /// The theme ID currently applied to the editor.
    String? theme,

    /// A snapshot of live statistics.
    LiveStats? stats,
  }) = _EditorState;

  const EditorState._();

  /// Creates an [EditorState] from a JSON map.
  factory EditorState.fromJson(Map<String, dynamic> json) {
    return EditorState(
      content: json.getString(
        'content',
        altKeys: ['text', 'value'],
        defaultValue: '',
      ),
      selection: json.tryParse('selection', Range.fromJson),
      cursorPosition: json.tryParse('cursorPosition', Position.fromJson),
      lineCount: json.getInt(
        'lineCount',
        altKeys: ['lines', 'totalLines'],
        defaultValue: 0,
      ),
      hasUnsavedChanges: json.getBool(
        'hasUnsavedChanges',
        altKeys: ['dirty', 'modified', 'isDirty'],
        defaultValue: false,
      ),
      language: json.tryGetString(
        'language',
        altKeys: ['lang', 'mode', 'languageId'],
      ),
      theme: json.tryGetString('theme', altKeys: ['themeName']),
      stats: json.tryParse('stats', LiveStats.fromJson),
    );
  }

  /// Converts the editor state to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'content': content,
        if (selection != null) 'selection': selection!.toJson(),
        if (cursorPosition != null) 'cursorPosition': cursorPosition!.toJson(),
        'lineCount': lineCount,
        'hasUnsavedChanges': hasUnsavedChanges,
        if (language != null) 'language': language,
        if (theme != null) 'theme': theme,
        if (stats != null) 'stats': stats!.toJson(),
      };

  /// Returns `true` if the editor content is empty.
  bool get isEmpty => content.isEmpty;

  /// Returns an approximate word count.
  int get wordCount =>
      content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
}

/// Represents a single match found during a find operation.
@freezed
sealed class FindMatch with _$FindMatch {
  /// Creates a find match result.
  const factory FindMatch({
    /// The range of the matched text.
    required Range range,

    /// The text that was matched.
    String? match,
  }) = _FindMatch;

  const FindMatch._();

  /// Creates a [FindMatch] from a JSON map.
  factory FindMatch.fromJson(Map<String, dynamic> json) {
    return FindMatch(
      range: json.parse('range', Range.fromJson),
      match: json.tryGetString('match', altKeys: ['text', 'value']),
    );
  }

  /// Converts the find match to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'range': range.toJson(),
        if (match != null) 'match': match,
      };
}
