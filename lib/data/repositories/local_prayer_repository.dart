import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/services/local_safe_call.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../mappers/reminder_mapper.dart';
import '../models/session_mapper.dart';
import '../services/local_prayer_database_service.dart';

class LocalPrayerRepository implements PrayerRepository {
  final LocalPrayerDatabaseService _service;

  /// Compatibility constructor for existing database tests and callers.
  LocalPrayerRepository(Database db, String root)
    : _service = LocalPrayerDatabaseService(db, root);

  LocalPrayerRepository.fromService(this._service);

  Database get db => _service.db;
  String get root => _service.root;

  static Future<LocalPrayerRepository> open(String root) async {
    return LocalPrayerRepository.fromService(
      await LocalPrayerDatabaseService.open(root),
    );
  }

  static Future<void> createSchema(Database db, int version) =>
      LocalPrayerDatabaseService.createSchema(db, version);

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() =>
      safeLocalCall(() async {
        final rows = await _service.sessions();
        return rows.map(sessionFromRow).toList();
      });

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) =>
      safeLocalCall(() async {
        if (session.audioPath != null &&
            !await _service.audioExists(session.audioPath!)) {
          throw StateError('Recording missing');
        }
        final row = sessionToRow(session);
        await _service.insertSession(row);
      });

  Future<void> _removeAudio(String id) async {
    final row = await _service.session(id);
    if (row == null) return;
    final name = row['audioPath'] as String?;
    if (name != null) {
      await _service.deleteAudioFile(name);
      await _service.updateAudioPath(id, null);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAudio(String id) =>
      safeLocalCall(() async {
        await _removeAudio(id);
      });

  @override
  Future<Either<Failure, void>> deleteSession(String id) =>
      safeLocalCall(() async {
        await _removeAudio(id);
        await _service.deleteSession(id);
      });

  @override
  Future<Either<Failure, List<Reminder>>> reminders() =>
      safeLocalCall(() async {
        final rows = await _service.reminders();
        return rows.map(reminderFromRow).toList();
      });

  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) =>
      safeLocalCall(() async {
        final row = reminder.toRow();
        await _service.upsertReminder(row);
      });

  @override
  Future<Either<Failure, void>> deleteReminder(int id) =>
      safeLocalCall(() async {
        await _service.deleteReminder(id);
      });

  @override
  Future<Either<Failure, void>> reset() => safeLocalCall(() async {
    await _service.reset();
  });

  /// Clean only unreferenced recordings from a previous process, never saved prayers.
  Future<void> reconcileFiles() => _service.reconcileFiles();
}
