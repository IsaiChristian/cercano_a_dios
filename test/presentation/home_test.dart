import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cercano_a_dios/data/services/device_services.dart';
import 'package:cercano_a_dios/data/repositories/local_prayer_repository.dart';
import 'package:cercano_a_dios/data/services/local_storage_service.dart';
import 'package:cercano_a_dios/ui/core/theme.dart';
import 'package:cercano_a_dios/ui/features/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/ui/features/home/views/home_page.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';

void main() {
  testWidgets('home remains readable on a small screen with large text', (
    tester,
  ) async {
    sqfliteFfiInit();
    final root = await Directory.systemTemp.createTemp('prayer-ui');
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: LocalPrayerRepository.createSchema,
      ),
    );
    final app = AppBloc(
      repository: LocalPrayerRepository(db, root.path),
      device: DeviceServices(),
      storage: LocalStorageService(root.path),
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await app.close();
      await app.device.interruptions.close();
      await db.close();
      await root.delete(recursive: true);
    });
    await tester.pumpWidget(
      BlocProvider.value(
        value: app,
        child: MaterialApp(
          theme: appTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SizedBox(
              height: 568,
              child: Scaffold(body: HomePage(app: app)),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Make room\nfor God.'), findsOneWidget);
    expect(find.text('Begin a moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
