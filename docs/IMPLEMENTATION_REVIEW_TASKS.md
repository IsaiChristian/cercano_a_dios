# Implementation review task list

Reviewed on 2026-09-17 against `main` at `4d8e66edf71709df6f9863ad5efe004374dc94cd`.
This is a source review and verification snapshot, not an implementation change.
All tasks below are proposed and unassigned. No fixes, commits, or pushes were made.

## Coverage and verification

Coverage includes startup/routing, authentication and profile lifecycle, domain rules,
repositories and storage, feature BLoCs and screens, localization, Android/iOS native
bridges, macOS scaffold, tests, build configuration, and project documentation.
Generated code was treated as output rather than hand-maintained implementation.

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Passed: no issues |
| `flutter test --no-pub --reporter expanded` | Passed: 125 tests |
| `dart format --output=none --set-exit-if-changed lib test` | Failed style check: 13 of 93 files would change; no files written |
| Native builds, live Appwrite, device/alarm/audio/accessibility flows | Not run in this review |

Toolchain: Flutter 3.35.5, Dart 3.9.2. Existing changes to `ios/Podfile.lock` and
`macos/Flutter/GeneratedPluginRegistrant.swift` were preserved.

P1 means a core behavior or planned feature is blocked or incorrect; P2 means a
significant reliability/usability improvement; P3 means maintenance work.
Code-supported findings are distinguished from verification gaps and hardening ideas.
Passing component tests does not validate the full application or native device behavior.

## Prioritized tasks

- [x] **R01 · P1 · Complete authentication and per-user app integration.**
  **Evidence:** `lib/main.dart:25`, `lib/core/di/bootstrap.dart:9`,
  `lib/core/router/router.dart:19`. Startup still constructs a shared-root
  `AppBloc`; the router exposes no auth flow or profile-readiness guard. The
  implemented auth/profile components are therefore unreachable from the actual
  app. This is unfinished integration, not evidence of a deployed login bypass.
  **Done when:** startup selects the configured auth repository, auth and profile
  lifecycle drive routing, settings exposes sign-out, and no prayer screen mounts
  before the matching user's profile is ready. Add full-app tests for cold start,
  sign-in/out, profile failure/retry, account switching, and alarm entry. Define
  explicit handling of existing anonymous data before migrating it.

- [x] **R02 · P1 · Keep history and audio storage totals consistent after mutations.**
  **Evidence:** `lib/src/app/bloc/app_bloc.dart:236`, `:250`, `:264`, `:278`;
  `lib/src/history/presentation/pages/history_page.dart:137`;
  `lib/src/prayer_session/presentation/bloc/session_bloc.dart:116`.
  Saving/deleting a session refreshes history without recomputing audio bytes;
  audio deletion updates bytes without replacing history's old `audioPath`.
  Playback controls can remain for deleted files, and the recording quota uses
  stale totals until a later refresh.
  **Done when:** single/bulk audio deletion immediately removes playback controls;
  save/session deletion updates storage and quota immediately; streak/history
  semantics remain intact. Add AppBloc integration tests across child BLoCs.

- [x] **R03 · P2 · Preserve failed and partially completed audio-delete results.**
  **Evidence:** `lib/src/audio/presentation/bloc/audio_bloc.dart:125` and `:153`.
  A repository `Left` emits an error, but the handler proceeds to emit
  `clearError: true` and resolves its command normally. Bulk deletion also hides
  which operations failed, so callers cannot reliably distinguish full success.
  **Done when:** failed/partial deletion has an explicit outcome, preserves a
  useful error until handled, refreshes the successful changes, and supports
  retry. Test single failure and mixed-success bulk deletion.
  **Implemented:** `codex/r03-audio-delete-results` (PR #18). Details: [`R03-AUDIO-DELETE-RESULTS.md`](../agent-comms/R03-AUDIO-DELETE-RESULTS.md).

- [x] **R04 · P2 · Honor device locale and persist the user's language choice.**
  **Evidence:** `lib/src/app/bloc/app_state.dart:13`,
  `lib/src/app/bloc/app_bloc.dart:214`, `lib/main.dart:154`,
  `lib/src/settings/presentation/pages/settings_page.dart:51`.
  App state forces English and language changes only update memory. A Spanish
  device does not get the documented default, and a chosen language resets on
  restart.
  **Done when:** first launch uses supported device-locale resolution, an explicit
  choice survives restart, and unsupported locales fall back consistently. Test
  English, Spanish, unsupported locale, and persisted override.
  **Implemented:** `codex/r04-locale-persistence` (PR #19). Details: [`R04-LOCALE-PERSISTENCE.md`](../agent-comms/R04-LOCALE-PERSISTENCE.md).

- [x] **R05 · P3 · Make formatting and toolchain validation reproducible.**
  **Evidence:** `.github/workflows/flutter.yml:8`, `:23`, `:35` use unpinned
  stable Flutter and run no formatting check. The read-only formatter check
  currently reports 13 files.
  **Done when:** choose and document a tested Flutter version, use it consistently
  in CI, normalize formatting in a separate mechanical change, and gate CI with
  `dart format --output=none --set-exit-if-changed lib test`. Preserve the tracked
  dependency lockfile. Consider stricter analyzer rules separately after checking
  their actual diagnostic value.
  **Formatting scope:** `lib/data/prompts.dart`,
  `lib/domain/repositories/prayer_repository.dart`,
  `lib/domain/use_cases/calculate_progress.dart`,
  `lib/domain/use_cases/next_reminder.dart`,
  history/home/settings page files, `test/core/services/local_safe_call_test.dart`,
  `test/data/appwrite_auth_repository_test.dart`, `test/domain/progress_test.dart`,
  `test/domain/reminder_test.dart`, `test/presentation/auth_page_test.dart`,
  `test/src/app/bloc/app_state_test.dart`.
  **Implemented:** `codex/r05-formatting-toolchain`. Pinned Flutter 3.35.5 across CI jobs, added `dart format --output=none --set-exit-if-changed lib test` CI gate, updated AGP to 8.11.1 with `--android-skip-build-dependency-validation` to resolve CI build conflicts, and normalized formatting across all 11 files with flow-control braces. Details: [`R05-FORMATTING-TOOLCHAIN.md`](../agent-comms/R05-FORMATTING-TOOLCHAIN.md).

- [ ] **R06 · P3 · Reconcile product/setup documentation with the actual checkout.**
  **Evidence:** `README.md:20` still says no account is included; its run section
  describes generating an untracked lockfile even though `pubspec.lock` is tracked.
  `docs/VALIDATION.md` mixes old no-tests-run claims with newer results, while
  auth-related privacy copy already describes Appwrite. Account components exist,
  but R01 integration is still missing.
  **Done when:** document implemented versus wired features, the tested toolchain,
  actual verification results and remaining device gaps. Include auth configuration
  and fake-mode instructions when R01 lands. Remove contradictory current-status
  claims while keeping historical evidence explicitly dated.

- [ ] **R07 · P1 · Make refresh failures deterministic across child BLoCs.**
  **Evidence:** `lib/src/app/bloc/app_bloc.dart:188`;
  `lib/src/history/presentation/bloc/history_bloc.dart:40`;
  `lib/src/reminders/presentation/bloc/reminders_bloc.dart:91`;
  `lib/src/audio/presentation/bloc/audio_bloc.dart:64`.
  Child loads resolve normally on failure, while AppBloc subsequently clears its
  error unconditionally. Child error events and refresh completion can race;
  startup/factory code relies on that final error to decide whether opening worked.
  **Done when:** refresh returns an explicit aggregate result, failed loads cannot
  be overwritten by a success state, and startup exposes retry rather than a
  misleading empty journal. Test each child failing alone and mixed outcomes.

- [ ] **R08 · P1 · Prevent stale auth requests from replacing newer auth state.**
  **Evidence:** `lib/src/auth/presentation/bloc/auth_bloc.dart:22`, `:65`, `:100`.
  Session checks can overlap sign-in/up: a delayed `currentUser()` returning null
  can clear a newer successful sign-in. The submitting guard does not serialize
  checks with other event types. This is a component defect to fix before R01 ships.
  **Done when:** auth operations have a defined ordering/latest-request policy;
  delayed checks cannot reverse a newer sign-in or sign-out. Add controlled-future
  tests across event types, including check completion after successful sign-in.

- [ ] **R09 · P1 · Close partially initialized resources on startup failure.**
  **Evidence:** `lib/core/di/bootstrap.dart:14`, `:28`;
  `lib/core/di/authenticated_app_factory.dart:37`, `:41`, `:47`.
  Failures after opening a database but before returning the app lack complete
  cleanup. Legacy bootstrap also throws after a failed refresh without closing
  the AppBloc. Repeated retries can retain connections/subscriptions.
  **Done when:** ownership is explicit through every initialization stage and each
  failed attempt closes all resources it created. Test reconciliation, onboarding
  read, and initial-load failure. Preserve the shared device stream when closing
  only an authenticated profile.

- [ ] **R10 · P1 · Make profile shutdown safe during an in-flight transition.**
  **Evidence:** `lib/src/app_session/bloc/app_session_bloc.dart:86`, `:130`, `:182`.
  `close()` captures only the current app and does not invalidate transition
  tickets. A delayed factory can return afterward and install an unclosed app.
  Normal profile-switch cleanup is not used by `close()`. This becomes reachable
  through app composition in R01.
  **Done when:** closing prevents late installation, disposes late-created apps,
  settles pending operations, and applies an explicit native-effect shutdown
  policy. Test close during creation, retry, reminder restoration, and ready state.

- [ ] **R11 · P2 · Attempt local data reset even if native cancellation fails.**
  **Evidence:** `lib/src/app/bloc/app_bloc.dart:333`.
  A throwing `device.cancelAll()` aborts before `repository.reset()`, so the user's
  delete-data request leaves local history/audio intact. Playback failures also
  need explicit treatment because AudioBloc currently resolves them normally.
  **Done when:** local wipe and native cleanup are attempted independently, the
  result clearly identifies incomplete alarm cleanup or data deletion, and retry
  is safe. Test cancellation failure, storage failure, and combined failures.

- [ ] **R12 · P2 · Constrain audio paths to the active profile.**
  **Evidence:** `lib/data/services/local_storage_service.dart:11`;
  `lib/data/services/local_prayer_database_service.dart:94`;
  `lib/data/repositories/local_prayer_repository.dart:50`.
  Audio paths from persisted rows are joined to the root without rejecting
  traversal/absolute paths. Malformed or tampered rows can make read/delete
  operations escape the profile. Normal session generation supplies safe names;
  this is boundary hardening, not a demonstrated remote exploit.
  **Done when:** both storage services enforce one filename/containment contract;
  repository operations and reconciliation reject invalid paths safely. Test
  absolute paths, `..`, separators, and an outside sentinel file that must survive.

- [ ] **R13 · P2 · Use safe, typed, localized errors across app features.**
  **Evidence:** `lib/src/prayer_session/presentation/bloc/session_bloc.dart:116`,
  `:157`, `:213`, `:232`; `lib/src/prayer_session/presentation/pages/session_page.dart:194`;
  `lib/src/app_session/bloc/app_session_bloc.dart:104`, `:146`;
  `lib/src/audio/presentation/bloc/audio_bloc.dart:175`.
  Session errors are hardcoded English despite existing ARB translations.
  Other handlers expose `error.toString()`, which can include filesystem paths
  and internal details. Profile errors are not yet displayed by the main app,
  but their state already carries these unsafe messages.
  **Done when:** BLoCs expose typed reasons, UI maps them to generated localization
  getters, and internal exceptions never become user-facing strings. Test Spanish
  recording/storage/playback/save errors and a path-bearing profile exception.

- [ ] **R14 · P2 · Finish localization and accessible labels in feature screens.**
  **Evidence:** `lib/src/progress/presentation/pages/progress_page.dart:52` uses
  English `badgeLabels` from `lib/domain/use_cases/calculate_progress.dart:11`;
  `lib/src/home/presentation/pages/home_page.dart:133` hardcodes weekday letters;
  `lib/src/reminders/presentation/pages/reminders_page.dart:170` displays platform
  status/date values; `lib/src/history/presentation/pages/history_page.dart:131`
  displays stored ISO dates.
  **Done when:** badge IDs map to existing generated translations; weekdays and
  dates follow the locale; permission codes become understandable localized copy;
  reminder switches have names identifying the associated time/day. Add English
  and Spanish widget/semantics checks, including large text on small screens.

- [ ] **R15 · P2 · Make feature command completion and teardown contracts explicit.**
  **Evidence:** `lib/src/history/presentation/bloc/history_bloc.dart:22`, `:40`;
  `lib/src/audio/presentation/bloc/audio_bloc.dart:34`;
  `lib/src/reminders/presentation/bloc/reminders_bloc.dart:30`, `:60`;
  `lib/main.dart:84`, `:129`.
  Command wrappers add events without a closed-state policy; History handlers can
  leave completers pending if a repository unexpectedly throws. Reminder settings
  and test-alarm futures resolve before their work finishes. The app's native
  callback handler is installed without corresponding removal on disposal.
  **Done when:** every public future settles with a defined outcome, callers can
  await actual completion, and late callbacks cannot target disposed state. Test
  unexpected repository exceptions and commands/callbacks around teardown. Keep
  the existing Either repository contract; this is lifecycle hardening.

- [ ] **R16 · P2 · Reconcile reminder persistence with native scheduling failures.**
  **Evidence:** `lib/src/reminders/presentation/bloc/reminders_bloc.dart:118`.
  Native scheduling occurs between a `pending` write and the final `ready` write.
  If the final write fails, an alarm may be active while stored status remains
  pending. The pending marker is useful, but recovery is not an explicit tested
  transaction/reconciliation policy.
  **Done when:** define recovery for every failure stage, report actual scheduling
  status honestly, and reconcile idempotently on retry/relaunch. Test final-write
  failure, cancellation failure, partial scheduling, and restart with pending rows.

- [ ] **R17 · P1 before multi-account release · Bind native alarms to profile ownership.**
  **Evidence:** `android/app/src/main/kotlin/com/cercanoadios/app/PrayerAlarm.kt:16`;
  `android/app/src/main/kotlin/com/cercanoadios/app/MainActivity.kt:28`;
  `ios/Runner/AppDelegate.swift:223`; `lib/data/services/device_services.dart:27`;
  `lib/src/app_session/bloc/app_session_bloc.dart:54`.
  Native persistence and callback payloads use global integer reminder IDs, while
  Android restores alarms before profile selection. The profile validator checks
  only whether an integer exists in the current profile, so reused IDs cannot
  establish the originating owner. Clean-switch cancellation mitigates this;
  crash/interrupted-switch behavior remains unverified. R01 is not wired today.
  **Done when:** persistent schedules and actions carry sufficient profile or
  generation ownership, restoration waits for a valid owner, and stale callbacks
  cannot act on another user's reminder. Test same IDs across users, process kill
  during sign-out/switch, reboot, and delayed old-user notification actions.

- [ ] **R18 · P2 · Specify and verify iOS overlap behavior when recording starts.**
  **Evidence:** `ios/Runner/AppDelegate.swift:275` stops every alerting AlarmKit
  alarm; `lib/src/prayer_session/presentation/bloc/session_bloc.dart:132` invokes
  that global stop before recording, without passing the linked reminder ID.
  This is confirmed code behavior; whether quieting all alarms for recording is
  intended needs an explicit product decision. It is distinct from the previously
  fixed reminder-specific Stop/Snooze notification actions.
  **Done when:** document the overlap rule, carry identity through the bridge if
  only the linked reminder should stop, and verify two simultaneous reminders on
  iOS 26. An unrelated reminder must retain the behavior chosen by that policy.

- [ ] **R19 · P2 · Validate release builds and native device flows.**
  **Evidence:** `.github/workflows/flutter.yml:27`, `:39` build debug/simulator
  variants only; `android/app/build.gradle.kts:37` signs release with debug keys;
  `docs/VALIDATION.md` records outstanding native validation.
  **Done when:** configure distribution signing, build release variants, verify
  merged Android network permissions and Appwrite connectivity for R01, compile
  the AlarmKit branch with Xcode 26+, and execute the documented device matrix.
  Include permissions denied/revoked, lock/background/termination, reboot, DST,
  overlaps, snooze/stop, interruption, storage failure, and native UI language.
  These are release/verification gaps, not claimed device test failures.

- [ ] **R20 · P3 · Define macOS support and reconcile its generated dependencies.**
  **Evidence:** `macos/Runner/MainFlutterWindow.swift:12` implements only the
  `directory` channel method; other audio/alarm calls are unsupported. The
  user-modified `macos/Flutter/GeneratedPluginRegistrant.swift:8` references more
  plugins than the current `macos/Podfile.lock` records; no build was run to prove
  whether regeneration resolves this.
  **Done when:** explicitly limit the target to development or gate unsupported
  features with capability states; implement missing methods only if macOS is a
  product target. Regenerate dependencies using Flutter/CocoaPods and verify a
  clean build. Preserve the user's generated-file changes until reconciled.

- [ ] **R21 · P3 · Reject invalid auth backend configuration.**
  **Evidence:** `lib/core/config/auth_config.dart:20` maps every value except
  exact `fake` to Appwrite. A typo can select an unintended backend when credentials
  are present, or report misleading missing-config errors.
  **Done when:** preserve the documented empty/default behavior, accept explicit
  supported values, reject other values clearly, and test default/fake/Appwrite/
  invalid selection. Integrate with R01 startup configuration handling.

- [ ] **R22 · P2 · Add tests at the boundaries missed by the current suite.**
  **Evidence:** `test/` has component BLoC coverage but no full startup/router/auth
  integration suite; main feature screen interaction/locale coverage is sparse.
  `test/presentation/auth_page_test.dart:116` taps the password visibility toggle
  without asserting its effect; localization tests focus on privacy copy.
  **Done when:** assert obscured/visible password behavior, add full-app flows from
  R01, cross-BLoC cases from R02/R07, and critical session/history/reminder/settings/
  progress interaction tests. Add Spanish, large-text and semantics cases tied to
  R13/R14. Native device checks remain separate from Dart unit tests.

## Suggested execution order and constraints

1. Fix current data/state reliability: R02, R03, R07, R09, R11.
2. Prepare auth integration: R08, R10, R12, R17, R21, then complete R01 with R22.
3. Finish user-facing quality: R04, R13, R14, R15, R16, R18.
4. Establish release evidence and cleanup: R19, R20 if supported, R05, R06.

R22 regression coverage should land with the corresponding fixes, not wait until
the end. Most tasks touch shared composition or BLoC files: claim narrow ownership
on the coordination board before implementation rather than dispatching the list
all at once. Follow the repository's Astra-low implementation and focused review
policy for domain/architecture or cross-layer changes. This review creates no
implementation assignments and does not authorize integrating old remote work.
