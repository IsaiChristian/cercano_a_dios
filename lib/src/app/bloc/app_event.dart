part of 'app_bloc.dart';

abstract class AppEvent {}

class AppRefreshRequested extends AppEvent {
  final Completer<void>? result;

  AppRefreshRequested([this.result]);
}

class AppErrorReported extends AppEvent {
  final Object error;

  AppErrorReported(this.error);
}

class AppOnboardingCompleted extends AppEvent {
  final Completer<void>? result;

  AppOnboardingCompleted([this.result]);
}

class AppPrayerCompleted extends AppEvent {
  final PrayerSession session;
  final Completer<bool>? result;

  AppPrayerCompleted(this.session, [this.result]);
}

class AppSessionDeleted extends AppEvent {
  final String id;
  final Completer<void>? result;

  AppSessionDeleted(this.id, [this.result]);
}

class AppAudioDeleted extends AppEvent {
  final String id;
  final Completer<void>? result;

  AppAudioDeleted(this.id, [this.result]);
}

class AppAllAudioDeleted extends AppEvent {
  final Completer<void>? result;

  AppAllAudioDeleted([this.result]);
}

class AppReminderSaved extends AppEvent {
  final Reminder reminder;
  final Completer<bool>? result;

  AppReminderSaved(this.reminder, [this.result]);
}

class AppReminderDeleted extends AppEvent {
  final int id;
  final Completer<void>? result;

  AppReminderDeleted(this.id, [this.result]);
}

class AppReminderSnoozeCancelled extends AppEvent {
  final int id;
  final Completer<void>? result;

  AppReminderSnoozeCancelled(this.id, [this.result]);
}

class AppDataReset extends AppEvent {
  final Completer<bool>? result;

  AppDataReset([this.result]);
}

class AppAudioPlaybackRequested extends AppEvent {
  final PrayerSession session;

  AppAudioPlaybackRequested(this.session);
}

class AppAudioPlaybackStopped extends AppEvent {}

class AppDeviceSettingsRequested extends AppEvent {}

class AppAlarmTestRequested extends AppEvent {}
