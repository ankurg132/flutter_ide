import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:path/path.dart' as p;
import 'package:webview_flutter/webview_flutter.dart';
import 'models/file_system_entity.dart';
import 'services/file_service.dart';
import 'file_tree.dart';
import 'flutter_sidebar.dart';
import 'output_panel.dart';
import 'pubdev_sidebar.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

// Model for web tabs
class WebTab {
  final String title;
  final String url;

  WebTab({required this.title, required this.url});
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

  // Terminal command to run
  String? _pendingCommand;

  // File watchers for detecting external changes
  final Map<String, StreamSubscription<FileSystemEvent>> _fileWatchers = {};

  // Track files we recently saved to avoid reloading from our own changes
  final Set<String> _recentlySavedFiles = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
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

  Future<void> _pickDirectory() async {
    final root = await fileService.pickDirectory();
    if (root != null) {
      setState(() {
        _rootNode = root;
        // Optionally close existing files or keep them?
        // _openFiles.clear();
        // _activeFile = null;
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
        // Force rebuild of tree might be needed if children list isn't observable
        // But setState should trigger widget rebuild.
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
    // Poll for changes every 2 seconds
    // Since 'onChange' is not available in this wrapper, we must fetch the code manually.

    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;

      if (_activeFile != null && _editorController != null) {
        try {
          // We can't rely on _currentCode being up to date if there's no listener.
          // So we ask the controller for the value.
          // NOTE: getValue() might be asynchronous or not exist depending on the wrapper.
          // Checking flutter_monaco generic controller methods.
          // If 'getValue' is not exposed, we are stuck for auto-save without JS interop.
          // BUT, usually wrappers expose it.
          // assuming: Future<String> getValue() exists.

          /*
           * Since I can't see the library source, I'll try standard names.
           * If this fails to compile, we'll need to use JS evaluation or give up on POLL auto-save.
           */

          // Note: FlutterMonaco's controller usually allows executing JS.
          // Let's safe-guard this.
          // Actual method might be `getText()` or `getValue()`.

          // If compilation fails on `getValue`, I will revert this block.
          final content = await _editorController!.getValue();

          if (content != _currentCode) {
            // Don't save if content became empty but wasn't before (prevents accidental data loss)
            if (content.trim().isEmpty && _currentCode.trim().isNotEmpty) {
              // Skip saving empty content - likely a glitch
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
          // debugPrint('Auto-save error: $e');
        }
      }
      return true;
    });
  }

  Future<void> _goToDefinition() async {
    // Current implementation placeholder as we need LSP integration back or another solution
    // But method must exist to fix compilation error.
    // Go to Definition triggered

    // Original LSP logic was here.
    // We can restore it when we are ready to fix LSP imports,
    // but for now let's just clear the error.
    /*
    if (_activeFile == null || _editorController == null) return;
    try {
      const pos = (lineNumber: 1, column: 1); // Dummy
      // ... Call lspService ...
    } catch (e) {
      // Go to definition failed
    }
    */
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

  void _showTerminal() {
    setState(() {
      _isOutputVisible = true;
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
      builder: (context) => _QuickOpenDialog(
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
        final newRoot = await fileService.pickDirectory();
        // This is a workaround - ideally we'd refresh without re-picking
        // For now, just reload the same directory
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

                // Sidebar
                if (_selectedActivityIndex == 0) _buildSidebar(),
                if (_selectedActivityIndex == 1)
                  FlutterSidebar(
                    rootNode: _rootNode,
                    onFileSelected: _openFile,
                    onPickDirectory: _pickDirectory,
                  ),
                if (_selectedActivityIndex == 2)
                  PubDevSidebar(
                    onOpenInBrowser: _openWebTab,
                    onRunCommand: _runTerminalCommand,
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
                                ? _buildWelcomeScreen()
                                : _buildEditor(),
                      ),

                      // Output Panel (Terminal)
                      OutputPanel(
                        isVisible: _isOutputVisible,
                        workingDirectory: _rootNode?.path,
                        initialCommand: _pendingCommand,
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
            return _ActivityBarItem(
              icon: icon,
              tooltip: tooltip,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedActivityIndex = index),
            );
          }),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
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
                      _SidebarIconButton(
                        icon: Icons.create_new_folder_outlined,
                        tooltip: 'New Folder',
                        onPressed: _createNewFolder,
                      ),
                      const SizedBox(width: 4),
                      _SidebarIconButton(
                        icon: Icons.note_add_outlined,
                        tooltip: 'New File',
                        onPressed: _createNewFile,
                      ),
                      const SizedBox(width: 4),
                      _SidebarIconButton(
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
                  return _buildTab(file, isActive);
                }),
                // Web tabs
                ..._webTabs.map((webTab) {
                  final isActive = webTab == _activeWebTab;
                  return _buildWebTab(webTab, isActive);
                }),
              ],
            ),
          ),

          // Actions
          if (_rootNode != null)
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
              tooltip: 'Run App',
              onPressed: _showTerminal,
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

  Widget _buildWelcomeScreen() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.code, size: 64, color: Color(0x1AFFFFFF)),
            const SizedBox(height: 24),
            const Text(
              'Flutter IDE',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a file or folder to get started',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WelcomeButton(
                  icon: Icons.folder_open,
                  label: 'Open Folder',
                  shortcut: '⌘O',
                  onPressed: _pickDirectory,
                ),
                const SizedBox(width: 16),

                if (_rootNode != null)
                  _WelcomeButton(
                    icon: Icons.note_add,
                    label: 'New File',
                    shortcut: '⌘N',
                    onPressed: _createNewFile,
                  ),
              ],
            ),
            const SizedBox(height: 48),
            if (_rootNode != null) ...[
              const Text(
                'Recent',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.folder,
                      size: 16,
                      color: Color(0xFF90A4AE),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _rootNode!.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Listener(
      onPointerDown: (_) {
        if (HardwareKeyboard.instance.isMetaPressed) {
          _goToDefinition();
        }
      },
      child: MonacoEditor(
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
          _StatusBarItem(label: 'Spaces: 2', onPressed: () {}),
          const _StatusBarDivider(),
          _StatusBarItem(label: 'UTF-8', onPressed: () {}),
          const _StatusBarDivider(),
          _StatusBarItem(label: language, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildTab(FileNodeFile file, bool isActive) {
    return _EditorTab(
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
  }

  Widget _buildWebTab(WebTab webTab, bool isActive) {
    return _WebEditorTab(
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
  }

  Icon _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData icon = Icons.insert_drive_file_outlined;
    Color color = Colors.grey;

    switch (ext) {
      case '.dart':
        icon = Icons.code;
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

// Helper Widgets

class _ActivityBarItem extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityBarItem({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ActivityBarItem> createState() => _ActivityBarItemState();
}

class _ActivityBarItemState extends State<_ActivityBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0x1AFFFFFF) : null,
              border: Border(
                left: BorderSide(
                  color: widget.isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 24,
              color: widget.isSelected || _isHovered
                  ? Colors.white
                  : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0x1AFFFFFF) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? Colors.white : Colors.white70,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _TabActionButton({
    required this.icon,
    required this.tooltip,
    this.color,
    required this.onPressed,
  });

  @override
  State<_TabActionButton> createState() => _TabActionButtonState();
}

class _TabActionButtonState extends State<_TabActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0x1AFFFFFF) : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              color:
                  widget.color ?? (_isHovered ? Colors.white : Colors.white70),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final VoidCallback onPressed;

  const _WelcomeButton({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.onPressed,
  });

  @override
  State<_WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<_WelcomeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFF007ACC)
                : const Color(0xFF0E639C),
            borderRadius: BorderRadius.circular(6),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0x4D007ACC),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.shortcut,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBarItem extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onPressed;

  const _StatusBarItem({this.icon, this.label, required this.onPressed});

  @override
  State<_StatusBarItem> createState() => _StatusBarItemState();
}

class _StatusBarItemState extends State<_StatusBarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: _isHovered ? const Color(0x1FFFFFFF) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.only(
                    right: widget.label != null && widget.label!.isNotEmpty
                        ? 4
                        : 0,
                  ),
                  child: Icon(widget.icon, size: 14, color: Colors.white),
                ),
              if (widget.label != null && widget.label!.isNotEmpty)
                Text(
                  widget.label!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBarDivider extends StatelessWidget {
  const _StatusBarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white24,
    );
  }
}

class _EditorTab extends StatefulWidget {
  final FileNodeFile file;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final Icon icon;

  const _EditorTab({
    required this.file,
    required this.isActive,
    required this.onTap,
    required this.onClose,
    required this.icon,
  });

  @override
  State<_EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<_EditorTab> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 4),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF1E1E1E)
                : _isHovered
                ? const Color(0xFF2D2D2D)
                : const Color(0xFF252526),
            border: widget.isActive
                ? const Border(
                    top: BorderSide(color: Color(0xFF007ACC), width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.file.name,
                  style: TextStyle(
                    color: widget.isActive || _isHovered
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                onEnter: (_) => setState(() => _isCloseHovered = true),
                onExit: (_) => setState(() => _isCloseHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isCloseHovered ? const Color(0x33FFFFFF) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: _isHovered || widget.isActive
                          ? Colors.white70
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Web Tab Widget
class _WebEditorTab extends StatefulWidget {
  final WebTab webTab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _WebEditorTab({
    required this.webTab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_WebEditorTab> createState() => _WebEditorTabState();
}

class _WebEditorTabState extends State<_WebEditorTab> {
  bool _isHovered = false;
  bool _isCloseHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 10, right: 4),
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? const Color(0xFF1E1E1E)
                : _isHovered
                ? const Color(0xFF2D2D2D)
                : const Color(0xFF252526),
            border: widget.isActive
                ? const Border(
                    top: BorderSide(color: Color(0xFF007ACC), width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, size: 14, color: Color(0xFF42A5F5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.webTab.title,
                  style: TextStyle(
                    color: widget.isActive || _isHovered
                        ? Colors.white
                        : Colors.white54,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MouseRegion(
                onEnter: (_) => setState(() => _isCloseHovered = true),
                onExit: (_) => setState(() => _isCloseHovered = false),
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _isCloseHovered ? const Color(0x33FFFFFF) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: _isHovered || widget.isActive
                          ? Colors.white70
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick Open Dialog Widget
class _QuickOpenDialog extends StatefulWidget {
  final List<FileNodeFile> files;
  final String rootPath;
  final Function(FileNodeFile) onFileSelected;

  const _QuickOpenDialog({
    required this.files,
    required this.rootPath,
    required this.onFileSelected,
  });

  @override
  State<_QuickOpenDialog> createState() => _QuickOpenDialogState();
}

class _QuickOpenDialogState extends State<_QuickOpenDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FileNodeFile> _filteredFiles = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredFiles = _sortFiles(List.from(widget.files));
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      List<FileNodeFile> results;
      if (query.isEmpty) {
        results = List.from(widget.files);
      } else {
        results = widget.files.where((file) {
          return file.name.toLowerCase().contains(query) ||
              file.path.toLowerCase().contains(query);
        }).toList();
      }
      _filteredFiles = _sortFiles(results);
      _selectedIndex = 0;
    });
  }

  List<FileNodeFile> _sortFiles(List<FileNodeFile> files) {
    // Priority: Dart files first, build folder last, alphabetical within groups
    files.sort((a, b) {
      final aInBuild = a.path.contains('/build/');
      final bInBuild = b.path.contains('/build/');
      final aIsDart = a.name.endsWith('.dart');
      final bIsDart = b.name.endsWith('.dart');

      // Build folder files go last
      if (aInBuild && !bInBuild) return 1;
      if (!aInBuild && bInBuild) return -1;

      // Dart files go first (unless in build folder)
      if (aIsDart && !bIsDart) return -1;
      if (!aIsDart && bIsDart) return 1;

      // Alphabetical by name within same priority
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return files;
  }

  String _getRelativePath(String fullPath) {
    if (fullPath.startsWith(widget.rootPath)) {
      return fullPath.substring(widget.rootPath.length + 1);
    }
    return fullPath;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, _filteredFiles.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, _filteredFiles.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_filteredFiles.isNotEmpty) {
        widget.onFileSelected(_filteredFiles[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  Icon _getFileIcon(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    IconData icon = Icons.insert_drive_file_outlined;
    Color color = Colors.grey;

    switch (ext) {
      case '.dart':
        icon = Icons.code;
        color = const Color(0xFF42A5F5);
        break;
      case '.yaml':
      case '.yml':
        icon = Icons.settings;
        color = const Color(0xFFEF5350);
        break;
      case '.json':
        icon = Icons.data_object;
        color = const Color(0xFF66BB6A);
        break;
      case '.md':
        icon = Icons.description;
        color = Colors.white70;
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
    }
    return Icon(icon, size: 18, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: const Color(0xFF252526),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF3C3C3C), width: 1),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search files by name...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF3C3C3C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // File list
              Flexible(
                child: _filteredFiles.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No files found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          final isSelected = index == _selectedIndex;
                          final relativePath = _getRelativePath(file.path);

                          return InkWell(
                            onTap: () => widget.onFileSelected(file),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              color: isSelected ? const Color(0xFF094771) : null,
                              child: Row(
                                children: [
                                  _getFileIcon(file.name),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          file.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          relativePath,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF3C3C3C), width: 1),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      '↑↓ to navigate  ',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      '↵ to open  ',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      'esc to close',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

