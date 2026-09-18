import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cercano_a_dios/domain/repositories/auth_repository.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_event.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required this._authRepository})
    : super(const AuthState()) {
    on<AuthSessionCheckRequested>(_onAuthSessionCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthFailureDismissed>(_onAuthFailureDismissed);
  }

  Future<void> _onAuthSessionCheckRequested(
    AuthSessionCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        operationStatus: AuthOperationStatus.checking,
        failure: () => null,
      ),
    );

    final result = await _authRepository.currentUser();

    result.fold(
      (failure) => emit(
        state.copyWith(
          operationStatus: AuthOperationStatus.failed,
          failure: () => failure,
          // Keep sessionStatus as unknown on initial check failure
        ),
      ),
      (user) {
        if (user != null) {
          emit(
            state.copyWith(
              sessionStatus: AuthSessionStatus.authenticated,
              operationStatus: AuthOperationStatus.idle,
              user: () => user,
            ),
          );
        } else {
          emit(
            state.copyWith(
              sessionStatus: AuthSessionStatus.unauthenticated,
              operationStatus: AuthOperationStatus.idle,
              user: () => null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.operationStatus == AuthOperationStatus.submitting) return;

    emit(
      state.copyWith(
        operationStatus: AuthOperationStatus.submitting,
        failure: () => null,
      ),
    );

    final result = await _authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          operationStatus: AuthOperationStatus.failed,
          failure: () => failure,
        ),
      ),
      (user) => emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.authenticated,
          operationStatus: AuthOperationStatus.idle,
          user: () => user,
        ),
      ),
    );
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.operationStatus == AuthOperationStatus.submitting) return;

    emit(
      state.copyWith(
        operationStatus: AuthOperationStatus.submitting,
        failure: () => null,
      ),
    );

    final result = await _authRepository.signUpWithEmail(
      email: event.email,
      password: event.password,
      name: event.name,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          operationStatus: AuthOperationStatus.failed,
          failure: () => failure,
        ),
      ),
      (user) => emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.authenticated,
          operationStatus: AuthOperationStatus.idle,
          user: () => user,
        ),
      ),
    );
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.operationStatus == AuthOperationStatus.submitting) return;

    emit(
      state.copyWith(
        operationStatus: AuthOperationStatus.submitting,
        failure: () => null,
      ),
    );

    final result = await _authRepository.signOut();

    result.fold(
      (failure) => emit(
        state.copyWith(
          operationStatus: AuthOperationStatus.failed,
          failure: () => failure,
          // Retain authenticated user on sign-out failure
        ),
      ),
      (_) => emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.unauthenticated,
          operationStatus: AuthOperationStatus.idle,
          user: () => null,
        ),
      ),
    );
  }

  void _onAuthFailureDismissed(
    AuthFailureDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(
      state.copyWith(
        operationStatus: AuthOperationStatus.idle,
        failure: () => null,
      ),
    );
  }
}
