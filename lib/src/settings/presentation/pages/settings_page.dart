import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/widgets/quiet_card.dart';
import 'package:cercano_a_dios/presentation/widgets/page_body.dart';
import 'package:cercano_a_dios/presentation/widgets/section_label.dart';
import 'package:cercano_a_dios/presentation/dialogs/confirm.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';

class SettingsPage extends StatelessWidget {
  final AppBloc app;

  const SettingsPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
    bloc: app,
    builder: (context, _) {
      final localizations = AppLocalizations.of(context)!;
      final mb = app.state.audioBytes / (1024 * 1024);
      final currentPath = GoRouter.of(
        context,
      ).routeInformationProvider.value.uri.path;

      return Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.appName,
            style: const TextStyle(fontFamily: 'serif'),
          ),
          actions: [
            IconButton(
              tooltip: localizations.milestones,
              onPressed: () => context.push('/progress'),
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: PageBody(
            children: [
              SectionLabel(localizations.settings),
              Text(
                localizations.spaceTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizations.language),
                trailing: DropdownButton<Locale>(
                  key: const Key('languageDropdown'),
                  value: AppState.resolveLocale(app.state.locale),
                  onChanged: (locale) {
                    if (locale != null) app.setLocale(locale);
                  },
                  items: [
                    DropdownMenuItem(
                      value: const Locale('en'),
                      child: Text(localizations.english),
                    ),
                    DropdownMenuItem(
                      value: const Locale('es'),
                      child: Text(localizations.spanish),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.storageUsage(mb.toStringAsFixed(1)),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (mb / 100).clamp(0, 1).toDouble(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mb >= 80
                          ? localizations.storageNearLimit
                          : localizations.storagePrivate,
                    ),
                    TextButton(
                      onPressed: () async {
                        if (await confirm(
                          context,
                          localizations.deleteAllRecordingsTitle,
                          localizations.deleteAllRecordingsDescription,
                        )) {
                          await app.deleteAllAudio();
                        }
                      },
                      child: Text(localizations.deleteAllRecordings),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.permissions),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(localizations.permissionLabel),
                trailing: const Icon(Icons.open_in_new),
                onTap: app.openDeviceSettings,
              ),
              SectionLabel(localizations.aboutData),
              Text(localizations.privacyDescription),
              const SizedBox(height: 16),
              Text(localizations.timezoneNote),
              SectionLabel(localizations.startFresh),
              OutlinedButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    localizations.resetTitle,
                    localizations.resetDescription,
                  )) {
                    await app.reset();
                  }
                },
                child: Text(localizations.deleteAppData),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  try {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                  } catch (_) {}
                },
                child: Text(localizations.signOut),
              ),
              const SizedBox(height: 24),
              Text(localizations.footer, textAlign: TextAlign.center),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: switch (currentPath) {
            '/reminders' => 1,
            '/history' => 2,
            '/settings' => 3,
            _ => 0,
          },
          onDestinationSelected: (index) =>
              context.go(['/', '/reminders', '/history', '/settings'][index]),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              label: localizations.today,
            ),
            NavigationDestination(
              icon: const Icon(Icons.alarm),
              label: localizations.alarms,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              label: localizations.journal,
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune),
              label: localizations.settings,
            ),
          ],
        ),
      );
    },
  );
}
