import '../../domain/entities/reminder.dart';

Reminder reminderFromRow(Map<String, Object?> row) {
  return Reminder(
    id: row['id'] as int,
    hour: row['hour'] as int,
    minute: row['minute'] as int,
    weekdays: (row['weekdays'] as String).split(',').map(int.parse).toList(),
    enabled: row['enabled'] == 1,
    status: row['status'] as String,
  );
}

extension ReminderMapper on Reminder {
  Map<String, Object?> toRow() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays.join(','),
    'enabled': enabled ? 1 : 0,
    'status': status,
  };

  Map<String, Object?> toPlatform() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays,
    'enabled': enabled,
  };
}
