# REFACTOR-FEATURE-BLOCS Handoff Note

## Objective

Refactor `AppBloc` from a monolithic god object (~420 lines, 16 handlers) into lightweight feature-scoped BLoCs (`HistoryBloc`, `AudioBloc`, `RemindersBloc`) with `AppBloc` acting as coordinator, implemented in an isolated worktree.

## Owner and scope

- Owner: Antigravity (feature-bloc refactor agent)
- Branch: `refactor-feature-blocs` (worktree at `.worktrees/refactor-feature-blocs`)
- Files/directories in scope:
  - `lib/src/history/presentation/bloc/` (new `HistoryBloc`, `HistoryEvent`, `HistoryState`)
  - `lib/src/audio/presentation/bloc/` (new `AudioBloc`, `AudioEvent`, `AudioState`)
  - `lib/src/reminders/presentation/bloc/` (`RemindersBloc`, `RemindersEvent`, `RemindersState` updated to direct repository ownership)
  - `lib/src/reminders/presentation/pages/reminders_page.dart` (reads `RemindersBloc` directly)
  - `lib/src/app/bloc/` (`AppBloc`, `AppEvent`, `AppState` coordinator)
  - `lib/core/router/router.dart` and `lib/main.dart` (dependency injection and route provider wiring)
  - `test/src/history/bloc/history_bloc_test.dart`
  - `test/src/audio/bloc/audio_bloc_test.dart`
  - `test/src/reminders/bloc/reminders_bloc_test.dart`
- Files/directories intentionally out of scope:
  - Main workspace working tree files (`j04-local-profiles` profile refactor files)
  - Other feature pages (`home_page.dart`, `session_page.dart`, `history_page.dart` remain compatible with existing providers)

## Baseline

- Starting commit: `c906822a70bf48b5fa827c893d98cd4bdcc86fd5`
- Existing user changes observed: Uncommitted profile migration changes in the main working tree left untouched via dedicated `.worktrees/refactor-feature-blocs` worktree.

## Work completed

1. **History Feature BLoC**:
   - Implemented `HistoryBloc`, `HistoryEvent` (`HistoryLoaded`, `HistorySessionCompleted`, `HistorySessionDeleted`), and `HistoryState`.
   - Extracted session listing, completion, and deletion directly into `HistoryBloc`.
   - Added unit test suite in `test/src/history/bloc/history_bloc_test.dart` (6/6 tests passing).

2. **Audio Feature BLoC**:
   - Implemented `AudioBloc`, `AudioEvent` (`AudioPlaybackRequested`, `AudioPlaybackStopped`, `AudioDeleted`, `AudioAllDeleted`, `AudioBytesUpdated`), and `AudioState`.
   - Extracted playback control, audio cleanup, and audio storage byte calculations.
   - Added unit test suite in `test/src/audio/bloc/audio_bloc_test.dart` (5/5 tests passing).

3. **Reminders Feature BLoC**:
   - Decoupled `RemindersBloc` from `AppBloc`; it now interacts directly with `PrayerRepository` and `DeviceServices`.
   - Added `RemindersSaved`, `RemindersDeleted`, `RemindersSnoozeCancelled` handlers and state ownership.
   - Updated `reminders_page.dart` to consume `RemindersBloc` directly.
   - Added unit test suite in `test/src/reminders/bloc/reminders_bloc_test.dart` (7/7 tests passing).

4. **App Coordinator**:
   - Simplified `AppBloc` to coordinate `RemindersBloc`, `AudioBloc`, and `HistoryBloc`.
   - Maintained full backward compatibility for `AppState` fields (`sessions`, `reminders`, `audioBytes`) and public delegation methods (`saveReminder`, `deleteReminder`, `completeSession`, `deleteSession`, `playAudio`, `stopPlayback`, etc.).
   - Synchronously updates and emits intermediate state during delegated calls to guarantee immediate test and caller expectations.

5. **Dependency Injection & Routing**:
   - Updated `lib/main.dart` `MultiProvider` to instantiate and provide `HistoryBloc`, `AudioBloc`, and `RemindersBloc`.
   - Updated `lib/core/router/router.dart` `/reminders` route to provide `app.remindersBloc`.

## Verification

| Command | Result |
| --- | --- |
| `git diff --check` | Passed (clean) |
| `dart format --output=none --set-exit-if-changed` | Passed (18 files checked, 0 changed) |
| `flutter analyze --no-pub` | Passed (No issues found) |
| `flutter test --no-pub test/src/history/bloc/history_bloc_test.dart test/src/audio/bloc/audio_bloc_test.dart test/src/reminders/bloc/reminders_bloc_test.dart` | Passed (18/18 passed) |
| `flutter test --no-pub` | Passed (125/125 passed across entire repository) |

## Blockers or risks

- None. All changes are backward compatible with existing session tests, home tests, authenticated factory setup, and router configurations.
- Worktree branch `refactor-feature-blocs` is ready to be merged when ready.

## Next action

- Merge `refactor-feature-blocs` into target branch when other local feature migrations are ready for integration.
