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

    test('missing Appwrite configuration falls back to fake auth', () {
      final partialEndpointConfig = AuthConfig.fromMap({
        'APPWRITE_ENDPOINT': 'https://cloud.appwrite.io/v1',
      });
      expect(partialEndpointConfig.backend, equals(AuthBackend.fake));
      expect(partialEndpointConfig.appwriteEndpoint, isNull);
      expect(partialEndpointConfig.appwriteProjectId, isNull);

      final partialProjectConfig = AuthConfig.fromMap({
        'APPWRITE_PROJECT_ID': 'proj-123',
      });
      expect(partialProjectConfig.backend, equals(AuthBackend.fake));
      expect(partialProjectConfig.appwriteEndpoint, isNull);
      expect(partialProjectConfig.appwriteProjectId, isNull);

      final emptyConfig = AuthConfig.fromMap({});
      expect(emptyConfig.backend, equals(AuthBackend.fake));
      expect(emptyConfig.appwriteEndpoint, isNull);
      expect(emptyConfig.appwriteProjectId, isNull);
    });
  });
}
