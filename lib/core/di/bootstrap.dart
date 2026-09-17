import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cercano_a_dios/core/config/auth_config.dart';
import 'package:cercano_a_dios/core/di/authenticated_app_factory.dart';
import 'package:cercano_a_dios/data/repositories/appwrite_auth_repository.dart';
import 'package:cercano_a_dios/data/repositories/fake_auth_repository.dart';
import 'package:cercano_a_dios/data/services/appwrite_auth_service.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/domain/repositories/auth_repository.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';

/// Container for dependencies initialized during application startup.
class AppBootstrapResult {
  final DeviceServices device;
  final AuthRepository authRepository;
  final AuthenticatedAppFactory appFactory;
  final AuthBloc authBloc;
  final AppSessionBloc appSessionBloc;
  final StreamSubscription<AuthState>? _authSubscription;
  bool _isDisposed = false;

  AppBootstrapResult({
    required this.device,
    required this.authRepository,
    required this.appFactory,
    required this.authBloc,
    required this.appSessionBloc,
    this._authSubscription,
  });

  /// Disposes scoped bloc resources and listeners idempotently.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    await _authSubscription?.cancel();
    await appSessionBloc.close();
    await authBloc.close();
  }
}

/// Initializes core services and authentication for Cercano a Dios.
///
/// Uses [AuthConfig] to configure the authentication backend. Appwrite is the
/// default and requires explicit endpoint and project ID. Fake auth is selected
/// only when explicitly configured with [AuthBackend.fake]. Missing configuration
/// throws [StateError] to prevent silent fallback.
Future<AppBootstrapResult> bootstrap({
  AuthConfig? config,
  AuthRepository? authRepository,
  DeviceServices? deviceServices,
  DatabaseOpener? databaseOpener,
}) async {
  final device = deviceServices ?? DeviceServices();
  final baseRoot = await device.directory();
  Directory(baseRoot).createSync(recursive: true);

  final AuthRepository effectiveAuthRepo;
  if (authRepository != null) {
    effectiveAuthRepo = authRepository;
  } else {
    final effectiveConfig = config ?? AuthConfig.fromEnvironment();
    switch (effectiveConfig.backend) {
      case AuthBackend.fake:
        effectiveAuthRepo = FakeAuthRepository();
      case AuthBackend.appwrite:
        final endpoint = effectiveConfig.appwriteEndpoint;
        final projectId = effectiveConfig.appwriteProjectId;
        if (endpoint == null ||
            projectId == null ||
            endpoint.isEmpty ||
            projectId.isEmpty) {
          throw StateError(
            'Missing APPWRITE_ENDPOINT or APPWRITE_PROJECT_ID configuration. '
            'Appwrite is the default backend. To use the fake backend, '
            'explicitly pass --dart-define=AUTH_BACKEND=fake.',
          );
        }
        final client = Client()
          ..setEndpoint(endpoint)
          ..setProject(projectId);
        final account = Account(client);
        final service = AppwriteAuthServiceImpl(account);
        effectiveAuthRepo = AppwriteAuthRepository(service);
    }
  }

  final appFactory = AuthenticatedAppFactory(
    device: device,
    baseRoot: baseRoot,
    databaseOpener: databaseOpener,
  );

  final authBloc = AuthBloc(authRepository: effectiveAuthRepo);
  final appSessionBloc = AppSessionBloc(appFactory: appFactory, device: device);

  // Auth events drive AppSessionBloc lifecycle
  final authSubscription = authBloc.stream.listen((authState) {
    if (authState.sessionStatus == AuthSessionStatus.authenticated) {
      final user = authState.user;
      if (user != null && appSessionBloc.state.userId != user.id) {
        appSessionBloc.add(AppSessionUserChanged(user));
      }
    } else if (authState.sessionStatus == AuthSessionStatus.unauthenticated) {
      if (appSessionBloc.state.status != AppSessionStatus.signedOut) {
        appSessionBloc.add(const AppSessionUserChanged(null));
      }
    }
  });

  // Start initial session check
  authBloc.add(const AuthSessionCheckRequested());

  return AppBootstrapResult(
    device: device,
    authRepository: effectiveAuthRepo,
    appFactory: appFactory,
    authBloc: authBloc,
    appSessionBloc: appSessionBloc,
    authSubscription: authSubscription,
  );
}
