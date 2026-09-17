import 'dart:io';

import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/settings/presentation/pages/settings_page.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
  late Directory tempDir;
  late LocalStorageService storage;
  late _FakePrayerRepository repository;
  late DeviceServices device;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_page_test_');
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

  Widget buildApp(AppBloc app, GoRouter router) {
    return BlocProvider<AppBloc>.value(
      value: app,
      child: MaterialApp.router(
        theme: appTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  GoRouter createTestRouter(AppBloc app) {
    return GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => BlocBuilder<AppBloc, AppState>(
            bloc: app,
            builder: (context, appState) => Localizations.override(
              context: context,
              locale: appState.locale,
              child: SettingsPage(app: app),
            ),
          ),
        ),
      ],
    );
  }

  testWidgets(
    'settings page displays English on English device and persists Spanish selection',
    (tester) async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('en'),
      );
      addTearDown(app.close);

      final router = createTestRouter(app);
      addTearDown(router.dispose);

      await tester.pumpWidget(buildApp(app, router));
      await tester.pumpAndSettle();

      // Verify English labels
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Open language dropdown
      final dropdown = find.byKey(const Key('languageDropdown'));
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap 'Spanish' option from menu (in English locale, the Spanish option label is 'Spanish')
      final spanishOption = find.text('Spanish').last;
      await tester.tap(spanishOption);
      await tester.pumpAndSettle();

      // Verify BLoC and storage updated to Spanish
      expect(app.state.locale, const Locale('es'));
      expect(storage.readLanguageCodeSync(), 'es');

      // Verify UI updated to Spanish strings
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    },
  );

  testWidgets(
    'settings page displays Spanish by default on Spanish device and persists English selection',
    (tester) async {
      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('es'),
      );
      addTearDown(app.close);

      final router = createTestRouter(app);
      addTearDown(router.dispose);

      await tester.pumpWidget(buildApp(app, router));
      await tester.pumpAndSettle();

      // Verify Spanish labels
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);

      // Open language dropdown
      final dropdown = find.byKey(const Key('languageDropdown'));
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Tap 'Inglés' option from menu (in Spanish locale, the English option label is 'Inglés')
      final englishOption = find.text('Inglés').last;
      await tester.tap(englishOption);
      await tester.pumpAndSettle();

      // Verify BLoC and storage updated to English
      expect(app.state.locale, const Locale('en'));
      expect(storage.readLanguageCodeSync(), 'en');

      // Verify UI updated to English strings
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    },
  );

  testWidgets(
    'settings page respects persisted Spanish preference on English device',
    (tester) async {
      // Pre-persist Spanish choice before app creation
      storage.writeLanguageCodeSync('es');

      final app = AppBloc(
        repository: repository,
        device: device,
        storage: storage,
        deviceLocale: const Locale('en'),
      );
      addTearDown(app.close);

      final router = createTestRouter(app);
      addTearDown(router.dispose);

      await tester.pumpWidget(buildApp(app, router));
      await tester.pumpAndSettle();

      // Displays Spanish due to persisted preference
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    },
  );
}
