import 'dart:io';

import 'package:cercano_a_dios/core/config/auth_config.dart';
import 'package:cercano_a_dios/core/di/bootstrap.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_prayer_database_service.dart';
import 'package:cercano_a_dios/data/services/local_profile_service.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/auth_repository.dart';
import 'package:cercano_a_dios/main.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/pages/auth_page.dart';
import 'package:cercano_a_dios/src/home/presentation/pages/home_page.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/pages/session_page.dart';
import 'package:cercano_a_dios/src/settings/presentation/pages/settings_page.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

class _FakeTestAuthRepository implements AuthRepository {
  AuthUser? _currentUser;
  bool returnErrorOnCurrent = false;

  _FakeTestAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  @override
  Future<Either<Failure, AuthUser?>> currentUser() async {
    if (returnErrorOnCurrent) {
      return const Left(Failure('Session check failed'));
    }
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _currentUser = AuthUser(id: 'user_${email.hashCode}', email: email);
    return Right(_currentUser!);
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _currentUser = AuthUser(
      id: 'user_${email.hashCode}',
      email: email,
      name: name,
    );
    return Right(_currentUser!);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _currentUser = null;
    return const Right(null);
  }
}

class _TestDeviceServices extends DeviceServices {
  final Directory tempDir;
  int stopPlaybackCalls = 0;
  int stopAlarmCalls = 0;
  int cancelAllCalls = 0;

  _TestDeviceServices(this.tempDir);

  @override
  Future<String> directory() async => tempDir.path;

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalls++;
  }

  @override
  Future<void> stopAlarm() async {
    stopAlarmCalls++;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }
}

class _TestPrayerDatabaseService implements LocalPrayerDatabaseService {
  final List<Map<String, Object?>> _sessions = [];
  final List<Map<String, Object?>> _reminders = [];

  @override
  final String root;

  _TestPrayerDatabaseService(this.root);

  @override
  Database get db => throw UnimplementedError();

  @override
  Future<void> close() async {}

  @override
  Future<List<Map<String, Object?>>> sessions() async => List.from(_sessions);

  @override
  Future<List<Map<String, Object?>>> reminders() async => List.from(_reminders);

  @override
  Future<void> upsertReminder(Map<String, Object?> row) async {
    _reminders.removeWhere((r) => r['id'] == row['id']);
    _reminders.add(Map.from(row));
  }

  @override
  Future<void> deleteReminder(int id) async {
    _reminders.removeWhere((r) => r['id'] == id);
  }

  @override
  Future<void> insertSession(Map<String, Object?> row) async {
    _sessions.add(Map.from(row));
  }

  @override
  Future<Map<String, Object?>?> session(String id) async => _sessions
      .cast<Map<String, Object?>?>()
      .firstWhere((s) => s?['id'] == id, orElse: () => null);

  @override
  Future<void> updateAudioPath(String id, String? audioPath) async {}

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s['id'] == id);
  }

  @override
  Future<void> reset() async {
    _sessions.clear();
    _reminders.clear();
  }

  @override
  Future<void> deleteAudioFile(String filename) async {}

  @override
  Future<bool> audioExists(String filename) async => false;

  @override
  Future<int> audioLength(String filename) async => 0;

  @override
  Future<void> reconcileFiles() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _TestDeviceServices device;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'app_auth_integration_test_',
    );
    device = _TestDeviceServices(tempDir);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(device.channel, (call) async {
          if (call.method == 'consumeOpenPrayer') {
            return null;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(device.channel, null);
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<AppBootstrapResult> runTestBootstrap({
    AuthRepository? authRepo,
  }) async {
    return bootstrap(
      config: AuthConfig.fromMap(const {'AUTH_BACKEND': 'fake'}),
      authRepository: authRepo,
      deviceServices: device,
      databaseOpener: (r) async => _TestPrayerDatabaseService(r),
    );
  }

  testWidgets('cold start signed-out displays AuthPage', (tester) async {
    final authRepo = _FakeTestAuthRepository(initialUser: null);
    final boot = await runTestBootstrap(authRepo: authRepo);

    await tester.pumpWidget(
      PrayerApp(bootstrapResult: boot, schedulePeriodicRefresh: false),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('cold start authenticated opens profile and mounts HomePage', (
    tester,
  ) async {
    const user = AuthUser(
      id: 'existing_user_1',
      email: 'existing@cercanoadios.app',
    );
    final authRepo = _FakeTestAuthRepository(initialUser: user);
    late AppBootstrapResult boot;

    await tester.runAsync(() async {
      final profileService = LocalProfileService(tempDir.path);
      final userRoot = await profileService.resolveProfileRoot(user.id);
      await File('$userRoot/welcomed').writeAsString('1');

      boot = await runTestBootstrap(authRepo: authRepo);
      if (boot.appSessionBloc.state.status != AppSessionStatus.ready) {
        await boot.appSessionBloc.stream.firstWhere(
          (s) => s.status == AppSessionStatus.ready,
        );
      }
    });

    await tester.pumpWidget(
      PrayerApp(bootstrapResult: boot, schedulePeriodicRefresh: false),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AuthPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
    'config failure displays recoverable error screen with retry button',
    (tester) async {
      int attempts = 0;
      Future<AppBootstrapResult> failingBootstrap() async {
        attempts++;
        if (attempts == 1) {
          throw StateError('Missing APPWRITE_ENDPOINT or APPWRITE_PROJECT_ID');
        }
        return runTestBootstrap(authRepo: _FakeTestAuthRepository());
      }

      await tester.pumpWidget(Startup(bootstrapOverride: failingBootstrap));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.byType(AuthPage), findsOneWidget);
    },
  );

  testWidgets('sign-in and sign-out integration flow', (tester) async {
    final authRepo = _FakeTestAuthRepository(initialUser: null);
    late AppBootstrapResult boot;

    await tester.runAsync(() async {
      boot = await runTestBootstrap(authRepo: authRepo);
      if (boot.authBloc.state.sessionStatus == AuthSessionStatus.unknown) {
        await boot.authBloc.stream.firstWhere(
          (s) => s.sessionStatus != AuthSessionStatus.unknown,
        );
      }
      if (boot.appSessionBloc.state.status != AppSessionStatus.signedOut) {
        await boot.appSessionBloc.stream.firstWhere(
          (s) => s.status == AppSessionStatus.signedOut,
        );
      }
    });

    await tester.pumpWidget(
      PrayerApp(bootstrapResult: boot, schedulePeriodicRefresh: false),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthPage), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');

    // Sign in inside runAsync so file I/O resolves without stalling FakeAsync
    await tester.runAsync(() async {
      boot.authBloc.add(
        const AuthSignInRequested(
          email: 'user@example.com',
          password: 'password123',
        ),
      );
      await boot.appSessionBloc.stream.firstWhere(
        (s) => s.status == AppSessionStatus.ready,
      );
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Profile should be ready, now at HomePage or Welcome
    expect(find.byType(AuthPage), findsNothing);

    // If on /welcome, complete onboarding to go to /
    final beginJourney = find.widgetWithText(FilledButton, 'Begin my journey');
    if (beginJourney.evaluate().isNotEmpty) {
      await tester.runAsync(() async {
        await boot.appSessionBloc.activeAppBloc!.completeOnboarding();
      });
      await tester.pumpAndSettle();
    }

    // Navigate to Settings
    final settingsNav = find.byIcon(Icons.tune);
    if (settingsNav.evaluate().isNotEmpty) {
      await tester.tap(settingsNav);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      final signOutBtn = find.widgetWithText(OutlinedButton, 'Sign out');
      await tester.scrollUntilVisible(signOutBtn, 200);
      expect(signOutBtn, findsOneWidget);

      await tester.runAsync(() async {
        boot.authBloc.add(const AuthSignOutRequested());
        await boot.appSessionBloc.stream.firstWhere(
          (s) => s.status == AppSessionStatus.signedOut,
        );
      });
      await tester.pumpAndSettle();

      // Should now be back on AuthPage
      expect(find.byType(AuthPage), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
    }
  });

  testWidgets(
    'gated alarm entry validates reminder ID and avoids stale navigation',
    (tester) async {
      const user = AuthUser(id: 'alarm_user', email: 'alarm@cercanoadios.app');
      final authRepo = _FakeTestAuthRepository(initialUser: user);
      late AppBootstrapResult boot;

      await tester.runAsync(() async {
        final profileService = LocalProfileService(tempDir.path);
        final userRoot = await profileService.resolveProfileRoot(user.id);
        await File('$userRoot/welcomed').writeAsString('1');

        boot = await runTestBootstrap(authRepo: authRepo);
        if (boot.appSessionBloc.state.status != AppSessionStatus.ready) {
          await boot.appSessionBloc.stream.firstWhere(
            (s) => s.status == AppSessionStatus.ready,
          );
        }
      });

      await tester.pumpWidget(
        PrayerApp(bootstrapResult: boot, schedulePeriodicRefresh: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Profile is ready. Suppose reminder 99 does NOT exist in this profile.
      expect(boot.appSessionBloc.isValidReminderId(99), isFalse);

      // Save reminder 42 in this profile
      const validReminder = Reminder(
        id: 42,
        hour: 7,
        minute: 30,
        weekdays: [1, 2],
      );
      await tester.runAsync(() async {
        await boot.appSessionBloc.activeAppBloc!.saveReminder(validReminder);
      });
      expect(boot.appSessionBloc.isValidReminderId(42), isTrue);

      // Send invalid reminder 99
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            device.channel.name,
            device.channel.codec.encodeMethodCall(
              const MethodCall('openPrayer', 99),
            ),
            (data) {},
          );
      await tester.pumpAndSettle();

      // Should NOT navigate to prayer for invalid reminder 99
      expect(find.byType(SessionPage), findsNothing);

      // Send valid reminder 42
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            device.channel.name,
            device.channel.codec.encodeMethodCall(
              const MethodCall('openPrayer', 42),
            ),
            (data) {},
          );
      await tester.pumpAndSettle();

      // Should navigate to prayer session
      expect(find.byType(SessionPage), findsOneWidget);
    },
  );
}
