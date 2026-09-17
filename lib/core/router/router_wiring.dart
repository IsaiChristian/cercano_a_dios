import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../data/services/device_services.dart';
import '../../l10n/app_localizations.dart';
import 'package:cercano_a_dios/src/app/bloc/app_bloc.dart';
import 'package:cercano_a_dios/src/app_session/bloc/app_session_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';

/// Notifier that triggers GoRouter redirect re-evaluation on auth and session state changes.
class AppRouterRefreshListenable extends ChangeNotifier {
  late final StreamSubscription<AuthState>? _authSub;
  late final StreamSubscription<AppSessionState>? _sessionSub;

  AppRouterRefreshListenable({
    AuthBloc? authBloc,
    AppSessionBloc? appSessionBloc,
  }) {
    _authSub = authBloc?.stream.listen((_) => notifyListeners());
    _sessionSub = appSessionBloc?.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }
}

/// Scopes feature-level BLoC and service providers to the active authenticated profile.
///
/// Detaches and unmounts the old feature tree immediately when the profile is closed
/// or transitioning.
class AuthenticatedFeatureScope extends StatelessWidget {
  final AppSessionBloc? sessionBloc;
  final AppBloc? legacyApp;
  final Widget child;

  const AuthenticatedFeatureScope({
    super.key,
    this.sessionBloc,
    this.legacyApp,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (sessionBloc != null) {
      return BlocBuilder<AppSessionBloc, AppSessionState>(
        bloc: sessionBloc,
        builder: (context, sessionState) {
          final activeApp = sessionBloc!.activeAppBloc;
          if (sessionState.status != AppSessionStatus.ready ||
              activeApp == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return MultiProvider(
            key: ValueKey(
              'profile_${sessionState.userId}_${activeApp.hashCode}',
            ),
            providers: [
              Provider<DeviceServices>.value(value: activeApp.device),
              BlocProvider<AppBloc>.value(value: activeApp),
              BlocProvider<RemindersBloc>.value(value: activeApp.remindersBloc),
              BlocProvider<AudioBloc>.value(value: activeApp.audioBloc),
              BlocProvider<HistoryBloc>.value(value: activeApp.historyBloc),
            ],
            child: child,
          );
        },
      );
    }

    if (legacyApp != null) {
      return MultiProvider(
        key: ValueKey('legacy_app_${legacyApp.hashCode}'),
        providers: [
          Provider<DeviceServices>.value(value: legacyApp!.device),
          BlocProvider<AppBloc>.value(value: legacyApp!),
          BlocProvider<RemindersBloc>.value(value: legacyApp!.remindersBloc),
          BlocProvider<AudioBloc>.value(value: legacyApp!.audioBloc),
          BlocProvider<HistoryBloc>.value(value: legacyApp!.historyBloc),
        ],
        child: child,
      );
    }

    return child;
  }
}

/// Loading screen shown while opening the active local user profile.
class ProfileLoadingPage extends StatelessWidget {
  const ProfileLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              localizations.openingLocalProfile,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen displayed when local profile opening fails.
class ProfileErrorPage extends StatelessWidget {
  final AppSessionBloc sessionBloc;
  final AuthBloc authBloc;

  const ProfileErrorPage({
    super.key,
    required this.sessionBloc,
    required this.authBloc,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                localizations.appOpenError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  sessionBloc.add(const AppSessionRetryRequested());
                },
                child: Text(localizations.tryAgain),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  authBloc.add(const AuthSignOutRequested());
                },
                child: Text(localizations.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen displayed when the cold-start session check fails.
class SessionCheckFailedPage extends StatelessWidget {
  final AuthBloc authBloc;

  const SessionCheckFailedPage({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                localizations.authFailureConfiguration,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  authBloc.add(const AuthSessionCheckRequested());
                },
                child: Text(localizations.retrySessionCheck),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  authBloc.add(const AuthSignOutRequested());
                },
                child: Text(localizations.signIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
