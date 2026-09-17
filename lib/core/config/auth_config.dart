class AuthConfig {
  final AuthBackend backend;
  final String? appwriteEndpoint;
  final String? appwriteProjectId;

  const AuthConfig._({
    required this.backend,
    this.appwriteEndpoint,
    this.appwriteProjectId,
  });

  factory AuthConfig.fromEnvironment() {
    return AuthConfig.fromMap(const {
      'AUTH_BACKEND': String.fromEnvironment('AUTH_BACKEND'),
      'APPWRITE_ENDPOINT': String.fromEnvironment('APPWRITE_ENDPOINT'),
      'APPWRITE_PROJECT_ID': String.fromEnvironment('APPWRITE_PROJECT_ID'),
    });
  }

  factory AuthConfig.fromMap(Map<String, String> env) {
    final backendStr = env['AUTH_BACKEND'] ?? '';

    final backend = backendStr == 'fake'
        ? AuthBackend.fake
        : AuthBackend.appwrite;

    final endpoint = env['APPWRITE_ENDPOINT'] ?? '';
    final projectId = env['APPWRITE_PROJECT_ID'] ?? '';

    final effectiveEndpoint = endpoint.isEmpty ? null : endpoint;
    final effectiveProjectId = projectId.isEmpty ? null : projectId;

    if (backend == AuthBackend.appwrite) {
      if (effectiveEndpoint == null || effectiveProjectId == null) {
        throw StateError(
          'Missing APPWRITE_ENDPOINT or APPWRITE_PROJECT_ID configuration. '
          'Appwrite is the default backend. To use the fake backend, '
          'explicitly pass --dart-define=AUTH_BACKEND=fake.',
        );
      }
    }

    return AuthConfig._(
      backend: backend,
      appwriteEndpoint: effectiveEndpoint,
      appwriteProjectId: effectiveProjectId,
    );
  }
}

enum AuthBackend { fake, appwrite }
