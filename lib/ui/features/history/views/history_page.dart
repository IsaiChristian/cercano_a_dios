import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../domain/entities/prayer.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';

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
          return PageBody(
            children: [
              SectionLabel(localizations.t('journal')),
              Text(
                localizations.t('journalTitle'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(localizations.t('journalSubtitle')),
              const SizedBox(height: 24),
              if (state.sessions.isEmpty)
                QuietCard(child: Text(localizations.t('firstMomentHint'))),
              ...state.sessions.take(visible).map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(
                        session: session,
                        app: app,
                      ),
                    ),
                  ),
              if (visible < state.sessions.length)
                TextButton(
                  onPressed: () => setState(() => visible += 30),
                  child: Text(localizations.t('loadEarlier')),
                ),
            ],
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
            '${session.localDate} · ${session.spoken ? localizations.t('spokenPrayer') : localizations.t('silentReflection')}',
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
                    localizations.t('listenDuration', {
                      'seconds': session.durationSeconds,
                    }),
                  ),
                ),
                IconButton(
                  tooltip: localizations.t('stopPlayback'),
                  onPressed: app.stopPlayback,
                  icon: const Icon(Icons.stop),
                ),
                IconButton(
                  tooltip: localizations.t('deleteAudioKeepMoment'),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      localizations.t('deleteRecordingTitle'),
                      localizations.t('deleteRecordingDescription'),
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
                localizations.t('deleteMomentTitle'),
                localizations.t('deleteMomentDescription'),
              )) {
                await app.deleteSession(session.id);
              }
            },
            child: Text(localizations.t('deleteMoment')),
          ),
        ],
      ),
    );
  }
}
