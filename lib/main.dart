import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/di/bootstrap.dart';
import 'core/router/router.dart';
import 'data/services/device_services.dart';
import 'domain/repositories/auth_repository.dart';
import 'l10n/app_localizations.dart';
import 'presentation/theme.dart';
import 'src/app/bloc/app_bloc.dart';
import 'src/app_session/bloc/app_session_bloc.dart';
import 'src/auth/presentation/bloc/auth_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Startup());
}

class Startup extends StatefulWidget {
  final Future<AppBootstrapResult> Function()? bootstrapOverride;

  const Startup({super.key, this.bootstrapOverride});

  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  late Future<AppBootstrapResult> _boot;

  @override
  void initState() {
    super.initState();
    _boot = (widget.bootstrapOverride ?? bootstrap)();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppBootstrapResult>(
    future: _boot,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return PrayerApp(bootstrapResult: snapshot.data!);
      }
      return MaterialApp(
        theme: appTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            final errorMessage = snapshot.error is StateError
                ? localizations.authFailureConfiguration
                : localizations.appOpenError;
            return Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(errorMessage, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => setState(() {
                                _boot =
                                    (widget.bootstrapOverride ?? bootstrap)();
                              }),
                              child: Text(localizations.tryAgain),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            );
          },
        ),
      );
    },
  );
}

class PrayerApp extends StatefulWidget {
  final AppBootstrapResult? bootstrapResult;
  final AppBloc? app;
  final bool schedulePeriodicRefresh;

  const PrayerApp({
    super.key,
    this.bootstrapResult,
    this.app,
    this.schedulePeriodicRefresh = true,
  }) : assert(
         bootstrapResult != null || app != null,
         'Either bootstrapResult or app must be provided',
       );

  @override
  State<PrayerApp> createState() => _PrayerAppState();
}

class _PrayerAppState extends State<PrayerApp> with WidgetsBindingObserver {
  late GoRouter router;
  AppRouterRefreshListenable? _refreshListenable;
  Timer? timer;
  StreamSubscription<AppSessionState>? _sessionSub;
  int? _pendingOpenPrayerReminderId;
  bool _hasPendingOpenPrayer = false;

  DeviceServices get _device =>
      widget.bootstrapResult?.device ?? widget.app!.device;
  AppSessionBloc? get _sessionBloc => widget.bootstrapResult?.appSessionBloc;
  AuthBloc? get _authBloc => widget.bootstrapResult?.authBloc;
  AuthRepository? get _authRepo => widget.bootstrapResult?.authRepository;

  @override
  void initState() {
    super.initState();
    if (_authBloc != null || _sessionBloc != null) {
      _refreshListenable = AppRouterRefreshListenable(
        authBloc: _authBloc,
        appSessionBloc: _sessionBloc,
      );
    }
    router = createRouter(
      authBloc: _authBloc,
      appSessionBloc: _sessionBloc,
      app: widget.app,
      refreshListenable: _refreshListenable,
    );
    WidgetsBinding.instance.addObserver(this);
    if (widget.schedulePeriodicRefresh) {
      scheduleMidnightRefresh();
    }

    _device.channel.setMethodCallHandler((call) async {
      if (call.method == 'recordingInterrupted') {
        _device.interruptions.add(null);
      }
      if (call.method == 'openPrayer') {
        final reminderId = call.arguments is int ? call.arguments as int : null;
        _handleOpenPrayer(reminderId);
      }
    });

    _device.channel
        .invokeMethod<int>('consumeOpenPrayer')
        .then((origin) {
          if (origin != null && mounted) {
            _handleOpenPrayer(origin);
          }
        })
        .catchError((Object _) {});

    if (_sessionBloc != null) {
      _sessionSub = _sessionBloc!.stream.listen((state) {
        if (state.status == AppSessionStatus.ready && _hasPendingOpenPrayer) {
          final reminderId = _pendingOpenPrayerReminderId;
          _hasPendingOpenPrayer = false;
          _pendingOpenPrayerReminderId = null;
          _dispatchOpenPrayer(reminderId);
        }
      });
    }
  }

  void _handleOpenPrayer(int? reminderId) {
    if (_sessionBloc == null) {
      if (!router.routeInformationProvider.value.uri.path.startsWith(
        '/prayer/',
      )) {
        router.push(
          '/prayer/p01${reminderId != null ? '?reminder=$reminderId' : ''}',
        );
      }
      return;
    }

    if (_sessionBloc!.state.status == AppSessionStatus.ready &&
        _sessionBloc!.activeAppBloc != null) {
      _dispatchOpenPrayer(reminderId);
    } else {
      _pendingOpenPrayerReminderId = reminderId;
      _hasPendingOpenPrayer = true;
    }
  }

  void _dispatchOpenPrayer(int? reminderId) {
    if (_sessionBloc != null) {
      if (reminderId != null) {
        if (!_sessionBloc!.isValidReminderId(reminderId)) {
          // Drop stale or mismatched reminder ID
          return;
        }
      }
    }

    final currentPath = router.routeInformationProvider.value.uri.path;
    if (!currentPath.startsWith('/prayer/')) {
      router.push(
        '/prayer/p01${reminderId != null ? '?reminder=$reminderId' : ''}',
      );
    }
  }

  void scheduleMidnightRefresh() {
    timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(midnight.difference(now), () {
      final activeApp = _sessionBloc?.activeAppBloc ?? widget.app;
      activeApp?.refresh();
      scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final activeApp = _sessionBloc?.activeAppBloc ?? widget.app;
    if (state == AppLifecycleState.resumed) {
      activeApp?.refresh();
      scheduleMidnightRefresh();
    } else if (state == AppLifecycleState.paused) {
      timer?.cancel();
      _device.stopPlayback();
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    timer?.cancel();
    _refreshListenable?.dispose();
    router.dispose();
    _device.channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    if (widget.bootstrapResult != null) {
      unawaited(widget.bootstrapResult!.dispose());
    } else if (widget.app != null) {
      unawaited(widget.app!.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providers = <SingleChildWidget>[
      Provider<DeviceServices>.value(value: _device),
      if (_authRepo != null)
        RepositoryProvider<AuthRepository>.value(value: _authRepo!),
      if (_authBloc != null) BlocProvider<AuthBloc>.value(value: _authBloc!),
      if (_sessionBloc != null)
        BlocProvider<AppSessionBloc>.value(value: _sessionBloc!),
      if (widget.app != null) ...[
        BlocProvider<AppBloc>.value(value: widget.app!),
        BlocProvider<RemindersBloc>.value(value: widget.app!.remindersBloc),
        BlocProvider<AudioBloc>.value(value: widget.app!.audioBloc),
        BlocProvider<HistoryBloc>.value(value: widget.app!.historyBloc),
      ],
    ];

    Widget buildApp({Locale? locale, AppBloc? listenerApp}) {
      return MaterialApp.router(
        title: 'Cercano a Dios',
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
        theme: appTheme(),
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          if (listenerApp != null) {
            return BlocListener<AppBloc, AppState>(
              bloc: listenerApp,
              listenWhen: (previous, current) =>
                  current.error != null && current.error != previous.error,
              listener: (context, state) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.error!)));
              },
              child: child!,
            );
          }
          return child!;
        },
      );
    }

    if (_sessionBloc != null) {
      return MultiProvider(
        providers: providers,
        child: BlocBuilder<AppSessionBloc, AppSessionState>(
          bloc: _sessionBloc,
          builder: (context, sessionState) {
            final activeApp = _sessionBloc!.activeAppBloc;
            if (activeApp != null) {
              return BlocBuilder<AppBloc, AppState>(
                bloc: activeApp,
                builder: (context, appState) =>
                    buildApp(locale: appState.locale, listenerApp: activeApp),
              );
            }
            return buildApp(locale: null, listenerApp: null);
          },
        ),
      );
    }

    return MultiProvider(
      providers: providers,
      child: BlocBuilder<AppBloc, AppState>(
        bloc: widget.app,
        builder: (context, state) =>
            buildApp(locale: state.locale, listenerApp: widget.app),
      ),
    );
  }
}
