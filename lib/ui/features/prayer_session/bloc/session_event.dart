part of 'session_bloc.dart';

abstract class SessionEvent {}

class SessionStartRequested extends SessionEvent {
  final Completer<void> result;

  SessionStartRequested(this.result);
}

class SessionFinishRequested extends SessionEvent {
  final Completer<void>? result;

  SessionFinishRequested([this.result]);
}

class SessionAmplitudeRequested extends SessionEvent {}

class SessionPlaybackRequested extends SessionEvent {
  final Completer<void>? result;

  SessionPlaybackRequested([this.result]);
}

class SessionPlaybackStopped extends SessionEvent {
  final Completer<void>? result;

  SessionPlaybackStopped([this.result]);
}

class SessionSaveRequested extends SessionEvent {
  final bool silent;
  final Completer<bool> result;

  SessionSaveRequested({required this.silent, required this.result});
}

class SessionInterrupted extends SessionEvent {
  final Completer<void>? result;

  SessionInterrupted([this.result]);
}
