import 'dart:async';

import 'package:cercano_a_dios/core/di/authenticated_app_factory.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_session_event.dart';
import 'app_session_state.dart';

export 'app_session_event.dart';
export 'app_session_state.dart';

/// Coordinates the lifecycle of user-scoped [AppBloc] instances and native resources.
class AppSessionBloc extends Bloc<AppSessionEvent, AppSessionState> {
  final AuthenticatedAppFactory appFactory;
  final DeviceServices device;

  AppBloc? _currentAppBloc;
  AuthUser? _currentUser;
  bool _isTransitioning = false;
  int _latestTicket = 0;

  AppSessionBloc({required this.appFactory, required this.device})
    : super(const AppSessionState.signedOut()) {
    on<AppSessionUserChanged>(_onUserChanged);
    on<AppSessionRetryRequested>(_onRetryRequested);
  }

  /// The active [AppBloc] for the ready session, or `null` if transitioning or signed out.
  AppBloc? get activeAppBloc =>
      (_isTransitioning || state.status != AppSessionStatus.ready)
      ? null
      : _currentAppBloc;

  @override
  void add(AppSessionEvent event) {
    _isTransitioning = true;
    final ticket = ++_latestTicket;
    if (event is AppSessionUserChanged) {
      super.add(event.withTicket(ticket));
    } else if (event is AppSessionRetryRequested) {
      super.add(event.withTicket(ticket));
    } else {
      super.add(event);
    }
  }

  /// Checks whether a [reminderId] belongs to the currently ready profile.
  ///
  /// Rejects stale reminder IDs from former profiles or unauthenticated states.
  bool isValidReminderId(int reminderId) {
    if (state.status != AppSessionStatus.ready || activeAppBloc == null) {
      return false;
    }
    return activeAppBloc!.state.reminders.any((r) => r.id == reminderId);
  }

  Future<void> _onUserChanged(
    AppSessionUserChanged event,
    Emitter<AppSessionState> emit,
  ) async {
    final ticket = event.ticket ?? ++_latestTicket;

    final oldAppBloc = _currentAppBloc;
    _currentAppBloc = null;
    _currentUser = event.user;

    // Independently stop device effects and close old user resources
    await _teardownSession(oldAppBloc);

    if (ticket != _latestTicket) return;

    if (event.user == null) {
      _isTransitioning = false;
      emit(const AppSessionState.signedOut());
      return;
    }

    final user = event.user!;
    emit(AppSessionState.loading(userId: user.id));

    try {
      final appBloc = await appFactory.create(user);
      if (ticket != _latestTicket) {
        await appBloc.close();
        return;
      }

      _currentAppBloc = appBloc;

      // Restore enabled reminders independently
      await _restoreReminders(appBloc, ticket);
      if (ticket != _latestTicket) return;

      _isTransitioning = false;
      emit(AppSessionState.ready(userId: user.id));
    } catch (error) {
      if (ticket != _latestTicket) return;
      _currentAppBloc = null;
      _isTransitioning = false;
      final failure = error is Failure ? error : Failure(error.toString());
      emit(AppSessionState.failure(userId: user.id, failure: failure));
    }
  }

  Future<void> _onRetryRequested(
    AppSessionRetryRequested event,
    Emitter<AppSessionState> emit,
  ) async {
    if (_currentUser == null || state.status != AppSessionStatus.failure) {
      _isTransitioning = false;
      return;
    }

    final user = _currentUser!;
    final ticket = event.ticket ?? ++_latestTicket;

    final oldAppBloc = _currentAppBloc;
    _currentAppBloc = null;
    await _teardownSession(oldAppBloc);

    if (ticket != _latestTicket) return;

    emit(AppSessionState.loading(userId: user.id));

    try {
      final appBloc = await appFactory.create(user);
      if (ticket != _latestTicket) {
        await appBloc.close();
        return;
      }

      _currentAppBloc = appBloc;
      await _restoreReminders(appBloc, ticket);
      if (ticket != _latestTicket) return;

      _isTransitioning = false;
      emit(AppSessionState.ready(userId: user.id));
    } catch (error) {
      if (ticket != _latestTicket) return;
      _currentAppBloc = null;
      _isTransitioning = false;
      final failure = error is Failure ? error : Failure(error.toString());
      emit(AppSessionState.failure(userId: user.id, failure: failure));
    }
  }

  Future<void> _teardownSession(AppBloc? appToClose) async {
    try {
      await device.stopPlayback();
    } catch (_) {}
    try {
      await device.stopAlarm();
    } catch (_) {}
    try {
      await device.cancelAll();
    } catch (_) {}
    if (appToClose != null) {
      try {
        await appToClose.close();
      } catch (_) {}
    }
  }

  Future<void> _restoreReminders(AppBloc appBloc, int ticket) async {
    final reminders = appBloc.state.reminders;
    for (final reminder in reminders) {
      if (ticket != _latestTicket) return;
      if (reminder.enabled) {
        try {
          await device.schedule(reminder);
        } catch (error) {
          appBloc.report(error);
        }
      }
    }
  }

  @override
  Future<void> close() async {
    final current = _currentAppBloc;
    _currentAppBloc = null;
    _isTransitioning = false;
    if (current != null) {
      await current.close();
    }
    return super.close();
  }
}
