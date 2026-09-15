import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/use_cases/next_reminder.dart';

void main() {
  const reminder = Reminder(id: 1, hour: 7, minute: 30, weekdays: [1, 3, 5]);
  test('after the scheduled time, finds the next selected weekday', () {
    expect(nextReminder(reminder, DateTime(2026, 9, 14, 8)), DateTime(2026, 9, 16, 7, 30));
  });
  test('before the scheduled time, uses today', () {
    expect(nextReminder(reminder, DateTime(2026, 9, 14, 7)), DateTime(2026, 9, 14, 7, 30));
  });
  test('paused reminders do not claim a next occurrence', () {
    expect(nextReminder(reminder.copyWith(enabled: false), DateTime(2026, 9, 14)), isNull);
  });
}
