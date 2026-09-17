part of 'history_bloc.dart';

class HistoryState extends Equatable {
  final List<PrayerSession> sessions;
  final bool loading;
  final String? error;

  const HistoryState({
    this.sessions = const [],
    this.loading = false,
    this.error,
  });

  HistoryState copyWith({
    List<PrayerSession>? sessions,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [sessions, loading, error];
}
