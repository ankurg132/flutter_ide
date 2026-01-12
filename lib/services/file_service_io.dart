import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/file_system_entity.dart';
import 'file_service_interface.dart';

class FileServiceImpl implements FileService {
  @override
  Future<FileNodeDirectory?> pickDirectory() async {
    final String? selectedDirectory = await FilePicker.platform
        .getDirectoryPath();
    if (selectedDirectory == null) return null;

    final dir = Directory(selectedDirectory);
    return _buildDirectoryNode(dir);
  }

  FileNodeDirectory _buildDirectoryNode(Directory dir) {
    List<FileNode> children = [];
    try {
      final entities = dir.listSync();

      // Sort: Directories first, then files
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });

      for (var entity in entities) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue; // Skip hidden

        if (entity is Directory) {
          children.add(_buildDirectoryNode(entity));
        } else if (entity is File) {
          children.add(FileNodeFile(name, entity.path));
        }
      }
    } catch (e) {
      // Error listing directory
    }

    return FileNodeDirectory(
      p.basename(dir.path),
      dir.path,
      children: children,
    );
  }

  @override
  Future<String?> readFile(FileNodeFile file) async {
    try {
      // Try fast path.
      return await File(file.path).readAsString();
    } on FileSystemException {
      // Likely binary/non-UTF8 file (e.g. png). Skip for text searches.
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FileNodeFile?> createFile(String parentPath, String name) async {
    try {
      final file = File(p.join(parentPath, name));
      if (await file.exists()) return null;
      await file.create();
      return FileNodeFile(name, file.path);
    } catch (e) {
      // Error creating file
      return null;
    }
  }

  @override
  Future<FileNodeDirectory?> createDirectory(
    String parentPath,
    String name,
  ) async {
    try {
      final dir = Directory(p.join(parentPath, name));
      if (await dir.exists()) return null;
      await dir.create();
      return FileNodeDirectory(name, dir.path, children: []);
    } catch (e) {
      // Error creating directory
      return null;
    }
  }

  @override
  Future<void> saveFile(FileNodeFile file, String content) async {
    try {
      final f = File(file.path);
      await f.writeAsString(content);
    } catch (e) {
      // Error saving file
    }
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      // Error deleting file
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      // Error deleting directory
      return false;
    }
  }

  @override
  Future<bool> rename(String oldPath, String newName) async {
    try {
      final entity = FileSystemEntity.typeSync(oldPath);

      if (entity == FileSystemEntityType.file) {
        final file = File(oldPath);
        final newPath = p.join(p.dirname(oldPath), newName);
        await file.rename(newPath);
        return true;
      } else if (entity == FileSystemEntityType.directory) {
        final dir = Directory(oldPath);
        final newPath = p.join(p.dirname(oldPath), newName);
        await dir.rename(newPath);
        return true;
      }
      return false;
    } catch (e) {
      // Error renaming
      return false;
    }
  }
}
