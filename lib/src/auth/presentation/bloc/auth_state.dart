import 'package:equatable/equatable.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';

enum AuthSessionStatus { unknown, authenticated, unauthenticated }

enum AuthOperationStatus { idle, checking, submitting, failed }

class AuthState extends Equatable {
  final AuthSessionStatus sessionStatus;
  final AuthOperationStatus operationStatus;
  final AuthUser? user;
  final Failure? failure;

  const AuthState({
    this.sessionStatus = AuthSessionStatus.unknown,
    this.operationStatus = AuthOperationStatus.idle,
    this.user,
    this.failure,
  });

  AuthState copyWith({
    AuthSessionStatus? sessionStatus,
    AuthOperationStatus? operationStatus,
    AuthUser? Function()? user,
    Failure? Function()? failure,
  }) {
    return AuthState(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      operationStatus: operationStatus ?? this.operationStatus,
      user: user != null ? user() : this.user,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [sessionStatus, operationStatus, user, failure];
}
