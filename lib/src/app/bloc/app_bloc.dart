import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../domain/entities/prayer.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/prayer_repository.dart';
import '../../../../domain/use_cases/calculate_progress.dart';

part 'app_state.dart';
part 'app_event.dart';

/// Application coordinator for journal state and cross-feature commands.
///
/// All state changes are driven by [AppEvent]s so feature views only rebuild
/// from immutable [AppState] snapshots via BlocBuilder.
class AppBloc extends Bloc<AppEvent, AppState> {
  final PrayerRepository repository;
  final DeviceServices device;
  final LocalStorageService storage;
  final Future<void> Function()? closeResources;

  AppBloc({
    required this.repository,
    required this.device,
    required this.storage,
    bool onboardingComplete = false,
    this.closeResources,
  }) : super(AppState(loading: true, onboardingComplete: onboardingComplete)) {
    on<AppLocaleChanged>(_onLocaleChanged);
    on<AppRefreshRequested>(_onRefresh);
    on<AppErrorReported>(_onErrorReported);
    on<AppOnboardingCompleted>(_onOnboardingCompleted);
    on<AppPrayerCompleted>(_onPrayerCompleted);
    on<AppSessionDeleted>(_onSessionDeleted);
    on<AppAudioDeleted>(_onAudioDeleted);
    on<AppAllAudioDeleted>(_onAllAudioDeleted);
    on<AppReminderSaved>(_onReminderSaved);
    on<AppReminderDeleted>(_onReminderDeleted);
    on<AppReminderSnoozeCancelled>(_onReminderSnoozeCancelled);
    on<AppDataReset>(_onDataReset);
    on<AppAudioPlaybackRequested>(_onAudioPlaybackRequested);
    on<AppAudioPlaybackStopped>(_onAudioPlaybackStopped);
    on<AppDeviceSettingsRequested>(_onDeviceSettingsRequested);
    on<AppAlarmTestRequested>(_onAlarmTestRequested);
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

  Future<void> playAudio(PrayerSession session) {
    add(AppAudioPlaybackRequested(session));
    return Future<void>.value();
  }

  Future<void> stopPlayback() {
    add(AppAudioPlaybackStopped());
    return Future<void>.value();
  }

  Future<void> openDeviceSettings() {
    add(AppDeviceSettingsRequested());
    return Future<void>.value();
  }

  Future<void> testAlarm() {
    add(AppAlarmTestRequested());
    return Future<void>.value();
  }

  Future<void> _onRefresh(
    AppRefreshRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      final sessions = unwrap(await repository.sessions());
      final reminders = unwrap(await repository.reminders());
      final bytes = await storage.audioBytes();
      emit(
        state.copyWith(
          sessions: sessions,
          reminders: reminders,
          audioBytes: bytes,
          loading: false,
        ),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  void _onLocaleChanged(AppLocaleChanged event, Emitter<AppState> emit) {
    emit(
      state.copyWith(
        locale: event.locale,
        loading: false,
      ),
    );
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
      emit(
        state.copyWith(
          onboardingComplete: true,
          loading: false,
        ),
      );
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
    try {
      unwrap(await repository.complete(event.session));
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete(false);
      return;
    }
    try {
      await _refreshState(emit);
    } catch (error) {
      _emitError(emit, error);
    }
    // A refresh failure cannot undo the committed session or its audio.
    event.result?.complete(true);
  }

  Future<void> _onSessionDeleted(
    AppSessionDeleted event,
    Emitter<AppState> emit,
  ) async {
    try {
      unwrap(await repository.deleteSession(event.id));
      await _refreshState(emit);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onAudioDeleted(
    AppAudioDeleted event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.stopPlayback();
      unwrap(await repository.deleteAudio(event.id));
      await _refreshState(emit);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onAllAudioDeleted(
    AppAllAudioDeleted event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.stopPlayback();
      for (final session in state.sessions) {
        unwrap(await repository.deleteAudio(session.id));
      }
      await _refreshState(emit);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onReminderSaved(
    AppReminderSaved event,
    Emitter<AppState> emit,
  ) async {
    try {
      unwrap(
        await repository.saveReminder(
          event.reminder.copyWith(status: 'pending'),
        ),
      );
      await device.cancel(event.reminder.id);
      if (event.reminder.enabled) await device.schedule(event.reminder);
      unwrap(
        await repository.saveReminder(
          event.reminder.copyWith(
            status: event.reminder.enabled ? 'ready' : 'paused',
          ),
        ),
      );
      await _refreshState(emit);
      event.result?.complete(true);
    } catch (error) {
      try {
        await _refreshState(emit);
      } catch (_) {
        // Preserve the original actionable error below.
      }
      _emitError(emit, error);
      event.result?.complete(false);
    }
  }

  Future<void> _onReminderDeleted(
    AppReminderDeleted event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.cancel(event.id);
      unwrap(await repository.deleteReminder(event.id));
      await _refreshState(emit);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onReminderSnoozeCancelled(
    AppReminderSnoozeCancelled event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.cancelSnooze(event.id);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.completeError(error);
    }
  }

  Future<void> _onDataReset(AppDataReset event, Emitter<AppState> emit) async {
    try {
      await device.stopPlayback();
      await device.cancelAll();
      unwrap(await repository.reset());
      await _refreshState(emit, onboardingComplete: false);
      event.result?.complete(true);
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete(false);
    }
  }

  Future<void> _onAudioPlaybackRequested(
    AppAudioPlaybackRequested event,
    Emitter<AppState> emit,
  ) async {
    if (event.session.audioPath == null) return;
    try {
      await device.play(storage.pathFor(event.session.audioPath!));
    } catch (error) {
      _emitError(emit, error);
    }
  }

  Future<void> _onAudioPlaybackStopped(
    AppAudioPlaybackStopped event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.stopPlayback();
    } catch (error) {
      _emitError(emit, error);
    }
  }

  Future<void> _onDeviceSettingsRequested(
    AppDeviceSettingsRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.settings();
    } catch (error) {
      _emitError(emit, error);
    }
  }

  Future<void> _onAlarmTestRequested(
    AppAlarmTestRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await device.testAlarm();
    } catch (error) {
      _emitError(emit, error);
    }
  }

  Future<void> _refreshState(
    Emitter<AppState> emit, {
    bool? onboardingComplete,
  }) async {
    final sessions = unwrap(await repository.sessions());
    final reminders = unwrap(await repository.reminders());
    final bytes = await storage.audioBytes();
    emit(
      state.copyWith(
        sessions: sessions,
        reminders: reminders,
        audioBytes: bytes,
        onboardingComplete: onboardingComplete,
        loading: false,
      ),
    );
  }

  void _emitError(Emitter<AppState> emit, Object error) {
    final message = error is Failure
        ? error.message
        : error is PlatformException
        ? error.message ?? 'Check your device settings and try again.'
        : 'Something went wrong. Please try again.';
    emit(
      state.copyWith(
        error: message,
        loading: false,
      ),
    );
  }

  @override
  Future<void> close() async {
    await super.close();
    await closeResources?.call();
  }
}
