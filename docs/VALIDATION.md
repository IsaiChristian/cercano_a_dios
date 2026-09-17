# Validation status

Snapshot as of September 17, 2026.

## Current verification summary

| Check | Tool / Command | Result |
|---|---|---|
| Static analysis | `flutter analyze --no-pub` | Passed: 0 issues found |
| Automated test suite | `flutter test --no-pub` | Passed: 182/182 tests across 17 test files |
| Code formatting | `dart format --output=none --set-exit-if-changed lib test` | Reports 11 files with style differences (tracked in task R05) |
| Dependency locking | `pubspec.lock` | Tracked in git and resolved |
| Toolchain baseline | Flutter 3.35.5 (channel stable) • Dart 3.9.2 | Verified functional on macOS (Darwin arm64) |
| Native builds & device QA | Android release APK, iOS/Xcode 26 AlarmKit, physical devices | Pending release packaging and physical device testing |

## Implemented and wired features

### 1. Authentication & per-user isolation (R01)
- **Backend configuration**: Evaluates `AuthConfig.fromEnvironment()`. Defaults to Appwrite (`APPWRITE_ENDPOINT` and `APPWRITE_PROJECT_ID`), throwing a fail-fast recoverable startup error on missing/empty configuration. Supports offline/test mode via `--dart-define=AUTH_BACKEND=fake`.
- **Reactive routing guards**: GoRouter dynamically navigates unauthenticated sessions to `/auth`, in-flight initialization or account switching to `/loading`, setup/profile errors to `/profile-error`, and authenticated ready profiles to `/` (or `/welcome` if onboarding is incomplete).
- **Scoped resource lifecycle**: `AuthenticatedFeatureScope` provides user-scoped `DeviceServices`, `AppBloc`, `RemindersBloc`, `AudioBloc`, and `HistoryBloc` only when the active profile status is `ready`. Sign-out dispatches `AuthSignOutRequested`, unmounts scoped widgets, and closes scoped resources cleanly.
- **Data isolation & legacy data preservation**: Each user's database, welcomed preference, and audio recordings reside under `profiles/<hex_user_id>/`. Pre-existing files in `baseRoot` from prior single-user installations remain untouched.
- **Native alarm gating**: Native alarm callbacks (`openPrayer` and `consumeOpenPrayer`) validate the incoming reminder ID against the active profile's database (`AppSessionBloc.isValidReminderId`); stale or mismatched reminder navigation is dropped.

### 2. Audio & history storage synchronization (R02)
- **Immediate storage updates**: Completing a recorded prayer session or deleting a session immediately triggers `audioBloc.loadAudioBytes()`, updating storage totals for Settings and `SessionBloc` quota enforcement without app restart.
- **Playback control synchronization**: Single audio deletion or bulk audio deletion immediately reloads history sessions with `audioPath: null`, clearing playback controls while preserving session history and streak credit.
- **Fresh query on bulk deletion**: Bulk audio deletion queries fresh sessions directly from the repository rather than relying on a potentially stale memory snapshot.
- **Committed audio preservation**: Successfully saved recordings survive subsequent UI refresh failures, remaining observable on `AppState.error`.

### 3. Resilient audio delete outcomes (R03)
- **Outcome tracking**: Domain model `AudioDeleteResult` tracks `successfulIds` and `failedIds`.
- **Error retention**: Deletion failures preserve the error on `AudioState.error` (`clearError: false`) instead of silently discarding failure states.
- **Partial bulk deletion reporting**: Distinguishes complete success, partial failure, and full failure. Storage bytes are recalculated for successful deletions, and failed IDs can be re-attempted via `AudioBloc.retryFailedDeletions()`.
- **Explicit error dismissal**: Errors remain visible until dismissed via `AudioBloc.clearError()` / `AudioErrorCleared`.

### 4. Locale resolution & persistence (R04)
- **Device locale resolution**: First launch resolves device locale to supported languages (Spanish `es` or English `en`), falling back to English for unsupported locales.
- **Synchronous persistence**: User language selection in `SettingsPage` is written synchronously to `<storage-root>/language` via `LocalStorageService.writeLanguageCodeSync` and restored on startup and refresh.

### 5. Core Catholic prayer companion
- **Prayer prompts**: 20 original draft Catholic prayer prompts across gratitude, hope, peace, and reflection; offline prompt selection.
- **Prayer recording**: Private mono AAC capture, review, re-record, play, delete, and silent reflection.
- **Daily habit**: Calendar-date streaks, weekly progress strip, and 6 personal milestone badges with offline award logic.
- **Reminders**: Up to 5 weekly reminder schedules, weekday selection, Stop and 10-minute Snooze controls, and system permission states.
- **Localization**: English and Spanish ARB resources with generated Flutter localizations.

## Device checklist before beta

- Fresh installation, onboarding, denied/granted/revoked microphone and notification permissions.
- Record a short prayer, preview, replace, save, restart, replay, delete audio while preserving streak.
- Silent completion, repeated taps, save error/retry, interrupted recording, full storage, reset.
- Alarm while screen locked, app backgrounded/terminated, doze, reboot, time-zone change, daylight-saving change.
- Stop and ten-minute snooze, editing/deleting/pausing reminders, overlapping alarms, completion cancels only the linked snooze.
- Android native sound, notification-channel settings, two-minute timeout, and exact-alarm access recovery.
- iOS 15/18 reminder mode and iOS 26 AlarmKit authorization, Stop/Snooze, and app entry behavior.
- VoiceOver/TalkBack, large text, a 320-point wide screen, and reduced motion.
- Low-end 2 GB Android and older supported iPhone: launch, recording latency, memory, frame times, and 1,000-session history.
- Review original prayer text with a knowledgeable Catholic reviewer.

## Remaining release gates & verification gaps

### Physical device verification matrix
1. **Android API 24+ hardware**:
   - Ringing alarms while screen locked, backgrounded, terminated, and across device reboot.
   - Overlapping alarm deferral (10-minute snooze) and Stop/Snooze notification actions.
   - Doze mode and exact alarm permission grant / revocation recovery.
2. **iOS physical devices**:
   - iOS 15–18 notification reminders following sound and Focus modes.
   - iOS 26+ AlarmKit ringing alarms compiled with Xcode 26+.
   - Validation of Stop & pray and Snooze actions.
3. **Hardware performance budgets**:
   - Launch latency p95 < 4s on 2 GB Android hardware.
   - Memory usage < 150 MB during a 2-minute recording.
   - Frame rendering times on core flows.

### Distribution & signing configuration
- Android release signing configuration in `android/app/build.gradle.kts` currently uses debug signing keys and must be configured with a production keystore.
- Apple Developer team assignment and distribution provisioning for physical iOS devices.

### Multi-user native alarm ownership (R17)
- Platform channel callbacks pass integer reminder IDs without user ownership metadata. While `isValidReminderId` drops IDs not belonging to the currently active profile, native channel ownership binding across process death and user switching is tracked under task R17.

### Toolchain & formatting normalization (R05)
- 11 files currently report formatting differences against `dart format`. Normalization and CI enforcement are tracked under task R05.

---

## Historical environment notes

### Native alarm correction (2026-09-16 snapshot)
Android keeps the first alarm ringing and defers overlapping reminders ten minutes using persisted snoozes. Notification actions validate both reminder and ringing occurrence. iOS 26 uses **Stop & pray** plus **Snooze**, with reminder-aware cold/warm entry through the existing Flutter bridge. Previously scheduled iOS alarms must be rescheduled to use the new intent. Flutter analysis and 14 session tests passed. Swift syntax parsing passed; it does not typecheck AlarmKit. Details: [`FIX-NATIVE-ALARMS.md`](../agent-comms/FIX-NATIVE-ALARMS.md).

### Initial execution environment constraints (2026-09-15 snapshot)
During initial project scaffolding, the Codex execution sandbox restricted the macOS CPU sysctl call used by Dart, and neither `flutter` nor `dart` was directly exported on the default execution PATH. Dart source and Kotlin/Swift syntax checks were performed statically. These historical limitations were resolved once Flutter 3.35.5 and Dart 3.9.2 were executed directly with appropriate permissions.
