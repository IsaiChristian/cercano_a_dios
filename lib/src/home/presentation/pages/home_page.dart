import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/prompts.dart';
import '../../../../domain/entities/prayer.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/prompt_localization.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/presentation/widgets/quiet_card.dart';
import 'package:cercano_a_dios/presentation/widgets/page_body.dart';
import 'package:cercano_a_dios/presentation/widgets/section_label.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';

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
      final monday = civilDay(now).subtract(Duration(days: now.weekday - 1));
      final localizations = AppLocalizations.of(context)!;
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
              SectionLabel(localizations.onboardingTagline),
              Text(
                localizations.onboardingTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(localizations.onboardingSubtitle),
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
                        label: Text(localizations.beginMoment),
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.yourRhythm),
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
                            localizations.daysStreak(progress.currentStreak),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/progress'),
                          child: Text(localizations.view),
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
                          localizations.monday,
                          localizations.tuesday,
                          localizations.wednesday,
                          localizations.thursday,
                          localizations.friday,
                          localizations.saturday,
                          localizations.sunday,
                        ];
                        return Semantics(
                          label:
                              '${dayNames[i]} ${done ? localizations.completed : localizations.notCompleted}',
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
                          ? localizations.todayComplete
                          : localizations.todayIncomplete,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.weekProgress(
                        List.generate(
                          7,
                          (i) => calendarDate(monday.add(Duration(days: i))),
                        ).where(progress.dates.contains).length,
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.gentleInvitation),
              QuietCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.makePrayerPart),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/reminders'),
                      icon: const Icon(Icons.alarm),
                      label: Text(
                        state.reminders.isEmpty
                            ? localizations.setFirstAlarm
                            : localizations.manageAlarms,
                      ),
                    ),
                  ],
                ),
              ),
              SectionLabel(localizations.moreWays),
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
