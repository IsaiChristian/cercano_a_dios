import 'package:equatable/equatable.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';

/// Base event for [AppSessionBloc].
abstract class AppSessionEvent extends Equatable {
  final int? ticket;

  const AppSessionEvent([this.ticket]);

  @override
  List<Object?> get props => [ticket];
}

/// Dispatched when the active authenticated identity changes (or is cleared).
class AppSessionUserChanged extends AppSessionEvent {
  final AuthUser? user;

  const AppSessionUserChanged(this.user, [super.ticket]);

  AppSessionUserChanged withTicket(int ticket) =>
      AppSessionUserChanged(user, ticket);

  @override
  List<Object?> get props => [user, ticket];
}

/// Retries opening the active profile after a failure.
class AppSessionRetryRequested extends AppSessionEvent {
  const AppSessionRetryRequested([super.ticket]);

  AppSessionRetryRequested withTicket(int ticket) =>
      AppSessionRetryRequested(ticket);
}
