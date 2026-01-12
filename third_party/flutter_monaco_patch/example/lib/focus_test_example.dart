import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class FocusTestExample extends StatefulWidget {
  const FocusTestExample({super.key});

  @override
  State<FocusTestExample> createState() => _FocusTestExampleState();
}

class _FocusTestExampleState extends State<FocusTestExample> {
  MonacoController? _controller;
  final _textController =
      TextEditingController(text: 'Flutter TextField content');

  @override
  void initState() {
    super.initState();
    _initEditor();
  }

  Future<void> _initEditor() async {
    _controller = await MonacoController.create(
      options: const EditorOptions(
        language: MonacoLanguage.javascript,
        theme: MonacoTheme.vsDark,
        fontSize: 14,
      ),
    );
    await _controller!
        .setValue('// Monaco Editor\nlet message = "Hello World";');
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Test'),
        backgroundColor: Colors.purple,
      ),
      body: Row(
        children: [
          // Left: Monaco Editor
          Expanded(
            child: _controller?.webViewWidget ??
                const Center(child: CircularProgressIndicator()),
          ),
          const VerticalDivider(width: 1),
          // Right: Flutter TextField
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type here...',
                ),
              ),
            ),
          ),
        ],
      ),
      // Dialog button at bottom
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String dialogText = '';
              return AlertDialog(
                title: const Text('Type to Monaco'),
                content: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Type here to send to Monaco...',
                  ),
                  onChanged: (value) => dialogText = value,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      // Send dialog text to Monaco
                      final current = await _controller?.getValue() ?? '';
                      await _controller
                          ?.setValue('$current\n// From dialog: $dialogText');
                    },
                    child: const Text('Send to Monaco'),
                  ),
                ],
              );
            },
          );
        },
        label: const Text('Open Dialog'),
        icon: const Icon(Icons.open_in_new),
      ),
    );
  }
}
