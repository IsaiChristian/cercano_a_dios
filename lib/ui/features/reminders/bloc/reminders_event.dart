part of 'reminders_bloc.dart';

abstract class RemindersEvent {}

class RemindersStatusRequested extends RemindersEvent {
  final Completer<void>? result;

  RemindersStatusRequested([this.result]);
}

class ReminderSaveRequested extends RemindersEvent {
  final Reminder reminder;
  final Completer<bool> result;

  ReminderSaveRequested(this.reminder, this.result);
}

class ReminderDeleteRequested extends RemindersEvent {
  final int id;
  final Completer<void> result;

  ReminderDeleteRequested(this.id, this.result);
}

class ReminderSettingsRequested extends RemindersEvent {}

class ReminderTestRequested extends RemindersEvent {}
