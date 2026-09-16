import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/domain/entities/prayer.dart';
import 'package:cercano_a_dios/data/mappers/session_mapper.dart';
import 'package:cercano_a_dios/data/mappers/reminder_mapper.dart';

void main() {
  group('Session Mapper', () {
    test('round trip and exact key/type payloads', () {
      final session = PrayerSession(
        id: 's-123',
        promptId: 'p-1',
        promptText: 'Hello',
        localDate: '2023-10-27',
        completedAt: DateTime.utc(2023, 10, 27, 12, 0, 0),
        durationSeconds: 60,
        offsetMinutes: 120,
        spoken: true,
        audioPath: 'path/to/audio.m4a',
      );

      final row = sessionToRow(session);

      expect(row, {
        'id': 's-123',
        'promptId': 'p-1',
        'promptText': 'Hello',
        'localDate': '2023-10-27',
        'completedAt': '2023-10-27T12:00:00.000Z',
        'duration': 60,
        'offsetMinutes': 120,
        'spoken': 1,
        'audioPath': 'path/to/audio.m4a',
      });

      final mappedSession = sessionFromRow(row);

      expect(mappedSession.id, session.id);
      expect(mappedSession.promptId, session.promptId);
      expect(mappedSession.promptText, session.promptText);
      expect(mappedSession.localDate, session.localDate);
      expect(
        mappedSession.completedAt.toUtc().toIso8601String(),
        session.completedAt.toUtc().toIso8601String(),
      );
      expect(mappedSession.durationSeconds, session.durationSeconds);
      expect(mappedSession.offsetMinutes, session.offsetMinutes);
      expect(mappedSession.spoken, session.spoken);
      expect(mappedSession.audioPath, session.audioPath);
    });

    test('round trip with null audio path', () {
      final session = PrayerSession(
        id: 's-456',
        promptId: 'p-2',
        promptText: 'World',
        localDate: '2023-10-28',
        completedAt: DateTime.utc(2023, 10, 28, 12, 0, 0),
        durationSeconds: 30,
        offsetMinutes: -300,
        spoken: false,
        audioPath: null,
      );

      final row = sessionToRow(session);

      expect(row['audioPath'], isNull);

      final mappedSession = sessionFromRow(row);
      expect(mappedSession.audioPath, isNull);
    });

    test('malformed mapping throws', () {
      expect(
        () => sessionFromRow({'id': 'only-id'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('Reminder Mapper', () {
    test('round trip and exact key/type payloads', () {
      final reminder = Reminder(
        id: 1,
        hour: 7,
        minute: 30,
        weekdays: [1, 2, 3],
        enabled: true,
        status: 'pending',
      );

      final row = reminder.toRow();

      expect(row, {
        'id': 1,
        'hour': 7,
        'minute': 30,
        'weekdays': '1,2,3',
        'enabled': 1,
        'status': 'pending',
      });

      final mappedReminder = reminderFromRow(row);

      expect(mappedReminder.id, reminder.id);
      expect(mappedReminder.hour, reminder.hour);
      expect(mappedReminder.minute, reminder.minute);
      expect(mappedReminder.weekdays, reminder.weekdays);
      expect(mappedReminder.enabled, reminder.enabled);
      expect(mappedReminder.status, reminder.status);
    });

    test('round trip with disabled and completed status', () {
      final reminder = Reminder(
        id: 2,
        hour: 22,
        minute: 0,
        weekdays: [7],
        enabled: false,
        status: 'completed',
      );

      final row = reminder.toRow();

      expect(row['enabled'], 0);

      final mappedReminder = reminderFromRow(row);
      expect(mappedReminder.enabled, false);
      expect(mappedReminder.status, 'completed');
    });

    test('toPlatform exact payloads', () {
      final reminder = Reminder(
        id: 3,
        hour: 12,
        minute: 15,
        weekdays: [1, 5],
        enabled: true,
        status: 'ignored-by-platform',
      );

      final platformData = reminder.toPlatform();

      expect(platformData, {
        'id': 3,
        'hour': 12,
        'minute': 15,
        'weekdays': [1, 5],
        'enabled': true,
      });

      expect(platformData.containsKey('status'), false);
    });

    test('malformed mapping throws', () {
      expect(() => reminderFromRow({'id': 1}), throwsA(isA<TypeError>()));
    });
  });
}
