import 'dart:io';

import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class RefreshTestDevice extends DeviceServices {
  @override
  Future<void> play(String path) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> record(String path) async {}

  @override
  Future<void> finishRecording() async {}

  @override
  Future<void> stopAlarm() async {}

  @override
  Future<void> cancelAll() async {}
}

class RefreshTestRepository implements PrayerRepository {
  final Map<String, PrayerSession> sessionStore = {};
  final List<Reminder> reminderStore = [];
  bool failSessions = false;
  bool failReminders = false;
  String failMessageSessions = 'History load failed';
  String failMessageReminders = 'Reminders load failed';

  final LocalStorageService storage;

  RefreshTestRepository({required this.storage});

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async {
    if (failSessions) return Left(Failure(failMessageSessions));
    return Right(sessionStore.values.toList());
  }

  @override
  Future<Either<Failure, List<Reminder>>> reminders() async {
    if (failReminders) return Left(Failure(failMessageReminders));
    return Right(reminderStore.toList());
  }

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async {
    sessionStore[session.id] = session;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    sessionStore.remove(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAudio(String id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, bool>> saveReminder(Reminder reminder) async {
    reminderStore.add(reminder);
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> deleteReminder(int id) async {
    return const Right(null);
  }


  @override
  Future<Either<Failure, bool>> reset() async {
    return const Right(true);
  }
}

class TestLocalStorageService extends LocalStorageService {
  bool failAudioBytes = false;
  String failMessageAudio = 'Audio load failed';

  TestLocalStorageService(super.rootPath);

  @override
  Future<int> audioBytes() async {
    if (failAudioBytes) throw Failure(failMessageAudio);
    return super.audioBytes();
  }
}

void main() {
  late Directory tempDir;
  late TestLocalStorageService storage;
  late RefreshTestDevice device;
  late RefreshTestRepository repository;
  late AppBloc appBloc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_refresh_test_');
    storage = TestLocalStorageService(tempDir.path);
    device = RefreshTestDevice();
    repository = RefreshTestRepository(storage: storage);
    appBloc = AppBloc(repository: repository, device: device, storage: storage);
  });

  tearDown(() async {
    await appBloc.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('All three children load successfully', () async {
    repository.sessionStore['s1'] = PrayerSession(
      id: 's1',
      promptId: 'p1',
      promptText: 'Session 1',
      localDate: '2023-01-01',
      completedAt: DateTime.now(),
      durationSeconds: 60,
      offsetMinutes: 0,
      spoken: false,
    );
    repository.reminderStore.add(
      const Reminder(id: 1, hour: 8, minute: 0, weekdays: [], enabled: true),
    );

    // Initial state loading should be true
    expect(appBloc.state.loading, isTrue);

    await appBloc.refresh();

    expect(appBloc.state.loading, isFalse);
    expect(appBloc.state.error, isNull);
    expect(appBloc.state.sessions.length, equals(1));
    expect(appBloc.state.reminders.length, equals(1));
    expect(appBloc.state.audioBytes, equals(0));
  });

  test('Only HistoryBloc fails -> error is shown, other data loaded', () async {
    repository.failSessions = true;
    repository.reminderStore.add(
      const Reminder(id: 1, hour: 8, minute: 0, weekdays: [], enabled: true),
    );

    await appBloc.refresh();

    expect(appBloc.state.loading, isFalse);
    expect(appBloc.state.error, equals('History load failed'));
    expect(appBloc.state.sessions, isEmpty);
    expect(appBloc.state.reminders.length, equals(1));
  });

  test(
    'Only RemindersBloc fails -> error is shown, other data loaded',
    () async {
      repository.failReminders = true;
      repository.sessionStore['s1'] = PrayerSession(
        id: 's1',
        promptId: 'p1',
        promptText: 'Session 1',
        localDate: '2023-01-01',
        completedAt: DateTime.now(),
        durationSeconds: 60,
        offsetMinutes: 0,
        spoken: false,
      );

      await appBloc.refresh();

      expect(appBloc.state.loading, isFalse);
      expect(appBloc.state.error, equals('Reminders load failed'));
      expect(appBloc.state.sessions.length, equals(1));
      expect(appBloc.state.reminders, isEmpty);
    },
  );

  test('Only AudioBloc fails -> error is shown, other data loaded', () async {
    storage.failAudioBytes = true;
    repository.sessionStore['s1'] = PrayerSession(
      id: 's1',
      promptId: 'p1',
      promptText: 'Session 1',
      localDate: '2023-01-01',
      completedAt: DateTime.now(),
      durationSeconds: 60,
      offsetMinutes: 0,
      spoken: false,
    );
    repository.reminderStore.add(
      const Reminder(id: 1, hour: 8, minute: 0, weekdays: [], enabled: true),
    );

    await appBloc.refresh();

    expect(appBloc.state.loading, isFalse);
    expect(appBloc.state.error, equals('Audio load failed'));
    expect(appBloc.state.sessions.length, equals(1));
    expect(appBloc.state.reminders.length, equals(1));
  });

  test('All three fail -> error is shown', () async {
    repository.failSessions = true;
    repository.failReminders = true;
    storage.failAudioBytes = true;

    await appBloc.refresh();

    expect(appBloc.state.loading, isFalse);
    expect(appBloc.state.error, isNotNull);
  });

  test(
    'Mixed: two fail, one succeeds -> error is shown, successful data loaded',
    () async {
      repository.failSessions = true;
      storage.failAudioBytes = true;
      repository.reminderStore.add(
        const Reminder(id: 1, hour: 8, minute: 0, weekdays: [], enabled: true),
      );

      await appBloc.refresh();

      expect(appBloc.state.loading, isFalse);
      expect(appBloc.state.error, isNotNull);
      // Successful data is still loaded
      expect(appBloc.state.reminders.length, equals(1));
    },
  );
}
