# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2025-11-16
### Changed
- Bundled Monaco Editor updated to **v0.54.0** (latest stable drop from Microsoft). Existing apps automatically pick up the new assets on next launch.

## [1.1.0] - 2025-11-16
### Added
- Full IntelliSense bridge: JavaScript hooks + `MonacoController.registerCompletionSource` / `registerStaticCompletions`.
- Strongly typed completion models (`CompletionItem`, `CompletionList`, `CompletionRequest`, `CompletionItemKind`, `InsertTextRule`).
- README + example updates showing how to source completions from snippets or remote services.

### Fixed
- Export ordering and analyzer fixes to keep the public API clean.

## [1.0.0] - 2025-09-15
- Reliable typing after route/app switches on macOS/Windows — no right‑click needed.
- Optional `MonacoFocusGuard` to auto‑restore focus on resume/route return.
- New guide: doc/focus-and-platform-views.md with best practices and snippets.
- Sensible defaults: word wrap ON, minimap OFF, consistent across APIs.

## [0.1.0] - 2025-08-16

### Initial Release 🎉

#### Features
- **Full Monaco Editor Integration** - Complete VS Code editor experience in Flutter
- **100+ Language Support** - Syntax highlighting for all major programming languages
- **Multiple Themes** - VS Light, VS Dark, High Contrast Black, High Contrast Light
- **Cross-Platform Support** - Works on Android, iOS, macOS, and Windows
- **Type-Safe API** - Comprehensive typed bindings with enums for all configurations
- **Multi-Editor Support** - Run multiple independent editor instances
- **Live Statistics** - Real-time line/character counts and selection information
- **Find & Replace** - Full programmatic find/replace with regex support
- **Decorations & Markers** - Add highlights, errors, warnings to code
- **Event Streams** - Listen to content changes, selection, focus events
- **Versioned Asset Caching** - Efficient one-time asset installation (~30MB)
- **Custom Fonts** - Support for Fira Code, JetBrains Mono, Cascadia Code, and more
- **Editor Actions** - Format, undo, redo, cut, copy, paste, select all
- **Clipboard Operations** - Full clipboard support across platforms
- **Navigation** - Scroll to top/bottom, reveal line, focus management
- **Content Management** - Get/set value, language switching, theme switching
- **Advanced Options** - Word wrap, minimap, line numbers, rulers, bracket colorization

#### Platform Requirements
- **Android**: 5.0+ (API level 21)
- **iOS**: 11.0+
- **macOS**: 10.13+
- **Windows**: 10 version 1809+ with WebView2 Runtime

#### Known Limitations
- Web platform not supported (asset bundling limitations)
- Linux platform not supported (WebKitGTK integration pending)
- Initial startup requires ~1-2 seconds for asset extraction (one-time)
- Each editor instance consumes ~30-100MB memory depending on content

#### Dependencies
- `webview_flutter`: - For mobile and macOS WebView
- `webview_windows`: - For Windows WebView2
- `path_provider`: - For asset caching
- `dart_helper_utils`: - For utility extensions
- `freezed`: - For immutable models

[0.1.0]: https://github.com/omar-hanafy/flutter_monaco/releases/tag/v0.1.0
