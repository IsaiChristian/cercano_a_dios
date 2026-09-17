import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/auth_repository.dart';
import 'package:cercano_a_dios/domain/repositories/prayer_repository.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/settings/presentation/pages/settings_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;

  @override
  Future<Either<Failure, AuthUser?>> currentUser() async => const Right(null);

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCalls++;
    return const Right(null);
  }
}

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
  late _FakeAuthRepository authRepository;
  late AuthBloc authBloc;
  late AppBloc app;
  late GoRouter router;

  setUp(() {
    authRepository = _FakeAuthRepository();
    authBloc = AuthBloc(authRepository: authRepository);
    app = AppBloc(
      repository: _FakePrayerRepository(),
      device: DeviceServices(),
      storage: const LocalStorageService('unused'),
    );
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsPage(app: app),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await app.close();
    await app.device.interruptions.close();
    await authBloc.close();
  });

  testWidgets(
    'settings page displays Sign out button and dispatches AuthSignOutRequested',
    (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: app),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: MaterialApp.router(
            theme: appTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final signOutFinder = find.widgetWithText(OutlinedButton, 'Sign out');
      await tester.scrollUntilVisible(signOutFinder, 200);
      expect(signOutFinder, findsOneWidget);

      await tester.tap(signOutFinder);
      await tester.pumpAndSettle();

      expect(authRepository.signOutCalls, 1);
    },
  );
}
