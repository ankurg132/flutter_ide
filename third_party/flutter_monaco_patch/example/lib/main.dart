import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() {
  runApp(
    MaterialApp(
      showSemanticsDebugger: false,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Monaco',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monaco Editor'),
        ),
        body: const SafeArea(
          child: MonacoEditor(
            showStatusBar: true,
          ),
        ),
      ),
    ),
  );
}
