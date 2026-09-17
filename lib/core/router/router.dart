import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/prompts.dart';
import '../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/presentation/prompt_localization.dart';
import 'package:cercano_a_dios/presentation/theme.dart';
import 'package:cercano_a_dios/ui/core/widgets.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/pages/auth_page.dart';
import 'package:cercano_a_dios/src/history/presentation/pages/history_page.dart';
import 'package:cercano_a_dios/src/home/presentation/pages/home_page.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/pages/session_page.dart';
import 'package:cercano_a_dios/src/prayer_session/presentation/bloc/session_bloc.dart';
import 'package:cercano_a_dios/src/progress/presentation/pages/progress_page.dart';
import 'package:cercano_a_dios/src/reminders/presentation/pages/reminders_page.dart';
import 'package:cercano_a_dios/src/settings/presentation/pages/settings_page.dart';
import 'router_wiring.dart';

export 'router_wiring.dart';

/// Builds the GoRouter instance wired with authentication and profile lifecycle guards.
GoRouter createRouter({
  AuthBloc? authBloc,
  AppSessionBloc? appSessionBloc,
  AppBloc? app,
  String? initialLocation,
  Listenable? refreshListenable,
}) {
  final effectiveRefreshListenable =
      refreshListenable ??
      (authBloc != null || appSessionBloc != null
          ? AppRouterRefreshListenable(
              authBloc: authBloc,
              appSessionBloc: appSessionBloc,
            )
          : null);

  final String effectiveInitialLocation;
  if (initialLocation != null) {
    effectiveInitialLocation = initialLocation;
  } else if (authBloc != null &&
      authBloc.state.sessionStatus == AuthSessionStatus.unauthenticated) {
    effectiveInitialLocation = '/auth';
  } else if (app != null) {
    effectiveInitialLocation = app.state.onboardingComplete ? '/' : '/welcome';
  } else if (authBloc != null &&
      authBloc.state.sessionStatus == AuthSessionStatus.authenticated &&
      appSessionBloc != null &&
      appSessionBloc.state.status == AppSessionStatus.ready &&
      appSessionBloc.activeAppBloc != null) {
    effectiveInitialLocation =
        appSessionBloc.activeAppBloc!.state.onboardingComplete
        ? '/'
        : '/welcome';
  } else {
    effectiveInitialLocation = '/loading';
  }

  return GoRouter(
    initialLocation: effectiveInitialLocation,
    refreshListenable: effectiveRefreshListenable,
    redirect: (context, state) {
      if (authBloc == null || appSessionBloc == null) {
        if (app != null) {
          final onboarding = app.state.onboardingComplete;
          final isWelcome = state.uri.path == '/welcome';
          if (!onboarding && !isWelcome) return '/welcome';
          if (onboarding && isWelcome) return '/';
        }
        return null;
      }

      final authState = authBloc.state;
      final sessionState = appSessionBloc.state;
      final path = state.uri.path;

      // 1. Initial session check on startup
      if (authState.sessionStatus == AuthSessionStatus.unknown) {
        if (authState.operationStatus == AuthOperationStatus.failed) {
          return path == '/session-check-failed'
              ? null
              : '/session-check-failed';
        }
        return path == '/loading' ? null : '/loading';
      }

      // 2. Unauthenticated -> AuthPage
      if (authState.sessionStatus == AuthSessionStatus.unauthenticated) {
        return path == '/auth' ? null : '/auth';
      }

      // 3. Authenticated
      if (authState.sessionStatus == AuthSessionStatus.authenticated) {
        final activeUser = authState.user;

        // Profile loading or switching/transitioning
        if (sessionState.status == AppSessionStatus.loading ||
            sessionState.status == AppSessionStatus.signedOut ||
            sessionState.userId != activeUser?.id) {
          return path == '/loading' ? null : '/loading';
        }

        // Profile failed to open
        if (sessionState.status == AppSessionStatus.failure) {
          return path == '/profile-error' ? null : '/profile-error';
        }

        // Profile ready with matching user
        if (sessionState.status == AppSessionStatus.ready &&
            sessionState.userId == activeUser?.id &&
            appSessionBloc.activeAppBloc != null) {
          final activeApp = appSessionBloc.activeAppBloc!;
          final isOnboardingComplete = activeApp.state.onboardingComplete;

          // If coming from auth or status routes, go to main flow
          if (path == '/auth' ||
              path == '/loading' ||
              path == '/profile-error' ||
              path == '/session-check-failed') {
            return isOnboardingComplete ? '/' : '/welcome';
          }

          if (!isOnboardingComplete && path != '/welcome') {
            return '/welcome';
          }

          if (isOnboardingComplete && path == '/welcome') {
            return '/';
          }

          return null;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const ProfileLoadingPage(),
      ),
      GoRoute(
        path: '/session-check-failed',
        builder: (context, state) =>
            SessionCheckFailedPage(authBloc: authBloc!),
      ),
      GoRoute(
        path: '/profile-error',
        builder: (context, state) =>
            ProfileErrorPage(sessionBloc: appSessionBloc!, authBloc: authBloc!),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      ShellRoute(
        builder: (context, state, child) => AuthenticatedFeatureScope(
          sessionBloc: appSessionBloc,
          legacyApp: app,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
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
                      Text(
                        localizations.welcomeBody,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      QuietCard(
                        color: sage,
                        child: Text(localizations.onboardingPrivacy),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () async {
                          await activeApp.completeOnboarding();
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
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              return HomePage(app: activeApp);
            },
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              return BlocProvider<RemindersBloc>.value(
                value: activeApp.remindersBloc,
                child: const RemindersPage(),
              );
            },
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              return HistoryPage(app: activeApp);
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              return SettingsPage(app: activeApp);
            },
          ),
          GoRoute(
            path: '/prayer/:id',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              final prompt = localizedPrompt(
                context,
                prompts.firstWhere(
                  (prompt) => prompt.id == state.pathParameters['id'],
                  orElse: () => prompts.first,
                ),
              );
              return BlocProvider(
                create: (_) => SessionBloc(
                  device: activeApp.device,
                  storage: activeApp.storage,
                  prompt: prompt,
                  reminderId: int.tryParse(
                    state.uri.queryParameters['reminder'] ?? '',
                  ),
                  audioBytes: () => activeApp.state.audioBytes,
                  completeSession: activeApp.complete,
                  cancelReminderSnooze: activeApp.cancelReminderSnooze,
                  lastError: () => activeApp.state.error,
                ),
                child: SessionPage(prompt: prompt),
              );
            },
          ),
          GoRoute(
            path: '/progress',
            builder: (context, state) {
              final activeApp = appSessionBloc?.activeAppBloc ?? app!;
              return ProgressPage(app: activeApp);
            },
          ),
        ],
      ),
    ],
  );
}
