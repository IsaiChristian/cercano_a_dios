import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/audio/presentation/bloc/audio_bloc.dart';

class FakeAudioDevice extends DeviceServices {
  String? lastPlayedPath;
  bool stopPlaybackCalled = false;

  @override
  Future<void> play(String path) async {
    lastPlayedPath = path;
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalled = true;
  }
}

class FakeAudioRepository implements PrayerRepository {
  final List<String> deletedAudioIds = [];
  List<PrayerSession> sessionsToReturn = [];
  bool failDeleteAudio = false;
  final Set<String> failAudioIds = {};
  bool failSessions = false;
  String failMessage = 'Error';

  @override
  Future<Either<Failure, void>> deleteAudio(String id) async {
    if (failDeleteAudio || failAudioIds.contains(id)) {
      return Left(
        Failure(
          failAudioIds.contains(id) ? '$failMessage for $id' : failMessage,
        ),
      );
    }
    deletedAudioIds.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async {
    if (failSessions) return Left(Failure(failMessage));
    return Right(sessionsToReturn);
  }

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteSession(String id) async =>
      const Right(null);
  @override
  Future<Either<Failure, List<Reminder>>> reminders() async => const Right([]);
  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteReminder(int id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> reset() async => const Right(null);
}

void main() {
  late Directory tempDir;
  late LocalStorageService storage;
  late FakeAudioDevice device;
  late FakeAudioRepository repository;
  late AudioBloc bloc;

  final sampleSession = PrayerSession(
    id: 's1',
    promptId: 'p1',
    promptText: 'Prompt',
    localDate: '2026-09-16',
    completedAt: DateTime.now(),
    durationSeconds: 30,
    offsetMinutes: 0,
    spoken: true,
    audioPath: 'recording1.m4a',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio_bloc_test_');
    storage = LocalStorageService(tempDir.path);
    device = FakeAudioDevice();
    repository = FakeAudioRepository();
    bloc = AudioBloc(device: device, storage: storage, repository: repository);
  });

  tearDown(() async {
    await bloc.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('initial state has 0 audioBytes and not playing', () {
    expect(bloc.state.audioBytes, equals(0));
    expect(bloc.state.isPlaying, isFalse);
    expect(bloc.state.playingSessionId, isNull);
  });

  test('playAudio updates isPlaying and calls device.play', () async {
    await bloc.playAudio(sampleSession);
    expect(bloc.state.isPlaying, isTrue);
    expect(bloc.state.playingSessionId, equals('s1'));
    expect(device.lastPlayedPath, equals(storage.pathFor('recording1.m4a')));
  });

  test('stopPlayback stops playing', () async {
    await bloc.playAudio(sampleSession);
    expect(bloc.state.isPlaying, isTrue);

    await bloc.stopPlayback();
    expect(bloc.state.isPlaying, isFalse);
    expect(bloc.state.playingSessionId, isNull);
    expect(device.stopPlaybackCalled, isTrue);
  });

  test('deleteAudio stops playback and deletes recording', () async {
    await bloc.deleteAudio('s1');
    expect(device.stopPlaybackCalled, isTrue);
    expect(repository.deletedAudioIds, contains('s1'));
    expect(bloc.state.isPlaying, isFalse);
  });

  test('deleteAllAudio deletes all recordings for provided sessions', () async {
    final s2 = PrayerSession(
      id: 's2',
      promptId: 'p2',
      promptText: 'Prompt 2',
      localDate: '2026-09-16',
      completedAt: DateTime.now(),
      durationSeconds: 45,
      offsetMinutes: 0,
      spoken: true,
      audioPath: 'recording2.m4a',
    );
    await bloc.deleteAllAudio([sampleSession, s2]);
    expect(repository.deletedAudioIds, containsAll(['s1', 's2']));
  });

  test(
    'deleteAllAudio without arguments queries repository sessions',
    () async {
      final s2 = PrayerSession(
        id: 's2',
        promptId: 'p2',
        promptText: 'Prompt 2',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'recording2.m4a',
      );
      repository.sessionsToReturn = [sampleSession, s2];
      await bloc.deleteAllAudio();
      expect(repository.deletedAudioIds, containsAll(['s1', 's2']));
    },
  );

  test(
    'deleteAllAudio sets error and does not delete when repository read fails',
    () async {
      repository.failSessions = true;
      repository.failMessage = 'DB read failed';
      await bloc.deleteAllAudio();
      expect(bloc.state.error, equals('DB read failed'));
      expect(bloc.state.busy, isFalse);
      expect(repository.deletedAudioIds, isEmpty);
    },
  );

  test('deleteAudio preserves failure error instead of clearing it', () async {
    repository.failDeleteAudio = true;
    repository.failMessage = 'File locked';
    final result = await bloc.deleteAudio('s1');
    expect(bloc.state.error, equals('File locked'));
    expect(result.isFailure, isTrue);
    expect(result.failedIds['s1'], equals('File locked'));
    expect(bloc.state.lastDeleteResult, equals(result));
  });

  test(
    'deleteAudio on success returns AudioDeleteResult with successfulIds and clears error',
    () async {
      final result = await bloc.deleteAudio('s1');
      expect(result.isSuccess, isTrue);
      expect(result.successfulIds, contains('s1'));
      expect(result.failedIds, isEmpty);
      expect(bloc.state.error, isNull);
      expect(bloc.state.lastDeleteResult, equals(result));
    },
  );

  test(
    'deleteAllAudio handles mixed-success bulk deletion, refreshes bytes, preserves failure error, and reports outcome',
    () async {
      final s2 = PrayerSession(
        id: 's2',
        promptId: 'p2',
        promptText: 'Prompt 2',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'recording2.m4a',
      );
      final s3 = PrayerSession(
        id: 's3',
        promptId: 'p3',
        promptText: 'Prompt 3',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 60,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'recording3.m4a',
      );

      // Create files in storage so bytes are calculated
      final file1 = File(storage.pathFor('recording1.m4a'));
      final file3 = File(storage.pathFor('recording3.m4a'));
      await file1.create(recursive: true);
      await file1.writeAsBytes(List.filled(100, 1));
      await file3.create(recursive: true);
      await file3.writeAsBytes(List.filled(200, 2));

      // Make s2 fail
      repository.failAudioIds.add('s2');

      final result = await bloc.deleteAllAudio([sampleSession, s2, s3]);

      // Verify explicit outcome
      expect(result.isPartial, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.successfulIds, equals(['s1', 's3']));
      expect(result.failedIds.keys, equals(['s2']));
      expect(result.failedIds['s2'], contains('Error for s2'));

      // Verify state preserves error and outcome
      expect(
        bloc.state.error,
        contains('Failed to delete audio for session s2'),
      );
      expect(bloc.state.lastDeleteResult, equals(result));
      expect(repository.deletedAudioIds, equals(['s1', 's3']));

      // Verify retryFailedDeletions retries only the failed session (s2)
      repository.failAudioIds.clear();
      final retryResult = await bloc.retryFailedDeletions();
      expect(retryResult.isSuccess, isTrue);
      expect(retryResult.successfulIds, equals(['s2']));
      expect(bloc.state.error, isNull);
      expect(repository.deletedAudioIds, containsAll(['s1', 's3', 's2']));
    },
  );

  test('clearError clears preserved error on AudioState', () async {
    repository.failDeleteAudio = true;
    repository.failMessage = 'Disk failure';
    await bloc.deleteAudio('s1');
    expect(bloc.state.error, equals('Disk failure'));

    bloc.clearError();
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.error, isNull);
  });
}
