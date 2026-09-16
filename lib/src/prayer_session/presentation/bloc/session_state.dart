part of 'session_bloc.dart';

enum SessionPhase {
  ready,
  starting,
  recording,
  stopping,
  review,
  saving,
  complete,
}

class SessionState {
  final SessionPhase phase;
  final int seconds;
  final double level;
  final String? error;

  const SessionState(
    this.phase, {
    this.seconds = 0,
    this.level = 0,
    this.error,
  });
}
