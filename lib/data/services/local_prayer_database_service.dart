import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Raw SQLite and journal-file access.
///
/// This service deliberately exposes rows rather than domain objects. Mapping
/// remains the repository's responsibility.
class LocalPrayerDatabaseService {
  final Database db;
  final String root;

  LocalPrayerDatabaseService(this.db, this.root);

  static Future<LocalPrayerDatabaseService> open(String root) async {
    final db = await openDatabase(
      p.join(root, 'prayer.db'),
      version: 1,
      onCreate: createSchema,
    );
    return LocalPrayerDatabaseService(db, root);
  }

  static Future<void> createSchema(Database db, int version) async {
    await db.execute(
      'CREATE TABLE sessions (id TEXT PRIMARY KEY, promptId TEXT NOT NULL, '
      'promptText TEXT NOT NULL, localDate TEXT NOT NULL, completedAt TEXT NOT NULL, '
      'duration INTEGER NOT NULL, offsetMinutes INTEGER NOT NULL, spoken INTEGER NOT NULL, audioPath TEXT)',
    );
    await db.execute('CREATE INDEX sessions_date ON sessions(localDate)');
    await db.execute(
      'CREATE TABLE reminders (id INTEGER PRIMARY KEY, hour INTEGER NOT NULL, '
      'minute INTEGER NOT NULL, weekdays TEXT NOT NULL, enabled INTEGER NOT NULL, status TEXT NOT NULL)',
    );
  }

  Future<List<Map<String, Object?>>> sessions() =>
      db.query('sessions', orderBy: 'completedAt DESC');

  Future<void> insertSession(Map<String, Object?> row) async {
    await db.insert(
      'sessions',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Map<String, Object?>?> session(String id) async {
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateAudioPath(String id, String? audioPath) async {
    await db.update(
      'sessions',
      {'audioPath': audioPath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> reminders() =>
      db.query('reminders', orderBy: 'hour, minute');

  Future<void> upsertReminder(Map<String, Object?> row) async {
    await db.insert(
      'reminders',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteReminder(int id) async {
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reset() async {
    for (final file in Directory(root).listSync().whereType<File>()) {
      if (file.path.endsWith('.m4a')) await file.delete();
    }
    final welcome = File(p.join(root, 'welcomed'));
    if (await welcome.exists()) await welcome.delete();
    await db.transaction((txn) async {
      await txn.delete('sessions');
      await txn.delete('reminders');
    });
  }

  Future<void> deleteAudioFile(String filename) async {
    final file = File(p.join(root, filename));
    if (await file.exists()) await file.delete();
  }

  Future<bool> audioExists(String filename) =>
      File(p.join(root, filename)).exists();

  Future<int> audioLength(String filename) =>
      File(p.join(root, filename)).length();

  Future<void> reconcileFiles() async {
    final rows = await db.query('sessions', columns: ['id', 'audioPath']);
    for (final row in rows) {
      final path = row['audioPath'] as String?;
      if (path != null && !await audioExists(path)) {
        await updateAudioPath(row['id'] as String, null);
      }
    }
    final keep = rows.map((r) => r['audioPath']).whereType<String>().toSet();
    for (final file in Directory(root).listSync().whereType<File>()) {
      if (file.path.endsWith('.m4a') && !keep.contains(p.basename(file.path))) {
        await file.delete();
      }
    }
  }

  Future<void> close() => db.close();
}
