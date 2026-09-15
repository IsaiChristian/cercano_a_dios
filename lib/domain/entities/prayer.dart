class PrayerPrompt {
  final String id, title, text, category;
  const PrayerPrompt(this.id, this.title, this.text, this.category);
}

class PrayerSession {
  final String id, promptId, promptText, localDate;
  final DateTime completedAt;
  final int durationSeconds, offsetMinutes;
  final String? audioPath;
  final bool spoken;
  const PrayerSession({required this.id, required this.promptId,
    required this.promptText, required this.localDate, required this.completedAt,
    required this.durationSeconds, required this.spoken, this.audioPath,
    required this.offsetMinutes});
}

class Reminder {
  final int id, hour, minute;
  final List<int> weekdays;
  final bool enabled;
  final String status;
  const Reminder({required this.id, required this.hour, required this.minute,
    required this.weekdays, this.enabled = true, this.status = 'pending'});
  Reminder copyWith({bool? enabled, String? status}) => Reminder(id: id,
    hour: hour, minute: minute, weekdays: weekdays,
    enabled: enabled ?? this.enabled, status: status ?? this.status);
  Map<String, Object?> toPlatform() => {'id': id, 'hour': hour,
    'minute': minute, 'weekdays': weekdays, 'enabled': enabled};
}

String calendarDate(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
  '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
DateTime civilDay(DateTime date) => DateTime.utc(date.year, date.month, date.day);
