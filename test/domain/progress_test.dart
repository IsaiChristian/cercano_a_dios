import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/domain/use_cases/calculate_progress.dart';

PrayerSession moment(String id, String day, {bool spoken = false}) =>
    PrayerSession(
      id: id,
      promptId: 'p01',
      promptText: 'A prayer',
      localDate: day,
      completedAt: DateTime.parse('${day}T12:00:00Z'),
      durationSeconds: 10,
      spoken: spoken,
      offsetMinutes: -360,
    );
void main() {
  test(
    'duplicate sessions and multiple daily moments give only one streak day',
    () {
      final first = moment('1', '2026-09-14');
      final p = calculateProgress([
        first,
        first,
        moment('2', '2026-09-14', spoken: true),
        moment('3', '2026-09-15'),
      ], DateTime(2026, 9, 15));
      expect(p.currentStreak, 2);
      expect(p.total, 3);
      expect(p.dates.length, 2);
    },
  );
  test('yesterday carries over until a whole day is missed', () {
    final sessions = [moment('1', '2026-09-14'), moment('2', '2026-09-15')];
    expect(
      calculateProgress(sessions, DateTime(2026, 9, 16, 23, 59)).currentStreak,
      2,
    );
    expect(calculateProgress(sessions, DateTime(2026, 9, 17)).currentStreak, 0);
    expect(
      calculateProgress([
        ...sessions,
        moment('3', '2026-09-17'),
      ], DateTime(2026, 9, 17)).currentStreak,
      1,
    );
  });
  test('civil dates remain consecutive across DST and year boundaries', () {
    final dst = [
      moment('1', '2026-03-07'),
      moment('2', '2026-03-08'),
      moment('3', '2026-03-09'),
    ];
    expect(calculateProgress(dst, DateTime(2026, 3, 9)).currentStreak, 3);
    expect(
      calculateProgress([
        moment('a', '2025-12-31'),
        moment('b', '2026-01-01'),
      ], DateTime(2026, 1, 1)).currentStreak,
      2,
    );
  });
  test('badges are earned once and rebuilt after session deletion', () {
    final sessions = List.generate(
      30,
      (i) => moment('$i', calendarDate(DateTime(2026, 8, 1 + i))),
    );
    final p = calculateProgress(sessions, DateTime(2026, 8, 30));
    expect(
      p.badges,
      containsAll(['first', 'streak3', 'streak7', 'streak30', 'total10']),
    );
    expect(p.badges, isNot(contains('total50')));
    sessions.removeAt(15);
    expect(
      calculateProgress(sessions, DateTime(2026, 8, 30)).badges,
      isNot(contains('streak30')),
    );
  });
  test('empty history and travel dates do not create future-day credit', () {
    expect(calculateProgress([], DateTime(2026, 9, 15)).currentStreak, 0);
    final p = calculateProgress([
      moment('1', '2026-09-16'),
    ], DateTime(2026, 9, 15));
    expect(p.currentStreak, 0);
  });
}
