import 'dart:io';

import 'package:path/path.dart' as p;

/// Owns app-local files that are not part of the journal database.
class LocalStorageService {
  final String root;

  const LocalStorageService(this.root);

  String pathFor(String filename) => p.join(root, filename);

  Future<bool> hasCompletedOnboarding() =>
      File(pathFor('welcomed')).exists();

  Future<void> completeOnboarding() async {
    await File(pathFor('welcomed')).writeAsString('1');
  }

  Future<int> audioBytes() async {
    var bytes = 0;
    await for (final entity in Directory(root).list()) {
      if (entity is File && entity.path.endsWith('.m4a')) {
        bytes += await entity.length();
      }
    }
    return bytes;
  }

  Future<bool> fileExists(String filename) => File(pathFor(filename)).exists();

  Future<int> fileLength(String filename) => File(pathFor(filename)).length();

  Future<void> deleteFile(String filename) async {
    final file = File(pathFor(filename));
    if (await file.exists()) await file.delete();
  }
}
