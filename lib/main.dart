import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/di/bootstrap.dart';
import 'l10n/app_localizations.dart';
import 'core/router/router.dart';
import 'data/services/device_services.dart';
import 'ui/core/theme.dart';
import 'ui/features/app/bloc/app_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Startup());
}

class Startup extends StatefulWidget {
  const Startup({super.key});
  @override
  State<Startup> createState() => _StartupState();
}

class _StartupState extends State<Startup> {
  late Future<AppBloc> boot;
  @override
  void initState() {
    super.initState();
    boot = bootstrap();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppBloc>(
    future: boot,
    builder: (context, snapshot) {
      if (snapshot.hasData) return PrayerApp(app: snapshot.data!);
      return MaterialApp(
        theme: appTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            return Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(localizations.appOpenError),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(() => boot = bootstrap()),
                            child: Text(localizations.tryAgain),
                          ),
                        ],
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
  final AppBloc app;
  const PrayerApp({super.key, required this.app});
  @override
  State<PrayerApp> createState() => _PrayerAppState();
}

class _PrayerAppState extends State<PrayerApp> with WidgetsBindingObserver {
  late GoRouter router;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    router = createRouter(widget.app);
    WidgetsBinding.instance.addObserver(this);
    scheduleMidnightRefresh();
    widget.app.device.channel.setMethodCallHandler((call) async {
      if (call.method == 'recordingInterrupted') {
        widget.app.device.interruptions.add(null);
      }
      if (call.method == 'openPrayer' &&
          !router.routeInformationProvider.value.uri.path.startsWith(
            '/prayer/',
          )) {
        router.push(
          '/prayer/p01${call.arguments is int ? '?reminder=${call.arguments}' : ''}',
        );
      }
    });
    widget.app.device.channel
        .invokeMethod<int>('consumeOpenPrayer')
        .then((origin) {
          if (origin != null && mounted) {
            router.push('/prayer/p01?reminder=$origin');
          }
        })
        .catchError((Object _) {});
  }

  void scheduleMidnightRefresh() {
    timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(midnight.difference(now), () {
      widget.app.refresh();
      scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.app.refresh();
      scheduleMidnightRefresh();
    } else if (state == AppLifecycleState.paused) {
      timer?.cancel();
      widget.app.device.stopPlayback();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    router.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.app.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<DeviceServices>.value(value: widget.app.device),
      BlocProvider<AppBloc>.value(value: widget.app),
    ],
    child: MaterialApp.router(
      title: 'Cercano a Dios',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => BlocListener<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.error != null && current.error != previous.error,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error!)));
        },
        child: child!,
      ),
    ),
  );
}
