import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonacoLanguage', () {
    test('fromId should return correct language enum', () {
      expect(MonacoLanguage.fromId('javascript'), MonacoLanguage.javascript);
      expect(MonacoLanguage.fromId('typescript'), MonacoLanguage.typescript);
      expect(MonacoLanguage.fromId('dart'), MonacoLanguage.dart);
      expect(MonacoLanguage.fromId('python'), MonacoLanguage.python);
    });

    test('fromId should return plaintext for unknown language', () {
      expect(MonacoLanguage.fromId('unknown-lang'), MonacoLanguage.plaintext);
    });

    test('language id should match enum name', () {
      expect(MonacoLanguage.javascript.id, 'javascript');
      expect(MonacoLanguage.python.id, 'python');
      expect(MonacoLanguage.dart.id, 'dart');
    });
  });

  group('MonacoTheme', () {
    test('fromId should return correct theme enum', () {
      expect(MonacoTheme.fromId('vs'), MonacoTheme.vs);
      expect(MonacoTheme.fromId('vs-dark'), MonacoTheme.vsDark);
      expect(MonacoTheme.fromId('hc-black'), MonacoTheme.hcBlack);
      expect(MonacoTheme.fromId('hc-light'), MonacoTheme.hcLight);
    });

    test('fromId should return vs for unknown theme', () {
      expect(MonacoTheme.fromId('unknown-theme'), MonacoTheme.vs);
    });

    test('theme id should match expected values', () {
      expect(MonacoTheme.vs.id, 'vs');
      expect(MonacoTheme.vsDark.id, 'vs-dark');
      expect(MonacoTheme.hcBlack.id, 'hc-black');
      expect(MonacoTheme.hcLight.id, 'hc-light');
    });
  });

  group('EditorOptions', () {
    test('should create with default values', () {
      const options = EditorOptions();
      expect(options.fontSize, 14);
      expect(options.tabSize, 4);
      expect(options.wordWrap, true);
      expect(options.minimap, false);
      expect(options.lineNumbers, true);
    });

    test('should create with custom values', () {
      const options = EditorOptions(
        language: MonacoLanguage.python,
        theme: MonacoTheme.vsDark,
        fontSize: 16,
        tabSize: 2,
        wordWrap: true,
        minimap: false,
      );
      expect(options.language, MonacoLanguage.python);
      expect(options.theme, MonacoTheme.vsDark);
      expect(options.fontSize, 16);
      expect(options.tabSize, 2);
      expect(options.wordWrap, true);
      expect(options.minimap, false);
    });
  });
}
