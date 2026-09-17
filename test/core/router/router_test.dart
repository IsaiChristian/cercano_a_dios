import 'package:cercano_a_dios/core/router/router.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockAppSessionBloc extends Mock implements AppSessionBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockAppSessionBloc mockSessionBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockSessionBloc = MockAppSessionBloc();

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockSessionBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestWidget({required router}) {
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: MaterialApp.router(
        theme: appTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets(
    'routes to /loading when auth state is unknown (checking session)',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(
          sessionStatus: AuthSessionStatus.unknown,
          operationStatus: AuthOperationStatus.checking,
        ),
      );
      when(
        () => mockSessionBloc.state,
      ).thenReturn(const AppSessionState.signedOut());

      final router = createRouter(
        authBloc: mockAuthBloc,
        appSessionBloc: mockSessionBloc,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pump();

      expect(find.byType(ProfileLoadingPage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/loading');
    },
  );

  testWidgets(
    'routes to /session-check-failed when cold start session check fails',
    (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(
          sessionStatus: AuthSessionStatus.unknown,
          operationStatus: AuthOperationStatus.failed,
          failure: Failure('network error'),
        ),
      );
      when(
        () => mockSessionBloc.state,
      ).thenReturn(const AppSessionState.signedOut());

      final router = createRouter(
        authBloc: mockAuthBloc,
        appSessionBloc: mockSessionBloc,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pump();

      expect(find.byType(SessionCheckFailedPage), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/session-check-failed',
      );
    },
  );

  testWidgets('routes to /auth when unauthenticated', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(sessionStatus: AuthSessionStatus.unauthenticated),
    );
    when(
      () => mockSessionBloc.state,
    ).thenReturn(const AppSessionState.signedOut());

    final router = createRouter(
      authBloc: mockAuthBloc,
      appSessionBloc: mockSessionBloc,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(buildTestWidget(router: router));
    await tester.pump();

    expect(find.byType(AuthPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/auth');
  });

  testWidgets('routes to /profile-error when profile opening fails', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'u1@test.com');
    when(() => mockAuthBloc.state).thenReturn(
      const AuthState(
        sessionStatus: AuthSessionStatus.authenticated,
        user: user,
      ),
    );
    when(() => mockSessionBloc.state).thenReturn(
      const AppSessionState.failure(
        userId: 'u1',
        failure: Failure('disk full'),
      ),
    );

    final router = createRouter(
      authBloc: mockAuthBloc,
      appSessionBloc: mockSessionBloc,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(buildTestWidget(router: router));
    await tester.pump();

    expect(find.byType(ProfileErrorPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/profile-error');
  });

  testWidgets(
    'matching-user guard routes to /loading if session profile belongs to different user',
    (tester) async {
      const activeUser = AuthUser(id: 'user_b', email: 'b@test.com');
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(
          sessionStatus: AuthSessionStatus.authenticated,
          user: activeUser,
        ),
      );
      // Session state has not transitioned yet or still holds former user's profile
      when(
        () => mockSessionBloc.state,
      ).thenReturn(const AppSessionState.ready(userId: 'user_a'));

      final router = createRouter(
        authBloc: mockAuthBloc,
        appSessionBloc: mockSessionBloc,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(buildTestWidget(router: router));
      await tester.pump();

      expect(router.routeInformationProvider.value.uri.path, '/loading');
    },
  );
}
