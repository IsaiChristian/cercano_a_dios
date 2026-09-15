import 'package:dartz/dartz.dart';
import '../failures/failure.dart';
import '../entities/prayer.dart';
abstract class PrayerRepository {
  Future<Either<Failure, List<PrayerSession>>> sessions();
  Future<Either<Failure, void>> complete(PrayerSession session);
  Future<Either<Failure, void>> deleteSession(String id);
  Future<Either<Failure, void>> deleteAudio(String id);
  Future<Either<Failure, List<Reminder>>> reminders();
  Future<Either<Failure, void>> saveReminder(Reminder reminder);
  Future<Either<Failure, void>> deleteReminder(int id);
  Future<Either<Failure, void>> reset();
}
