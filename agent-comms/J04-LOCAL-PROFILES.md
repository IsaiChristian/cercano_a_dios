# Agent Handoff - J04: User-Scoped Local Profiles & Authenticated App Factory

## Objective

Prevent account switching from exposing another user's device-local prayer history, without uploading, moving, copying, or deleting data. Implement `LocalProfileService`, `AuthenticatedAppFactory`, and `AppSessionBloc` with active-profile lifecycle coordination, generation-guarded transitions, and independent reminder/device cleanup.

## Owner and scope

- Owner: Astra low (local execution)
- Files in scope:
  - `lib/data/services/local_profile_service.dart`
  - `lib/core/di/authenticated_app_factory.dart`
  - `lib/src/app_session/bloc/app_session_bloc.dart`
  - `lib/src/app_session/bloc/app_session_event.dart`
  - `lib/src/app_session/bloc/app_session_state.dart`
  - `test/data/local_profile_service_test.dart`
  - `test/core/di/authenticated_app_factory_test.dart`
  - `test/src/app_session/bloc/app_session_bloc_test.dart`
  - `agent-comms/J04-LOCAL-PROFILES.md`
- Files intentionally out of scope:
  - `lib/core/di/bootstrap.dart`, `lib/core/router/router.dart`, `lib/main.dart` (reserved for connector task J06)
  - `lib/src/auth/` and existing prayer data services / UI / localization / pubspec

## Baseline

- Starting commit: `34c9a44` (main with J01, J02, J03, and J05 integrated)
- Branch: `j04-local-profiles`
- Existing uncommitted changes preserved:
  - `agent-comms/CURRENT_STATUS.md`
  - `macos/Flutter/GeneratedPluginRegistrant.swift`
  - `agent-comms/LOGIN-PLAN.md`

## Work completed

1. **`LocalProfileService`**:
   - Implemented deterministic, path-traversal-safe encoding of user IDs using hexadecimal representation of UTF-8 bytes (`[0-9a-f]+`).
   - Resolves and ensures isolated profile directories under `profiles/<encodedUserId>`.
   - Different user IDs receive separate directory trees; re-opening with the same user ID reopens their existing directory without reassigning or deleting files.
   - Enforces privacy: no user IDs or file paths are logged or leaked in error strings.

2. **`AuthenticatedAppFactory`**:
   - Accepts process-wide `DeviceServices`, base directory root, and `LocalProfileService`.
   - Creates user-scoped `LocalStorageService`, opens user-scoped `LocalPrayerDatabaseService`, initializes `LocalPrayerRepository`, reconciles audio files, and constructs `AppBloc`.
   - `AppBloc.close()` only closes the user database; process-wide `DeviceServices` and its `interruptions` stream remain open across sessions.

3. **`AppSessionBloc`**:
   - Coordinates active profile lifecycle (`signedOut`, `loading`, `ready`, `failure`) with target `userId` and safe `Failure`.
   - Holds active `AppBloc` as an owned resource outside immutable state.
   - Detaches `activeAppBloc` synchronously upon user changes or sign-out before async work begins.
   - Serializes transitions using tickets to prevent race conditions or stale profile leaks during rapid account switching (e.g. A -> B -> null).
   - Performs independent device cleanup during transitions (stops playback, stops ringing alarm, cancels native reminder schedules, and closes old `AppBloc` without cross-failure abortion).
   - Independently restores enabled incoming reminders via `device.schedule(reminder)` and reports individual scheduling failures to `appBloc.report(error)` without aborting remaining schedules.
   - Implemented `isValidReminderId(reminderId)` to validate and reject stale reminder payloads.

4. **Unit Tests**:
   - `test/data/local_profile_service_test.dart` (7 tests)
   - `test/core/di/authenticated_app_factory_test.dart` (3 tests)
   - `test/src/app_session/bloc/app_session_bloc_test.dart` (9 tests)

## Verification

| Command | Result |
| --- | --- |
| `dart format lib/data/services/local_profile_service.dart lib/core/di/authenticated_app_factory.dart lib/src/app_session/bloc/ test/data/local_profile_service_test.dart test/core/di/authenticated_app_factory_test.dart test/src/app_session/bloc/app_session_bloc_test.dart` | Passed (formatted cleanly) |
| `dart analyze` | Passed (0 errors, 0 warnings in task files; 1 pre-existing info in auth_page_test) |
| `flutter test --no-pub test/data/local_profile_service_test.dart test/core/di/authenticated_app_factory_test.dart test/src/app_session/bloc/app_session_bloc_test.dart` | Passed (19/19 tests) |
| `flutter test --no-pub` | Passed (full repository test suite) |
| `git diff --check` | Clean |

## Blockers or risks

- None. All requirements and edge cases specified for J04 pass automated verification.

## Next action

- Ready for integration with J06 (Auth composition, route guards, sign-out, and full integration).
