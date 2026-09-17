import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../domain/entities/prayer.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

part 'reminders_state.dart';
part 'reminders_event.dart';

class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  final AppBloc app;
  final DeviceServices device;

  RemindersBloc({required this.app, required this.device})
    : super(const RemindersState()) {
    on<RemindersStatusRequested>(_onStatusRequested);
    on<ReminderSaveRequested>(_onSaveRequested);
    on<ReminderDeleteRequested>(_onDeleteRequested);
    on<ReminderSettingsRequested>(_onSettingsRequested);
    on<ReminderTestRequested>(_onTestRequested);
  }

  Future<void> loadStatus() {
    final result = Completer<void>();
    add(RemindersStatusRequested(result));
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

  void openSettings() => add(ReminderSettingsRequested());

  void testAlarm() => add(ReminderTestRequested());

  Future<void> _onStatusRequested(
    RemindersStatusRequested event,
    Emitter<RemindersState> emit,
  ) async {
    try {
      emit(
        RemindersState(
          capability: await device.alarmCapability(),
          permission: await device.alarmStatus(),
          busy: state.busy,
        ),
      );
      event.result?.complete();
    } catch (error) {
      app.report(error);
      event.result?.complete();
    }
  }

  Future<void> _onSaveRequested(
    ReminderSaveRequested event,
    Emitter<RemindersState> emit,
  ) async {
    if (state.busy) {
      event.result.complete(false);
      return;
    }
    emit(
      RemindersState(
        capability: state.capability,
        permission: state.permission,
        busy: true,
      ),
    );
    try {
      final saved = await app.saveReminder(event.reminder);
      event.result.complete(saved);
    } catch (error) {
      app.report(error);
      event.result.complete(false);
    } finally {
      emit(
        RemindersState(
          capability: state.capability,
          permission: state.permission,
          busy: false,
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ReminderDeleteRequested event,
    Emitter<RemindersState> emit,
  ) async {
    if (state.busy) {
      event.result.complete();
      return;
    }
    emit(
      RemindersState(
        capability: state.capability,
        permission: state.permission,
        busy: true,
      ),
    );
    try {
      await app.deleteReminder(event.id);
      event.result.complete();
    } catch (error) {
      app.report(error);
      event.result.complete();
    } finally {
      emit(
        RemindersState(
          capability: state.capability,
          permission: state.permission,
          busy: false,
        ),
      );
    }
  }

  void _onSettingsRequested(
    ReminderSettingsRequested event,
    Emitter<RemindersState> emit,
  ) {
    app.openDeviceSettings();
  }

  void _onTestRequested(
    ReminderTestRequested event,
    Emitter<RemindersState> emit,
  ) {
    app.testAlarm();
  }
}
