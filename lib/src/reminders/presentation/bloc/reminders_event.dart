part of 'reminders_bloc.dart';

abstract class RemindersEvent {
  const RemindersEvent();
}

class RemindersStatusRequested extends RemindersEvent {
  final Completer<void>? result;

  const RemindersStatusRequested([this.result]);
}

class RemindersLoadRequested extends RemindersEvent {
  final Completer<void>? result;

  const RemindersLoadRequested([this.result]);
}

class ReminderSaveRequested extends RemindersEvent {
  final Reminder reminder;
  final Completer<bool>? result;

  const ReminderSaveRequested(this.reminder, [this.result]);
}

class ReminderDeleteRequested extends RemindersEvent {
  final int id;
  final Completer<void>? result;

  const ReminderDeleteRequested(this.id, [this.result]);
}

class ReminderSnoozeCancelRequested extends RemindersEvent {
  final int id;
  final Completer<void>? result;

  const ReminderSnoozeCancelRequested(this.id, [this.result]);
}

class ReminderSettingsRequested extends RemindersEvent {
  const ReminderSettingsRequested();
}

class ReminderTestRequested extends RemindersEvent {
  const ReminderTestRequested();
}
