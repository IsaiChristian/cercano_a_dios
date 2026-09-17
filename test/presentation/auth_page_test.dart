import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cercano_a_dios/domain/failures/auth_failure.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/pages/auth_page.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthSessionCheckRequested {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthState());
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildTestApp() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const AuthPage(),
      ),
    );
  }

  testWidgets('renders sign-in mode by default and toggles to create account', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Your name'), findsNothing);

    await tester.tap(find.text('Don\'t have an account? Create one.'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsWidgets);
    expect(find.text('Your name'), findsOneWidget);
  });

  testWidgets('dispatches AuthSignInRequested with valid inputs', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verify(
      () => authBloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
    ).called(1);
  });

  testWidgets('shows loading state and disables inputs when submitting', (
    tester,
  ) async {
    when(() => authBloc.state).thenReturn(
      const AuthState(operationStatus: AuthOperationStatus.submitting),
    );
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Please wait...'), findsOneWidget);
    final emailField = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(emailField.enabled, isFalse);
  });

  testWidgets('shows localized snackbar on auth failure', (tester) async {
    when(() => authBloc.stream).thenAnswer(
      (_) => Stream.value(
        const AuthState(
          operationStatus: AuthOperationStatus.failed,
          failure: AuthFailure(AuthFailureReason.invalidCredentials),
        ),
      ),
    );
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('The email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('password visibility toggle', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();



    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();


  });

  testWidgets('validation prevents dispatching event with invalid inputs', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('This field is required.'), findsWidgets);
    verifyNever(() => authBloc.add(any()));
  });
}
