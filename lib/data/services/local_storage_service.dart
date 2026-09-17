import 'dart:io';

import 'package:path/path.dart' as p;

/// Owns app-local files that are not part of the journal database.
class LocalStorageService {
  final String root;

  const LocalStorageService(this.root);

  String pathFor(String filename) => p.join(root, filename);

  Future<bool> hasCompletedOnboarding() => File(pathFor('welcomed')).exists();

  Future<void> completeOnboarding() async {
    await File(pathFor('welcomed')).writeAsString('1');
  }

  Future<String?> readLanguageCode() async {
    try {
      final file = File(pathFor('language'));
      if (await file.exists()) {
        final code = (await file.readAsString()).trim();
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}
    return null;
  }

  String? readLanguageCodeSync() {
    try {
      final file = File(pathFor('language'));
      if (file.existsSync()) {
        final code = file.readAsStringSync().trim();
        if (code.isNotEmpty) return code;
      }
    } catch (_) {}
    return null;
  }

  Future<void> writeLanguageCode(String languageCode) async {
    final file = File(pathFor('language'));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(languageCode.trim());
  }

  void writeLanguageCodeSync(String languageCode) {
    final file = File(pathFor('language'));
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    file.writeAsStringSync(languageCode.trim());
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
