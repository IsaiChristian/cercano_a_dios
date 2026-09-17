import 'package:equatable/equatable.dart';

class PrayerSession extends Equatable {
  final String id;
  final String promptId;
  final String promptText;
  final String localDate;
  final DateTime completedAt;
  final int durationSeconds;
  final int offsetMinutes;
  final String? audioPath;
  final bool spoken;

  const PrayerSession({
    required this.id,
    required this.promptId,
    required this.promptText,
    required this.localDate,
    required this.completedAt,
    required this.durationSeconds,
    required this.spoken,
    this.audioPath,
    required this.offsetMinutes,
  });

  @override
  List<Object?> get props => [
    id, promptId, promptText, localDate, completedAt,
    durationSeconds, offsetMinutes, spoken, audioPath,
  ];
}
