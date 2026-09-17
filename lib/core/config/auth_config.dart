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
    final endpoint = env['APPWRITE_ENDPOINT'] ?? '';
    final projectId = env['APPWRITE_PROJECT_ID'] ?? '';

    final effectiveEndpoint = endpoint.isEmpty ? null : endpoint;
    final effectiveProjectId = projectId.isEmpty ? null : projectId;

    final hasAppwriteConfig =
        effectiveEndpoint != null && effectiveProjectId != null;
    final backend = backendStr == 'fake'
        ? AuthBackend.fake
        : hasAppwriteConfig
            ? AuthBackend.appwrite
            : AuthBackend.fake;

    return AuthConfig._(
      backend: backend,
      appwriteEndpoint: backend == AuthBackend.appwrite
          ? effectiveEndpoint
          : null,
      appwriteProjectId: backend == AuthBackend.appwrite
          ? effectiveProjectId
          : null,
    );
  }
}

enum AuthBackend { fake, appwrite }
