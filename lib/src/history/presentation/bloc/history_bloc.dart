import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/prayer_session.dart';
import '../../../../domain/repositories/prayer_repository.dart';

part 'history_state.dart';
part 'history_event.dart';

/// Feature-scoped BLoC managing prayer session history and journal entries.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final PrayerRepository repository;

  HistoryBloc({required this.repository}) : super(const HistoryState()) {
    on<HistoryLoadRequested>(_onLoadRequested);
    on<HistorySessionCompleted>(_onSessionCompleted);
    on<HistorySessionDeleted>(_onSessionDeleted);
    on<HistoryAudioDeleted>(_onAudioDeleted);
    on<HistoryAllAudioDeleted>(_onAllAudioDeleted);
  }

  Future<void> loadSessions() {
    final result = Completer<void>();
    add(HistoryLoadRequested(result));
    return result.future;
  }

  Future<bool> completeSession(PrayerSession session) {
    final result = Completer<bool>();
    add(HistorySessionCompleted(session, result));
    return result.future;
  }

  Future<void> deleteSession(String id) {
    final result = Completer<void>();
    add(HistorySessionDeleted(id, result));
    return result.future;
  }

  Future<void> syncAudioDeleted(String id) {
    final result = Completer<void>();
    add(HistoryAudioDeleted(id, result));
    return result.future;
  }

  Future<void> syncAllAudioDeleted() {
    final result = Completer<void>();
    add(HistoryAllAudioDeleted(result));
    return result.future;
  }

  Future<void> _onLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(loading: true));
    final result = await repository.sessions();
    result.fold(
      (failure) {
        emit(state.copyWith(loading: false, error: failure.message));
        event.result?.complete();
      },
      (sessions) {
        emit(
          state.copyWith(sessions: sessions, loading: false, clearError: true),
        );
        event.result?.complete();
      },
    );
  }

  Future<void> _onSessionCompleted(
    HistorySessionCompleted event,
    Emitter<HistoryState> emit,
  ) async {
    final completeResult = await repository.complete(event.session);
    await completeResult.fold(
      (failure) async {
        emit(state.copyWith(error: failure.message));
        event.result?.complete(false);
      },
      (_) async {
        final sessionsResult = await repository.sessions();
        sessionsResult.fold(
          (failure) => emit(state.copyWith(error: failure.message)),
          (sessions) =>
              emit(state.copyWith(sessions: sessions, clearError: true)),
        );
        event.result?.complete(true);
      },
    );
  }

  Future<void> _onSessionDeleted(
    HistorySessionDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final deleteResult = await repository.deleteSession(event.id);
    await deleteResult.fold(
      (failure) async {
        emit(state.copyWith(error: failure.message));
        event.result?.complete();
      },
      (_) async {
        final sessionsResult = await repository.sessions();
        sessionsResult.fold(
          (failure) => emit(state.copyWith(error: failure.message)),
          (sessions) =>
              emit(state.copyWith(sessions: sessions, clearError: true)),
        );
        event.result?.complete();
      },
    );
  }

  Future<void> _onAudioDeleted(
    HistoryAudioDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final sessionsResult = await repository.sessions();
    sessionsResult.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (sessions) => emit(state.copyWith(sessions: sessions, clearError: true)),
    );
    event.result?.complete();
  }

  Future<void> _onAllAudioDeleted(
    HistoryAllAudioDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final sessionsResult = await repository.sessions();
    sessionsResult.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (sessions) => emit(state.copyWith(sessions: sessions, clearError: true)),
    );
    event.result?.complete();
  }
}
