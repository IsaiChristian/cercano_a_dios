part of 'reminders_bloc.dart';

class RemindersState {
  final String capability;
  final String permission;
  final bool busy;

  const RemindersState({
    this.capability = 'loading',
    this.permission = 'unknown',
    this.busy = false,
  });
}
