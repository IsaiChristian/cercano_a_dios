# TechTest style alignment — parallel implementation backlog

Status: proposed work only. No task in this file has been implemented by this review.

Read [the comparison](TECHTEST_STYLE_COMPARISON.md) for evidence and reference links. Target baseline: `88501f082c5ddf1c7e0a649986a182c1ae018765`. Recheck the checkout before starting; local links and paths describe the review baseline, and later paths follow T05's move manifest.

## Scope and frozen decisions

These decisions make the mechanical tasks safe for smaller models:

1. Preserve `dartz` and all eight `PrayerRepository` signatures, the canonical domain `Failure`, entity class names, constructor parameters/defaults, and persisted data formats.
2. Adopt `src/<feature>/presentation/{bloc,pages,widgets}`, `src/app/bloc`, `presentation/widgets`, and `data/mappers`. Keep `lib/main.dart`, `domain/use_cases`, `domain/failures`, `data/services`, and `l10n`.
3. Use `part`/`part of` for BLoC declarations. Separate files without changing states, event payloads, handler sequencing, equality, or async method behavior first.
4. Prefer `package:cercano_a_dios/...` imports between library files. Part directives remain relative. Preserve `flutter_lints`; do not add experimental syntax or change the SDK constraint.
5. Temporary export files keep old import paths working during independent tasks. They contain no duplicate class/function implementations. T11 removes them after all callers migrate.
6. Do not add Dio, a global network error bus, a remote logger, a database migration, an entity suffix rename, Equatable, or a concurrency package in the initial phase.
7. Keep existing generated localization, visuals, accessibility semantics, routing, platform method names, resource ownership, and failure messages. Log no prayer text, raw rows, recordings, or full local paths.

Use the routing in `agents.md`: Flash for narrowly defined extraction, Terra for state/repository behavior, Jules for the isolated repository-wide move and final cleanup. These are intended future worker assignments, not a claim that Flash or Jules is callable in this session. If unavailable, use the cheapest available capable model; do not silently assign implementation to Astra. Astra reviews contract/architecture decisions and reported uncertainty, not routine formatting.

## Scheduling and ownership

Each work item gets an isolated branch/worktree based on the required completed wave. Do not have workers format the entire shared checkout. Read access to another task's files is allowed; writing outside the allowlist is not. The integrator alone updates shared coordination status and performs merges. A missing outside-scope change must be reported, not silently made.

| Wave | Ready work | Can overlap | Merge barrier |
| --- | --- | --- | --- |
| 0 | T00 baseline | Nothing else edits yet | Establish baseline and task ownership |
| 1 | T01, T02-App, T02-Session, T02-Reminders, T03, T04 | Any disjoint items, bounded by available workers | Merge and check all before T05 |
| 2 | T05 global path migration | Exclusive source writer | Publish exact move manifest and verify all imports |
| 3 | T06 mappers/repository, T07 session composition, T08 AppBloc Either handling | These three have distinct source/test ownership | Merge and verify before T11 or optional wave 4 |
| 4, optional | T09 session event/state migration; T10 reminders event migration | Can overlap after their contracts are fixed; neither changes AppBloc | Required behavior tests and architecture review |
| 5 | T11 integration cleanup | Exclusive source writer | Final analysis/tests and handoff |

The minimal alignment route is waves 0–3 and 5. Wave 4 is the further BLoC resemblance work; mark it explicitly deferred if it is not commissioned. Do not claim event-only alignment if it is skipped. No worker may move directories concurrently with another worker editing their contents.

## Shared acceptance and handoff

For each patch run `dart format <owned changed Dart files>`, then `dart analyze`, plus the listed relevant tests. Run commands from the project root with the configured Flutter SDK. Record baseline failures separately. For repository-wide work, follow the Jules workflow: `flutter pub get`, `dart format .`, `dart analyze`, `flutter test`. Do not accept unrelated dependency/lockfile churn from `pub get`. Do not hand-edit generated localization files.

Each worker returns: task ID, base commit, files changed, decisions made, verification commands/results, unresolved issues, and dependency task IDs. Tests should verify behavior, not just renamed symbols. A merge is accepted only with `git diff --check` clean and the required checks passing, or a clearly identified pre-existing blocker handled by the integrator.

### T00 — Capture baseline and prepare ownership

- **Owner:** integrator; read-only analysis before workers start.
- **Read:** `agents.md`, `agent-comms/RULES.md`, current status, both alignment documents, `pubspec.yaml`.
- **Work:** record branch/commit, user-owned changes, toolchain versions, `dart analyze` and `flutter test` baseline. Record the current `lib` inventory and assign disjoint task branches. Keep checks bounded; investigate a hang rather than rerunning blindly.
- **Output:** baseline and ownership in coordination docs; no source edits.
- **Done:** later workers can distinguish regressions from baseline issues and know their exact write scopes.

### T01 — Split entities and domain date helpers

- **Owner:** Flash. **Depends on:** T00.
- **Write only:** `lib/domain/entities/prayer.dart`; new `prayer_prompt.dart`, `prayer_session.dart`, `reminder.dart` in that directory; new `lib/domain/utils/calendar_date.dart`.
- **Read:** existing entity file and the two domain use cases.
- **Work:** move each existing class unchanged to its file. Expand grouped fields and format constructors while preserving all parameter names, defaults, positional/named status, and type names. Move `calendarDate` and `civilDay` unchanged to the domain helper. Make `prayer.dart` an export-only compatibility file.
- **Constraints:** leave `Reminder.toPlatform` intact until T06. Do not add JSON methods, rename types, change date/timezone rules, or edit callers.
- **Verify:** analyze; `flutter test test/domain/progress_test.dart test/domain/reminder_test.dart test/data/repository_test.dart`.
- **Done:** old imports still compile, all original public declarations remain accessible, and calculations/persistence are unchanged.

### T02 — Split BLoC declarations (three separate tasks)

- **Owner:** Flash per feature. **Depends on:** T00.
- **Instances and allowlists:** T02-App owns only `lib/ui/features/app/bloc/`; T02-Session only `lib/ui/features/prayer_session/bloc/`; T02-Reminders only `lib/ui/features/reminders/bloc/`.
- **Read:** the owned BLoC and its callers, without editing callers.
- **Work:** extract `<name>_event.dart` and `<name>_state.dart`; add `part` in `<name>_bloc.dart` and `part of` in each part. Keep shared imports in the parent library. For Session, place `SessionPhase` with the state and preserve the completion typedef's accessibility. An optional `bloc.dart` barrel may export the parent library only.
- **Constraints:** no new dependency, equality implementation, subclass state conversion, removed Completer, or renamed public symbol. Existing imports of the BLoC must still expose its declarations.
- **Verify:** analyze. Session/App: `flutter test test/presentation/session_test.dart test/presentation/home_test.dart`; Reminders: run existing relevant domain/reminder checks and full analysis, explicitly noting the lack of dedicated reminder-BLoC coverage.
- **Done:** declaration organization resembles TechTest while behavior and caller APIs remain identical.

### T03 — Split shared widgets and helpers

- **Owner:** Flash. **Depends on:** T00.
- **Write only:** `lib/ui/core/widgets.dart`; new `lib/presentation/widgets/{quiet_card,page_body,section_label}.dart`, `lib/presentation/dialogs/confirm.dart`, `lib/presentation/formatters/time_label.dart`.
- **Read:** existing widgets, theme, localization imports, and widget callers.
- **Work:** move existing declarations intact; preserve constructor APIs, callbacks, semantics, colors, padding, and localized dialog labels. Keep old `widgets.dart` as an export-only compatibility file. Import the existing theme directly until T05 moves it.
- **Constraints:** do not edit theme, localization, feature pages, or constructor call sites. No visual redesign or arbitrary helper framework.
- **Verify:** analyze; `flutter test test/presentation/home_test.dart test/l10n/localization_test.dart`.
- **Done:** each reusable widget has its own file and old callers remain functional.

### T04 — Organize and verify the local Either boundary

- **Owner:** Terra. **Depends on:** T00.
- **Write only:** `lib/core/error/failure.dart`; new `lib/core/services/local_safe_call.dart`, `lib/core/error/logger_service.dart`, `test/core/services/local_safe_call_test.dart`.
- **Read:** domain `Failure`, repository usage, TechTest `safe_call.dart` and logger.
- **Work:** move `safeLocalCall` without changing its generic public signature. Re-export the helper and canonical domain `Failure` from the old core file. Return `Right` for success, preserve an already-thrown domain `Failure` in `Left`, and preserve the current fallback message for other exceptions. Provide one sanitized diagnostic entry per failure using an operation-neutral tag and exception type; do not expose raw exception text or sensitive stack/path content.
- **Constraints:** no HTTP dependencies, second Failure class, UI messages, new failure hierarchy, repository edits, or remote logging. Logger implementation must not throw into callers.
- **Verify:** tests for successful/null-or-void values, async thrown `Failure` identity, generic exception conversion, and one diagnostic without sensitive content; analyze and existing repository tests.
- **Done:** callers retain the same API and all failures stay inside Either. This is a small intentional correctness improvement, not merely formatting.

### T05 — Move presentation paths and normalize imports

- **Owner:** Jules, isolated branch; one source writer. **Depends on:** all wave 1 items.
- **Write scope:** all handwritten `lib`/`test` import sites affected by moves; moved presentation files; README architecture section. Never edit generated localization or unrelated platform/config files.
- **Move manifest:** `ui/features/app/bloc` → `src/app/bloc`; all other `ui/features/<feature>/bloc` → `src/<feature>/presentation/bloc`; their `views` → `src/<feature>/presentation/pages`; `ui/core/theme.dart` → `presentation/theme.dart`; `ui/core/prompt_localization.dart` → `presentation/prompt_localization.dart`. Shared widgets are already at T03 destinations. Do not create empty `bloc`/`widgets` directories for features without them.
- **Work:** update router, bootstrap, main, all feature imports, tests, part relationships as necessary, and temporary exports. Use package imports for handwritten library-to-library imports. Keep descriptive page filenames; reference `pages.dart` names need not be copied.
- **Constraints:** no logic, dependency, class-name, localization, platform, or schema changes. Leave T01/T03/T04 compatibility exports available for later cleanup. Keep test locations stable during this task so later task commands remain valid.
- **Verify:** full repository workflow; check all old moved UI paths with `rg`; distinguish expected compatibility references from stale imports.
- **Done:** provide an exact before/after manifest, passing imports/checks, and no competing path migrations.

### T06 — Extract data mappers and clarify local repository code

- **Owner:** Flash for the prescribed extraction; escalate to Terra only if behavior must change. **Depends on:** T01, T04, T05.
- **Write only:** `lib/data/models/session_mapper.dart`, new `lib/data/mappers/{session_mapper,reminder_mapper}.dart`, `lib/domain/entities/reminder.dart`, `lib/data/services/device_services.dart`, `lib/data/repositories/local_prayer_repository.dart`, new `test/data/mappers_test.dart`.
- **Read:** domain repository contract, database service schema, existing repository tests. Do not edit those files.
- **Work:** move existing session functions unchanged to `data/mappers`, leaving an export at the old path. Define `reminderFromRow(Map<String,Object?>)`, and a `ReminderMapper` extension with `toRow()` and `toPlatform()`. Move the platform method from Reminder into the extension; update DeviceServices and repository imports/calls. Expand compressed repository methods and use clear local variable names. Keep service access and conversion inside `safeLocalCall`; import its new path directly.
- **Frozen encoding:** session keys remain `id`, `promptId`, `promptText`, `localDate`, `completedAt`, `duration`, `offsetMinutes`, `spoken`, `audioPath`; UTC ISO completedAt and integer spoken flags remain unchanged. Reminder DB weekdays remain comma-separated strings and enabled stays integer; platform weekdays stay a list and enabled stays boolean. Keep `status` in DB rows and omit it from the platform payload.
- **Constraints:** no nullable-model/fold imitation, no duplicate error logging, no changes to delete/reset/audio validation ordering, schema, startup APIs, or repository signatures.
- **Verify:** mapper round trips, exact stored/platform keys and types, nullable audio, reminder status preservation; existing repository and domain tests; analyze.
- **Done:** mapping is explicit and correctly placed, malformed conversions remain `Left` when called through the repository, and persistence remains compatible.

### T07 — Extract session page rendering sections

- **Owner:** Flash. **Depends on:** T03, T05; uses the unchanged T02-Session state API.
- **Write only:** `lib/src/prayer_session/presentation/pages/session_page.dart`, new files in that feature's `widgets/`, and new `test/presentation/session_widgets_test.dart`.
- **Read:** SessionBloc, router provider wiring, current session page and localization.
- **Work:** extract cohesive ready/recording/review/completion rendering components. Pass only needed values and callbacks using existing types. The amplitude component, if extracted, displays the current value and adds no animation or polling. Keep localized error resolution and event wiring in the page as appropriate.
- **Constraints:** preserve existing SessionBloc ownership in the router, lifecycle observer, badge snapshot, `PopScope`, button enablement, callbacks and save/retry behavior. Do not edit BLoCs, router, shared widgets or existing session logic tests. No second provider or new state mechanism.
- **Verify:** focused widget tests covering phase-specific controls and disabled busy controls; analyze; existing session and home tests.
- **Done:** page coordinates lifecycle/state while extracted widgets render the same content and interactions.

### T08 — Handle repository Either results explicitly in AppBloc

- **Owner:** Terra. **Depends on:** T02-App, T05. Can run beside T06 and T07.
- **Write only:** `lib/src/app/bloc/` and new `test/presentation/app_bloc_test.dart`.
- **Read:** `PrayerRepository`, bootstrap, SessionBloc/RemindersBloc callers and existing tests.
- **Work:** replace AppBloc's throw-based internal `unwrap` flow with explicit success/failure branching for repository operations. Preserve sequential side effects and await async fold branches correctly. Keep all public methods, event types, Completer success/failure behavior, and AppState fields unchanged. Preserve public `unwrap` compatibility if retained callers exist; remove its internal use first.
- **Constraints:** no domain changes or global error bus. A failed prerequisite must not execute later operations. Keep refresh completion behavior used by bootstrap, prayer-save success after refresh, reminder pending→schedule→ready/paused behavior, and recovery refresh after scheduling failure.
- **Verify:** new tests for Left on each prerequisite, no later side effects, successful refresh, failed refresh, successful/failed save, pending reminder recovery, and reset failure; existing session/home tests; analyze.
- **Done:** repository failures are explicit at their consumers, with unchanged outward async behavior. Escalate uncertain completion semantics before changing them.

### T09 — Optional SessionBloc event/state migration

- **Owner:** Terra; Astra reviews the frozen state/consumer contract and resulting cross-layer change. **Depends on:** T07, T08 and merged wave 3.
- **Write only:** `lib/src/prayer_session/presentation/`, `test/presentation/session_test.dart`, `test/presentation/session_widgets_test.dart`, and `lib/core/router/router.dart` only if a verified SessionBloc call requires migration. No AppBloc edits.
- **Contract before coding:** model the existing ready, starting, recording, stopping, review, saving and complete phases as distinct states; retain duration, amplitude, and recoverable error payloads where they apply. A recording/review error must not become a terminal generic failure that discards retry context. Document every existing caller of `start`, `finish`, `save`, `play`, `stopPlayback`, and `interrupt`, including awaited return values.
- **Work:** convert UI actions to payload-only events and update tests to observe deterministic states. Preserve the AppBloc completion callback until a separate coordinator API change is designed. Remove public command Completers only after every consumer has an equivalent completion mechanism. Use listeners only for one-time effects, with no navigation repeated on rebuild.
- **Constraints:** do not blindly apply `droppable` to every event. Preserve ordering across recording, stop, save, interruption and close; interruption during startup must preserve the `_leaving` safeguard. Retain the 120-second automatic stop, storage-limit response, silent-success draft deletion, and snooze cancellation only after successful completion. No package additions without a separately justified contract change. Do not remove `close` cleanup or substitute timing sleeps in tests. Completion state currently precedes silent-file deletion; tests that assert cleanup must await an explicit settled-operation signal or close, not assume the first terminal state means every side effect has finished.
- **Verify:** recording finish does not save; microphone denial permits silent completion; save failure retains retryable draft; retries do not duplicate credit; interruption stops without completing; repeated taps and close-during-operation settle safely; stop/save failures recover; playback failure retains a usable phase; time/storage limits remain intact; successful silent save deletes draft audio; successful reminder completion cancels snooze; close deletes unsaved files but preserves saved recordings; amplitude/timer/subscription cleanup; existing widget tests and full tests/analyze for this cross-layer change.
- **Done:** UI command events contain no Completers, state payloads preserve behavior, all callers are migrated, and no test depends on arbitrary waiting.

### T10 — Optional reminder UI event migration

- **Owner:** Terra. **Depends on:** T08 and merged wave 3. May overlap T09.
- **Write only:** `lib/src/reminders/presentation/` and new `test/presentation/reminders_bloc_test.dart`.
- **Read:** AppBloc public methods and reminder page dialog/lifecycle flows.
- **Work:** replace reminder UI command wrappers with payload-only events and explicit operation completion state. Preserve capability/permission/busy data. The state contract must identify which save/delete completed, so listeners close the correct dialog only after success and never repeat effects on rebuild. Internal awaited AppBloc calls remain until a separate coordinator migration is designed.
- **Constraints:** no AppBloc, SessionBloc, router, platform channel, scheduler, or persistence edits. Preserve failure-visible dialog behavior, permission refresh and busy guards. State shape can stay a snapshot where that avoids unrelated churn.
- **Verify:** save success/failure, delete failure, permission refresh, duplicate taps, no premature dialog closure, and repeated listener/rebuild behavior; analyze and relevant tests.
- **Done:** reminder UI uses events with reliable completion feedback. This does not claim to remove AppBloc's awaitable coordination APIs.

### T11 — Integrate, remove transitional exports and verify

- **Owner:** Jules, exclusive source writer. **Depends on:** wave 3, plus T09/T10 if commissioned.
- **Write scope:** obsolete compatibility files and their handwritten import sites, final formatting, README, coordination handoff. No new behavior, dependencies, or generated-file edits.
- **Work:** update consumers of `prayer.dart`, old `widgets.dart`, old mapper path and old helper exports to canonical files; remove only confirmed unused compatibility exports. Preserve any documented public API still used. Optionally relocate tests to mirror feature paths now, recording the new commands; this move belongs only to the integrator. Check no import cycles or duplicate domain types were introduced.
- **Verify:** `flutter pub get`, `dart format .`, `dart analyze`, `flutter test`, `git diff --check`; inspect dependency/lockfile changes and generated outputs. Verify all eight domain repository methods still return Either and no Dio/HTTP stack was introduced. Review the final diff for unintended visual, schema, method-channel, or generated localization changes.
- **Done:** no migration shims remain unless explicitly documented with a caller/removal reason; final docs describe actual structure. Report optional tasks as completed or deferred. Request Astra review only for architecture/contract changes, uncertainty, or failures per `agents.md`.

## Deferred rather than forgotten

- **Dio and global network errors:** reopen only with a concrete remote feature, endpoints, error UX and lifecycle requirements. Do not assign an empty networking implementation now.
- **Entity suffixes/constructor API changes:** optional literal naming alignment, not part of this behavior-preserving plan.
- **All AppBloc commands becoming event-only:** requires a separate design for bootstrap readiness and cross-feature completion results. T08 improves Either usage without prematurely changing those contracts.
- **Exact Equatable/transformer parity:** evaluate only alongside defined state equality and event ordering, not as a cosmetic dependency change.

## Small-worker dispatch template

> Implement task Txx only, based on the recorded dependency commit. Read the listed input files and the frozen decisions above; do not load the whole conversation. Edit only the task allowlist. Preserve its stated APIs and invariants. If a change outside that scope is necessary, report the exact file and reason without editing it. Run the specified verification and return files changed, decisions, command results, and unresolved issues. Do not start dependent or optional tasks.
