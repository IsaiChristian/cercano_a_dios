import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../domain/entities/prayer_session.dart';
import '../../../../domain/failures/failure.dart';
import '../../../../domain/repositories/prayer_repository.dart';

part 'audio_state.dart';
part 'audio_event.dart';

/// Feature-scoped BLoC managing audio playback, file storage, and audio deletion.
class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final DeviceServices device;
  final LocalStorageService storage;
  final PrayerRepository repository;

  AudioBloc({
    required this.device,
    required this.storage,
    required this.repository,
  }) : super(const AudioState()) {
    on<AudioBytesLoadRequested>(_onBytesLoadRequested);
    on<AudioPlaybackRequested>(_onPlaybackRequested);
    on<AudioPlaybackStopped>(_onPlaybackStopped);
    on<AudioDeleted>(_onAudioDeleted);
    on<AudioAllDeleted>(_onAllAudioDeleted);
  }

  Future<void> loadAudioBytes() {
    final result = Completer<void>();
    add(AudioBytesLoadRequested(result));
    return result.future;
  }

  Future<void> playAudio(PrayerSession session) {
    final result = Completer<void>();
    add(AudioPlaybackRequested(session, result));
    return result.future;
  }

  Future<void> stopPlayback() {
    final result = Completer<void>();
    add(AudioPlaybackStopped(result));
    return result.future;
  }

  Future<void> deleteAudio(String id) {
    final result = Completer<void>();
    add(AudioDeleted(id, result));
    return result.future;
  }

  Future<void> deleteAllAudio([List<PrayerSession>? sessions]) {
    final result = Completer<void>();
    add(AudioAllDeleted(sessions, result));
    return result.future;
  }

  Future<void> _onBytesLoadRequested(
    AudioBytesLoadRequested event,
    Emitter<AudioState> emit,
  ) async {
    try {
      final bytes = await storage.audioBytes();
      emit(state.copyWith(audioBytes: bytes, clearError: true));
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onPlaybackRequested(
    AudioPlaybackRequested event,
    Emitter<AudioState> emit,
  ) async {
    if (event.session.audioPath == null) {
      event.result?.complete();
      return;
    }
    try {
      emit(
        state.copyWith(
          isPlaying: true,
          playingSessionId: event.session.id,
          clearError: true,
        ),
      );
      await device.play(storage.pathFor(event.session.audioPath!));
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      emit(state.copyWith(isPlaying: false, clearPlaying: true));
      event.result?.complete();
    }
  }

  Future<void> _onPlaybackStopped(
    AudioPlaybackStopped event,
    Emitter<AudioState> emit,
  ) async {
    try {
      await device.stopPlayback();
      emit(
        state.copyWith(isPlaying: false, clearPlaying: true, clearError: true),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      event.result?.complete();
    }
  }

  Future<void> _onAudioDeleted(
    AudioDeleted event,
    Emitter<AudioState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    try {
      await device.stopPlayback();
      final deleteResult = await repository.deleteAudio(event.id);
      String? error;
      deleteResult.fold((failure) {
        error = failure.message;
        _emitError(emit, failure);
      }, (_) {});
      final bytes = await storage.audioBytes();
      emit(
        state.copyWith(
          audioBytes: bytes,
          isPlaying: false,
          clearPlaying: true,
          busy: false,
          error: error,
          clearError: error == null,
        ),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      emit(state.copyWith(busy: false));
      event.result?.complete();
    }
  }

  Future<void> _onAllAudioDeleted(
    AudioAllDeleted event,
    Emitter<AudioState> emit,
  ) async {
    emit(state.copyWith(busy: true));
    try {
      await device.stopPlayback();
      List<PrayerSession> targetSessions = event.sessions ?? [];
      if (event.sessions == null) {
        final sessionsResult = await repository.sessions();
        var readFailed = false;
        sessionsResult.fold((failure) {
          _emitError(emit, failure);
          readFailed = true;
        }, (sessions) => targetSessions = sessions);
        if (readFailed) {
          emit(state.copyWith(busy: false));
          event.result?.complete();
          return;
        }
      }
      String? error;
      for (final session in targetSessions) {
        final deleteResult = await repository.deleteAudio(session.id);
        deleteResult.fold((failure) {
          error = failure.message;
          _emitError(emit, failure);
        }, (_) {});
      }
      final bytes = await storage.audioBytes();
      emit(
        state.copyWith(
          audioBytes: bytes,
          isPlaying: false,
          clearPlaying: true,
          busy: false,
          error: error,
          clearError: error == null,
        ),
      );
      event.result?.complete();
    } catch (error) {
      _emitError(emit, error);
      emit(state.copyWith(busy: false));
      event.result?.complete();
    }
  }

  void _emitError(Emitter<AudioState> emit, Object error) {
    final message = error is Failure
        ? error.message
        : error is PlatformException
        ? error.message ??
              'Audio error. Check your device settings and try again.'
        : error.toString();
    emit(state.copyWith(error: message));
  }
}
