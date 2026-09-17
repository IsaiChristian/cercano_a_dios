import 'dart:io';

import 'package:cercano_a_dios/data/prompts.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/bloc/session_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class SyncTestDevice extends DeviceServices {
  String? lastPlayedPath;
  bool stopPlaybackCalled = false;
  bool recording = false;

  @override
  Future<void> play(String path) async {
    lastPlayedPath = path;
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalled = true;
  }

  @override
  Future<void> record(String path) async {
    recording = true;
  }

  @override
  Future<void> finishRecording() async {
    recording = false;
  }

  @override
  Future<void> stopAlarm() async {}

  @override
  Future<void> cancelAll() async {}
}

class SyncTestRepository implements PrayerRepository {
  final Map<String, PrayerSession> sessionStore = {};
  final List<String> deletedAudioIds = [];
  bool failSessions = false;
  bool failComplete = false;
  bool failDeleteAudio = false;
  bool failDeleteSession = false;
  String failMessage = 'Repository error';

  final LocalStorageService storage;

  SyncTestRepository({required this.storage});

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async {
    if (failSessions) return Left(Failure(failMessage));
    return Right(sessionStore.values.toList());
  }

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async {
    if (failComplete) return Left(Failure(failMessage));
    sessionStore[session.id] = session;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    if (failDeleteSession) return Left(Failure(failMessage));
    final session = sessionStore[id];
    if (session?.audioPath != null) {
      await storage.deleteFile(session!.audioPath!);
    }
    sessionStore.remove(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteAudio(String id) async {
    if (failDeleteAudio) return Left(Failure(failMessage));
    deletedAudioIds.add(id);
    final session = sessionStore[id];
    if (session != null) {
      if (session.audioPath != null) {
        await storage.deleteFile(session.audioPath!);
      }
      sessionStore[id] = PrayerSession(
        id: session.id,
        promptId: session.promptId,
        promptText: session.promptText,
        localDate: session.localDate,
        completedAt: session.completedAt,
        durationSeconds: session.durationSeconds,
        offsetMinutes: session.offsetMinutes,
        spoken: session.spoken,
        audioPath: null,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Reminder>>> reminders() async => const Right([]);

  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteReminder(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reset() async {
    sessionStore.clear();
    deletedAudioIds.clear();
    return const Right(null);
  }
}

void main() {
  late Directory tempDir;
  late LocalStorageService storage;
  late SyncTestDevice device;
  late SyncTestRepository repository;
  late AppBloc appBloc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_audio_sync_test_');
    storage = LocalStorageService(tempDir.path);
    device = SyncTestDevice();
    repository = SyncTestRepository(storage: storage);
    appBloc = AppBloc(repository: repository, device: device, storage: storage);
  });

  tearDown(() async {
    await appBloc.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> createAudioFile(String name, int byteCount) async {
    final file = File('${storage.root}/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(List.filled(byteCount, 42));
  }

  test(
    'recorded session save immediately updates state.audioBytes and audioBloc storage totals',
    () async {
      expect(appBloc.state.audioBytes, equals(0));

      await createAudioFile('rec1.m4a', 2048);
      final session = PrayerSession(
        id: 'session-1',
        promptId: 'prompt-1',
        promptText: 'Be grateful',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );

      final success = await appBloc.complete(session);
      expect(success, isTrue);

      // Both AppState and AudioState are immediately updated without app resume/restart
      expect(appBloc.state.audioBytes, equals(2048));
      expect(appBloc.audioBloc.state.audioBytes, equals(2048));
      expect(appBloc.state.sessions.length, equals(1));
      expect(appBloc.state.sessions.first.id, equals('session-1'));
    },
  );

  test(
    'session deletion immediately updates state.audioBytes and removes session',
    () async {
      await createAudioFile('rec1.m4a', 4096);
      final session = PrayerSession(
        id: 'session-1',
        promptId: 'prompt-1',
        promptText: 'Morning reflection',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 60,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );
      await appBloc.complete(session);
      expect(appBloc.state.audioBytes, equals(4096));

      await appBloc.deleteSession('session-1');

      expect(appBloc.state.sessions, isEmpty);
      expect(appBloc.state.audioBytes, equals(0));
      expect(appBloc.audioBloc.state.audioBytes, equals(0));
    },
  );

  test(
    'session deletion stops active playback if the deleted session was playing',
    () async {
      await createAudioFile('rec1.m4a', 1024);
      final session = PrayerSession(
        id: 'session-1',
        promptId: 'prompt-1',
        promptText: 'Evening prayer',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 30,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );
      await appBloc.complete(session);
      await appBloc.playAudio(session);

      expect(appBloc.audioBloc.state.isPlaying, isTrue);
      expect(appBloc.audioBloc.state.playingSessionId, equals('session-1'));

      await appBloc.deleteSession('session-1');

      expect(appBloc.audioBloc.state.isPlaying, isFalse);
      expect(device.stopPlaybackCalled, isTrue);
    },
  );

  test(
    'single audio deletion immediately clears audioPath in state.sessions while retaining metadata and streak',
    () async {
      await createAudioFile('rec1.m4a', 3072);
      final session = PrayerSession(
        id: 'session-1',
        promptId: 'prompt-1',
        promptText: 'Faith and trust',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 120,
        offsetMinutes: -360,
        spoken: true,
        audioPath: 'rec1.m4a',
      );
      await appBloc.complete(session);
      expect(appBloc.state.audioBytes, equals(3072));
      expect(appBloc.state.sessions.first.audioPath, equals('rec1.m4a'));

      await appBloc.deleteAudio('session-1');

      // Storage is cleared
      expect(appBloc.state.audioBytes, equals(0));
      expect(appBloc.audioBloc.state.audioBytes, equals(0));

      // Session remains in history with metadata preserved, but audioPath is null
      expect(appBloc.state.sessions.length, equals(1));
      final preserved = appBloc.state.sessions.first;
      expect(preserved.id, equals('session-1'));
      expect(preserved.promptText, equals('Faith and trust'));
      expect(preserved.durationSeconds, equals(120));
      expect(preserved.localDate, equals('2026-09-17'));
      expect(preserved.spoken, isTrue);
      expect(preserved.audioPath, isNull);
    },
  );

  test(
    'bulk audio deletion immediately clears all audioPaths and resets audioBytes while retaining session records',
    () async {
      await createAudioFile('rec1.m4a', 1000);
      await createAudioFile('rec2.m4a', 2000);
      final s1 = PrayerSession(
        id: 'session-1',
        promptId: 'p1',
        promptText: 'First',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 30,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );
      final s2 = PrayerSession(
        id: 'session-2',
        promptId: 'p2',
        promptText: 'Second',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec2.m4a',
      );
      await appBloc.complete(s1);
      await appBloc.complete(s2);
      expect(appBloc.state.audioBytes, equals(3000));
      expect(appBloc.state.sessions.length, equals(2));

      await appBloc.deleteAllAudio();

      expect(appBloc.state.audioBytes, equals(0));
      expect(appBloc.audioBloc.state.audioBytes, equals(0));
      expect(appBloc.state.sessions.length, equals(2));
      expect(appBloc.state.sessions[0].audioPath, isNull);
      expect(appBloc.state.sessions[1].audioPath, isNull);
      expect(appBloc.state.sessions[0].promptText, isNotEmpty);
      expect(appBloc.state.sessions[1].promptText, isNotEmpty);
    },
  );

  test(
    'bulk audio deletion queries repository to avoid skipping persisted recordings when cached state.sessions is stale/empty',
    () async {
      // Write files to disk and populate repository directly, but leave appBloc.state.sessions empty
      await createAudioFile('rec1.m4a', 1500);
      await createAudioFile('rec2.m4a', 2500);
      final s1 = PrayerSession(
        id: 's1',
        promptId: 'p1',
        promptText: 'Direct 1',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 30,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );
      final s2 = PrayerSession(
        id: 's2',
        promptId: 'p2',
        promptText: 'Direct 2',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec2.m4a',
      );
      repository.sessionStore['s1'] = s1;
      repository.sessionStore['s2'] = s2;

      // Verify appBloc has stale empty sessions snapshot
      expect(appBloc.state.sessions, isEmpty);

      // Call bulk deletion
      await appBloc.deleteAllAudio();

      // Verify both recordings were found and deleted via repository query
      expect(repository.deletedAudioIds, containsAll(['s1', 's2']));
      expect(appBloc.state.audioBytes, equals(0));
      expect(appBloc.state.sessions.length, equals(2));
      expect(appBloc.state.sessions[0].audioPath, isNull);
      expect(appBloc.state.sessions[1].audioPath, isNull);
    },
  );

  test(
    'bulk audio deletion reports repository read failure and does not claim silent successful completion',
    () async {
      repository.failSessions = true;
      repository.failMessage = 'Database locked';

      await appBloc.deleteAllAudio();

      expect(appBloc.state.error, equals('Database locked'));
      expect(repository.deletedAudioIds, isEmpty);
    },
  );

  test('SessionBloc quota check reflects audioBytes after mutations', () async {
    final sessionBloc = SessionBloc(
      device: device,
      storage: storage,
      prompt: prompts.first,
      completeSession: appBloc.complete,
      audioBytes: () => appBloc.state.audioBytes,
    );
    addTearDown(sessionBloc.close);

    // When storage is below 99MiB, start recording succeeds
    await sessionBloc.start();
    expect(sessionBloc.state.phase, equals(SessionPhase.recording));
    await sessionBloc.finish();

    // Simulate audioBytes exceeding 99MiB limit
    const overLimitBytes = 100 * 1024 * 1024;
    await createAudioFile('large_rec.m4a', 512); // placeholder file
    final largeSession = PrayerSession(
      id: 'large-1',
      promptId: 'p1',
      promptText: 'Large',
      localDate: '2026-09-17',
      completedAt: DateTime.now(),
      durationSeconds: 999,
      offsetMinutes: 0,
      spoken: true,
      audioPath: 'large_rec.m4a',
    );
    await appBloc.complete(largeSession);

    // Force appBloc audioBytes over quota to simulate full storage
    appBloc.emit(appBloc.state.copyWith(audioBytes: overLimitBytes));
    expect(appBloc.state.audioBytes, greaterThan(99 * 1024 * 1024));

    // SessionBloc start() is rejected due to storage quota
    await sessionBloc.start();
    expect(sessionBloc.state.phase, equals(SessionPhase.ready));
    expect(sessionBloc.state.error, contains('Recording storage is full'));

    // Deleting audio frees space and brings audioBytes back to normal
    await appBloc.deleteAudio('large-1');
    expect(appBloc.state.audioBytes, equals(0));

    // SessionBloc now permits recording again
    await sessionBloc.start();
    expect(sessionBloc.state.phase, equals(SessionPhase.recording));
    await sessionBloc.finish();
  });

  test(
    'post-persistence refresh failure preserves committed audio and marks failure observable',
    () async {
      await createAudioFile('rec1.m4a', 2048);
      final session = PrayerSession(
        id: 'session-persist',
        promptId: 'p1',
        promptText: 'Committed prayer',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 30,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec1.m4a',
      );

      // First save normally
      await appBloc.complete(session);
      expect(appBloc.state.sessions.length, equals(1));

      // Now complete another session where repository.sessions() fails during post-save reload
      await createAudioFile('rec2.m4a', 2048);
      final secondSession = PrayerSession(
        id: 'session-persist-2',
        promptId: 'p2',
        promptText: 'Second committed prayer',
        localDate: '2026-09-17',
        completedAt: DateTime.now(),
        durationSeconds: 40,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec2.m4a',
      );

      repository.failSessions = true;
      repository.failMessage = 'Session reload failed';

      final success = await appBloc.complete(secondSession);

      // Persistence itself succeeded
      expect(success, isTrue);

      // Refresh error is observable on AppState
      expect(appBloc.state.error, equals('Session reload failed'));

      // Existing sessions were not wiped into empty data
      expect(appBloc.state.sessions, isNotEmpty);
      expect(
        appBloc.state.sessions.any((s) => s.id == 'session-persist'),
        isTrue,
      );

      // The committed file was NOT cleaned up
      final file = File('${storage.root}/rec2.m4a');
      expect(await file.exists(), isTrue);
    },
  );

  test('AppBloc operates independently without auth dependency', () {
    expect(appBloc.state.loading, isTrue);
    expect(appBloc.state.onboardingComplete, isFalse);
    expect(appBloc.state.sessions, isEmpty);
    expect(appBloc.state.reminders, isEmpty);
    expect(appBloc.state.audioBytes, equals(0));
    expect(appBloc.state.error, isNull);
  });
}
