import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/services/device_services.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../domain/entities/prayer.dart';

part 'session_state.dart';
part 'session_event.dart';

typedef CompletePrayerSession = Future<bool> Function(PrayerSession session);

/// Event-driven state machine for recording and completing one prayer.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final DeviceServices device;
  final LocalStorageService storage;
  final PrayerPrompt prompt;
  final int? reminderId;
  final CompletePrayerSession completeSession;
  final int Function() audioBytes;
  final Future<void> Function(int id)? cancelReminderSnooze;
  final String? Function()? lastError;

  final String id =
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  StreamSubscription<void>? _interruptions;
  Timer? _timer;
  final Stopwatch _watch = Stopwatch();
  bool _hasRecording = false;
  bool _leaving = false;
  bool _closing = false;
  bool _audioCommitted = false;
  Completer<void>? _pendingSave;
  Future<void>? _closeFuture;

  SessionBloc({
    required this.device,
    required this.storage,
    required this.prompt,
    required this.completeSession,
    required this.audioBytes,
    this.reminderId,
    this.cancelReminderSnooze,
    this.lastError,
  }) : super(const SessionState(SessionPhase.ready)) {
    on<SessionStartRequested>(_onStartRequested);
    on<SessionFinishRequested>(_onFinishRequested);
    on<SessionAmplitudeRequested>(_onAmplitudeRequested);
    on<SessionPlaybackRequested>(_onPlaybackRequested);
    on<SessionPlaybackStopped>(_onPlaybackStopped);
    on<SessionSaveRequested>(_onSaveRequested);
    on<SessionInterrupted>(_onInterrupted);
    _interruptions = device.interruptions.stream.listen((_) {
      if (!_closing && !isClosed) add(SessionInterrupted());
    });
  }

  String get filename => '$id.m4a';
  String get path => storage.pathFor(filename);
  bool get hasRecording => _hasRecording;

  Future<void> start() {
    if (isClosed || _closing) return Future<void>.value();
    final result = Completer<void>();
    add(SessionStartRequested(result));
    return result.future;
  }

  Future<void> finish() {
    if (isClosed || _closing) return Future<void>.value();
    final result = Completer<void>();
    add(SessionFinishRequested(result));
    return result.future;
  }

  Future<void> play() {
    if (isClosed || _closing) return Future<void>.value();
    final result = Completer<void>();
    add(SessionPlaybackRequested(result));
    return result.future;
  }

  Future<void> stopPlayback() {
    if (isClosed || _closing) return Future<void>.value();
    final result = Completer<void>();
    add(SessionPlaybackStopped(result));
    return result.future;
  }

  Future<bool> save({bool silent = false}) {
    if (isClosed || _closing) return Future<bool>.value(false);
    final result = Completer<bool>();
    add(SessionSaveRequested(silent: silent, result: result));
    return result.future;
  }

  Future<void> interrupt() {
    if (isClosed || _closing) return Future<void>.value();
    final result = Completer<void>();
    add(SessionInterrupted(result));
    return result.future;
  }

  Future<void> _onStartRequested(
    SessionStartRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (state.phase != SessionPhase.ready &&
        state.phase != SessionPhase.review) {
      event.result.complete();
      return;
    }
    if (audioBytes() >= 99 * 1024 * 1024) {
      emit(
        const SessionState(
          SessionPhase.ready,
          error:
              'Recording storage is full. Free some space in Settings or reflect silently.',
        ),
      );
      event.result.complete();
      return;
    }

    _leaving = false;
    emit(const SessionState(SessionPhase.starting));
    try {
      await device.stopPlayback();
      await device.stopAlarm();
      await device.record(path);
      if (_leaving || isClosed || _closing) {
        await device.finishRecording();
        if (isClosed || _closing) {
          await storage.deleteFile(filename);
        } else {
          _hasRecording = await storage.fileExists(filename);
          emit(const SessionState(SessionPhase.review));
        }
        event.result.complete();
        return;
      }

      _hasRecording = true;
      _watch
        ..reset()
        ..start();
      emit(const SessionState(SessionPhase.recording));
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (!isClosed && !_closing && state.phase == SessionPhase.recording) {
          add(SessionAmplitudeRequested());
        }
      });
      event.result.complete();
    } catch (error) {
      emit(
        SessionState(
          SessionPhase.ready,
          error: error is PlatformException
              ? error.message ??
                    'Could not start recording. You can still reflect silently.'
              : 'Could not start recording. You can still reflect silently.',
        ),
      );
      event.result.complete();
    }
  }

  Future<void> _onFinishRequested(
    SessionFinishRequested event,
    Emitter<SessionState> emit,
  ) async {
    await _finishRecording(emit);
    event.result?.complete();
  }

  Future<void> _onAmplitudeRequested(
    SessionAmplitudeRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (state.phase != SessionPhase.recording || _closing) return;
    final seconds = _watch.elapsed.inSeconds;
    if (seconds >= 120) {
      await _finishRecording(emit);
      return;
    }
    try {
      final level = await device.amplitude();
      if (!isClosed && state.phase == SessionPhase.recording) {
        emit(
          SessionState(SessionPhase.recording, seconds: seconds, level: level),
        );
      }
    } catch (_) {
      add(SessionFinishRequested());
    }
  }

  Future<void> _finishRecording(Emitter<SessionState> emit) async {
    if (state.phase != SessionPhase.recording) return;
    _timer?.cancel();
    _watch.stop();
    final seconds = _watch.elapsed.inSeconds;
    emit(SessionState(SessionPhase.stopping, seconds: seconds));
    try {
      await device.finishRecording();
      _hasRecording =
          await storage.fileExists(filename) &&
          await storage.fileLength(filename) > 0;
      emit(SessionState(SessionPhase.review, seconds: seconds));
    } catch (_) {
      emit(
        SessionState(
          SessionPhase.review,
          seconds: seconds,
          error:
              'Recording was interrupted. Try playback, record again, or complete without audio.',
        ),
      );
    }
  }

  Future<void> _onPlaybackRequested(
    SessionPlaybackRequested event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await device.play(path);
      event.result?.complete();
    } catch (_) {
      emit(
        SessionState(
          state.phase,
          seconds: state.seconds,
          level: state.level,
          error:
              'Could not play this recording. Please record again or complete without audio.',
        ),
      );
      event.result?.complete();
    }
  }

  Future<void> _onPlaybackStopped(
    SessionPlaybackStopped event,
    Emitter<SessionState> emit,
  ) async {
    try {
      await device.stopPlayback();
    } catch (_) {}
    event.result?.complete();
  }

  Future<void> _onSaveRequested(
    SessionSaveRequested event,
    Emitter<SessionState> emit,
  ) async {
    if (_closing ||
        (state.phase != SessionPhase.ready &&
            state.phase != SessionPhase.review)) {
      event.result.complete(false);
      return;
    }
    final seconds = state.seconds;
    final pendingSave = Completer<void>();
    _pendingSave = pendingSave;
    emit(SessionState(SessionPhase.saving, seconds: seconds));
    try {
      await device.stopPlayback();
      final now = DateTime.now();
      final session = PrayerSession(
        id: id,
        promptId: prompt.id,
        promptText: prompt.text,
        localDate: calendarDate(now),
        completedAt: now.toUtc(),
        offsetMinutes: now.timeZoneOffset.inMinutes,
        durationSeconds: seconds,
        spoken: !event.silent,
        audioPath: !event.silent && _hasRecording ? filename : null,
      );
      final ok = await completeSession(session);
      if (ok) {
        _audioCommitted = session.audioPath != null;
        if (reminderId != null && cancelReminderSnooze != null) {
          try {
            await cancelReminderSnooze!(reminderId!);
          } catch (_) {}
        }
        emit(SessionState(SessionPhase.complete, seconds: seconds));
        if (event.silent) {
          try {
            await storage.deleteFile(filename);
          } catch (_) {
            // Startup reconciliation removes abandoned files.
          }
        }
      } else {
        emit(
          SessionState(
            _hasRecording ? SessionPhase.review : SessionPhase.ready,
            seconds: seconds,
            error:
                lastError?.call() ??
                'Could not save this moment. Please try again.',
          ),
        );
      }
      event.result.complete(ok);
    } catch (_) {
      emit(
        SessionState(
          _hasRecording ? SessionPhase.review : SessionPhase.ready,
          seconds: seconds,
          error: 'Could not save this moment. Please try again.',
        ),
      );
      event.result.complete(false);
    } finally {
      pendingSave.complete();
      _pendingSave = null;
    }
  }

  Future<void> _onInterrupted(
    SessionInterrupted event,
    Emitter<SessionState> emit,
  ) async {
    if (state.phase == SessionPhase.starting) _leaving = true;
    await _finishRecording(emit);
    try {
      await device.stopPlayback();
    } catch (_) {}
    event.result?.complete();
  }

  @override
  Future<void> close() => _closeFuture ??= _close().then((_) => super.close());

  Future<void> _close() async {
    _closing = true;
    _leaving = true;
    _timer?.cancel();
    _watch.stop();
    await _interruptions?.cancel();
    // Let persistence settle before deciding whether this file is a draft.
    await _pendingSave?.future;
    try {
      await device.finishRecording();
      await device.stopPlayback();
      if (!_audioCommitted && await storage.fileExists(filename)) {
        await storage.deleteFile(filename);
      }
    } catch (_) {}
  }
}
