import 'dart:io';

import 'package:cercano_a_dios/data/repositories/local_prayer_repository.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/services/local_prayer_database_service.dart';
import 'package:cercano_a_dios/data/services/local_profile_service.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

typedef DatabaseOpener =
    Future<LocalPrayerDatabaseService> Function(String root);

/// Creates an [AppBloc] configured for a specific authenticated user.
class AuthenticatedAppFactory {
  final DeviceServices device;
  final String baseRoot;
  final LocalProfileService profileService;
  final DatabaseOpener? databaseOpener;

  AuthenticatedAppFactory({
    required this.device,
    required this.baseRoot,
    LocalProfileService? profileService,
    this.databaseOpener,
  }) : profileService = profileService ?? LocalProfileService(baseRoot);

  /// Builds and initializes the user-scoped [AppBloc].
  ///
  /// Reconciles files inside the user's root and closes only the user-scoped
  /// database when [AppBloc.close] is invoked.
  Future<AppBloc> create(AuthUser user) async {
    final userRoot = await profileService.resolveProfileRoot(user.id);
    await Directory(userRoot).create(recursive: true);

    final storage = LocalStorageService(userRoot);
    final repositoryService = await (databaseOpener != null
        ? databaseOpener!(userRoot)
        : LocalPrayerDatabaseService.open(userRoot));
    final repository = LocalPrayerRepository.fromService(repositoryService);
    await repository.reconcileFiles();

    final app = AppBloc(
      repository: repository,
      device: device,
      storage: storage,
      onboardingComplete: await storage.hasCompletedOnboarding(),
      closeResources: () async {
        await repositoryService.close();
      },
    );

    await app.refresh();
    if (app.state.error != null) {
      await app.close();
      throw StateError(app.state.error!);
    }
    return app;
  }
}
