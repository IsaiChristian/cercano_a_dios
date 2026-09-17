part of 'app_bloc.dart';

abstract class AppEvent {
  const AppEvent();
}

class AppLocaleChanged extends AppEvent {
  final Locale locale;
  final Completer<void>? result;

  const AppLocaleChanged(this.locale, [this.result]);
}

class AppRefreshRequested extends AppEvent {
  final Completer<void>? result;

  const AppRefreshRequested([this.result]);
}

class AppErrorReported extends AppEvent {
  final Object error;

  const AppErrorReported(this.error);
}

class AppOnboardingCompleted extends AppEvent {
  final Completer<void>? result;

  const AppOnboardingCompleted([this.result]);
}

class AppPrayerCompleted extends AppEvent {
  final PrayerSession session;
  final Completer<bool>? result;

  const AppPrayerCompleted(this.session, [this.result]);
}

class AppSessionDeleted extends AppEvent {
  final String id;
  final Completer<void>? result;

  const AppSessionDeleted(this.id, [this.result]);
}

class AppAudioDeleted extends AppEvent {
  final String id;
  final Completer<void>? result;

  const AppAudioDeleted(this.id, [this.result]);
}

class AppAllAudioDeleted extends AppEvent {
  final Completer<void>? result;

  const AppAllAudioDeleted([this.result]);
}

class AppReminderSaved extends AppEvent {
  final Reminder reminder;
  final Completer<bool>? result;

  const AppReminderSaved(this.reminder, [this.result]);
}

class AppReminderDeleted extends AppEvent {
  final int id;
  final Completer<void>? result;

  const AppReminderDeleted(this.id, [this.result]);
}

class AppReminderSnoozeCancelled extends AppEvent {
  final int id;
  final Completer<void>? result;

  const AppReminderSnoozeCancelled(this.id, [this.result]);
}

class AppDataReset extends AppEvent {
  final Completer<bool>? result;

  const AppDataReset([this.result]);
}

class AppAudioPlaybackRequested extends AppEvent {
  final PrayerSession session;

  const AppAudioPlaybackRequested(this.session);
}

class AppAudioPlaybackStopped extends AppEvent {
  const AppAudioPlaybackStopped();
}

class AppDeviceSettingsRequested extends AppEvent {
  const AppDeviceSettingsRequested();
}

class AppAlarmTestRequested extends AppEvent {
  const AppAlarmTestRequested();
}

class _AppSessionsUpdated extends AppEvent {
  final List<PrayerSession> sessions;

  const _AppSessionsUpdated(this.sessions);
}

class _AppRemindersUpdated extends AppEvent {
  final List<Reminder> reminders;

  const _AppRemindersUpdated(this.reminders);
}

class _AppAudioBytesUpdated extends AppEvent {
  final int audioBytes;

  const _AppAudioBytesUpdated(this.audioBytes);
}
