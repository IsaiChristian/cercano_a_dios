import '../entities/prayer.dart';

class PrayerProgress {
  final int currentStreak, bestStreak, total;
  final Set<String> dates;
  final Set<String> badges;
  const PrayerProgress({
    required this.currentStreak,
    required this.bestStreak,
    required this.total,
    required this.dates,
    required this.badges,
  });
}

const badgeLabels = <String, String>{
  'first': 'First moment',
  'streak3': 'Three faithful days',
  'streak7': 'A week of prayer',
  'streak30': 'Thirty days together',
  'total10': 'Ten moments',
  'total50': 'Fifty moments',
};

PrayerProgress calculateProgress(
  Iterable<PrayerSession> sessions,
  DateTime now,
) {
  final unique = {for (final session in sessions) session.id: session};
  final dates = unique.values.map((s) => s.localDate).toSet();
  // UTC civil dates avoid 23/25-hour daylight-saving arithmetic.
  final days = dates.map((d) => DateTime.parse('${d}T00:00:00Z')).toList()
    ..sort();
  int best = 0, run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > best) best = run;
    previous = day;
  }
  var cursor = civilDay(now);
  if (!dates.contains(calendarDate(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var current = 0;
  while (dates.contains(calendarDate(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  final badges = <String>{
    if (unique.isNotEmpty) 'first',
    if (best >= 3) 'streak3',
    if (best >= 7) 'streak7',
    if (best >= 30) 'streak30',
    if (unique.length >= 10) 'total10',
    if (unique.length >= 50) 'total50',
  };
  return PrayerProgress(
    currentStreak: current,
    bestStreak: best,
    total: unique.length,
    dates: dates,
    badges: badges,
  );
}
