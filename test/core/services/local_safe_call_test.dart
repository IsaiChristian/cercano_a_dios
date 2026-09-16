import 'dart:async';
import 'package:cercano_a_dios/core/services/local_safe_call.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeLocalCall', () {
    test('returns Right with successful value', () async {
      final result = await safeLocalCall(() async => 'success');
      expect(result, const Right('success'));
    });

    test('returns Right with successful nullable value', () async {
      final result = await safeLocalCall<String?>(() async => null);
      expect(result, const Right(null));
    });

    test('returns Right with void value', () async {
      final result = await safeLocalCall<void>(() async {});
      expect(result, const Right(null));
    });

    test('preserves identity of already-thrown Failure in Left', () async {
      const failure = Failure('custom failure');
      final result = await safeLocalCall(() async {
        throw failure;
      });

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(identical(f, failure), true),
        (_) => fail('Should be Left'),
      );
    });

    test('converts generic exception to fallback Failure', () async {
      final result = await safeLocalCall(() async {
        throw Exception('random exception');
      });

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f.message, 'Could not save your changes. Please try again.'),
        (_) => fail('Should be Left'),
      );
    });

    test('logs exactly one sanitized diagnostic on failure', () async {
      final logMessages = <String>[];
      await runZoned(
        () async {
          await safeLocalCall(() async {
            throw Exception('secret data that should not be logged');
          });
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            logMessages.add(line);
          },
        ),
      );

      expect(logMessages, hasLength(1));
      expect(logMessages.first, '[LocalOperation] Exception: _Exception');
      expect(logMessages.first.contains('secret data'), isFalse);
    });
  });
}
