class Reminder {
  final int id;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final bool enabled;
  final String status;

  const Reminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.enabled = true,
    this.status = 'pending',
  });

  Reminder copyWith({bool? enabled, String? status}) => Reminder(
    id: id,
    hour: hour,
    minute: minute,
    weekdays: weekdays,
    enabled: enabled ?? this.enabled,
    status: status ?? this.status,
  );

  Map<String, Object?> toPlatform() => {
    'id': id,
    'hour': hour,
    'minute': minute,
    'weekdays': weekdays,
    'enabled': enabled,
  };
}
