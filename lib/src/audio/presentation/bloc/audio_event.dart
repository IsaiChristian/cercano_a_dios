part of 'audio_bloc.dart';

abstract class AudioEvent {
  const AudioEvent();
}

class AudioBytesLoadRequested extends AudioEvent {
  final Completer<void>? result;

  const AudioBytesLoadRequested([this.result]);
}

class AudioPlaybackRequested extends AudioEvent {
  final PrayerSession session;
  final Completer<void>? result;

  const AudioPlaybackRequested(this.session, [this.result]);
}

class AudioPlaybackStopped extends AudioEvent {
  final Completer<void>? result;

  const AudioPlaybackStopped([this.result]);
}

class AudioDeleted extends AudioEvent {
  final String id;
  final Completer<AudioDeleteResult>? result;

  const AudioDeleted(this.id, [this.result]);
}

class AudioAllDeleted extends AudioEvent {
  final List<PrayerSession>? sessions;
  final Completer<AudioDeleteResult>? result;

  const AudioAllDeleted([this.sessions, this.result]);
}

class AudioErrorCleared extends AudioEvent {
  const AudioErrorCleared();
}
