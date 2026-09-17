# R01-AUTH-INTEGRATION Task Note

## Objective

Implement review task R01: complete authentication and per-user app integration in Cercano a Dios.
Startup uses AuthConfig to explicitly configure Appwrite (or explicit fake auth); missing/invalid configuration is a recoverable/localized setup error.
Auth lifecycle and profile readiness drive routing; prayer/history/settings features only mount when an authenticated user has a ready profile.
Settings exposes sign-out; sign-out/switch detaches old feature widgets and closes scoped resources while preserving process-wide device ownership and native alarm gating.
Anonymous shared-root data is preserved untouched without silent migration or deletion.

## Owner and Scope

- Owner: Gemini Flash
- Branch: `codex/r01-auth-integration`
- Worktree: `/private/tmp/cercano-r01-auth-integration`
- Base commit: `4d8e66edf71709df6f9863ad5efe004374dc94cd` (main)
- Board claim: [Issue #6 Comment 5710431588](https://github.com/IsaiChristian/cercano_a_dios/issues/6#issuecomment-5710431588)

### Owned Write Scope (Allowlist)
- `lib/main.dart`
- `lib/core/di/bootstrap.dart`
- Narrowly needed composition helpers in `lib/core/di/`
- `lib/core/router/router.dart` and router wiring helpers in `lib/core/router/` (`lib/core/router/router_wiring.dart`)
- `lib/src/settings/presentation/pages/settings_page.dart`
- New tests under `test/core/router/`, `test/core/di/bootstrap_test.dart`, `test/presentation/app_auth_integration_test.dart`, `test/presentation/settings_auth_test.dart`
- `README.md` (R01 configuration, fake auth instructions, legacy data behavior)
- `agent-comms/R01-AUTH-INTEGRATION.md`

### Parallel Boundaries
- R02 owns `lib/src/app/bloc/`, history/audio BLoCs, and their unit tests. R01 did NOT edit these.
- R01 did NOT change public `AppBloc` constructor/method/state contracts.
- Internal implementations of `AuthBloc`, `AppSessionBloc`, and `AuthenticatedAppFactory` were kept intact.
- Shared `CURRENT_STATUS.md` is owned by the coordinator.

## Implementation Details

1. **Bootstrap & Configuration (`lib/core/di/bootstrap.dart`)**:
   - Implemented `AppBootstrapResult` container holding `device`, `authRepository`, `appFactory`, `authBloc`, and `appSessionBloc` with an idempotent `dispose()` method that cancels the auth stream listener and closes Blocs cleanly.
   - Evaluated `AuthConfig.fromEnvironment()`: when `backend == AuthBackend.fake`, instantiated `FakeAuthRepository`; when `backend == AuthBackend.appwrite`, verified non-empty endpoint and project ID (throwing fail-fast `StateError` if missing to avoid silent fallbacks) and initialized `AppwriteAuthRepository`.
   - Connected `authBloc.stream` to `appSessionBloc.add(AppSessionUserChanged(...))` and initiated `authBloc.add(const AuthSessionCheckRequested())`.

2. **Routing & Feature Scope Guards (`lib/core/router/router.dart`, `lib/core/router/router_wiring.dart`)**:
   - Implemented `AppRouterRefreshListenable` merging streams from `AuthBloc` and `AppSessionBloc`.
   - Guarded routing:
     - `AuthSessionStatus.unknown`: routes to `/loading` (or `/session-check-failed` if check failed).
     - `AuthSessionStatus.unauthenticated`: routes to `/auth`.
     - `AuthSessionStatus.authenticated`:
       - Profile loading / user transition: routes to `/loading`.
       - Profile failure: routes to `/profile-error`.
       - Profile ready with matching active user: routes to `/` (or `/welcome` if onboarding incomplete).
   - Created `AuthenticatedFeatureScope` as a `ShellRoute` builder providing scoped `DeviceServices`, `AppBloc`, `RemindersBloc`, `AudioBloc`, and `HistoryBloc` only when the authenticated profile is in `ready` state, cleanly preventing unauthenticated tree access to user-scoped resources.

3. **Settings Sign Out (`lib/src/settings/presentation/pages/settings_page.dart`)**:
   - Added a localized "Sign out" (`OutlinedButton`) dispatching `AuthSignOutRequested()`.
   - Supported both scoped `AuthBloc` resolution via `context.read<AuthBloc>()` and legacy direct construction.

4. **App Entry & Native Gating (`lib/main.dart`)**:
   - Updated `Startup` stateful widget to catch recoverable bootstrap configuration errors, presenting localized failure message and a "Try again" action button.
   - Updated `PrayerApp` to accept `AppBootstrapResult` while maintaining full backwards compatibility with legacy `AppBloc` parameters.
   - Implemented gated native alarm handling: incoming `openPrayer` and `consumeOpenPrayer` events are deferred until profile status is `ready`, then validated against `appSessionBloc.isValidReminderId(reminderId)` before navigating to `/prayer/...`. Unauthenticated or mismatched reminder IDs are safely dropped.
   - Added `schedulePeriodicRefresh` flag (default `true`, `false` for tests) to eliminate infinite midnight timers during widget testing.

5. **Legacy Data Guarantee**:
   - Preserved all files in `baseRoot` untouched without moving, copying, or deleting them. User profiles are isolated under `profiles/<hex_user_id>/`.

6. **R17 Protocol Limitation**:
   - Native platform channels only deliver integer reminder IDs without user ownership tags. While `isValidReminderId` drops IDs not belonging to the currently active profile, cross-profile ID collisions during an unclean crash or user switch cannot be disambiguated at the native channel layer alone; multi-user alarm disambiguation is documented and tracked under task R17.

## Verification & Test Results

1. **`dart format`**:
   - Formatted all touched files in `lib/` and `test/`. Clean 0 formatting diffs.

2. **`flutter analyze --no-pub`**:
   - 0 errors, 0 warnings, 0 lints.

3. **`flutter test --no-pub`**:
   - Full test suite: **140 passed**, 0 failed, 0 skipped.
   - Includes baseline 125 tests + 15 new tests for R01:
     - `test/core/di/bootstrap_test.dart`: 4 tests passed.
     - `test/core/router/router_test.dart`: 5 tests passed.
     - `test/presentation/settings_auth_test.dart`: 1 test passed.
     - `test/presentation/app_auth_integration_test.dart`: 5 tests passed (covering cold start signed-out, cold start authenticated, recoverable config failure, sign-in/sign-out lifecycle, and gated alarm navigation).

## File Changes Summary

- **Modified**:
  - `README.md`
  - `lib/core/di/bootstrap.dart`
  - `lib/core/router/router.dart`
  - `lib/main.dart`
  - `lib/src/settings/presentation/pages/settings_page.dart`
- **Created**:
  - `agent-comms/R01-AUTH-INTEGRATION.md`
  - `lib/core/router/router_wiring.dart`
  - `test/core/di/bootstrap_test.dart`
  - `test/core/router/router_test.dart`
  - `test/presentation/app_auth_integration_test.dart`
  - `test/presentation/settings_auth_test.dart`
