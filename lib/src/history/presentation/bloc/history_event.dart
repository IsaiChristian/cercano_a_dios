part of 'history_bloc.dart';

abstract class HistoryEvent {
  const HistoryEvent();
}

class HistoryLoadRequested extends HistoryEvent {
  final Completer<void>? result;

  const HistoryLoadRequested([this.result]);
}

class HistorySessionCompleted extends HistoryEvent {
  final PrayerSession session;
  final Completer<bool>? result;

  const HistorySessionCompleted(this.session, [this.result]);
}

class HistorySessionDeleted extends HistoryEvent {
  final String id;
  final Completer<void>? result;

  const HistorySessionDeleted(this.id, [this.result]);
}

class HistoryAudioDeleted extends HistoryEvent {
  final String id;
  final Completer<void>? result;

  const HistoryAudioDeleted(this.id, [this.result]);
}

class HistoryAllAudioDeleted extends HistoryEvent {
  final Completer<void>? result;

  const HistoryAllAudioDeleted([this.result]);
}
