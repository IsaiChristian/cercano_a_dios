import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/prayer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';
import '../bloc/session_bloc.dart';

class SessionPage extends StatefulWidget {
  final PrayerPrompt prompt;
  final int? reminderId;

  const SessionPage({
    super.key,
    required this.prompt,
    this.reminderId,
  });

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage>
    with WidgetsBindingObserver {
  Set<String> previousBadges = {};

  AppBloc get app => context.read<AppBloc>();
  SessionBloc get bloc => context.read<SessionBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    previousBadges = app.state.progress(DateTime.now()).badges;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(bloc.interrupt());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          final localizations = AppLocalizations.of(context)!;
          final busy = [
            SessionPhase.starting,
            SessionPhase.stopping,
            SessionPhase.saving,
          ].contains(state.phase);

          if (state.phase == SessionPhase.complete) {
            final progress = app.state.progress(DateTime.now());
            final earned = progress.badges.difference(previousBadges);
            return Scaffold(
              appBar: AppBar(),
              body: PageBody(
                children: [
                  const SizedBox(height: 48),
                  const Icon(
                    Icons.check_circle_outline,
                    size: 72,
                    color: ink,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.t('momentWellSpent'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.t('prayerSaved', {
                      'count': progress.currentStreak,
                    }),
                    textAlign: TextAlign.center,
                  ),
                  if (earned.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    QuietCard(
                      color: sage,
                      child: Text(
                        localizations.t('newMilestone'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go('/'),
                    child: Text(localizations.t('returnToday')),
                  ),
                ],
              ),
            );
          }

          return PopScope(
            canPop: !busy,
            child: Scaffold(
              appBar: AppBar(
                title: Text(localizations.t('prayerMoment')),
              ),
              body: PageBody(
                children: [
                  SectionLabel(localizations.t('beStill')),
                  Text(
                    widget.prompt.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  QuietCard(
                    color: sage,
                    child: Text(
                      widget.prompt.text,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state.phase == SessionPhase.ready) ...[
                    Text(localizations.t('usePrayerBeginning')),
                    const SizedBox(height: 16),
                    Text(
                      localizations.t('voiceStaysDevice'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: bloc.start,
                      icon: const Icon(Icons.mic_none),
                      label: Text(localizations.t('speakPrayer')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => bloc.save(silent: true),
                      child: Text(localizations.t('silentMoment')),
                    ),
                  ],
                  if (state.phase == SessionPhase.recording) ...[
                    Text(
                      localizations.t('recording', {
                        'time': timeLabel(
                          state.seconds ~/ 60,
                          state.seconds % 60,
                        ),
                      }),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: localizations.t('microphoneLevel'),
                      child: LinearProgressIndicator(
                        value: state.level.clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: bloc.finish,
                      icon: const Icon(Icons.stop),
                      label: Text(localizations.t('finishRecording')),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.t('recordingLimit'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (state.phase == SessionPhase.review) ...[
                    Text(
                      localizations.t('yourRecording', {
                        'seconds': state.seconds,
                      }),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: bloc.play,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(localizations.t('listen')),
                    ),
                    TextButton(
                      onPressed: bloc.stopPlayback,
                      child: Text(localizations.t('stopPlayback')),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: bloc.save,
                      child: Text(localizations.t('saveComplete')),
                    ),
                    TextButton(
                      onPressed: bloc.start,
                      child: Text(localizations.t('recordAgain')),
                    ),
                    TextButton(
                      onPressed: () => bloc.save(silent: true),
                      child: Text(localizations.t('completeWithoutAudio')),
                    ),
                  ],
                  if (busy) const Center(child: CircularProgressIndicator()),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (!busy)
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(localizations.t('leaveWithoutSaving')),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
