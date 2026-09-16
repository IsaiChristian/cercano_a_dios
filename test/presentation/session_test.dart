import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/core/error/failure.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/prompts.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/bloc/session_bloc.dart';

class MemoryRepository implements PrayerRepository {
  final records = <String, PrayerSession>{};
  bool failSave = false;
  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async {
    if (failSave) return const Left(Failure('Storage unavailable'));
    records.putIfAbsent(session.id, () => session);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async =>
      Right(records.values.toList());
  @override
  Future<Either<Failure, List<Reminder>>> reminders() async => const Right([]);
  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteReminder(int id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteAudio(String id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    records.remove(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reset() async {
    records.clear();
    return const Right(null);
  }
}

class FakeDevice extends DeviceServices {
  bool denied = false;
  bool recording = false;
  bool failStopPlayback = false;
  int? cancelledSnooze;
  @override
  Future<void> record(String path) async {
    if (denied) {
      throw PlatformException(code: 'denied', message: 'Microphone denied');
    }
    recording = true;
    await File(path).writeAsBytes([1, 2, 3]);
  }

  @override
  Future<void> finishRecording() async {
    recording = false;
  }

  @override
  Future<void> stopAlarm() async {}
  @override
  Future<void> stopPlayback() async {
    if (failStopPlayback) throw PlatformException(code: 'playback');
  }

  @override
  Future<void> cancelSnooze(int id) async {
    cancelledSnooze = id;
  }

  @override
  Future<double> amplitude() async => 0.2;
}

void main() {
  late Directory root;
  late MemoryRepository repository;
  late FakeDevice device;
  late AppBloc app;
  late SessionBloc session;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('prayer-session');
    repository = MemoryRepository();
    device = FakeDevice();
    app = AppBloc(
      repository: repository,
      device: device,
      storage: LocalStorageService(root.path),
    );
    session = SessionBloc(
      device: device,
      storage: app.storage,
      prompt: prompts.first,
      reminderId: 7,
      audioBytes: () => app.state.audioBytes,
      completeSession: app.complete,
      cancelReminderSnooze: app.cancelReminderSnooze,
      lastError: () => app.state.error,
    );
  });
  tearDown(() async {
    device.failStopPlayback = false;
    await session.close();
    await app.close();
    await device.interruptions.close();
    await root.delete(recursive: true);
  });
  test('finishing a recording waits for explicit completion', () async {
    await session.start();
    expect(device.recording, true);
    await session.finish();
    expect(device.recording, false);
    expect(session.state.phase, SessionPhase.review);
    expect(repository.records, isEmpty);
    expect(await session.save(), true);
    expect(repository.records.values.single.audioPath, session.filename);
    expect(device.cancelledSnooze, 7);
    expect(await session.save(), false);
    expect(repository.records.length, 1);
  });
  test('denied microphone still permits a silent completion', () async {
    device.denied = true;
    await session.start();
    expect(session.state.error, 'Microphone denied');
    expect(await session.save(silent: true), true);
    expect(repository.records.values.single.spoken, false);
  });
  test(
    'failed save keeps the draft and can be retried without duplicate credit',
    () async {
      await session.start();
      await session.finish();
      repository.failSave = true;
      expect(await session.save(), false);
      expect(session.state.phase, SessionPhase.review);
      expect(await File(session.path).exists(), true);
      repository.failSave = false;
      expect(await session.save(), true);
      expect(repository.records.length, 1);
    },
  );
  test(
    'audio errors restore a usable state instead of leaving Saving stuck',
    () async {
      device.failStopPlayback = true;
      expect(await session.save(silent: true), false);
      expect(session.state.phase, SessionPhase.ready);
      expect(repository.records, isEmpty);
    },
  );
  test('background interruption stops recording without completing', () async {
    await session.start();
    await session.interrupt();
    expect(device.recording, false);
    expect(session.state.phase, SessionPhase.review);
    expect(repository.records, isEmpty);
  });
}
