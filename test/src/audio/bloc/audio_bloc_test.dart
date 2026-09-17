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

  @override
  Future<Either<Failure, void>> deleteAudio(String id) async {
    deletedAudioIds.add(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async =>
      const Right([]);
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
}
