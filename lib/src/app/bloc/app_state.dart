part of 'app_bloc.dart';

class AppState extends Equatable {
  final Locale locale;
  final List<PrayerSession> sessions;
  final List<Reminder> reminders;
  final bool loading;
  final String? error;
  final int audioBytes;
  final bool onboardingComplete;

  static const Locale defaultLocale = Locale('en');
  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];

  static Locale resolveLocale(Locale? locale) {
    if (locale == null) return defaultLocale;
    final code = locale.languageCode.toLowerCase();
    for (final supported in supportedLocales) {
      if (supported.languageCode.toLowerCase() == code) {
        return supported;
      }
    }
    return defaultLocale;
  }

  static Locale resolveInitialLocale({
    String? persistedLanguageCode,
    Locale? deviceLocale,
  }) {
    if (persistedLanguageCode != null &&
        persistedLanguageCode.trim().isNotEmpty) {
      final code = persistedLanguageCode.trim().toLowerCase();
      for (final supported in supportedLocales) {
        if (supported.languageCode.toLowerCase() == code) {
          return supported;
        }
      }
    }
    if (deviceLocale != null) {
      return resolveLocale(deviceLocale);
    }
    return defaultLocale;
  }

  AppState({
    this.locale = defaultLocale,
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
    bool clearError = false,
    int? audioBytes,
    bool? onboardingComplete,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      sessions: sessions ?? this.sessions,
      reminders: reminders ?? this.reminders,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      audioBytes: audioBytes ?? this.audioBytes,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  PrayerProgress progress(DateTime now) => calculateProgress(sessions, now);

  @override
  List<Object?> get props => [
    locale,
    sessions,
    reminders,
    loading,
    error,
    audioBytes,
    onboardingComplete,
  ];
}
