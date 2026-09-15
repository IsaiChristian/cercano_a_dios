import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';

class SettingsPage extends StatelessWidget {
  final AppBloc app;

  const SettingsPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        bloc: app,
        builder: (context, _) {
          final localizations = AppLocalizations.of(context)!;
          final mb = app.state.audioBytes / (1024 * 1024);
          return PageBody(
            children: [
              SectionLabel(localizations.t('settings')),
              Text(
                localizations.t('spaceTitle'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.t('storageUsage', {
                        'used': mb.toStringAsFixed(1),
                      }),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (mb / 100).clamp(0, 1).toDouble(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mb >= 80
                          ? localizations.t('storageNearLimit')
                          : localizations.t('storagePrivate'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (await confirm(
                          context,
                          localizations.t('deleteAllRecordingsTitle'),
                          localizations.t('deleteAllRecordingsDescription'),
                        )) {
                          await app.deleteAllAudio();
                        }
                      },
                      child: Text(localizations.t('deleteAllRecordings')),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.t('permissions')),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizations.t('permissionLabel')),
                trailing: const Icon(Icons.open_in_new),
                onTap: app.openDeviceSettings,
              ),
              SectionLabel(localizations.t('aboutData')),
              Text(localizations.t('privacyDescription')),
              const SizedBox(height: 16),
              Text(localizations.t('timezoneNote')),
              SectionLabel(localizations.t('startFresh')),
              OutlinedButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    localizations.t('resetTitle'),
                    localizations.t('resetDescription'),
                  )) {
                    await app.reset();
                  }
                },
                child: Text(localizations.t('deleteAppData')),
              ),
              const SizedBox(height: 24),
              Text(localizations.t('footer'), textAlign: TextAlign.center),
            ],
          );
        },
      );
}
