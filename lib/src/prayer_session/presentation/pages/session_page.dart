import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/prayer.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/presentation/widgets/quiet_card.dart';
import 'package:cercano_a_dios/presentation/widgets/page_body.dart';
import 'package:cercano_a_dios/presentation/widgets/section_label.dart';
import 'package:cercano_a_dios/presentation/formatters/time_label.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import '../bloc/session_bloc.dart';

class SessionPage extends StatefulWidget {
  final PrayerPrompt prompt;
  final int? reminderId;

  const SessionPage({super.key, required this.prompt, this.reminderId});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> with WidgetsBindingObserver {
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
              const Icon(Icons.check_circle_outline, size: 72, color: ink),
              const SizedBox(height: 24),
              Text(
                localizations.momentWellSpent,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.prayerSaved(progress.currentStreak),
                textAlign: TextAlign.center,
              ),
              if (earned.isNotEmpty) ...[
                const SizedBox(height: 24),
                QuietCard(
                  color: sage,
                  child: Text(
                    localizations.newMilestone,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/'),
                child: Text(localizations.returnToday),
              ),
            ],
          ),
        );
      }

      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(title: Text(localizations.prayerMoment)),
          body: PageBody(
            children: [
              SectionLabel(localizations.beStill),
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
                Text(localizations.usePrayerBeginning),
                const SizedBox(height: 16),
                Text(
                  localizations.voiceStaysDevice,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: bloc.start,
                  icon: const Icon(Icons.mic_none),
                  label: Text(localizations.speakPrayer),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => bloc.save(silent: true),
                  child: Text(localizations.silentMoment),
                ),
              ],
              if (state.phase == SessionPhase.recording) ...[
                Text(
                  localizations.recording(
                    timeLabel(state.seconds ~/ 60, state.seconds % 60),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: localizations.microphoneLevel,
                  child: LinearProgressIndicator(
                    value: state.level.clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: bloc.finish,
                  icon: const Icon(Icons.stop),
                  label: Text(localizations.finishRecording),
                ),
                const SizedBox(height: 12),
                Text(localizations.recordingLimit, textAlign: TextAlign.center),
              ],
              if (state.phase == SessionPhase.review) ...[
                Text(localizations.yourRecording(state.seconds)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: bloc.play,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(localizations.listen),
                ),
                TextButton(
                  onPressed: bloc.stopPlayback,
                  child: Text(localizations.stopPlayback),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: bloc.save,
                  child: Text(localizations.saveComplete),
                ),
                TextButton(
                  onPressed: bloc.start,
                  child: Text(localizations.recordAgain),
                ),
                TextButton(
                  onPressed: () => bloc.save(silent: true),
                  child: Text(localizations.completeWithoutAudio),
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
                  child: Text(localizations.leaveWithoutSaving),
                ),
            ],
          ),
        ),
      );
    },
  );
}
