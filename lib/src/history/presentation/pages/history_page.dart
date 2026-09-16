import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/prayer.dart';
import 'package:cercano_a_dios/presentation/widgets/quiet_card.dart';
import 'package:cercano_a_dios/presentation/widgets/page_body.dart';
import 'package:cercano_a_dios/presentation/widgets/section_label.dart';
import 'package:cercano_a_dios/presentation/dialogs/confirm.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

class HistoryPage extends StatefulWidget {
  final AppBloc app;

  const HistoryPage({super.key, required this.app});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int visible = 30;

  AppBloc get app => widget.app;

  @override
  void deactivate() {
    unawaited(app.stopPlayback());
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
    bloc: app,
    builder: (context, state) {
      final localizations = AppLocalizations.of(context)!;
      final currentPath = GoRouter.of(context).routeInformationProvider.value.uri.path;

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
              SectionLabel(localizations.journal),
              Text(
                localizations.journalTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(localizations.journalSubtitle),
              const SizedBox(height: 24),
              if (state.sessions.isEmpty)
                QuietCard(child: Text(localizations.firstMomentHint)),
              ...state.sessions
                  .take(visible)
                  .map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(session: session, app: app),
                    ),
                  ),
              if (visible < state.sessions.length)
                TextButton(
                  onPressed: () => setState(() => visible += 30),
                  child: Text(localizations.loadEarlier),
                ),
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

class _SessionCard extends StatelessWidget {
  final PrayerSession session;
  final AppBloc app;

  const _SessionCard({required this.session, required this.app});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return QuietCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.localDate} · ${session.spoken ? localizations.spokenPrayer : localizations.silentReflection}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(session.promptText),
          if (session.audioPath != null)
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => app.playAudio(session),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    localizations.listenDuration(session.durationSeconds),
                  ),
                ),
                IconButton(
                  tooltip: localizations.stopPlayback,
                  onPressed: app.stopPlayback,
                  icon: const Icon(Icons.stop),
                ),
                IconButton(
                  tooltip: localizations.deleteAudioKeepMoment,
                  onPressed: () async {
                    if (await confirm(
                      context,
                      localizations.deleteRecordingTitle,
                      localizations.deleteRecordingDescription,
                    )) {
                      await app.deleteAudio(session.id);
                    }
                  },
                  icon: const Icon(Icons.mic_off_outlined),
                ),
              ],
            ),
          TextButton(
            onPressed: () async {
              if (await confirm(
                context,
                localizations.deleteMomentTitle,
                localizations.deleteMomentDescription,
              )) {
                await app.deleteSession(session.id);
              }
            },
            child: Text(localizations.deleteMoment),
          ),
        ],
      ),
    );
  }
}
