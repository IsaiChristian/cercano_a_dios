import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/home/presentation/pages/home_page.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';

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
  testWidgets('home remains readable on a small screen with large text', (
    tester,
  ) async {
    final app = AppBloc(
      repository: _FakePrayerRepository(),
      device: DeviceServices(),
      storage: const LocalStorageService('unused'),
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) => HomePage(app: app),
        ),
      ],
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await app.close();
      await app.device.interruptions.close();
      router.dispose();
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: app,
        child: MaterialApp.router(
          theme: appTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
        ),
      ),
    );
    expect(find.text('Make room\nfor God.'), findsOneWidget);
    final beginMoment = find.text('Begin a moment');
    await tester.scrollUntilVisible(beginMoment, 200);
    expect(beginMoment, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
