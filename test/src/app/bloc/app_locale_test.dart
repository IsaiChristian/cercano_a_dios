import 'dart:io';

import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePrayerRepository implements PrayerRepository {
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
  Future<Either<Failure, List<Reminder>>> reminders() async => const Right([]);
  @override
  Future<Either<Failure, void>> reset() async => const Right(null);
  @override
  Future<Either<Failure, List<PrayerSession>>> sessions() async =>
      const Right([]);
  @override
  Future<Either<Failure, void>> saveReminder(Reminder reminder) async =>
      const Right(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalStorageService storage;
  late _FakePrayerRepository repository;
  late DeviceServices device;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('locale_test_');
    storage = LocalStorageService(tempDir.path);
    repository = _FakePrayerRepository();
    device = DeviceServices();
  });

  tearDown(() async {
    await device.interruptions.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalStorageService language persistence', () {
    test('readLanguageCode returns null when not set', () async {
      expect(await storage.readLanguageCode(), isNull);
      expect(storage.readLanguageCodeSync(), isNull);
    });

    test('writeLanguageCode persists and reads back language code', () async {
      await storage.writeLanguageCode('es');
      expect(await storage.readLanguageCode(), 'es');
      expect(storage.readLanguageCodeSync(), 'es');

      await storage.writeLanguageCode('en');
      expect(await storage.readLanguageCode(), 'en');
      expect(storage.readLanguageCodeSync(), 'en');
    });

    test('writeLanguageCodeSync persists synchronously', () {
      storage.writeLanguageCodeSync('es');
      expect(storage.readLanguageCodeSync(), 'es');
    });
  });

  group('AppBloc initial locale resolution on first launch', () {
    test('defaults to Spanish on Spanish device locale', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('es'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('es'));
    });

    test('defaults to Spanish on Spanish regional device locale', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('es', 'MX'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('es'));
    });

    test('defaults to English on English device locale', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('en'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('en'));
    });

    test('defaults to English on English regional device locale', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('en', 'GB'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('en'));
    });

    test('falls back to English on unsupported device locale', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('fr', 'FR'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('en'));
    });

    test('respects explicit initialLocale parameter', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        initialLocale: const Locale('es'),
        deviceLocale: const Locale('en'),
      );
      addTearDown(app.close);

      expect(app.state.locale, const Locale('es'));
    });
  });

  group('AppBloc language change and persistence across restarts', () {
    test(
      'setLocale persists explicit choice and emits updated state',
      () async {
        final app = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('en'),
        );
        addTearDown(app.close);

        expect(app.state.locale, const Locale('en'));

        await app.setLocale(const Locale('es'));
        expect(app.state.locale, const Locale('es'));
        expect(await storage.readLanguageCode(), 'es');

        await app.setLocale(const Locale('en'));
        expect(app.state.locale, const Locale('en'));
        expect(await storage.readLanguageCode(), 'en');
      },
    );

    test(
      'setLocale normalizes unsupported locale to English and persists it',
      () async {
        final app = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('es'),
        );
        addTearDown(app.close);

        await app.setLocale(const Locale('de'));
        expect(app.state.locale, const Locale('en'));
        expect(await storage.readLanguageCode(), 'en');
      },
    );

    test(
      'persisted Spanish choice survives restart and overrides English device',
      () async {
        final app1 = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('en'),
        );
        expect(app1.state.locale, const Locale('en'));
        await app1.setLocale(const Locale('es'));
        await app1.close();

        // Restart app with English device locale
        final app2 = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('en'),
        );
        addTearDown(app2.close);

        expect(app2.state.locale, const Locale('es'));
      },
    );

    test(
      'persisted English choice survives restart and overrides Spanish device',
      () async {
        final app1 = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('es'),
        );
        expect(app1.state.locale, const Locale('es'));
        await app1.setLocale(const Locale('en'));
        await app1.close();

        // Restart app with Spanish device locale
        final app2 = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('es'),
        );
        addTearDown(app2.close);

        expect(app2.state.locale, const Locale('en'));
      },
    );

    test(
      'invalid persisted code on disk falls back to device locale',
      () async {
        final languageFile = File(storage.pathFor('language'));
        await languageFile.writeAsString('unsupported_xyz');

        final app = AppBloc(
          repository: repository,
          device: device,
          storage: storage,
          deviceLocale: const Locale('es'),
        );
        addTearDown(app.close);

        expect(app.state.locale, const Locale('es'));
      },
    );

    test('app.refresh reloads persisted locale if changed on disk', () async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('en'),
      );
      addTearDown(app.close);
      expect(app.state.locale, const Locale('en'));

      await storage.writeLanguageCode('es');
      await app.refresh();

      expect(app.state.locale, const Locale('es'));
    });
  });
}
