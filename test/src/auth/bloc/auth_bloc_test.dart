import 'package:bloc_test/bloc_test.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/failures/auth_failure.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/domain/repositories/auth_repository.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  Either<Failure, AuthUser?> currentUserResult = const Right(null);
  Either<Failure, AuthUser> signInResult = const Left(
    AuthFailure(AuthFailureReason.unknown),
  );
  Either<Failure, AuthUser> signUpResult = const Left(
    AuthFailure(AuthFailureReason.unknown),
  );
  Either<Failure, void> signOutResult = const Right(null);

  int currentUserCallCount = 0;
  int signInCallCount = 0;
  int signUpCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<Either<Failure, AuthUser?>> currentUser() async {
    currentUserCallCount++;
    return currentUserResult;
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    return signInResult;
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    signUpCallCount++;
    return signUpResult;
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCallCount++;
    return signOutResult;
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthBloc authBloc;

  const user = AuthUser(
    id: 'user_id',
    email: 'test@example.com',
    name: 'Test User',
  );
  const authFailure = AuthFailure(AuthFailureReason.network);

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authBloc = AuthBloc(authRepository: fakeRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is correct', () {
      expect(authBloc.state.sessionStatus, AuthSessionStatus.unknown);
      expect(authBloc.state.operationStatus, AuthOperationStatus.idle);
      expect(authBloc.state.user, isNull);
      expect(authBloc.state.failure, isNull);
    });

    group('AuthSessionCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits checking then authenticated when currentUser succeeds with a user',
        build: () {
          fakeRepository.currentUserResult = const Right(user);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSessionCheckRequested()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.checking,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.idle,
            user: user,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits checking then unauthenticated when currentUser succeeds with null',
        build: () {
          fakeRepository.currentUserResult = const Right(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSessionCheckRequested()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.checking,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.unauthenticated,
            operationStatus: AuthOperationStatus.idle,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits checking then failed and keeps sessionStatus unknown on failure',
        build: () {
          fakeRepository.currentUserResult = const Left(authFailure);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthSessionCheckRequested()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.checking,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.failed,
            failure: authFailure,
          ),
        ],
      );
    });

    group('AuthSignInRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits submitting then authenticated on success',
        build: () {
          fakeRepository.signInResult = const Right(user);
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignInRequested(email: 'test', password: 'password'),
        ),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.submitting,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.idle,
            user: user,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits submitting then failed on failure',
        build: () {
          fakeRepository.signInResult = const Left(authFailure);
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignInRequested(email: 'test', password: 'password'),
        ),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.submitting,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.failed,
            failure: authFailure,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'ignores duplicate submissions',
        build: () {
          fakeRepository.signInResult = const Right(user);
          return authBloc;
        },
        seed: () => const AuthState(
          sessionStatus: AuthSessionStatus.unauthenticated,
          operationStatus: AuthOperationStatus.submitting,
        ),
        act: (bloc) => bloc.add(
          const AuthSignInRequested(email: 'test', password: 'password'),
        ),
        expect: () => [],
      );
    });

    group('AuthSignUpRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits submitting then authenticated on success',
        build: () {
          fakeRepository.signUpResult = const Right(user);
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignUpRequested(
            email: 'test',
            password: 'password',
            name: 'name',
          ),
        ),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.submitting,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.idle,
            user: user,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits submitting then failed on failure',
        build: () {
          fakeRepository.signUpResult = const Left(authFailure);
          return authBloc;
        },
        act: (bloc) => bloc.add(
          const AuthSignUpRequested(
            email: 'test',
            password: 'password',
            name: 'name',
          ),
        ),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.submitting,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.failed,
            failure: authFailure,
          ),
        ],
      );
    });

    group('AuthSignOutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits submitting then unauthenticated on success',
        build: () {
          fakeRepository.signOutResult = const Right(null);
          return authBloc;
        },
        seed: () => const AuthState(
          sessionStatus: AuthSessionStatus.authenticated,
          operationStatus: AuthOperationStatus.idle,
          user: user,
        ),
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.submitting,
            user: user,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.unauthenticated,
            operationStatus: AuthOperationStatus.idle,
            user: null,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits submitting then failed and retains user on failure',
        build: () {
          fakeRepository.signOutResult = const Left(authFailure);
          return authBloc;
        },
        seed: () => const AuthState(
          sessionStatus: AuthSessionStatus.authenticated,
          operationStatus: AuthOperationStatus.idle,
          user: user,
        ),
        act: (bloc) => bloc.add(const AuthSignOutRequested()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.submitting,
            user: user,
          ),
          const AuthState(
            sessionStatus: AuthSessionStatus.authenticated,
            operationStatus: AuthOperationStatus.failed,
            user: user,
            failure: authFailure,
          ),
        ],
      );
    });

    group('AuthFailureDismissed', () {
      blocTest<AuthBloc, AuthState>(
        'clears failure and sets status to idle',
        build: () => authBloc,
        seed: () => const AuthState(
          sessionStatus: AuthSessionStatus.unknown,
          operationStatus: AuthOperationStatus.failed,
          failure: authFailure,
        ),
        act: (bloc) => bloc.add(const AuthFailureDismissed()),
        expect: () => [
          const AuthState(
            sessionStatus: AuthSessionStatus.unknown,
            operationStatus: AuthOperationStatus.idle,
            failure: null,
          ),
        ],
      );
    });
  });
}
