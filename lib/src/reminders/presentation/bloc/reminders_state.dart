part of 'reminders_bloc.dart';

class RemindersState extends Equatable {
  final String capability;
  final String permission;
  final bool busy;

  const RemindersState({
    this.capability = 'loading',
    this.permission = 'unknown',
    this.busy = false,
  });

  @override
  List<Object?> get props => [capability, permission, busy];
}
