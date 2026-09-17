import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/reminders/presentation/bloc/reminders_bloc.dart';

class FakeRemindersDevice extends DeviceServices {
  int? cancelledId;
  int? scheduledId;
  int? cancelledSnoozeId;
  bool settingsCalled = false;
  bool testAlarmCalled = false;

  @override
  Future<String> alarmCapability() async => 'alarm';

  @override
  Future<String> alarmStatus() async => 'ready';

  @override
  Future<void> cancel(int id) async {
    cancelledId = id;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    scheduledId = reminder.id;
  }

  @override
  Future<void> cancelSnooze(int id) async {
    cancelledSnoozeId = id;
  }

  @override
  Future<void> settings() async {
    settingsCalled = true;
  }

  @override
  Future<void> testAlarm() async {
    testAlarmCalled = true;
  }
}

class FakeRemindersRepository implements PrayerRepository {
  final Map<int, Reminder> remindersMap = {};
  bool failNext = false;

  @override
  Future<Either<Failure, List<Reminder>>> reminders() async {
    if (failNext) return const Left(Failure('Repository error'));
    return Right(remindersMap.values.toList());
  }

  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async {
    if (failNext) return const Left(Failure('Save error'));
    remindersMap[reminder.id] = reminder;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteReminder(int id) async {
    if (failNext) return const Left(Failure('Delete error'));
    remindersMap.remove(id);
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
  Future<Either<Failure, void>> deleteAudio(String id) async =>
      const Right(null);
  @override
  Future<Either<Failure, void>> reset() async => const Right(null);
}

void main() {
  late FakeRemindersDevice device;
  late FakeRemindersRepository repository;
  late RemindersBloc bloc;

  const sampleReminder = Reminder(
    id: 10,
    hour: 7,
    minute: 30,
    weekdays: [1, 2, 3, 4, 5],
  );

  setUp(() {
    device = FakeRemindersDevice();
    repository = FakeRemindersRepository();
    bloc = RemindersBloc(repository: repository, device: device);
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state has empty reminders and loading capability', () {
    expect(bloc.state.reminders, isEmpty);
    expect(bloc.state.capability, equals('loading'));
    expect(bloc.state.permission, equals('unknown'));
  });

  test('loadStatus updates capability and permission', () async {
    await bloc.loadStatus();
    expect(bloc.state.capability, equals('alarm'));
    expect(bloc.state.permission, equals('ready'));
  });

  test('loadReminders loads saved reminders', () async {
    repository.remindersMap[sampleReminder.id] = sampleReminder;
    await bloc.loadReminders();
    expect(bloc.state.reminders, contains(sampleReminder));
  });

  test('saveReminder schedules alarm and updates state', () async {
    final success = await bloc.saveReminder(sampleReminder);
    expect(success, isTrue);
    expect(device.cancelledId, equals(10));
    expect(device.scheduledId, equals(10));
    expect(bloc.state.reminders.any((r) => r.id == 10), isTrue);
    expect(bloc.state.reminders.first.status, equals('ready'));
  });

  test('deleteReminder cancels device alarm and removes from state', () async {
    await bloc.saveReminder(sampleReminder);
    expect(bloc.state.reminders.any((r) => r.id == 10), isTrue);

    await bloc.deleteReminder(10);
    expect(device.cancelledId, equals(10));
    expect(bloc.state.reminders, isEmpty);
  });

  test('cancelSnooze delegates to device', () async {
    await bloc.cancelSnooze(10);
    expect(device.cancelledSnoozeId, equals(10));
  });

  test('openSettings and testAlarm delegate to device', () async {
    await bloc.openSettings();
    expect(device.settingsCalled, isTrue);

    await bloc.testAlarm();
    expect(device.testAlarmCalled, isTrue);
  });
}
