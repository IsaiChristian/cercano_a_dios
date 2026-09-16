import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/prompts.dart';
import '../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/prompt_localization.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/ui/core/widgets.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/history/presentation/pages/history_page.dart';
import 'package:cercano_a_dios/src/home/presentation/pages/home_page.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/pages/session_page.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/bloc/session_bloc.dart';
import 'package:cercano_a_dios/src/progress/presentation/pages/progress_page.dart';
import 'package:cercano_a_dios/src/reminders/presentation/bloc/reminders_bloc.dart';
import 'package:cercano_a_dios/src/reminders/presentation/pages/reminders_page.dart';
import 'package:cercano_a_dios/src/settings/presentation/pages/settings_page.dart';

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
                  localizations.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                Text(localizations.welcomeBody, textAlign: TextAlign.center),
                const SizedBox(height: 40),
                QuietCard(
                  color: sage,
                  child: Text(localizations.onboardingPrivacy),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    await app.completeOnboarding();
                    if (context.mounted) context.go('/');
                  },
                  child: Text(localizations.beginJourney),
                ),
              ],
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(app: app),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => BlocProvider(
        create: (_) => RemindersBloc(app: app, device: app.device),
        child: const RemindersPage(),
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => HistoryPage(app: app),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(app: app),
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
