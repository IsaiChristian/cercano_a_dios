import 'package:equatable/equatable.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';

/// Status of the local active user session and profile.
enum AppSessionStatus { signedOut, loading, ready, failure }

/// State reflecting the active local profile lifecycle.
class AppSessionState extends Equatable {
  final AppSessionStatus status;
  final String? userId;
  final Failure? failure;

  const AppSessionState({required this.status, this.userId, this.failure});

  const AppSessionState.signedOut() : this(status: AppSessionStatus.signedOut);

  const AppSessionState.loading({required String userId})
    : this(status: AppSessionStatus.loading, userId: userId);

  const AppSessionState.ready({required String userId})
    : this(status: AppSessionStatus.ready, userId: userId);

  const AppSessionState.failure({
    required String userId,
    required Failure failure,
  }) : this(status: AppSessionStatus.failure, userId: userId, failure: failure);

  @override
  List<Object?> get props => [status, userId, failure];
}
