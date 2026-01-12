/// Type-safe enums for Monaco Editor configuration
/// Provides compile-time safety while maintaining backward compatibility
/// Defines the color themes available in the Monaco Editor.
enum MonacoTheme {
  /// The standard light theme.
  vs('vs', 'Light'),

  /// The standard dark theme.
  vsDark('vs-dark', 'Dark'),

  /// A high-contrast dark theme for accessibility.
  hcBlack('hc-black', 'High Contrast Dark'),

  /// A high-contrast light theme for accessibility.
  hcLight('hc-light', 'High Contrast Light');

  const MonacoTheme(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the theme.
  final String label;

  /// Creates a [MonacoTheme] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static MonacoTheme fromId(String? id,
      {MonacoTheme orElse = MonacoTheme.vsDark}) {
    if (id == null) return orElse;
    return MonacoTheme.values.firstWhere(
      (t) => t.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the programming languages supported by the Monaco Editor for syntax
/// highlighting and other language-specific features.
enum MonacoLanguage {
  /// Plain Text
  plaintext('plaintext', 'Plain Text'),

  /// ABAP
  abap('abap', 'ABAP'),

  /// Apex
  apex('apex', 'Apex'),

  /// Azure CLI
  azcli('azcli', 'Azure CLI'),

  /// Batch
  bat('bat', 'Batch'),

  /// Bicep
  bicep('bicep', 'Bicep'),

  /// Cameligo
  cameligo('cameligo', 'Cameligo'),

  /// Clojure
  clojure('clojure', 'Clojure'),

  /// CoffeeScript
  coffeescript('coffeescript', 'CoffeeScript'),

  /// C
  c('c', 'C'),

  /// C++
  cpp('cpp', 'C++'),

  /// C#
  csharp('csharp', 'C#'),

  /// Content Security Policy
  csp('csp', 'CSP'),

  /// CSS
  css('css', 'CSS'),

  /// Cypher
  cypher('cypher', 'Cypher'),

  /// Dart
  dart('dart', 'Dart'),

  /// Dockerfile
  dockerfile('dockerfile', 'Dockerfile'),

  /// ECL
  ecl('ecl', 'ECL'),

  /// Elixir
  elixir('elixir', 'Elixir'),

  /// Flow9
  flow9('flow9', 'Flow9'),

  /// F#
  fsharp('fsharp', 'F#'),

  /// Freemarker2
  freemarker2('freemarker2', 'Freemarker2'),

  /// Go
  go('go', 'Go'),

  /// GraphQL
  graphql('graphql', 'GraphQL'),

  /// Handlebars
  handlebars('handlebars', 'Handlebars'),

  /// HCL
  hcl('hcl', 'HCL'),

  /// HTML
  html('html', 'HTML'),

  /// INI
  ini('ini', 'INI'),

  /// Java
  java('java', 'Java'),

  /// JavaScript
  javascript('javascript', 'JavaScript'),

  /// Julia
  julia('julia', 'Julia'),

  /// Kotlin
  kotlin('kotlin', 'Kotlin'),

  /// Less
  less('less', 'Less'),

  /// Lexon
  lexon('lexon', 'Lexon'),

  /// Lua
  lua('lua', 'Lua'),

  /// Liquid
  liquid('liquid', 'Liquid'),

  /// M3
  m3('m3', 'M3'),

  /// Markdown
  markdown('markdown', 'Markdown'),

  /// MDX
  mdx('mdx', 'MDX'),

  /// MIPS
  mips('mips', 'MIPS'),

  /// MSDAX
  msdax('msdax', 'MSDAX'),

  /// MySQL
  mysql('mysql', 'MySQL'),

  /// Objective-C
  objectiveC('objective-c', 'Objective-C'),

  /// Pascal
  pascal('pascal', 'Pascal'),

  /// Pascaligo
  pascaligo('pascaligo', 'Pascaligo'),

  /// Perl
  perl('perl', 'Perl'),

  /// PostgreSQL
  pgsql('pgsql', 'PostgreSQL'),

  /// PHP
  php('php', 'PHP'),

  /// PLA
  pla('pla', 'PLA'),

  /// Postiats
  postiats('postiats', 'Postiats'),

  /// Power Query
  powerquery('powerquery', 'Power Query'),

  /// PowerShell
  powershell('powershell', 'PowerShell'),

  /// Protocol Buffers
  proto('proto', 'Protocol Buffers'),

  /// Pug
  pug('pug', 'Pug'),

  /// Python
  python('python', 'Python'),

  /// Q#
  qsharp('qsharp', 'Q#'),

  /// R
  r('r', 'R'),

  /// Razor
  razor('razor', 'Razor'),

  /// Redis
  redis('redis', 'Redis'),

  /// Redshift
  redshift('redshift', 'Redshift'),

  /// reStructuredText
  restructuredtext('restructuredtext', 'reStructuredText'),

  /// Ruby
  ruby('ruby', 'Ruby'),

  /// Rust
  rust('rust', 'Rust'),

  /// Small Basic
  sb('sb', 'Small Basic'),

  /// Scala
  scala('scala', 'Scala'),

  /// Scheme
  scheme('scheme', 'Scheme'),

  /// SCSS
  scss('scss', 'SCSS'),

  /// Shell Script
  shell('shell', 'Shell Script'),

  /// Solidity
  sol('sol', 'Solidity'),

  /// AES
  aes('aes', 'AES'),

  /// SPARQL
  sparql('sparql', 'SPARQL'),

  /// SQL
  sql('sql', 'SQL'),

  /// Structured Text
  st('st', 'Structured Text'),

  /// Swift
  swift('swift', 'Swift'),

  /// SystemVerilog
  systemverilog('systemverilog', 'SystemVerilog'),

  /// Verilog
  verilog('verilog', 'Verilog'),

  /// Tcl
  tcl('tcl', 'Tcl'),

  /// Twig
  twig('twig', 'Twig'),

  /// TypeScript
  typescript('typescript', 'TypeScript'),

  /// TypeSpec
  typespec('typespec', 'TypeSpec'),

  /// Visual Basic
  vb('vb', 'Visual Basic'),

  /// WGSL
  wgsl('wgsl', 'WGSL'),

  /// XML
  xml('xml', 'XML'),

  /// YAML
  yaml('yaml', 'YAML'),

  /// JSON
  json('json', 'JSON');

  const MonacoLanguage(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the language.
  final String label;

  /// Creates a [MonacoLanguage] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static MonacoLanguage fromId(String? id,
      {MonacoLanguage orElse = MonacoLanguage.markdown}) {
    if (id == null) return orElse;
    return MonacoLanguage.values.firstWhere(
      (l) => l.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the animation style of the editor's cursor.
enum CursorBlinking {
  /// The cursor blinks smoothly.
  blink('blink', 'Blink'),

  /// The cursor fades in and out.
  smooth('smooth', 'Smooth'),

  /// The cursor changes its opacity.
  phase('phase', 'Phase'),

  /// The cursor expands and contracts.
  expand('expand', 'Expand'),

  /// The cursor is a solid, non-blinking block.
  solid('solid', 'Solid');

  const CursorBlinking(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the cursor style.
  final String label;

  /// Creates a [CursorBlinking] style from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static CursorBlinking fromId(String? id,
      {CursorBlinking orElse = CursorBlinking.blink}) {
    if (id == null) return orElse;
    return CursorBlinking.values.firstWhere(
      (c) => c.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the visual style of the editor's cursor.
enum CursorStyle {
  /// A vertical line.
  line('line', 'Line'),

  /// A solid block.
  block('block', 'Block'),

  /// A horizontal line below the character.
  underline('underline', 'Underline'),

  /// A thin vertical line.
  lineThin('line-thin', 'Line Thin'),

  /// An outlined block.
  blockOutline('block-outline', 'Block Outline'),

  /// A thin horizontal line below the character.
  underlineThin('underline-thin', 'Underline Thin');

  const CursorStyle(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the cursor style.
  final String label;

  /// Creates a [CursorStyle] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static CursorStyle fromId(String? id,
      {CursorStyle orElse = CursorStyle.line}) {
    if (id == null) return orElse;
    return CursorStyle.values.firstWhere(
      (c) => c.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines how whitespace characters are rendered in the editor.
enum RenderWhitespace {
  /// No whitespace is rendered.
  none('none', 'None'),

  /// Whitespace is rendered at the boundary of words.
  boundary('boundary', 'Boundary'),

  /// Whitespace is rendered only in selected text.
  selection('selection', 'Selection'),

  /// Only trailing whitespace is rendered.
  trailing('trailing', 'Trailing'),

  /// All whitespace is rendered.
  all('all', 'All');

  const RenderWhitespace(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the whitespace rendering option.
  final String label;

  /// Creates a [RenderWhitespace] option from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static RenderWhitespace fromId(String? id,
      {RenderWhitespace orElse = RenderWhitespace.selection}) {
    if (id == null) return orElse;
    return RenderWhitespace.values.firstWhere(
      (r) => r.id == id,
      orElse: () => orElse,
    );
  }
}

/// Defines the automatic closing behavior for brackets and quotes.
enum AutoClosingBehavior {
  /// Brackets and quotes are always automatically closed.
  always('always', 'Always'),

  /// Behavior is determined by the language's configuration.
  languageDefined('languageDefined', 'Language Defined'),

  /// Brackets and quotes are closed only when the cursor is before whitespace.
  beforeWhitespace('beforeWhitespace', 'Before Whitespace'),

  /// Brackets and quotes are never automatically closed.
  never('never', 'Never');

  const AutoClosingBehavior(this.id, this.label);

  /// The unique identifier used by the Monaco Editor.
  final String id;

  /// A human-readable label for the behavior.
  final String label;

  /// Creates an [AutoClosingBehavior] from its string [id].
  ///
  /// If the [id] is not found, returns [orElse].
  static AutoClosingBehavior fromId(String? id,
      {AutoClosingBehavior orElse = AutoClosingBehavior.languageDefined}) {
    if (id == null) return orElse;
    return AutoClosingBehavior.values.firstWhere(
      (a) => a.id == id,
      orElse: () => orElse,
    );
  }
}

/// A collection of common font families for the Monaco editor.
///
/// Each enum value represents a CSS `font-family` string with fallbacks.
enum MonacoFont {
  /// A font stack prioritizing "Cascadia Code".
  cascadiaCodePrimary('Cascadia Code, Fira Code, Consolas, monospace'),

  /// A font stack prioritizing "Fira Code".
  firaCodePrimary('Fira Code, Consolas, monospace'),

  /// A font stack for Apple platforms.
  sfMono('SF Mono, Monaco, monospace'),

  /// The "JetBrains Mono" font.
  jetBrainsMono('JetBrains Mono, monospace'),

  /// The "Source Code Pro" font.
  sourceCodePro('Source Code Pro, monospace'),

  /// The "Consolas" font.
  consolas('Consolas, monospace'),

  /// The "Monaco" font.
  monaco('Monaco, monospace'),

  /// The "Menlo" font.
  menlo('Menlo, monospace'),

  /// The "Courier New" font.
  courierNew('Courier New, monospace'),

  /// A generic monospace font.
  monospace('monospace');

  const MonacoFont(this.value);

  /// The CSS `font-family` string.
  final String value;

  /// Returns a list of all available font family strings.
  static List<String> get all => MonacoFont.values.map((f) => f.value).toList();
}
