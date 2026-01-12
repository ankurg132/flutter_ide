import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// Example demonstrating custom font usage with flutter_monaco
class CustomFontExample extends StatefulWidget {
  const CustomFontExample({super.key});

  @override
  State<CustomFontExample> createState() => _CustomFontExampleState();
}

class _CustomFontExampleState extends State<CustomFontExample> {
  MonacoController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    try {
      // Example 1: Using system fonts with ligatures
      _controller = await MonacoController.create(
        options: const EditorOptions(
          fontSize: 16,
          fontFamily: 'Fira Code, JetBrains Mono, Cascadia Code, monospace',
          fontLigatures: true,
          // Enable ligatures for programming fonts
          theme: MonacoTheme.vsDark,
          language: MonacoLanguage.javascript,
        ),
      );

      // Set sample code that demonstrates ligatures
      await _controller!.setValue('''
// Font Ligatures Demo
// If you have Fira Code or similar font installed,
// you should see ligatures for these operators:

const arrow = () => console.log("Arrow function");
const notEqual = value !== undefined;
const lessOrEqual = count <= 100;
const greaterOrEqual = index >= 0;
const equality = a === b;
const spread = {...object};

// Mathematical operators
const sum = a + b;
const difference = a - b;
const product = a * b;
const division = a / b;

// Logical operators
const and = true && false;
const or = true || false;
const not = !value;

// Comments with special characters
// TODO: This is a todo item
// FIXME: This needs fixing
// NOTE: Important note here
''');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWithCdnFont() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Dispose previous controller
      _controller?.dispose();

      // Example 2: Using Google Fonts CDN
      _controller = await MonacoController.create(
        options: const EditorOptions(
          fontSize: 16,
          fontFamily: 'Fira Code, monospace',
          fontLigatures: true,
          theme: MonacoTheme.vsDark,
          language: MonacoLanguage.javascript,
        ),
        customCss: '''
          @import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&display=swap');
        ''',
        allowCdnFonts: true, // Must be true to allow CDN fonts
      );

      await _controller!.setValue('''
// Using Fira Code from Google Fonts
// This demonstrates loading fonts from CDN

const features = {
  ligatures: "=>", "!==", "<=", ">=", "===",
  customFont: "Fira Code from Google Fonts",
  cdnEnabled: true
};
''');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWithBase64Font() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Dispose previous controller
      _controller?.dispose();

      // Example 3: Using base64 embedded font (mock example)
      // In a real app, you would load your font file and convert to base64
      const mockBase64Font = ''; // Your base64 font data here

      _controller = await MonacoController.create(
        options: const EditorOptions(
          fontSize: 16,
          fontFamily: 'MyCustomFont, monospace',
          fontLigatures: true,
          theme: MonacoTheme.vsDark,
          language: MonacoLanguage.javascript,
        ),
        customCss: '''
          @font-face {
            font-family: 'MyCustomFont';
            src: url('data:font/woff2;base64,$mockBase64Font') format('woff2');
            font-weight: normal;
            font-style: normal;
          }
          
          /* Additional custom styles */
          .monaco-editor .line-numbers {
            color: #858585 !important;
          }
        ''',
        // No need for allowCdnFonts when using base64
      );

      await _controller!.setValue('''
// Using embedded base64 font
// This is the most secure way to use custom fonts
// as it doesn't require external resources

function secureCustomFont() {
  return {
    method: "base64 embedded",
    security: "high",
    offline: true
  };
}
''');

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Font Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.font_download),
            onPressed: _loadWithCdnFont,
            tooltip: 'Load with CDN Font',
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _loadWithBase64Font,
            tooltip: 'Load with Embedded Font',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeEditor,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.blue.shade100,
                      child: const Text(
                        'Tip: Install Fira Code or JetBrains Mono font on your system to see ligatures!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: _controller?.webViewWidget ??
                          const Center(child: Text('No editor')),
                    ),
                  ],
                ),
    );
  }
}
