import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/history/presentation/bloc/history_bloc.dart';

class FakeHistoryRepository implements PrayerRepository {
  final List<PrayerSession> sessionList = [];
  bool failNext = false;
  String failMessage = 'Error';

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async {
    if (failNext) return Left(Failure(failMessage));
    return Right(List.unmodifiable(sessionList));
  }

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async {
    if (failNext) return Left(Failure(failMessage));
    sessionList.add(session);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    if (failNext) return Left(Failure(failMessage));
    sessionList.removeWhere((s) => s.id == id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Reminder>>> reminders() async => const Right([]);
  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> deleteAudio(String id) async {
    final idx = sessionList.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = sessionList[idx];
      sessionList[idx] = PrayerSession(
        id: s.id,
        promptId: s.promptId,
        promptText: s.promptText,
        localDate: s.localDate,
        completedAt: s.completedAt,
        durationSeconds: s.durationSeconds,
        offsetMinutes: s.offsetMinutes,
        spoken: s.spoken,
        audioPath: null,
      );
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteReminder(int id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> reset() async => const Right(null);
}

void main() {
  late FakeHistoryRepository repository;
  late HistoryBloc bloc;

  final sampleSession = PrayerSession(
    id: 's1',
    promptId: 'p1',
    promptText: 'Be still',
    localDate: '2026-09-16',
    completedAt: DateTime.now(),
    durationSeconds: 60,
    offsetMinutes: 0,
    spoken: true,
  );

  setUp(() {
    repository = FakeHistoryRepository();
    bloc = HistoryBloc(repository: repository);
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state is empty and not loading', () {
    expect(bloc.state.sessions, isEmpty);
    expect(bloc.state.loading, isFalse);
    expect(bloc.state.error, isNull);
  });

  test('loadSessions updates state with repository sessions', () async {
    repository.sessionList.add(sampleSession);
    await bloc.loadSessions();
    expect(bloc.state.sessions, equals([sampleSession]));
    expect(bloc.state.error, isNull);
  });

  test('loadSessions sets error on failure', () async {
    repository.failNext = true;
    repository.failMessage = 'Network error';
    await bloc.loadSessions();
    expect(bloc.state.error, equals('Network error'));
  });

  test('completeSession adds session and reloads', () async {
    final success = await bloc.completeSession(sampleSession);
    expect(success, isTrue);
    expect(bloc.state.sessions, contains(sampleSession));
    expect(bloc.state.error, isNull);
  });

  test('completeSession returns false on failure', () async {
    repository.failNext = true;
    repository.failMessage = 'Save failed';
    final success = await bloc.completeSession(sampleSession);
    expect(success, isFalse);
    expect(bloc.state.error, equals('Save failed'));
  });

  test('deleteSession removes session and reloads', () async {
    repository.sessionList.add(sampleSession);
    await bloc.loadSessions();
    expect(bloc.state.sessions, contains(sampleSession));

    await bloc.deleteSession('s1');
    expect(bloc.state.sessions, isEmpty);
  });

  test('syncAudioDeleted reloads sessions with null audioPath', () async {
    final recordedSession = PrayerSession(
      id: 's1',
      promptId: 'p1',
      promptText: 'Be still',
      localDate: '2026-09-16',
      completedAt: DateTime.now(),
      durationSeconds: 60,
      offsetMinutes: 0,
      spoken: true,
      audioPath: 'rec.m4a',
    );
    repository.sessionList.add(recordedSession);
    await bloc.loadSessions();
    expect(bloc.state.sessions.first.audioPath, equals('rec.m4a'));

    await repository.deleteAudio('s1');
    await bloc.syncAudioDeleted('s1');
    expect(bloc.state.sessions.length, equals(1));
    expect(bloc.state.sessions.first.id, equals('s1'));
    expect(bloc.state.sessions.first.audioPath, isNull);
  });

  test(
    'syncAllAudioDeleted reloads all sessions with null audioPath',
    () async {
      final s1 = PrayerSession(
        id: 's1',
        promptId: 'p1',
        promptText: 'Prompt 1',
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
        promptText: 'Prompt 2',
        localDate: '2026-09-16',
        completedAt: DateTime.now(),
        durationSeconds: 45,
        offsetMinutes: 0,
        spoken: true,
        audioPath: 'rec2.m4a',
      );
      repository.sessionList.addAll([s1, s2]);
      await bloc.loadSessions();

      await repository.deleteAudio('s1');
      await repository.deleteAudio('s2');
      await bloc.syncAllAudioDeleted();

      expect(bloc.state.sessions.length, equals(2));
      expect(bloc.state.sessions[0].audioPath, isNull);
      expect(bloc.state.sessions[1].audioPath, isNull);
    },
  );

  test('syncAudioDeleted failure preserves sessions and sets error', () async {
    repository.sessionList.add(sampleSession);
    await bloc.loadSessions();
    expect(bloc.state.sessions, equals([sampleSession]));

    repository.failNext = true;
    repository.failMessage = 'Sync failed';
    await bloc.syncAudioDeleted('s1');

    expect(bloc.state.error, equals('Sync failed'));
    expect(bloc.state.sessions, equals([sampleSession]));
  });
}
