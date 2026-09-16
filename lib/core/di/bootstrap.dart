import 'dart:io';

import '../../data/repositories/local_prayer_repository.dart';
import '../../data/services/device_services.dart';
import '../../data/services/local_prayer_database_service.dart';
import '../../data/services/local_storage_service.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

Future<AppBloc> bootstrap() async {
  final device = DeviceServices();
  final root = await device.directory();
  await Directory(root).create(recursive: true);
  final storage = LocalStorageService(root);
  final repositoryService = await LocalPrayerDatabaseService.open(root);
  final repository = LocalPrayerRepository.fromService(repositoryService);
  await repository.reconcileFiles();
  final app = AppBloc(
    repository: repository,
    device: device,
    storage: storage,
    onboardingComplete: await storage.hasCompletedOnboarding(),
    closeResources: () async {
      await repositoryService.close();
      await device.interruptions.close();
    },
  );
  await app.refresh();
  if (app.state.error != null) throw StateError(app.state.error!);
  return app;
}
