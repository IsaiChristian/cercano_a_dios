part of 'app_bloc.dart';

class AppState {
  final Locale locale;
  final List<PrayerSession> sessions;
  final List<Reminder> reminders;
  final bool loading;
  final String? error;
  final int audioBytes;
  final bool onboardingComplete;

  AppState({
    this.locale = const Locale('en'),
    List<PrayerSession> sessions = const [],
    List<Reminder> reminders = const [],
    this.loading = false,
    this.error,
    this.audioBytes = 0,
    this.onboardingComplete = false,
  }) : sessions = List.unmodifiable(sessions),
       reminders = List.unmodifiable(reminders);

  AppState copyWith({
    Locale? locale,
    List<PrayerSession>? sessions,
    List<Reminder>? reminders,
    bool? loading,
    String? error,
    int? audioBytes,
    bool? onboardingComplete,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      sessions: sessions ?? this.sessions,
      reminders: reminders ?? this.reminders,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      audioBytes: audioBytes ?? this.audioBytes,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  PrayerProgress progress(DateTime now) => calculateProgress(sessions, now);
}
