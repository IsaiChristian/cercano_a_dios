part of 'reminders_bloc.dart';

class RemindersState extends Equatable {
  final List<Reminder> reminders;
  final String capability;
  final String permission;
  final bool busy;
  final String? error;

  const RemindersState({
    this.reminders = const [],
    this.capability = 'loading',
    this.permission = 'unknown',
    this.busy = false,
    this.error,
  });

  RemindersState copyWith({
    List<Reminder>? reminders,
    String? capability,
    String? permission,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      capability: capability ?? this.capability,
      permission: permission ?? this.permission,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [reminders, capability, permission, busy, error];
}
