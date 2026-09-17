import 'dart:io';

import 'package:cercano_a_dios/core/config/auth_config.dart';
import 'package:cercano_a_dios/core/di/bootstrap.dart';
import 'package:cercano_a_dios/data/repositories/appwrite_auth_repository.dart';
import 'package:cercano_a_dios/data/repositories/fake_auth_repository.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TestDeviceServices extends DeviceServices {
  final Directory tempDir;

  _TestDeviceServices(this.tempDir);

  @override
  Future<String> directory() async => tempDir.path;

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> stopAlarm() async {}

  @override
  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;
  late _TestDeviceServices testDevice;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bootstrap_test_');
    testDevice = _TestDeviceServices(tempDir);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return tempDir.path;
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('explicit fake backend selects FakeAuthRepository', () async {
    final config = AuthConfig.fromMap(const {'AUTH_BACKEND': 'fake'});
    final result = await bootstrap(config: config, deviceServices: testDevice);

    expect(result.authRepository, isA<FakeAuthRepository>());
    expect(result.authBloc, isA<AuthBloc>());
    expect(result.appSessionBloc, isA<AppSessionBloc>());

    await result.dispose();
  });

  test('explicit Appwrite config selects AppwriteAuthRepository', () async {
    final config = AuthConfig.fromMap(const {
      'AUTH_BACKEND': 'appwrite',
      'APPWRITE_ENDPOINT': 'https://example.com/v1',
      'APPWRITE_PROJECT_ID': 'proj_123',
    });
    final result = await bootstrap(config: config, deviceServices: testDevice);

    expect(result.authRepository, isA<AppwriteAuthRepository>());
    await result.dispose();
  });

  test('missing Appwrite configuration falls back to FakeAuthRepository', () async {
    final result = await bootstrap(
      config: AuthConfig.fromMap(const {}),
      deviceServices: testDevice,
    );

    expect(result.authRepository, isA<FakeAuthRepository>());
    expect(result.authBloc, isA<AuthBloc>());
    expect(result.appSessionBloc, isA<AppSessionBloc>());

    await result.dispose();
  });

  test(
    'AuthBloc sign-in events drive AppSessionBloc profile lifecycle',
    () async {
      final config = AuthConfig.fromMap(const {'AUTH_BACKEND': 'fake'});
      final result = await bootstrap(
        config: config,
        deviceServices: testDevice,
      );

      // Initial state on cold start
      expect(result.appSessionBloc.state.status, AppSessionStatus.signedOut);

      // Sign in with the seeded demo user
      result.authBloc.add(
        const AuthSignInRequested(
          email: 'demo@cercanoadios.app',
          password: 'password123',
        ),
      );

      // Wait for AppSessionBloc to reach ready state
      await expectLater(
        result.appSessionBloc.stream,
        emitsThrough(
          predicate<AppSessionState>(
            (s) =>
                s.status == AppSessionStatus.ready &&
                s.userId == 'demo_user_id',
          ),
        ),
      );

      expect(result.appSessionBloc.activeAppBloc, isNotNull);

      // Sign out
      result.authBloc.add(const AuthSignOutRequested());

      await expectLater(
        result.appSessionBloc.stream,
        emitsThrough(
          predicate<AppSessionState>(
            (s) => s.status == AppSessionStatus.signedOut,
          ),
        ),
      );

      expect(result.appSessionBloc.activeAppBloc, isNull);

      await result.dispose();
    },
  );
}
