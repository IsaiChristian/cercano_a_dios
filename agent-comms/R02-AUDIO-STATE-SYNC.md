# R02-AUDIO-STATE-SYNC Handoff Note

## Objective

Implement review task R02: keep history and audio storage totals consistent after mutations in Cercano a Dios.
Ensure `AppBloc` coordinates audio and history state mutations so that:
1. Completing a recorded session or deleting a session immediately refreshes audio storage totals (`audioBytes`) without relying on app lifecycle resume/restart.
2. Deleting a single session's audio or bulk deleting all audio immediately refreshes history sessions (clearing `audioPath` so playback controls disappear/disable) while preserving session history and streak data.
3. Bulk audio deletion queries fresh sessions directly via the repository read interface rather than relying exclusively on a potentially stale/empty cached state snapshot.
4. Bulk deletion reports a read failure before claiming completion if repository reading fails.
5. Committed audio persistence is preserved even if subsequent refresh fails; refresh failures stay observable on `AppState.error` rather than converting data to empty results.
6. Active audio playback is stopped when a session is deleted.

## Owner and scope

- Owner: Gemini Flash (worker)
- Branch: `codex/r02-audio-state-sync`
- Worktree: `/private/tmp/cercano-r02-audio-state-sync`
- Base commit: `4d8e66edf71709df6f9863ad5efe004374dc94cd` (main)
- Files changed in write allowlist:
  - `lib/src/app/bloc/app_bloc.dart`: Synchronized `_onPrayerCompleted`, `_onSessionDeleted`, `_onAudioDeleted`, and `_onAllAudioDeleted`. Stopped active playback on session delete. Kept all public constructors, methods, events, and state contracts strictly backward compatible.
  - `lib/src/audio/presentation/bloc/audio_bloc.dart` & `audio_event.dart`: Added optional `sessions` parameter support in `deleteAllAudio([List<PrayerSession>? sessions])` and `AudioAllDeleted([this.sessions, this.result])` with repository fallback. Fixed bug where `clearError: true` discarded deletion failures.
  - `lib/src/history/presentation/bloc/history_bloc.dart` & `history_event.dart`: Added narrow internal synchronization helpers `syncAudioDeleted(String id)` and `syncAllAudioDeleted()` / `HistoryAudioDeleted` and `HistoryAllAudioDeleted` to refresh session records without resetting global loading state.
  - `test/src/app/bloc/app_audio_sync_test.dart`: 10 new comprehensive cross-feature regression tests covering recorded save, session delete, playback stopping, single/bulk audio delete, stale snapshot fallback, repo read failure, quota enforcement with SessionBloc, committed audio preservation, and zero auth dependency.
  - `test/src/audio/bloc/audio_bloc_test.dart`: Added 3 tests for `deleteAllAudio` without arguments, repo read failure handling, and `deleteAudio` failure retention.
  - `test/src/history/bloc/history_bloc_test.dart`: Added 3 tests for `syncAudioDeleted`, `syncAllAudioDeleted`, and failure preservation.
  - `agent-comms/R02-AUDIO-STATE-SYNC.md`: Local task ownership note and findings.
- Preserved / out of scope:
  - `main.dart`, router, auth, profile, settings, pages, localization, and native files untouched.
  - `CURRENT_STATUS.md` and shared issue #6 body left to root coordinator.
  - No repository API or schema changes.

## Work completed

1. **AppBloc Mutation Synchronization (`app_bloc.dart`)**:
   - `_onPrayerCompleted`: When `completeSession` succeeds, immediately calls `await audioBloc.loadAudioBytes()`, updating `audioBytes` for Settings and `SessionBloc` quota calculations without app restart. If refresh fails, preserves `success = true` (committed audio survives refresh failure) while keeping the error observable.
   - `_onSessionDeleted`: Checks if the deleted session was currently playing (`audioBloc.state.playingSessionId == event.id`) and stops playback. Calls `deleteSession`, then immediately reloads storage totals via `audioBloc.loadAudioBytes()`.
   - `_onAudioDeleted`: Deletes the recording via `audioBloc.deleteAudio(event.id)`, then calls `historyBloc.syncAudioDeleted(event.id)` to reload session rows from the repository (where `audioPath` is now `null`). Emits updated `sessions` and `audioBytes`.
   - `_onAllAudioDeleted`: Queries `repository.sessions()` first. If reading fails, reports the failure on `state.error` and completes without deleting with a stale empty list. If reading succeeds, deletes recordings for all returned sessions, synchronizes `historyBloc.syncAllAudioDeleted()`, and updates `AppState`.

2. **Audio Feature BLoC Improvements (`audio_bloc.dart`, `audio_event.dart`)**:
   - Made `sessions` optional in `deleteAllAudio([List<PrayerSession>? sessions])` with internal repository fallback when omitted.
   - Fixed error masking: previously, lines 135 and 164 invoked `clearError: true`, which erased any deletion failure that was just emitted. Now failures are preserved on `AudioState.error`.

3. **History Feature BLoC Helpers (`history_bloc.dart`, `history_event.dart`)**:
   - Added `syncAudioDeleted(String id)` and `syncAllAudioDeleted()`, which re-query `repository.sessions()` to update `state.sessions` while preserving session records and streak metadata, without flickering `loading: true`.

4. **Testing and Verification**:
   - Added `test/src/app/bloc/app_audio_sync_test.dart` with 10 test cases.
   - Added 3 test cases to `test/src/audio/bloc/audio_bloc_test.dart` (now 8 tests).
   - Added 3 test cases to `test/src/history/bloc/history_bloc_test.dart` (now 9 tests).
   - Verified that all 27 focused tests pass and full test suite (141/141 tests) passes.
   - Verified `dart format` is clean across all touched files.
   - Verified `flutter analyze --no-pub` has 0 issues.
   - Verified `git diff --check` is clean.

## Verification results

| Check | Command | Result |
| --- | --- | --- |
| Formatting | `dart format --output=none --set-exit-if-changed <touched-files>` | Clean (8 files formatted, 0 changed) |
| Static Analysis | `flutter analyze --no-pub` | Clean (0 issues found) |
| Focused Tests | `flutter test --no-pub test/src/app/bloc/app_audio_sync_test.dart test/src/audio/bloc/audio_bloc_test.dart test/src/history/bloc/history_bloc_test.dart` | 27/27 passed |
| Full Test Suite | `flutter test --no-pub` | 141/141 passed (125 baseline + 16 new/expanded) |
| Whitespace & Conflict Check | `git diff --check` | Clean (no whitespace or conflict markers) |

## Unresolved issues and separate findings

- No blockers or unresolved issues for R02.
- Related audit findings preserved for separate tasks per instructions:
  - R03 (centralized error-handling redesign) and R07 (full refresh redesign): Not addressed here, scoped to separate tasks.
  - Pre-existing formatting drift across 13 untouched files outside write scope was preserved.

## Next step

Ready for review. Root coordinator can review the local worktree `codex/r02-audio-state-sync` at `/private/tmp/cercano-r02-audio-state-sync`.
