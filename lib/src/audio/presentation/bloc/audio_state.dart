part of 'audio_bloc.dart';

class AudioState extends Equatable {
  final int audioBytes;
  final bool isPlaying;
  final String? playingSessionId;
  final bool busy;
  final String? error;
  final AudioDeleteResult? lastDeleteResult;

  const AudioState({
    this.audioBytes = 0,
    this.isPlaying = false,
    this.playingSessionId,
    this.busy = false,
    this.error,
    this.lastDeleteResult,
  });

  AudioState copyWith({
    int? audioBytes,
    bool? isPlaying,
    String? playingSessionId,
    bool clearPlaying = false,
    bool? busy,
    String? error,
    bool clearError = false,
    AudioDeleteResult? lastDeleteResult,
    bool clearDeleteResult = false,
  }) {
    return AudioState(
      audioBytes: audioBytes ?? this.audioBytes,
      isPlaying: isPlaying ?? this.isPlaying,
      playingSessionId: clearPlaying
          ? null
          : (playingSessionId ?? this.playingSessionId),
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      lastDeleteResult: clearDeleteResult
          ? null
          : (lastDeleteResult ?? this.lastDeleteResult),
    );
  }

  @override
  List<Object?> get props => [
    audioBytes,
    isPlaying,
    playingSessionId,
    busy,
    error,
    lastDeleteResult,
  ];
}
