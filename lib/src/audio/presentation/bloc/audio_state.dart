part of 'audio_bloc.dart';

class AudioState extends Equatable {
  final int audioBytes;
  final bool isPlaying;
  final String? playingSessionId;
  final bool busy;
  final String? error;

  const AudioState({
    this.audioBytes = 0,
    this.isPlaying = false,
    this.playingSessionId,
    this.busy = false,
    this.error,
  });

  AudioState copyWith({
    int? audioBytes,
    bool? isPlaying,
    String? playingSessionId,
    bool clearPlaying = false,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return AudioState(
      audioBytes: audioBytes ?? this.audioBytes,
      isPlaying: isPlaying ?? this.isPlaying,
      playingSessionId: clearPlaying
          ? null
          : (playingSessionId ?? this.playingSessionId),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    audioBytes,
    isPlaying,
    playingSessionId,
    busy,
    error,
  ];
}
