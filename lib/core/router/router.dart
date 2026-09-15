import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/prompts.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/core/prompt_localization.dart';
import '../../ui/core/theme.dart';
import '../../ui/core/widgets.dart';
import '../../ui/features/app/bloc/app_bloc.dart';
import '../../ui/features/history/views/history_page.dart';
import '../../ui/features/home/views/home_page.dart';
import '../../ui/features/prayer_session/views/session_page.dart';
import '../../ui/features/prayer_session/bloc/session_bloc.dart';
import '../../ui/features/progress/views/progress_page.dart';
import '../../ui/features/reminders/bloc/reminders_bloc.dart';
import '../../ui/features/reminders/views/reminders_page.dart';
import '../../ui/features/settings/views/settings_page.dart';

GoRouter createRouter(AppBloc app) => GoRouter(
      initialLocation: app.state.onboardingComplete ? '/' : '/welcome',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) {
            final localizations = AppLocalizations.of(context)!;
            return Scaffold(
              body: SafeArea(
                child: PageBody(
                  children: [
                    const SizedBox(height: 48),
                    const Icon(Icons.church_outlined, size: 64, color: ink),
                    const SizedBox(height: 32),
                    Text(
                      'Cercano\na Dios',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Make a little space for prayer.\nGive thanks. Speak from the heart.\nReturn tomorrow.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    QuietCard(
                      color: sage,
                      child: Text(localizations.t('onboardingPrivacy')),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () async {
                        await app.completeOnboarding();
                        if (context.mounted) context.go('/');
                      },
                      child: Text(localizations.t('beginJourney')),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            final localizations = AppLocalizations.of(context)!;
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  localizations.t('appName'),
                  style: const TextStyle(fontFamily: 'serif'),
                ),
                actions: [
                  IconButton(
                    tooltip: localizations.t('milestones'),
                    onPressed: () => context.push('/progress'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                  ),
                ],
              ),
              body: SafeArea(child: child),
              bottomNavigationBar: NavigationBar(
                selectedIndex: switch (state.uri.path) {
                  '/reminders' => 1,
                  '/history' => 2,
                  '/settings' => 3,
                  _ => 0,
                },
                onDestinationSelected: (index) => context.go(
                  ['/', '/reminders', '/history', '/settings'][index],
                ),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.wb_sunny_outlined),
                    label: localizations.t('today'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.alarm),
                    label: localizations.t('alarms'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    label: localizations.t('journal'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.tune),
                    label: localizations.t('settings'),
                  ),
                ],
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (_, state) => HomePage(app: app),
            ),
            GoRoute(
              path: '/reminders',
              builder: (_, state) => BlocProvider(
                create: (_) => RemindersBloc(app: app, device: app.device),
                child: const RemindersPage(),
              ),
            ),
            GoRoute(
              path: '/history',
              builder: (_, state) => HistoryPage(app: app),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, state) => SettingsPage(app: app),
            ),
          ],
        ),
        GoRoute(
          path: '/prayer/:id',
          builder: (context, state) {
            final prompt = localizedPrompt(
              context,
              prompts.firstWhere(
                (prompt) => prompt.id == state.pathParameters['id'],
                orElse: () => prompts.first,
              ),
            );
            return BlocProvider(
              create: (_) => SessionBloc(
                device: app.device,
                storage: app.storage,
                prompt: prompt,
                reminderId: int.tryParse(
                  state.uri.queryParameters['reminder'] ?? '',
                ),
                audioBytes: () => app.state.audioBytes,
                completeSession: app.complete,
                cancelReminderSnooze: app.cancelReminderSnooze,
                lastError: () => app.state.error,
              ),
              child: SessionPage(prompt: prompt),
            );
          },
        ),
        GoRoute(
          path: '/progress',
          builder: (_, state) => ProgressPage(app: app),
        ),
      ],
    );
