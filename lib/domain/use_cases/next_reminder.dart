import '../entities/prayer.dart';

/// Local calendar construction preserves wall-clock times across offset changes.
/// Native scheduling remains authoritative; this is the displayed next date.
DateTime? nextReminder(Reminder reminder, DateTime now) {
  if (!reminder.enabled || reminder.weekdays.isEmpty) return null;
  for (var offset = 0; offset <= 7; offset++) {
    final date = DateTime(now.year, now.month, now.day + offset,
        reminder.hour, reminder.minute);
    if (reminder.weekdays.contains(date.weekday) && date.isAfter(now)) return date;
  }
  return null;
}
