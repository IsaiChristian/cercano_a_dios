# R03-AUDIO-DELETE-RESULTS Task Note

## Objective

Implement review task R03 from `docs/IMPLEMENTATION_REVIEW_TASKS.md`:
Preserve failed and partially completed audio-delete results in Cercano a Dios.
1. `AudioBloc.deleteAudio`: When repository deletion fails (`Left`), preserve the error on `AudioState.error` instead of unconditionally wiping it with `clearError: true`. Provide an explicit outcome via `AudioDeleteResult`.
2. `AudioBloc.deleteAllAudio`: Do not hide partial deletion failures in bulk deletion. Return an explicit outcome indicating which session IDs succeeded and which failed. Preserve error until handled, refresh storage bytes for the successful ones, and support retry.
3. Support explicit error clearing via `clearError()` / `AudioErrorCleared`.
4. Test single failure, single success, and mixed-success bulk deletion.

## Owner and Scope

- Owner: Gemini Flash
- Branch: `codex/r03-audio-delete-results`
- Base commit: `78209d58525b6a71e3557cf14e7a3eb08e64627a` (main)
- Parallel Boundary: R04 was dispatched to subagent on `codex/r04-locale-persistence` touching `app_bloc`, `app_state`, `settings_page`, `main.dart`, and storage. R03 strictly did NOT touch those files.

### Write Allowlist
- `lib/src/audio/domain/audio_delete_result.dart` (NEW)
- `lib/src/audio/presentation/bloc/audio_bloc.dart` (MODIFY)
- `lib/src/audio/presentation/bloc/audio_state.dart` (MODIFY)
- `lib/src/audio/presentation/bloc/audio_event.dart` (MODIFY)
- `test/src/audio/bloc/audio_bloc_test.dart` (MODIFY)
- `agent-comms/R03-AUDIO-DELETE-RESULTS.md` (NEW)

### Preserved / Out of Scope
- `lib/src/app/bloc/` (R04 / AppBloc contracts preserved)
- `lib/main.dart`, `lib/src/settings/` (R04 owns)
- Repository interfaces and database schema remain untouched

## Work Completed

1. **AudioDeleteResult Domain Model (`lib/src/audio/domain/audio_delete_result.dart`)**:
   - Created immutable Equatable class `AudioDeleteResult` with `successfulIds: List<String>` and `failedIds: Map<String, String>`.
   - Computed getters: `isSuccess`, `isFailure`, `isPartial`, `isEmpty`, `totalAttempted`.

2. **AudioState Updates (`lib/src/audio/presentation/bloc/audio_state.dart`)**:
   - Added `AudioDeleteResult? lastDeleteResult` to state and props.
   - Added `clearDeleteResult` and `lastDeleteResult` parameters to `copyWith`.

3. **AudioEvent Updates (`lib/src/audio/presentation/bloc/audio_event.dart`)**:
   - Updated `AudioDeleted` and `AudioAllDeleted` to carry `Completer<AudioDeleteResult>? result`.
   - Added `AudioErrorCleared` event.

4. **AudioBloc Implementation (`lib/src/audio/presentation/bloc/audio_bloc.dart`)**:
   - `deleteAudio(String id)`: Returns `Future<AudioDeleteResult>`. If repository deletion fails, error is preserved on `state.error` (clearError: false) and recorded in `AudioDeleteResult`. If success, clears error, updates `audioBytes`, and returns success result.
   - `deleteAllAudio([List<PrayerSession>? sessions])`: Returns `Future<AudioDeleteResult>`. Queries repository sessions if omitted. Tracks successful and failed deletions per session ID. Recalculates storage `audioBytes` for successful deletions. If any fail, preserves descriptive error on `state.error` (clearError: false). If all succeed, clears error.
   - `retryFailedDeletions()`: Re-attempts deletion only for `lastDeleteResult.failedIds.keys`.
   - `clearError()`: Emits `state.copyWith(clearError: true)` to allow callers/UI to dismiss errors when handled.

5. **Test Coverage (`test/src/audio/bloc/audio_bloc_test.dart`)**:
   - Extended `FakeAudioRepository` with `failAudioIds` set for selective failure simulation.
   - Added single failure test: verifies error is preserved on `AudioState.error` and `AudioDeleteResult.isFailure == true`.
   - Added single success test: verifies `AudioDeleteResult.isSuccess == true`, error is null, and outcome recorded.
   - Added mixed-success bulk deletion test: 3 sessions, 2 succeed and 1 fails. Verifies `isPartial == true`, `successfulIds` contains the 2 succeeded IDs, `failedIds` contains the failed ID, storage bytes updated, and error preserved.
   - Added retry test: calling `retryFailedDeletions()` re-attempts only the failed session and succeeds when repository recovers.
   - Added `clearError()` test: verifies preserved error can be cleared when handled.

## Verification Results

| Check | Command | Result |
| --- | --- | --- |
| Formatting | `dart format --output=none --set-exit-if-changed lib/src/audio test/src/audio` | Clean (5 files formatted, 0 changed) |
| Static Analysis | `flutter analyze --no-pub` | Clean (0 issues found) |
| Focused Tests | `flutter test --no-pub test/src/audio/bloc/audio_bloc_test.dart` | 11/11 passed |
| AppBloc Audio Sync Tests | `flutter test --no-pub test/src/app/bloc/app_audio_sync_test.dart` | 10/10 passed |
| Full Test Suite | `flutter test --no-pub` | 160/160 passed |
| Whitespace & Conflict Check | `git diff --check lib/src/audio/ test/src/audio/` | Clean |

## Next Step

Submit R03 for review and monitor/integrate subagent work for R04.
