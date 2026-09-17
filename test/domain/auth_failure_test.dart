import 'package:cercano_a_dios/domain/failures/auth_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthFailure', () {
    test('supports value equality', () {
      const failure1 = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'message',
      );
      const failure2 = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'message',
      );
      const failure3 = AuthFailure(AuthFailureReason.network, 'message');
      const failure4 = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'different',
      );

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(failure1, isNot(equals(failure4)));
    });

    test('retains proper hash code', () {
      const failure1 = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'message',
      );
      const failure2 = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'message',
      );

      expect(failure1.hashCode, equals(failure2.hashCode));
    });
  });
}
