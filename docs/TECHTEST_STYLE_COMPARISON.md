# TechTest architecture and code style comparison

Review date: 2026-09-15. Scope: analysis and future work only; no application changes.

## Assessment

Cercano a Dios resembles TechTest at the architectural vocabulary level: Flutter, BLoC, `core`/`data`/`domain`, repository interfaces, constructor injection, and `dartz` `Either`. Its presentation layout and file organization are noticeably different. A developer familiar with TechTest would probably recognize the architectural influences but encounter different conventions when opening individual files.

This is a qualitative style comparison, not reliable authorship attribution. A small sample cannot establish whether the same developer wrote both projects. Flash's categorical conclusion about authorship is stronger than the evidence supports.

The best initial alignment is mechanical: feature paths, separate event/state files, focused entity/widget files, mapper placement, package imports, and readable declarations. Keep the existing `Either` contracts. Do not add an unused Dio stack or copy reference implementation defects to increase resemblance.

The executable future backlog is in [TECHTEST_ALIGNMENT_TASKS.md](TECHTEST_ALIGNMENT_TASKS.md).

## Evidence and reproducibility

The comparison uses the actual TechTest checkout at commit `95e769d4258da2ceeee151dd1735a7e6d340b26a`, not just its README. The target baseline is `88501f082c5ddf1c7e0a649986a182c1ae018765`. Before this review, `git status --short` showed only an untracked, user-owned `agents.md`. Local line references below describe that baseline.

Flash's input was the attached **Architecture & Code Style Alignment Plan**, supplied as `pasted-text.txt`. Its claims are assessed separately below. This is a spot review, supplemented with direct dependencies to understand behavior; it is not an exhaustive audit or a runtime test report.

| Requested sample | TechTest source | Cercano a Dios source |
| --- | --- | --- |
| Structure | [Architecture README](https://github.com/IsaiChristian/TechTest/tree/95e769d4258da2ceeee151dd1735a7e6d340b26a#architecture), checked against actual `lib` files | Actual `lib` inventory; [README](../README.md) |
| Entity | [movie_entity.dart](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/domain/entities/movie_entity.dart#L1) | [prayer.dart](../lib/domain/entities/prayer.dart), lines 1–34 |
| BLoC | [home_bloc.dart](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/src/home/presentation/bloc/home_bloc.dart#L1), plus its event/state parts | [session_bloc.dart](../lib/ui/features/prayer_session/bloc/session_bloc.dart), especially lines 11–155 |
| Widget | [tt_app_bar.dart](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/presentation/widgets/tt_app_bar.dart#L1) | [widgets.dart](../lib/ui/core/widgets.dart), `QuietCard`, lines 6–22; also inspected the session page for composition |
| Dio | [dio_client.dart](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/core/network/dio_client.dart#L1) | No Dio file or dependency exists. Nearest boundary comparison: [device_services.dart](../lib/data/services/device_services.dart) and [failure.dart](../lib/core/error/failure.dart), not an HTTP equivalent |
| Required repository | [movies_repository_imp.dart](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/data/repositories/movies_repository_imp.dart#L17) | [local_prayer_repository.dart](../lib/data/repositories/local_prayer_repository.dart), lines 30–83 |

## Structure: what actually matches

```text
TechTest — observed                     Cercano a Dios — observed
lib/                                   lib/
  core/                                  core/
    di/, error/, network/                  di/, error/, router/
    router/, services/                   data/
  data/                                    models/session_mapper.dart
    mappers/, models/, repositories/       repositories/, services/, prompts.dart
  domain/                                domain/
    entities/, repositories/               entities/, failures/, repositories/
  presentation/widgets/                    use_cases/
  src/                                   ui/
    app/bloc/                              core/
    <feature>/presentation/                features/<feature>/
      bloc/, pages/, widgets/                bloc/, views/ (where needed)
  main.dart                              l10n/, main.dart
```

TechTest's app BLoC is an exception to its feature presentation nesting: `src/app/bloc`. Its actual entry point is `lib/main.dart`, although the README diagram and launch examples say `lib/src/main.dart`. Some reference `widgets.dart` files are placeholders; folder names alone do not prove extensive component extraction. Do not blindly reproduce the diagram or create empty folders.

Recommended target: move feature UI to `src/<feature>/presentation/{bloc,pages,widgets}`, app coordination to `src/app/bloc`, shared UI to `presentation`, and mapper functions to `data/mappers`. Keep `main.dart`, generated localization, domain use cases, the single domain `Failure` type, and the existing data service boundary. Moving platform adapters into `core/services` is a cosmetic option with little benefit here and is excluded from the initial work.

## Spot findings

### Entity: resemblance is mixed; Flash's purity claim is false

`MovieEntity` uses one class per file, an `Entity` suffix, separate field declarations, a const named constructor, and package imports. In contrast, `prayer.dart` combines `PrayerPrompt`, `PrayerSession`, `Reminder`, and two date helpers; it groups fields and compresses several declarations. `PrayerPrompt` uses positional arguments.

However, `MovieEntity` implements `JsonConvertible`, imports a core storage service, and defines both `toJson` and `fromJson` (lines 1–43). The reference is not consistently serialization-free. Moving `Reminder.toPlatform` out of the entity is a reasonable boundary improvement, but must be labeled a deliberate improvement, not a requirement faithfully inferred from TechTest.

The target's session row conversion already lives outside the entity, in `data/models/session_mapper.dart`. Reminder database conversion is inline in the repository, and reminder platform conversion is in the entity. These are three distinct locations to address. Keep calendar/streak date semantics in domain helpers; they are not database mappers.

Split files and expand fields first. Preserve class names and constructor signatures to limit cascading edits. An `Entity` suffix and named-only constructors would increase literal resemblance but have low return for their API churn, so defer them.

### BLoC: genuine style differences, with behavioral dependencies

TechTest's `HomeBloc` uses `part` event/state files, `Equatable`, explicit `HomeInitial`/`HomeLoading`/`HomeReady`/`HomeError` states, named event handlers, `Either.fold`, and `droppable()` on selected events. The target already extends `Bloc`, registers event handlers, and emits immutable snapshots. Its differences are colocated event/state declarations, a `SessionPhase` enum, and async public methods that enqueue events carrying `Completer`s.

Splitting files while preserving the API is mechanical. Replacing the state representation or removing completion futures is a separate logic migration. An enum state is not inherently incorrect. Session recording also has timing, interruptions, retries, draft cleanup, and navigation dependencies that a movie list does not have.

This convention spans the target's AppBloc and RemindersBloc as well. Migrating SessionBloc alone does not eliminate it project-wide. `AppBloc.unwrap` (lines 160–163) turns `Left` into exceptions; using explicit folds in repository-consuming handlers would resemble `HomeBloc` more closely. The reference itself also uses throw-inside-fold in its favorites repository, so it is not entirely uniform.

Keep dependency injection through `PrayerRepository`. The reference HomeBloc depends directly on `MovieRepositoryImpl`; copying that would weaken the current boundary. Do not add `Equatable` or `bloc_concurrency` just for file splitting; any future equality/concurrency change needs its own behavior review.

### Widget: smaller files and composition are the useful match

Both `TtAppBar` and `QuietCard` are small stateless widgets with const constructors and final fields. Reference `TtAppBar` has its own file and a block-bodied `build`; target `widgets.dart` combines three widgets, a dialog function, and a time formatter, using expression-bodied builds.

The session page already uses `BlocBuilder` at line 52. Lifecycle observation and `previousBadges` are local widget concerns, not proof that feature state is missing a BLoC. Its provider is already owned by the router. Extract cohesive rendering sections without creating another SessionBloc or losing its disposal behavior.

The reference is not uniformly formatted: the sampled app bar has compressed layout and spacing, and its home page mixes `BlocBuilder` with `context.watch`. Prefer formatter output, focused files, and clear page composition over mimicking those inconsistencies. Preserve target localization, accessibility, colors, routes, and existing constructor APIs. There is no standalone amplitude visualizer class in the current session page; extracting its existing amplitude display is optional, not a missing animation feature.

### Dio: compare the pattern, defer the infrastructure

TechTest wraps Dio with base options, timeouts, query credentials, a failure interceptor, and request/response logging. Its [failure interceptor](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/core/network/failure_interceptor.dart#L6) maps Dio errors and dispatches selected global errors. Its [safeCall](https://github.com/IsaiChristian/TechTest/blob/95e769d4258da2ceeee151dd1735a7e6d340b26a/lib/core/network/safe_call.dart#L6) converts thrown errors into `Either`.

The target is an offline SQLite and MethodChannel app. `pubspec.yaml` has no Dio dependency, and no Dio/HTTP client was found in `lib`. Its [PRD](PRD.md), lines 198 and 215–216, explicitly defers networking until remote features require it. The relevant reusable idea is a service boundary plus a safe operation wrapper, which already exists. Improve the local wrapper's organization and diagnostics; defer Dio, interceptors, credentials, and a global network error bus until a real remote feature exists. Do not copy body logging into a private prayer application.

### Repository and Either: preserve the contract, improve the implementation selectively

All eight methods of `PrayerRepository` already return `Future<Either<Failure, T>>`. `LocalPrayerRepository` wraps service access and row conversion together in `safeLocalCall`. Its constructors, `open`, schema helper, and startup reconciliation are infrastructure APIs, not domain operations; Flash's criterion that every repository method return `Either` is too broad.

The requested movie repository uses `safeCall`, `fold`, model parsing, mapper extensions, and `Right`/`Left`. Preserve those responsibilities, but do not copy its nullable-model control flow literally:

- In `getPopularMovies`, lines 34–41, the fold's failure callback returns an `UnexpectedFailure` that is ignored. The original failure is replaced by a generic parsing failure.
- Model parsing at line 37 and mapping at line 43 occur outside `safeCall`, so parsing/mapping exceptions can escape the declared `Either` return contract.
- Failure logging can repeat at the wrapper and repository layers.

The target currently catches mapping errors inside its wrapper; retain that property. Prefer meaningful variable names (`failure`, `rows`, `sessions`) and explicit folds where there are two genuine branches. Do not add identity folds solely to look similar. Keep one canonical domain `Failure`; the target's `core/error/failure.dart` re-exports it rather than defining a duplicate.

Useful local improvements: move `safeLocalCall` to a clearly named service helper, preserve an already-thrown `Failure`, keep the existing fallback message, provide a single sanitized diagnostic point, and extract reminder row mappers. Keep all persistence keys, values, and side-effect ordering unchanged.

## Comparison with Flash's plan

| Flash conclusion or task | Verdict | Corrected recommendation |
| --- | --- | --- |
| Partial high-level resemblance | Agree | BLoC, layers, repositories, and Either already match. |
| Definitely not the same developer | Unsupported certainty | Describe observable resemblance; do not infer identity from this sample. |
| Feature hierarchy differs | Agree, with exceptions | Follow actual `src/app/bloc` and `lib/main.dart`, not every README path. |
| Reference entities prohibit serialization | Incorrect | `MovieEntity` has JSON conversion and a storage interface dependency. |
| Remove session row conversion from entities | Incorrect location | Those functions are already in `data/models/session_mapper.dart`. |
| Move date helpers to data mappers | Wrong responsibility | Retain calendar and civil-day calculations in the domain. |
| Target needs standard BLoC widgets | Already present | Extract composition around the existing BlocBuilder and provider lifecycle. |
| Replace enum and all Completers as a small task | Underestimates scope | Split files first; test behavior and migrate callers together later. |
| Implement Dio/global error bus now | Not justified | No current remote feature; defer the entire network task. |
| Preserve Either | Agree | Already satisfied by domain repository operations; keep parsing inside the error boundary. |
| Copy movie repository folds/mapping | Partly agree | Copy separation of responsibilities, not lost failures or unguarded parsing. |
| Six tasks can run without merge conflicts | Incorrect | Directory moves edit imports globally; entity, repository, BLoC, and page tasks overlap. Use dependency waves and exclusive ownership. |
| Entity class renaming implied by `_entity.dart` | Unspecified | Keep current Dart type names and constructors; file splitting does not require API renaming. |

## Recommended completion boundary

The initial alignment is complete when the new feature paths, separate declaration files, focused widgets/entities, mapper placement, and consistent package imports are in place; local repository operations still return Either and preserve behavior; and the existing checks pass. Full event-only UI interaction is a later, explicitly scoped logic phase. Networking remains deferred.

No app tests or formatter writes were run for this documentation-only review. The report records source inspection, not claims of passing runtime behavior. Future workers must establish their own test baseline and use the verification requirements in the companion backlog.
