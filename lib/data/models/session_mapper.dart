import '../../domain/entities/prayer.dart';
Map<String, Object?> sessionToRow(PrayerSession s) => {
  'id': s.id, 'promptId': s.promptId, 'promptText': s.promptText,
  'localDate': s.localDate, 'completedAt': s.completedAt.toUtc().toIso8601String(),
  'duration': s.durationSeconds, 'offsetMinutes': s.offsetMinutes,
  'spoken': s.spoken ? 1 : 0, 'audioPath': s.audioPath,
};
PrayerSession sessionFromRow(Map<String, Object?> row) => PrayerSession(
  id: row['id'] as String, promptId: row['promptId'] as String,
  promptText: row['promptText'] as String, localDate: row['localDate'] as String,
  completedAt: DateTime.parse(row['completedAt'] as String),
  durationSeconds: row['duration'] as int, offsetMinutes: row['offsetMinutes'] as int,
  spoken: row['spoken'] == 1, audioPath: row['audioPath'] as String?,
);
