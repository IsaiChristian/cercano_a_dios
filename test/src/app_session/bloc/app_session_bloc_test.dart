import 'dart:async';
import 'dart:io';

import 'package:cercano_a_dios/core/di/authenticated_app_factory.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceServices extends DeviceServices {
  int stopPlaybackCalls = 0;
  int stopAlarmCalls = 0;
  int cancelAllCalls = 0;
  List<Reminder> scheduledReminders = [];

  bool throwOnStopPlayback = false;
  int? throwOnScheduleReminderId;

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalls++;
    if (throwOnStopPlayback) throw Exception('Playback error');
  }

  @override
  Future<void> stopAlarm() async {
    stopAlarmCalls++;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> schedule(Reminder reminder) async {
    if (throwOnScheduleReminderId == reminder.id) {
      throw Exception('Schedule error');
    }
    scheduledReminders.add(reminder);
  }
}

class FakePrayerRepository implements PrayerRepository {
  List<Reminder> mockReminders;

  FakePrayerRepository({this.mockReminders = const []});

  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Reminder>>> reminders() async =>
      Right(mockReminders);

  @override
  Future<Either<Failure, void>> complete(PrayerSession session) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteAudio(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteReminder(int id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteSession(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> reset() async => const Right(null);

  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);
}

class FakeAuthenticatedAppFactory extends AuthenticatedAppFactory {
  final Future<AppBloc> Function(AuthUser user)? createHandler;
  final List<AppBloc> createdApps = [];

  FakeAuthenticatedAppFactory({
    required super.device,
    required super.baseRoot,
    this.createHandler,
  });

  @override
  Future<AppBloc> create(AuthUser user) async {
    if (createHandler != null) {
      final app = await createHandler!(user);
      createdApps.add(app);
      return app;
    }
    throw UnimplementedError();
  }
}

AppBloc createTestAppBloc({
  required DeviceServices device,
  required String root,
  List<Reminder> reminders = const [],
  Future<void> Function()? closeCallback,
}) {
  final repo = FakePrayerRepository(mockReminders: reminders);
  final storage = LocalStorageService(root);
  return AppBloc(
    repository: repo,
    device: device,
    storage: storage,
    closeResources: closeCallback,
  );
}

void main() {
  late Directory tempBase;
  late FakeDeviceServices device;
  late FakeAuthenticatedAppFactory factory;
  late AppSessionBloc bloc;

  const userA = AuthUser(id: 'user-a', email: 'a@example.com');
  const userB = AuthUser(id: 'user-b', email: 'b@example.com');

  setUp(() async {
    tempBase = await Directory.systemTemp.createTemp('app_session_test_');
    device = FakeDeviceServices();
    factory = FakeAuthenticatedAppFactory(
      device: device,
      baseRoot: tempBase.path,
      createHandler: (user) async {
        final userDir = Directory('${tempBase.path}/${user.id}')
          ..createSync(recursive: true);
        final app = createTestAppBloc(device: device, root: userDir.path);
        await app.refresh();
        return app;
      },
    );
    bloc = AppSessionBloc(appFactory: factory, device: device);
  });

  tearDown(() async {
    await bloc.close();
    if (await tempBase.exists()) {
      await tempBase.delete(recursive: true);
    }
  });

  group('AppSessionBloc', () {
    test('initial state is signedOut with no active AppBloc', () {
      expect(bloc.state.status, AppSessionStatus.signedOut);
      expect(bloc.state.userId, isNull);
      expect(bloc.activeAppBloc, isNull);
    });

    test(
      'transitions from signedOut to loading to ready when user is supplied',
      () async {
        bloc.add(const AppSessionUserChanged(userA));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const AppSessionState.loading(userId: 'user-a'),
            const AppSessionState.ready(userId: 'user-a'),
          ]),
        );
        expect(bloc.activeAppBloc, isNotNull);
        expect(bloc.state.userId, equals('user-a'));
      },
    );

    test(
      'handles failed profile opens and transitions to failure state',
      () async {
        factory = FakeAuthenticatedAppFactory(
          device: device,
          baseRoot: tempBase.path,
          createHandler: (user) async => throw StateError('Failed to open DB'),
        );
        final failBloc = AppSessionBloc(appFactory: factory, device: device);
        failBloc.add(const AppSessionUserChanged(userA));

        await expectLater(
          failBloc.stream,
          emitsInOrder([
            const AppSessionState.loading(userId: 'user-a'),
            predicate<AppSessionState>(
              (state) =>
                  state.status == AppSessionStatus.failure &&
                  state.userId == 'user-a' &&
                  state.failure != null,
            ),
          ]),
        );
        expect(failBloc.activeAppBloc, isNull);
        await failBloc.close();
      },
    );

    test('retry event retries failed profile open for same user', () async {
      var attempts = 0;
      factory = FakeAuthenticatedAppFactory(
        device: device,
        baseRoot: tempBase.path,
        createHandler: (user) async {
          attempts++;
          if (attempts == 1) throw StateError('Network/DB error');
          final userDir = Directory('${tempBase.path}/${user.id}')
            ..createSync(recursive: true);
          final app = createTestAppBloc(device: device, root: userDir.path);
          await app.refresh();
          return app;
        },
      );
      final retryBloc = AppSessionBloc(appFactory: factory, device: device);

      retryBloc.add(const AppSessionUserChanged(userA));
      await expectLater(
        retryBloc.stream,
        emitsInOrder([
          const AppSessionState.loading(userId: 'user-a'),
          predicate<AppSessionState>(
            (s) => s.status == AppSessionStatus.failure,
          ),
        ]),
      );

      // Now dispatch retry
      retryBloc.add(const AppSessionRetryRequested());
      await expectLater(
        retryBloc.stream,
        emitsInOrder([
          const AppSessionState.loading(userId: 'user-a'),
          const AppSessionState.ready(userId: 'user-a'),
        ]),
      );

      expect(retryBloc.activeAppBloc, isNotNull);
      await retryBloc.close();
    });

    test('immediately removes active AppBloc upon user change', () async {
      bloc.add(const AppSessionUserChanged(userA));
      await expectLater(
        bloc.stream,
        emitsThrough(const AppSessionState.ready(userId: 'user-a')),
      );
      expect(bloc.activeAppBloc, isNotNull);

      // Trigger user change to userB
      bloc.add(const AppSessionUserChanged(userB));
      // activeAppBloc must be null immediately
      expect(bloc.activeAppBloc, isNull);

      await expectLater(
        bloc.stream,
        emitsThrough(const AppSessionState.ready(userId: 'user-b')),
      );
      expect(bloc.activeAppBloc, isNotNull);
    });

    test(
      'independently stops playback, ringing alarm, cancels schedules and closes old AppBloc on switch',
      () async {
        var oldAppClosed = false;
        factory = FakeAuthenticatedAppFactory(
          device: device,
          baseRoot: tempBase.path,
          createHandler: (user) async {
            final userDir = Directory('${tempBase.path}/${user.id}')
              ..createSync(recursive: true);
            final app = createTestAppBloc(
              device: device,
              root: userDir.path,
              closeCallback: () async {
                oldAppClosed = true;
              },
            );
            await app.refresh();
            return app;
          },
        );
        final testBloc = AppSessionBloc(appFactory: factory, device: device);

        testBloc.add(const AppSessionUserChanged(userA));
        await expectLater(
          testBloc.stream,
          emitsThrough(const AppSessionState.ready(userId: 'user-a')),
        );

        // Make stopPlayback throw to prove independent cleanup continues
        device.throwOnStopPlayback = true;

        testBloc.add(const AppSessionUserChanged(null));
        await expectLater(
          testBloc.stream,
          emitsThrough(const AppSessionState.signedOut()),
        );

        expect(device.stopPlaybackCalls, greaterThanOrEqualTo(1));
        expect(device.stopAlarmCalls, greaterThanOrEqualTo(1));
        expect(device.cancelAllCalls, greaterThanOrEqualTo(1));
        expect(oldAppClosed, isTrue);

        await testBloc.close();
      },
    );

    test(
      'rapid A -> B -> null transitions prevent stale profile leaks',
      () async {
        final completerA = Completer<AppBloc>();
        var appACreated = false;
        var appAClosed = false;

        factory = FakeAuthenticatedAppFactory(
          device: device,
          baseRoot: tempBase.path,
          createHandler: (user) async {
            if (user.id == 'user-a') {
              appACreated = true;
              return completerA.future;
            } else {
              final userDir = Directory('${tempBase.path}/${user.id}')
                ..createSync(recursive: true);
              final app = createTestAppBloc(device: device, root: userDir.path);
              await app.refresh();
              return app;
            }
          },
        );
        final rapidBloc = AppSessionBloc(appFactory: factory, device: device);

        // Dispatch userA, which will pause on completerA
        rapidBloc.add(const AppSessionUserChanged(userA));
        await pumpEventQueue();
        expect(appACreated, isTrue);

        // While userA is waiting, dispatch userB and null
        rapidBloc.add(const AppSessionUserChanged(userB));
        rapidBloc.add(const AppSessionUserChanged(null));

        // Resolve delayed factory completion for userA
        final dirA = Directory('${tempBase.path}/a')
          ..createSync(recursive: true);
        final appA = createTestAppBloc(
          device: device,
          root: dirA.path,
          closeCallback: () async {
            appAClosed = true;
          },
        );
        completerA.complete(appA);

        await expectLater(
          rapidBloc.stream,
          emitsThrough(const AppSessionState.signedOut()),
        );

        await pumpEventQueue();

        // App A should have been discarded and closed because its ticket was superseded
        expect(appAClosed, isTrue);
        expect(rapidBloc.activeAppBloc, isNull);
        expect(rapidBloc.state.status, AppSessionStatus.signedOut);

        await rapidBloc.close();
      },
    );

    test(
      'independently restores incoming enabled reminders and reports individual failures',
      () async {
        const enabled1 = Reminder(
          id: 1,
          hour: 8,
          minute: 0,
          weekdays: [1],
          enabled: true,
        );
        const enabled2 = Reminder(
          id: 2,
          hour: 9,
          minute: 0,
          weekdays: [2],
          enabled: true,
        );
        const disabled = Reminder(
          id: 3,
          hour: 10,
          minute: 0,
          weekdays: [3],
          enabled: false,
        );

        device.throwOnScheduleReminderId = 1; // Make reminder 1 throw

        factory = FakeAuthenticatedAppFactory(
          device: device,
          baseRoot: tempBase.path,
          createHandler: (user) async {
            final userDir = Directory('${tempBase.path}/${user.id}')
              ..createSync(recursive: true);
            final app = createTestAppBloc(
              device: device,
              root: userDir.path,
              reminders: [enabled1, enabled2, disabled],
            );
            await app.refresh();
            return app;
          },
        );

        final reminderBloc = AppSessionBloc(
          appFactory: factory,
          device: device,
        );
        reminderBloc.add(const AppSessionUserChanged(userA));

        await expectLater(
          reminderBloc.stream,
          emitsThrough(const AppSessionState.ready(userId: 'user-a')),
        );
        await pumpEventQueue();

        // Reminder 2 should be scheduled despite Reminder 1 failing
        expect(device.scheduledReminders.any((r) => r.id == 2), isTrue);
        // Disabled reminder should not be scheduled
        expect(device.scheduledReminders.any((r) => r.id == 3), isFalse);

        // AppBloc should have received error report for reminder 1
        expect(reminderBloc.activeAppBloc?.state.error, isNotNull);

        await reminderBloc.close();
      },
    );

    test(
      'validates and rejects stale reminder payloads via isValidReminderId',
      () async {
        const reminderA = Reminder(id: 100, hour: 7, minute: 0, weekdays: [1]);
        const reminderB = Reminder(id: 200, hour: 8, minute: 0, weekdays: [2]);

        factory = FakeAuthenticatedAppFactory(
          device: device,
          baseRoot: tempBase.path,
          createHandler: (user) async {
            final userDir = Directory('${tempBase.path}/${user.id}')
              ..createSync(recursive: true);
            final reminders = user.id == 'user-a' ? [reminderA] : [reminderB];
            final app = createTestAppBloc(
              device: device,
              root: userDir.path,
              reminders: reminders,
            );
            await app.refresh();
            return app;
          },
        );

        final testBloc = AppSessionBloc(appFactory: factory, device: device);

        // Signed out: any reminder is invalid
        expect(testBloc.isValidReminderId(100), isFalse);

        // User A
        testBloc.add(const AppSessionUserChanged(userA));
        await expectLater(
          testBloc.stream,
          emitsThrough(const AppSessionState.ready(userId: 'user-a')),
        );

        expect(testBloc.isValidReminderId(100), isTrue);
        expect(testBloc.isValidReminderId(200), isFalse);

        // Switch to User B
        testBloc.add(const AppSessionUserChanged(userB));
        // Immediately on change, reminder 100 is invalid
        expect(testBloc.isValidReminderId(100), isFalse);

        await expectLater(
          testBloc.stream,
          emitsThrough(const AppSessionState.ready(userId: 'user-b')),
        );

        expect(
          testBloc.isValidReminderId(100),
          isFalse,
        ); // Stale payload from user A rejected
        expect(testBloc.isValidReminderId(200), isTrue);

        await testBloc.close();
      },
    );
  });
}
