import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/prompts.dart';
import '../../../../domain/entities/prayer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/prompt_localization.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../app/bloc/app_bloc.dart';

class HomePage extends StatelessWidget {
  final AppBloc app;

  const HomePage({super.key, required this.app});

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        bloc: app,
        builder: (context, state) {
          final now = DateTime.now();
          final progress = state.progress(now);
          final prompt = localizedPrompt(
            context,
            prompts[(now.day + now.month * 31) % prompts.length],
          );
          final monday = civilDay(now).subtract(
            Duration(days: now.weekday - 1),
          );
          final localizations =
              AppLocalizations.of(context) ?? const AppLocalizations(Locale('en'));

          return PageBody(
            children: [
              SectionLabel(localizations.t('onboardingTagline')),
              Text(
                localizations.t('onboardingTitle'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(localizations.t('onboardingSubtitle')),
              const SizedBox(height: 28),
              QuietCard(
                color: sage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 36, color: ink),
                    const SizedBox(height: 24),
                    Text(
                      prompt.category.toUpperCase(),
                      style: const TextStyle(fontSize: 11, letterSpacing: 2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      prompt.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      prompt.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/prayer/${prompt.id}'),
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(localizations.t('beginMoment')),
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.t('yourRhythm')),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_outlined,
                          color: Color(0xFFB27443),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            localizations.t(
                              'daysStreak',
                              {'count': progress.currentStreak},
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/progress'),
                          child: Text(localizations.t('view')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final date = calendarDate(
                          monday.add(Duration(days: i)),
                        );
                        final done = progress.dates.contains(date);
                        final dayNames = [
                          localizations.t('monday'),
                          localizations.t('tuesday'),
                          localizations.t('wednesday'),
                          localizations.t('thursday'),
                          localizations.t('friday'),
                          localizations.t('saturday'),
                          localizations.t('sunday'),
                        ];
                        return Semantics(
                          label:
                              '${dayNames[i]} ${done ? localizations.t('completed') : localizations.t('notCompleted')}',
                          child: Column(
                            children: [
                              Text(
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: done ? ink : cream,
                                child: done
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : const SizedBox(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      progress.dates.contains(calendarDate(now))
                          ? localizations.t('todayComplete')
                          : localizations.t('todayIncomplete'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.t('weekProgress', {
                        'count': List.generate(
                          7,
                          (i) => calendarDate(monday.add(Duration(days: i))),
                        ).where(progress.dates.contains).length,
                      }),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.t('gentleInvitation')),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.t('makePrayerPart')),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/reminders'),
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        state.reminders.isEmpty
                            ? localizations.t('setFirstAlarm')
                            : localizations.t('manageAlarms'),
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.t('moreWays')),
              ...prompts.take(4).map((raw) {
                final localized = localizedPrompt(context, raw);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(localized.title),
                  subtitle: Text(localized.category),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/prayer/${localized.id}'),
                );
              }),
            ],
          );
        },
      );
}
