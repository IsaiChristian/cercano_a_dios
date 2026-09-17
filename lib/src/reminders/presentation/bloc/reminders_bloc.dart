import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../domain/entities/reminder.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/prayer_repository.dart';

part 'reminders_state.dart';
part 'reminders_event.dart';

/// Feature-scoped BLoC managing reminder scheduling, alarms, and persistence.
class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  final PrayerRepository repository;
  final DeviceServices device;

  RemindersBloc({required this.repository, required this.device})
    : super(const RemindersState()) {
    on<RemindersStatusRequested>(_onStatusRequested);
    on<RemindersLoadRequested>(_onLoadRequested);
    on<ReminderSaveRequested>(_onSaveRequested);
    on<ReminderDeleteRequested>(_onDeleteRequested);
    on<ReminderSnoozeCancelRequested>(_onSnoozeCancelRequested);
    on<ReminderSettingsRequested>(_onSettingsRequested);
    on<ReminderTestRequested>(_onTestRequested);
  }

  Future<void> loadStatus() {
    final result = Completer<void>();
    add(RemindersStatusRequested(result));
    return result.future;
  }

  Future<void> loadReminders() {
    final result = Completer<void>();
    add(RemindersLoadRequested(result));
    return result.future;
  }

  Future<bool> saveReminder(Reminder reminder) {
    final result = Completer<bool>();
    add(ReminderSaveRequested(reminder, result));
    return result.future;
  }

  Future<void> deleteReminder(int id) {
    final result = Completer<void>();
    add(ReminderDeleteRequested(id, result));
    return result.future;
  }

  Future<void> cancelSnooze(int id) {
    final result = Completer<void>();
    add(ReminderSnoozeCancelRequested(id, result));
    return result.future;
  }

  Future<void> openSettings() {
    add(const ReminderSettingsRequested());
    return Future<void>.value();
  }

  Future<void> testAlarm() {
    add(const ReminderTestRequested());
    return Future<void>.value();
  }

  Future<void> _onStatusRequested(
    RemindersStatusRequested event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      final capability = await device.alarmCapability();
      final permission = await device.alarmStatus();
      emit(
        state.copyWith(
          capability: capability,
          permission: permission,
          clearError: true,
        ),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onLoadRequested(
    RemindersLoadRequested event,
    Emitter<RemindersState> emit,
  ) async {
    final result = await repository.reminders();
    result.fold(
      (failure) {
        _emitError(emit, failure);
        event.result?.complete();
      },
      (reminders) {
        emit(state.copyWith(reminders: reminders, clearError: true));
        event.result?.complete();
      },
    );
  }

  Future<void> _onSaveRequested(
    ReminderSaveRequested event,
    Emitter<RemindersState> emit,
  ) async {
    if (state.busy) {
      event.result?.complete(false);
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      final pendingSave = await repository.saveReminder(
        event.reminder.copyWith(status: 'pending'),
      );
      if (pendingSave.isLeft()) {
        pendingSave.fold((f) => throw f, (_) {});
      }

      await device.cancel(event.reminder.id);
      if (event.reminder.enabled) {
        await device.schedule(event.reminder);
      }

      final finalSave = await repository.saveReminder(
        event.reminder.copyWith(
          status: event.reminder.enabled ? 'ready' : 'paused',
        ),
      );
      if (finalSave.isLeft()) {
        finalSave.fold((f) => throw f, (_) {});
      }

      final listResult = await repository.reminders();
      final reminders = listResult.getOrElse(() => state.reminders);
      emit(state.copyWith(reminders: reminders, busy: false, clearError: true));
      event.result?.complete(true);
    } catch (error) {
      final listResult = await repository.reminders();
      final reminders = listResult.getOrElse(() => state.reminders);
      final message = error is Failure ? error.message : error.toString();
      emit(state.copyWith(reminders: reminders, busy: false, error: message));
      event.result?.complete(false);
    }
  }

  Future<void> _onDeleteRequested(
    ReminderDeleteRequested event,
    Emitter<RemindersState> emit,
  ) async {
    if (state.busy) {
      event.result?.complete();
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      await device.cancel(event.id);
      final deleteResult = await repository.deleteReminder(event.id);
      deleteResult.fold((f) => throw f, (_) {});

      final listResult = await repository.reminders();
      final reminders = listResult.getOrElse(() => state.reminders);
      emit(state.copyWith(reminders: reminders, busy: false, clearError: true));
      event.result?.complete();
    } catch (error) {
      final listResult = await repository.reminders();
      final reminders = listResult.getOrElse(() => state.reminders);
      final message = error is Failure ? error.message : error.toString();
      emit(state.copyWith(reminders: reminders, busy: false, error: message));
      event.result?.complete();
    }
  }

  Future<void> _onSnoozeCancelRequested(
    ReminderSnoozeCancelRequested event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await device.cancelSnooze(event.id);
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.completeError(error);
    }
  }

  Future<void> _onSettingsRequested(
    ReminderSettingsRequested event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await device.settings();
    } catch (error) {
      _emitError(emit, error);
    }
  }

  Future<void> _onTestRequested(
    ReminderTestRequested event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      await device.testAlarm();
    } catch (error) {
      _emitError(emit, error);
    }
  }

  void _emitError(Emitter<RemindersState> emit, Object error) {
    final message = error is Failure ? error.message : error.toString();
    emit(state.copyWith(error: message));
  }
}
