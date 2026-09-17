import 'dart:io';

import 'package:cercano_a_dios/core/di/authenticated_app_factory.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempBase;
  late DeviceServices device;
  late AuthenticatedAppFactory factory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempBase = await Directory.systemTemp.createTemp('auth_app_factory_test_');
    device = DeviceServices();
    factory = AuthenticatedAppFactory(device: device, baseRoot: tempBase.path);
  });

  tearDown(() async {
    if (await tempBase.exists()) {
      await tempBase.delete(recursive: true);
    }
  });

  group('AuthenticatedAppFactory', () {
    const testUser = AuthUser(id: 'test-user-1', email: 'test@example.com');

    test('creates AppBloc scoped to the resolved user root', () async {
      final app = await factory.create(testUser);

      expect(app.state.loading, isFalse);
      expect(app.storage.root, contains('profiles'));
      expect(await Directory(app.storage.root).exists(), isTrue);

      await app.close();
    });

    test(
      'closing AppBloc closes database but keeps device interruptions open',
      () async {
        final app = await factory.create(testUser);

        // Verify interruptions controller is open
        expect(device.interruptions.isClosed, isFalse);

        await app.close();

        // Interruptions stream controller should still be open for subsequent sessions
        expect(device.interruptions.isClosed, isFalse);
      },
    );

    test('creates separate isolated AppBlocs for different users', () async {
      const userA = AuthUser(id: 'user-a', email: 'a@example.com');
      const userB = AuthUser(id: 'user-b', email: 'b@example.com');

      final appA = await factory.create(userA);
      final appB = await factory.create(userB);

      expect(appA.storage.root, isNot(equals(appB.storage.root)));

      // Save a reminder in A
      const reminder = Reminder(id: 42, hour: 8, minute: 0, weekdays: [1]);
      await appA.saveReminder(reminder);

      expect(appA.state.reminders.any((r) => r.id == 42), isTrue);
      expect(appB.state.reminders.any((r) => r.id == 42), isFalse);

      await appA.close();
      await appB.close();
    });
  });
}
