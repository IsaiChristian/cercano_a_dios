import 'package:cercano_a_dios/domain/entities/reminder.dart';
import 'package:cercano_a_dios/src/reminders/presentation/bloc/reminders_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reminder updates and errors remain distinct states', () {
    final reminder = Reminder(id: 1, hour: 7, minute: 30, weekdays: [1]);
    final state = RemindersState(reminders: [reminder]);
    final reloaded = RemindersState(
      reminders: [
        Reminder(id: 1, hour: 7, minute: 30, weekdays: [1]),
      ],
    );

    expect(reloaded, state);
    expect(reloaded.hashCode, state.hashCode);
    expect(state.copyWith(reminders: []), isNot(state));
    expect(
      state.copyWith(reminders: [reminder.copyWith(enabled: false)]),
      isNot(state),
    );
    expect(
      state.copyWith(reminders: [reminder.copyWith(status: 'scheduled')]),
      isNot(state),
    );
    final failed = state.copyWith(error: 'Scheduling failed');
    expect(failed, isNot(state));
    expect(failed.copyWith(clearError: true), state);
  });
}
