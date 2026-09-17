import 'package:flutter_test/flutter_test.dart';
import 'package:cercano_a_dios/core/config/auth_config.dart';

void main() {
  group('AuthConfig', () {
    test('absent AUTH_BACKEND selects appwrite in every build mode', () {
      final config = AuthConfig.fromMap({
        'APPWRITE_ENDPOINT': 'https://cloud.appwrite.io/v1',
        'APPWRITE_PROJECT_ID': 'proj-123',
      });
      expect(config.backend, equals(AuthBackend.appwrite));
      expect(config.appwriteEndpoint, equals('https://cloud.appwrite.io/v1'));
      expect(config.appwriteProjectId, equals('proj-123'));
    });

    test('explicit AUTH_BACKEND=fake selects fake backend', () {
      final config = AuthConfig.fromMap({'AUTH_BACKEND': 'fake'});
      expect(config.backend, equals(AuthBackend.fake));
      expect(config.appwriteEndpoint, isNull);
      expect(config.appwriteProjectId, isNull);
    });

    test(
      'missing Appwrite configuration throws StateError and never falls back to fake',
      () {
        expect(
          () => AuthConfig.fromMap({
            'APPWRITE_ENDPOINT': 'https://cloud.appwrite.io/v1',
          }),
          throwsStateError,
        );

        expect(
          () => AuthConfig.fromMap({'APPWRITE_PROJECT_ID': 'proj-123'}),
          throwsStateError,
        );

        expect(() => AuthConfig.fromMap({}), throwsStateError);
      },
    );
  });
}
