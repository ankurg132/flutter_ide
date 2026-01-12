import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ide/widgets/git/git_sidebar.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';
import 'models/file_system_entity.dart';
import 'models/web_tab.dart';
import 'services/file_service.dart';
import 'file_tree.dart';
import 'flutter_sidebar.dart';
import 'output_panel.dart';
import 'pubdev_sidebar.dart';
import 'widgets/editor/activity_bar.dart';
import 'widgets/editor/editor_tabs.dart';
import 'widgets/editor/status_bar.dart';
import 'widgets/editor/welcome_screen.dart';
import 'widgets/editor/quick_open_dialog.dart';
import 'widgets/editor/resize_handles.dart';
import 'widgets/editor/global_search_dialog.dart';
import 'services/search_service.dart';
import 'widgets/editor/search_button.dart';

// Global function to run terminal commands from anywhere
void Function(String command)? _globalRunTerminalCommand;

/// Run a command in the terminal from anywhere in the app
void runTerminalCommand(String command) {
  _globalRunTerminalCommand?.call(command);
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  FileNodeDirectory? _rootNode;
  MonacoController? _editorController;
  final List<FileNodeFile> _openFiles = [];
  FileNodeFile? _activeFile;
  String _currentCode = '// Open a file to start editing\n';
  int _selectedActivityIndex = 0;

  // Web tabs state
  final List<WebTab> _webTabs = [];
  WebTab? _activeWebTab;
  final Map<String, WebViewController> _webViewControllers = {};

  // Output panel state
  bool _isOutputVisible = false;
  double _terminalHeight = 250;

  // Terminal command to run
  String? _pendingCommand;

  // Resizable sidebar width
  double _sidebarWidth = 250;

  // File watchers for detecting external changes
  final Map<String, StreamSubscription<FileSystemEvent>> _fileWatchers = {};

  // Track files we recently saved to avoid reloading from our own changes
  final Set<String> _recentlySavedFiles = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    // Register global terminal command handler
    _globalRunTerminalCommand = _runTerminalCommand;
  }

  WebViewController _getOrCreateWebViewController(String url) {
    if (!_webViewControllers.containsKey(url)) {
      var hasCompletedInitialLoad = false;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              hasCompletedInitialLoad = true;
            },
            onNavigationRequest: (NavigationRequest request) {
              // Allow initial page load and redirects during load
              if (!hasCompletedInitialLoad) {
                return NavigationDecision.navigate;
              }

              // After initial load, open all navigations in new tabs
              _openWebTab(_getTitleFromUrl(request.url), request.url);
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
      _webViewControllers[url] = controller;
    }
    return _webViewControllers[url]!;
  }

  String _getTitleFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Extract a readable title from the URL
      if (uri.host.contains('github.com')) {
        final parts = uri.pathSegments;
        if (parts.length >= 2) {
          return '${parts[0]}/${parts[1]}';
        }
      }
      if (uri.host.contains('pub.dev')) {
        final parts = uri.pathSegments;
        if (parts.isNotEmpty && parts[0] == 'packages' && parts.length >= 2) {
          return parts[1];
        }
      }
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    // Clean up global terminal command handler
    _globalRunTerminalCommand = null;
    // Clean up all file watchers
    for (final subscription in _fileWatchers.values) {
      subscription.cancel();
    }
    _fileWatchers.clear();
    super.dispose();
  }

  void _watchFile(FileNodeFile file) {
    // Cancel existing watcher for this file
    _fileWatchers[file.path]?.cancel();

    try {
      final fileEntity = File(file.path);
      final subscription = fileEntity.watch(events: FileSystemEvent.modify).listen(
        (event) {
          if (event.type == FileSystemEvent.modify) {
            // Skip reload if we recently saved this file ourselves
            if (_recentlySavedFiles.contains(file.path)) {
              return;
            }
            _reloadFileContent(file);
          }
        },
        onError: (error) {
          // File watching failed, ignore silently
        },
      );
      _fileWatchers[file.path] = subscription;
    } catch (e) {
      // File watching not supported or failed
    }
  }

  Future<void> _reloadFileContent(FileNodeFile file) async {
    try {
      final content = await fileService.readFile(file);
      if (content != null && mounted) {
        // Only update if this is the active file
        if (file.path == _activeFile?.path) {
          setState(() {
            _currentCode = content;
          });
          _editorController?.setValue(content);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name} was modified externally and reloaded'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Failed to reload file
    }
  }

  void _stopWatchingFile(String path) {
    _fileWatchers[path]?.cancel();
    _fileWatchers.remove(path);
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    // Cmd/Ctrl+Shift+F: search across files
    if ((isMetaPressed || isControlPressed) && isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyF) {
      _showGlobalSearch();
      return true;
    }

    if (isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyP) {
      _showQuickOpen();
      return true; // Event handled
    }

    if (isMetaPressed && event.logicalKey == LogicalKeyboardKey.keyO) {
      _pickDirectory();
      return true; // Event handled
    }

    return false; // Event not handled
  }

  void _showGlobalSearch() {
    if (_rootNode == null) return;

    final allFiles = _collectAllFiles(_rootNode!);

    showDialog(
      context: context,
      builder: (context) => GlobalSearchDialog(
        root: _rootNode!,
        files: allFiles,
        onMatchSelected: (SearchMatch match) async {
          Navigator.of(context).pop();

          final file = FileNodeFile(match.fileName, match.filePath);
          await _openFile(file);

          // Best-effort jump to match in Monaco (waits for model/value to be ready).
          await _revealMatchInEditor(match);
        },
      ),
    );
  }

  Future<void> _revealMatchInEditor(SearchMatch match) async {
    final controller = _editorController;
    if (controller == null) return;

    // Ensure Monaco reports ready (webview loaded + editor created).
    await controller.onReady;

    final line = match.lineNumber;
    final startCol = match.matchStartColumn;
    final endCol = match.matchStartColumn + match.matchLength;

    // Wait until Monaco model is ready (lineCount > 0). This is the real race on macOS.
    int lineCount = 0;
    for (int i = 0; i < 30; i++) {
      await controller.layout();
      await controller.ensureEditorFocus(attempts: 1);
      lineCount = await controller.getLineCount(defaultValue: 0);
      if (lineCount > 0) break;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    if (lineCount <= 0) return;

    final safeLine = line.clamp(1, lineCount);

    final lineText = await controller.getLineContent(safeLine, defaultValue: '');
    final maxCol = (lineText.length + 1).clamp(1, 1 << 30);
    final safeStart = startCol.clamp(1, maxCol);
    final safeEnd = endCol.clamp(safeStart, maxCol);

    // IMPORTANT: Range in flutter_monaco uses startLine/endLine (not startLineNumber).
    final range = Range(
      startLine: safeLine,
      startColumn: safeStart,
      endLine: safeLine,
      endColumn: safeEnd,
    );

    await controller.setSelection(range);
    await controller.revealRange(range, center: true);
    await controller.ensureEditorFocus(attempts: 3);
  }

  Future<void> _pickDirectory() async {
    final root = await fileService.pickDirectory();
    if (root != null) {
      setState(() {
        _rootNode = root;
      });
    }
  }

  FileNodeDirectory? _selectedDirectory;

  Future<void> _createNewFile() async {
    final targetDir = _selectedDirectory ?? _rootNode;
    if (targetDir == null) return;

    final name = await _showNameDialog('New File', 'Enter file name');
    if (name == null || name.isEmpty) return;

    final newFile = await fileService.createFile(targetDir.path, name);
    if (newFile != null) {
      setState(() {
        targetDir.children.add(newFile);
      });
      await _openFile(newFile);
    }
  }

  Future<void> _createNewFolder() async {
    final targetDir = _selectedDirectory ?? _rootNode;
    if (targetDir == null) return;

    final name = await _showNameDialog('New Folder', 'Enter folder name');
    if (name == null || name.isEmpty) return;

    final newDir = await fileService.createDirectory(targetDir.path, name);
    if (newDir != null) {
      setState(() {
        targetDir.children.add(newDir);
      });
    }
  }

  void _startAutoSave() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;

      if (_activeFile != null && _editorController != null) {
        try {
          final content = await _editorController!.getValue();

          if (content != _currentCode) {
            // Don't save if content became empty but wasn't before (prevents accidental data loss)
            if (content.trim().isEmpty && _currentCode.trim().isNotEmpty) {
              return true; // Continue polling
            }
            _currentCode = content;
            // Mark as recently saved to prevent file watcher from reloading
            final filePath = _activeFile!.path;
            _recentlySavedFiles.add(filePath);
            await fileService.saveFile(_activeFile!, content);
            // Remove from recently saved after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              _recentlySavedFiles.remove(filePath);
            });
          }
        } catch (e) {
          // Auto-save error
        }
      }
      return true;
    });
  }

  void _openWebTab(String title, String url) {
    // Check if tab already exists
    final existingTab = _webTabs.where((t) => t.url == url).firstOrNull;
    if (existingTab != null) {
      setState(() {
        _activeWebTab = existingTab;
        _activeFile = null;
      });
      return;
    }

    final newTab = WebTab(title: title, url: url);
    setState(() {
      _webTabs.add(newTab);
      _activeWebTab = newTab;
      _activeFile = null;
    });
  }

  void _closeWebTab(WebTab tab) {
    setState(() {
      _webTabs.remove(tab);
      _webViewControllers.remove(tab.url);
      if (_activeWebTab == tab) {
        if (_webTabs.isNotEmpty) {
          _activeWebTab = _webTabs.last;
        } else if (_openFiles.isNotEmpty) {
          _activeWebTab = null;
          _activeFile = _openFiles.last;
        } else {
          _activeWebTab = null;
        }
      }
    });
  }

  void _runTerminalCommand(String command) {
    setState(() {
      _isOutputVisible = true;
      _pendingCommand = command;
    });
  }

  void _toggleOutput() {
    setState(() {
      _isOutputVisible = !_isOutputVisible;
    });
  }

  List<FileNodeFile> _collectAllFiles(FileNodeDirectory dir) {
    final files = <FileNodeFile>[];

    void traverse(FileNodeDirectory directory) {
      for (final child in directory.children) {
        if (child is FileNodeFile) {
          files.add(child);
        } else if (child is FileNodeDirectory) {
          traverse(child);
        }
      }
    }

    traverse(dir);
    return files;
  }

  void _showQuickOpen() {
    if (_rootNode == null) return;

    final allFiles = _collectAllFiles(_rootNode!);

    showDialog(
      context: context,
      builder: (context) => QuickOpenDialog(
        files: allFiles,
        rootPath: _rootNode!.path,
        onFileSelected: (file) {
          Navigator.of(context).pop();
          _openFile(file);
        },
      ),
    );
  }

  Future<void> _deleteNode(FileNode node) async {
    final isDirectory = node is FileNodeDirectory;
    final name = node.name;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isDirectory ? 'Folder' : 'File'}'),
        content: Text(
          'Are you sure you want to delete "$name"?${isDirectory ? '\n\nThis will delete all contents.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform deletion
    bool success;
    if (isDirectory) {
      success = await fileService.deleteDirectory(node.path);
    } else {
      success = await fileService.deleteFile(node.path);
    }

    if (success) {
      // Close the file if it was open
      if (node is FileNodeFile) {
        _closeFile(node);
      }

      // Refresh the file tree
      if (_rootNode != null) {
        await fileService.pickDirectory();
        setState(() {
          // The tree will update on next rebuild
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted $name')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete $name')));
      }
    }
  }

  Future<void> _renameNode(FileNode node) async {
    final oldName = node.name;

    // Show rename dialog
    final newName = await _showNameDialog(
      'Rename ${node is FileNodeDirectory ? 'Folder' : 'File'}',
      'New name',
    );

    if (newName == null || newName.isEmpty || newName == oldName) return;

    // Perform rename
    final success = await fileService.rename(node.path, newName);

    if (success) {
      // Update open file if it was renamed
      if (node is FileNodeFile && _activeFile?.path == node.path) {
        final newPath = p.join(p.dirname(node.path), newName);
        setState(() {
          _activeFile = FileNodeFile(newName, newPath);
          // Update in open files list
          final index = _openFiles.indexWhere((f) => f.path == node.path);
          if (index != -1) {
            _openFiles[index] = _activeFile!;
          }
        });
      }

      // Refresh the file tree (ideally we'd update in place)
      if (_rootNode != null) {
        setState(() {
          // Tree will update on rebuild
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Renamed to $newName')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to rename $oldName')));
      }
    }
  }

  Future<String?> _showNameDialog(String title, String label) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(context).pop(controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(FileNodeFile file) async {
    if (!_openFiles.any((f) => f.path == file.path)) {
      setState(() {
        _openFiles.add(file);
      });
      // Start watching this file for external changes
      _watchFile(file);
    }

    // Set active even if already open
    setState(() {
      _activeFile = file;
    });

    try {
      final content = await fileService.readFile(file) ?? '';
      setState(() {
        _currentCode = content;
      });

      _editorController?.setValue(_currentCode);
      try {
        final language = _getLanguage(file.path);
        _editorController?.setLanguage(language);
      } catch (e) {
        // Error setting language
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reading file: $e')));
      }
    }
  }

  void _closeFile(FileNodeFile file) {
    // Stop watching this file
    _stopWatchingFile(file.path);

    setState(() {
      _openFiles.removeWhere((f) => f.path == file.path);
      if (_activeFile?.path == file.path) {
        if (_openFiles.isNotEmpty) {
          _activeFile = _openFiles.last;
          _openFile(_activeFile!); // Load the new active file
        } else {
          _activeFile = null;
          _currentCode = '// Open a file to start editing\n';
          _editorController?.setValue(_currentCode);
        }
      }
    });
  }

  MonacoLanguage _getLanguage(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.dart':
        return MonacoLanguage.dart;
      case '.js':
        return MonacoLanguage.javascript;
      case '.ts':
        return MonacoLanguage.typescript;
      case '.html':
        return MonacoLanguage.html;
      case '.css':
        return MonacoLanguage.css;
      case '.json':
        return MonacoLanguage.json;
      case '.yaml':
      case '.yml':
        return MonacoLanguage.yaml;
      case '.md':
        return MonacoLanguage.markdown;
      case '.sql':
        return MonacoLanguage.sql;
      case '.xml':
        return MonacoLanguage.xml;
      default:
        return MonacoLanguage.dart;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Activity Bar
                _buildActivityBar(),

                // Sidebar with resizable width
                if (_selectedActivityIndex == 0)
                  SizedBox(width: _sidebarWidth, child: _buildSidebar()),
                if (_selectedActivityIndex == 1)
                  SizedBox(
                    width: _sidebarWidth,
                    child: FlutterSidebar(
                      rootNode: _rootNode,
                      onFileSelected: _openFile,
                      onPickDirectory: _pickDirectory,
                    ),
                  ),
                if (_selectedActivityIndex == 2)
                  SizedBox(
                    width: _sidebarWidth + 50, // PubDev sidebar is wider
                    child: PubDevSidebar(
                      onOpenInBrowser: _openWebTab,
                      onRunCommand: _runTerminalCommand,
                    ),
                  ),

                if (_selectedActivityIndex == 3)
                  SizedBox(
                    width: _sidebarWidth + 50,
                    child: GitSidebar(
                      workingDirectory: _rootNode?.path,
                      onRunCommand: _runTerminalCommand,
                    ),
                  ),

                // Horizontal resize handle for sidebar
                HorizontalResizeHandle(
                  onDrag: (delta) {
                    setState(() {
                      _sidebarWidth = (_sidebarWidth + delta).clamp(150.0, 500.0);
                    });
                  },
                ),

                // Main Editor Area
                Expanded(
                  child: Column(
                    children: [
                      // Tab Bar
                      _buildTabBar(),

                      // Breadcrumbs
                      if (_activeFile != null && _activeWebTab == null) _buildBreadcrumbs(),

                      // Editor, WebView, or Welcome Screen
                      Expanded(
                        child: _activeWebTab != null
                            ? _buildWebView()
                            : _activeFile == null
                                ? WelcomeScreen(
                                    rootName: _rootNode?.name,
                                    onPickDirectory: _pickDirectory,
                                    onCreateNewFile: _rootNode != null ? _createNewFile : null,
                                  )
                                : _buildEditor(),
                      ),

                      // Vertical resize handle for terminal
                      if (_isOutputVisible)
                        VerticalResizeHandle(
                          onDrag: (delta) {
                            setState(() {
                              _terminalHeight = (_terminalHeight - delta).clamp(100.0, 500.0);
                            });
                          },
                        ),

                      // Output Panel (Terminal)
                      OutputPanel(
                        isVisible: _isOutputVisible,
                        height: _terminalHeight,
                        workingDirectory: _rootNode?.path,
                        initialCommand: _pendingCommand,
                        onCloseTerminal: () {
                          setState(() {
                            _isOutputVisible = false;
                          });
                        },
                        onCommandExecuted: () {
                          setState(() {
                            _pendingCommand = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Bar
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildActivityBar() {
    final activities = [
      (Icons.insert_drive_file_outlined, 'Explorer'),
      (Icons.explore, 'Flutter explorer'),
      (Icons.inventory_2_outlined, 'Pub.dev Packages'),
      (FontAwesomeIcons.codeBranch, 'Source Control'),
    ];

    return Container(
      width: 48,
      color: const Color(0xFF333333),
      child: Column(
        children: [
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final (icon, tooltip) = entry.value;
            final isSelected = index == _selectedActivityIndex;
            return ActivityBarItem(
              icon: icon,
              tooltip: tooltip,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedActivityIndex = index),
            );
          }),
          const Spacer(),
          ActivityBarItem(
            icon: Icons.terminal,
            tooltip: 'Terminal',
            isSelected: false,
            onTap: () {
              setState(() {
                _isOutputVisible = !_isOutputVisible;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: const Color(0xFF181818),
      child: Column(
        children: [
          // Explorer Header
          if (_rootNode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      SidebarIconButton(
                        icon: Icons.create_new_folder_outlined,
                        tooltip: 'New Folder',
                        onPressed: _createNewFolder,
                      ),
                      const SizedBox(width: 4),
                      SidebarIconButton(
                        icon: Icons.note_add_outlined,
                        tooltip: 'New File',
                        onPressed: _createNewFile,
                      ),
                      const SizedBox(width: 4),
                      SidebarIconButton(
                        icon: Icons.folder_open,
                        tooltip: 'Open Folder',
                        onPressed: _pickDirectory,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Project Header
          if (_rootNode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _rootNode!.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: FileTree(
              rootNode: _rootNode,
              onFileSelected: _openFile,
              onDirectorySelected: (dir) {
                setState(() {
                  _selectedDirectory = dir;
                });
              },
              onPickDirectory: _pickDirectory,
              onDelete: _deleteNode,
              onRename: _renameNode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 35,
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // File tabs
                ..._openFiles.map((file) {
                  final isActive = file.path == _activeFile?.path && _activeWebTab == null;
                  return EditorTab(
                    file: file,
                    isActive: isActive,
                    onTap: () {
                      setState(() {
                        _activeWebTab = null;
                      });
                      _openFile(file);
                    },
                    onClose: () => _closeFile(file),
                    icon: _getFileIcon(file.name),
                  );
                }),
                // Web tabs
                ..._webTabs.map((webTab) {
                  final isActive = webTab == _activeWebTab;
                  return WebEditorTab(
                    webTab: webTab,
                    isActive: isActive,
                    onTap: () {
                      setState(() {
                        _activeWebTab = webTab;
                        _activeFile = null;
                      });
                    },
                    onClose: () => _closeWebTab(webTab),
                  );
                }),
              ],
            ),
          ),

          // Actions
          if (_rootNode != null)
            SearchButton(
              onPressed: _showGlobalSearch,
            ),

          if (_rootNode != null)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
              tooltip: 'Run App (flutter run)',
              onPressed: () => _runTerminalCommand('flutter run'),
              padding: const EdgeInsets.all(8),
            ),

          if (_rootNode != null)
            IconButton(
              icon: Icon(
                _isOutputVisible ? Icons.expand_more : Icons.expand_less,
                color: Colors.white54,
                size: 20,
              ),
              tooltip: _isOutputVisible ? 'Hide Output' : 'Show Output',
              onPressed: _toggleOutput,
              padding: const EdgeInsets.all(8),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final parts = _activeFile!.path.split('/');
    final relevantParts = <String>[];
    bool foundRoot = false;

    for (final part in parts) {
      if (part == _rootNode?.name) foundRoot = true;
      if (foundRoot) relevantParts.add(part);
    }

    return Container(
      height: 22,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          for (int i = 0; i < relevantParts.length; i++) ...[
            if (i > 0)
              const Icon(Icons.chevron_right, size: 14, color: Colors.white30),
            Text(
              relevantParts[i],
              style: TextStyle(
                color: i == relevantParts.length - 1
                    ? Colors.white70
                    : Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Listener(
      onPointerDown: (_) {
        if (HardwareKeyboard.instance.isMetaPressed) {
        }
      },
      child: MonacoEditor(
        loadingBuilder: (context) => Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF42A5F5)),
          ),
        ),
        initialValue: _currentCode,
        options: const EditorOptions(
          language: MonacoLanguage.dart,
          theme: MonacoTheme.vsDark,
          automaticLayout: true,
        ),
        onReady: (controller) {
          _editorController = controller;
          _startAutoSave();
        },
      ),
    );
  }

  Widget _buildWebView() {
    if (_activeWebTab == null) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          // URL bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF252526),
            child: Row(
              children: [
                const Icon(Icons.public, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C3C3C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _activeWebTab!.url,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // WebView content
          Expanded(
            child: WebViewWidget(
              controller: _getOrCreateWebViewController(_activeWebTab!.url),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final language = _activeFile != null
        ? _getLanguage(_activeFile!.path).name
        : 'Plain Text';

    return Container(
      height: 22,
      color: const Color(0xFF007ACC),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const Spacer(),

          // Right side
          StatusBarItem(label: 'Spaces: 2', onPressed: () {}),
          const StatusBarDivider(),
          StatusBarItem(label: 'UTF-8', onPressed: () {}),
          const StatusBarDivider(),
          StatusBarItem(label: language, onPressed: () {}),
        ],
      ),
    );
  }

  Icon _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData icon = Icons.insert_drive_file_outlined;
    Color color = Colors.grey;

    switch (ext) {
      case '.dart':
        icon = FontAwesomeIcons.dartLang;
        color = const Color(0xFF42A5F5);
        break;
      case '.html':
        icon = Icons.html;
        color = const Color(0xFFE65100);
        break;
      case '.css':
        icon = Icons.css;
        color = const Color(0xFF1E88E5);
        break;
      case '.js':
      case '.ts':
        icon = Icons.javascript;
        color = const Color(0xFFFFCA28);
        break;
      case '.json':
        icon = Icons.data_object;
        color = const Color(0xFF66BB6A);
        break;
      default:
      // keep defaults
    }
    return Icon(icon, size: 14, color: color);
  }
}
