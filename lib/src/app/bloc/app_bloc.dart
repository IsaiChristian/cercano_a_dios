import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../domain/entities/prayer.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/prayer_repository.dart';
import '../../../../domain/use_cases/calculate_progress.dart';
import '../../audio/presentation/bloc/audio_bloc.dart';
import '../../history/presentation/bloc/history_bloc.dart';
import '../../reminders/presentation/bloc/reminders_bloc.dart';

export '../../audio/presentation/bloc/audio_bloc.dart';
export '../../history/presentation/bloc/history_bloc.dart';
export '../../reminders/presentation/bloc/reminders_bloc.dart';

part 'app_state.dart';
part 'app_event.dart';

/// Application coordinator for journal state and cross-feature commands.
///
/// Delegates feature concerns to [RemindersBloc], [AudioBloc], and [HistoryBloc].
class AppBloc extends Bloc<AppEvent, AppState> {
  final PrayerRepository repository;
  final DeviceServices device;
  final LocalStorageService storage;
  final Future<void> Function()? closeResources;

  final RemindersBloc remindersBloc;
  final AudioBloc audioBloc;
  final HistoryBloc historyBloc;

  StreamSubscription<RemindersState>? _remindersSub;
  StreamSubscription<AudioState>? _audioSub;
  StreamSubscription<HistoryState>? _historySub;

  AppBloc({
    required this.repository,
    required this.device,
    required this.storage,
    bool onboardingComplete = false,
    this.closeResources,
    RemindersBloc? remindersBloc,
    AudioBloc? audioBloc,
    HistoryBloc? historyBloc,
  }) : remindersBloc =
           remindersBloc ??
           RemindersBloc(repository: repository, device: device),
       audioBloc =
           audioBloc ??
           AudioBloc(device: device, storage: storage, repository: repository),
       historyBloc = historyBloc ?? HistoryBloc(repository: repository),
       super(AppState(loading: true, onboardingComplete: onboardingComplete)) {
    on<AppLocaleChanged>(_onLocaleChanged);
    on<AppRefreshRequested>(_onRefresh);
    on<AppErrorReported>(_onErrorReported);
    on<AppOnboardingCompleted>(_onOnboardingCompleted);
    on<AppDataReset>(_onDataReset);
    on<_AppSessionsUpdated>((e, emit) {
      if (state.sessions != e.sessions) {
        emit(state.copyWith(sessions: e.sessions));
      }
    });
    on<_AppRemindersUpdated>((e, emit) {
      if (state.reminders != e.reminders) {
        emit(state.copyWith(reminders: e.reminders));
      }
    });
    on<_AppAudioBytesUpdated>((e, emit) {
      if (state.audioBytes != e.audioBytes) {
        emit(state.copyWith(audioBytes: e.audioBytes));
      }
    });

    on<AppPrayerCompleted>(_onPrayerCompleted);
    on<AppSessionDeleted>(_onSessionDeleted);
    on<AppAudioDeleted>(_onAudioDeleted);
    on<AppAllAudioDeleted>(_onAllAudioDeleted);
    on<AppReminderSaved>(_onReminderSaved);
    on<AppReminderDeleted>(_onReminderDeleted);
    on<AppReminderSnoozeCancelled>(_onReminderSnoozeCancelled);
    on<AppAudioPlaybackRequested>((e, emit) => playAudio(e.session));
    on<AppAudioPlaybackStopped>((e, emit) => stopPlayback());
    on<AppDeviceSettingsRequested>((e, emit) => openDeviceSettings());
    on<AppAlarmTestRequested>((e, emit) => testAlarm());

    _subscribeToChildren();
  }

  void _subscribeToChildren() {
    _remindersSub = remindersBloc.stream.listen((s) {
      add(_AppRemindersUpdated(s.reminders));
      if (s.error != null) report(s.error!);
    });
    _historySub = historyBloc.stream.listen((s) {
      add(_AppSessionsUpdated(s.sessions));
      if (s.error != null) report(s.error!);
    });
    _audioSub = audioBloc.stream.listen((s) {
      add(_AppAudioBytesUpdated(s.audioBytes));
      if (s.error != null) report(s.error!);
    });
  }

  String get root => storage.root;

  void setLocale(Locale locale) => add(AppLocaleChanged(locale));

  T unwrap<T>(Either<Failure, T> result) =>
      result.fold((Failure failure) => throw failure, (value) => value);

  Future<void> refresh() {
    final result = Completer<void>();
    add(AppRefreshRequested(result));
    return result.future;
  }

  void report(Object error) => add(AppErrorReported(error));

  Future<void> completeOnboarding() {
    final result = Completer<void>();
    add(AppOnboardingCompleted(result));
    return result.future;
  }

  Future<bool> complete(PrayerSession session) {
    final result = Completer<bool>();
    add(AppPrayerCompleted(session, result));
    return result.future;
  }

  Future<void> deleteSession(String id) {
    final result = Completer<void>();
    add(AppSessionDeleted(id, result));
    return result.future;
  }

  Future<void> deleteAudio(String id) {
    final result = Completer<void>();
    add(AppAudioDeleted(id, result));
    return result.future;
  }

  Future<void> deleteAllAudio() {
    final result = Completer<void>();
    add(AppAllAudioDeleted(result));
    return result.future;
  }

  Future<bool> saveReminder(Reminder reminder) {
    final result = Completer<bool>();
    add(AppReminderSaved(reminder, result));
    return result.future;
  }

  Future<void> deleteReminder(int id) {
    final result = Completer<void>();
    add(AppReminderDeleted(id, result));
    return result.future;
  }

  Future<void> cancelReminderSnooze(int id) {
    final result = Completer<void>();
    add(AppReminderSnoozeCancelled(id, result));
    return result.future;
  }

  Future<bool> reset() {
    final result = Completer<bool>();
    add(AppDataReset(result));
    return result.future;
  }

  Future<void> playAudio(PrayerSession session) => audioBloc.playAudio(session);

  Future<void> stopPlayback() => audioBloc.stopPlayback();

  Future<void> openDeviceSettings() => remindersBloc.openSettings();

  Future<void> testAlarm() => remindersBloc.testAlarm();

  Future<void> _onRefresh(
    AppRefreshRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await Future.wait([
        historyBloc.loadSessions(),
        remindersBloc.loadReminders(),
        audioBloc.loadAudioBytes(),
      ]);
      emit(
        state.copyWith(
          sessions: historyBloc.state.sessions,
          reminders: remindersBloc.state.reminders,
          audioBytes: audioBloc.state.audioBytes,
          loading: false,
          clearError: true,
        ),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  void _onLocaleChanged(AppLocaleChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(locale: event.locale, loading: false));
  }

  void _onErrorReported(AppErrorReported event, Emitter<AppState> emit) {
    _emitError(emit, event.error);
  }

  Future<void> _onOnboardingCompleted(
    AppOnboardingCompleted event,
    Emitter<AppState> emit,
  ) async {
    try {
      await storage.completeOnboarding();
      emit(state.copyWith(onboardingComplete: true, loading: false));
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.completeError(error);
    }
  }

  Future<void> _onPrayerCompleted(
    AppPrayerCompleted event,
    Emitter<AppState> emit,
  ) async {
    final success = await historyBloc.completeSession(event.session);
    if (success) {
      await audioBloc.loadAudioBytes();
    }
    final error = historyBloc.state.error ?? audioBloc.state.error;
    emit(
      state.copyWith(
        sessions: historyBloc.state.sessions,
        audioBytes: audioBloc.state.audioBytes,
        error: error,
        clearError: error == null,
      ),
    );
    event.result?.complete(success);
  }

  Future<void> _onSessionDeleted(
    AppSessionDeleted event,
    Emitter<AppState> emit,
  ) async {
    if (audioBloc.state.playingSessionId == event.id) {
      await audioBloc.stopPlayback();
    }
    await historyBloc.deleteSession(event.id);
    await audioBloc.loadAudioBytes();
    final error = historyBloc.state.error ?? audioBloc.state.error;
    emit(
      state.copyWith(
        sessions: historyBloc.state.sessions,
        audioBytes: audioBloc.state.audioBytes,
        error: error,
        clearError: error == null,
      ),
    );
    event.result?.complete();
  }

  Future<void> _onAudioDeleted(
    AppAudioDeleted event,
    Emitter<AppState> emit,
  ) async {
    await audioBloc.deleteAudio(event.id);
    await historyBloc.syncAudioDeleted(event.id);
    final error = audioBloc.state.error ?? historyBloc.state.error;
    emit(
      state.copyWith(
        sessions: historyBloc.state.sessions,
        audioBytes: audioBloc.state.audioBytes,
        error: error,
        clearError: error == null,
      ),
    );
    event.result?.complete();
  }

  Future<void> _onAllAudioDeleted(
    AppAllAudioDeleted event,
    Emitter<AppState> emit,
  ) async {
    final sessionsResult = await repository.sessions();
    await sessionsResult.fold(
      (failure) async {
        _emitError(emit, failure);
        event.result?.complete();
      },
      (freshSessions) async {
        await audioBloc.deleteAllAudio(freshSessions);
        await historyBloc.syncAllAudioDeleted();
        final error = audioBloc.state.error ?? historyBloc.state.error;
        emit(
          state.copyWith(
            sessions: historyBloc.state.sessions,
            audioBytes: audioBloc.state.audioBytes,
            error: error,
            clearError: error == null,
          ),
        );
        event.result?.complete();
      },
    );
  }

  Future<void> _onReminderSaved(
    AppReminderSaved event,
    Emitter<AppState> emit,
  ) async {
    final saved = await remindersBloc.saveReminder(event.reminder);
    emit(
      state.copyWith(
        reminders: remindersBloc.state.reminders,
        error: remindersBloc.state.error,
      ),
    );
    event.result?.complete(saved);
  }

  Future<void> _onReminderDeleted(
    AppReminderDeleted event,
    Emitter<AppState> emit,
  ) async {
    await remindersBloc.deleteReminder(event.id);
    emit(
      state.copyWith(
        reminders: remindersBloc.state.reminders,
        error: remindersBloc.state.error,
      ),
    );
    event.result?.complete();
  }

  Future<void> _onReminderSnoozeCancelled(
    AppReminderSnoozeCancelled event,
    Emitter<AppState> emit,
  ) async {
    try {
      await remindersBloc.cancelSnooze(event.id);
      event.result?.complete();
    } catch (err) {
      _emitError(emit, err);
      event.result?.completeError(err);
    }
  }

  Future<void> _onDataReset(AppDataReset event, Emitter<AppState> emit) async {
    try {
      await audioBloc.stopPlayback();
      await device.cancelAll();
      unwrap(await repository.reset());
      await Future.wait([
        historyBloc.loadSessions(),
        remindersBloc.loadReminders(),
        audioBloc.loadAudioBytes(),
      ]);
      emit(
        state.copyWith(
          sessions: historyBloc.state.sessions,
          reminders: remindersBloc.state.reminders,
          audioBytes: audioBloc.state.audioBytes,
          onboardingComplete: false,
          loading: false,
          clearError: true,
        ),
      );
      event.result?.complete(true);
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete(false);
    }
  }

  void _emitError(Emitter<AppState> emit, Object error) {
    final message = error is Failure
        ? error.message
        : error is String
        ? error
        : error is PlatformException
        ? error.message ?? 'Check your device settings and try again.'
        : 'Something went wrong. Please try again.';
    emit(state.copyWith(error: message, loading: false));
  }

  @override
  Future<void> close() async {
    await _remindersSub?.cancel();
    await _historySub?.cancel();
    await _audioSub?.cancel();
    await Future.wait([
      remindersBloc.close(),
      audioBloc.close(),
      historyBloc.close(),
    ]);
    await super.close();
    await closeResources?.call();
  }
}
