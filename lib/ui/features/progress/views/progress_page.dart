import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../domain/use_cases/calculate_progress.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';

class ProgressPage extends StatelessWidget {
  final AppBloc app;

  const ProgressPage({super.key, required this.app});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context)!.milestones)),
    body: BlocBuilder<AppBloc, AppState>(
      bloc: app,
      builder: (context, _) {
        final localizations = AppLocalizations.of(context)!;
        final progress = app.state.progress(DateTime.now());
        return PageBody(
          children: [
            SectionLabel(localizations.smallMoments),
            Text(
              localizations.progressTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            QuietCard(
              color: sage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.daysStreak(progress.currentStreak),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.bestAndMoments(
                      progress.bestStreak,
                      progress.total,
                    ),
                  ),
                ],
              ),
            ),
            SectionLabel(localizations.milestones),
            ...badgeLabels.entries.map(
              (badge) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: progress.badges.contains(badge.key)
                      ? sage
                      : Colors.white,
                  child: Icon(
                    progress.badges.contains(badge.key)
                        ? Icons.auto_awesome_outlined
                        : Icons.lock_outline,
                    color: ink,
                  ),
                ),
                title: Text(badge.value),
                subtitle: Text(
                  progress.badges.contains(badge.key)
                      ? localizations.milestoneReached
                      : localizations.oneMoment,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(localizations.progressDisclaimer),
          ],
        );
      },
    ),
  );
}
