# Architecture & Code Style Alignment Plan

## 1. Executive Summary & Author Style Analysis

This document analyzes the architectural and code style differences between the reference repository (**IsaiChristian/TechTest**) and the target codebase (**Cercano a Dios**), focusing on whether the code resembles being written by the same developer and what changes are required to bring it in line with that specific developer's style.

### Resemblance Assessment
The current codebase exhibits **partial resemblance** in high-level clean architecture concepts (e.g., separating `data`, `domain`, and using `Either<Failure, T>` from `dartz`). However, **it does NOT appear to be written by the same developer**.

Key stylistic differences that distinguish the reference developer (`IsaiChristian`) include:
1. **Feature Module Directory Layout**: The reference developer organizes features under `lib/src/<feature>/presentation/{bloc,pages,widgets}` and places global presentation widgets in `lib/presentation/`. The target codebase uses `lib/ui/features/<feature>/{bloc,views}`.
2. **Entity Isolation & Data Mappers**: The reference developer enforces strict layer separation—domain entities are clean Dart objects with no data transformation logic, while mapping logic lives exclusively in `lib/data/mappers/`. The target codebase combines multiple domain entities into a single file (`prayer.dart`) and embeds platform serialization (`toPlatform()`) directly on entity classes.
3. **BLoC State Modeling**: The reference developer uses distinct subclasses/unions for states (`HomeInitial`, `HomeLoading`, `HomeLoaded`, `HomeError`) paired with `BlocBuilder` / `BlocConsumer` in pages. The target codebase uses a single state class containing an `enum SessionPhase` and exposes public imperative methods on the BLoC that dispatch events internally using `Completer` objects.
4. **Networking, Dio, and Error Bus Stack**: The reference developer builds a complete HTTP network layer with `DioClient`, a custom `FailureInterceptor` that dispatches critical HTTP errors (401, 404, 500, timeouts) to a `GlobalErrorBus`, maps exceptions via `mapDioException`, wraps requests in `safeCall<T>()`, and handles responses in repository implementations using `response.fold(...)` with model `toEntity()` mappers. The target codebase lacks this unified network pipeline and interceptor setup.

---

## 2. Detailed Architectural Comparison

| Dimension | Reference Developer Style (`IsaiChristian/TechTest`) | Target Codebase Style (`Cercano a Dios`) | Alignment Gap / Action Required |
| :--- | :--- | :--- | :--- |
| **Directory Structure** | `lib/src/<feature>/presentation/{bloc,pages,widgets}`, `lib/presentation/`, `lib/data/mappers/` | `lib/ui/features/<feature>/{bloc,views}`, `lib/data/models/` | Reorganize presentation layer under `lib/src/` with dedicated `pages/` and `widgets/` folders per feature, and extract mappers to `lib/data/mappers/`. |
| **Domain Entities** | 1 file per entity in `lib/domain/entities/`. Clean objects without serialization or utility methods. | Multiple entities in `lib/domain/entities/prayer.dart`. Contains helper functions (`calendarDate`) and `toPlatform()` methods. | Split `prayer.dart` into individual files (`prayer_prompt.dart`, `prayer_session.dart`, `reminder.dart`). Move conversion logic to `data/mappers/`. |
| **BLoC Pattern** | Event-driven UI dispatching (`context.read<TBloc>().add(TEvent())`). Explicit subclassed States (`StateInitial`, `StateLoading`, `StateSuccess`, `StateError`). | Imperative BLoC method wrappers (`bloc.start()`, `bloc.save()`) using internal `Completer`s. Single `State` class with `enum SessionPhase`. | Convert BLoCs to pure event-driven interfaces with subclassed states and remove imperative method wrappers. |
| **Widget Architecture** | Clear separation between full-screen pages (`pages/`) and sub-components (`widgets/`). Clean UI bound via `BlocBuilder` / `BlocListener`. | Combined view files in `views/session_page.dart` mixing page layout, inline state management, and media widgets. | Split `session_page.dart` into `pages/session_page.dart` and `widgets/` components. Use standard BLoC widgets for UI reactivity. |
| **Dio & Network Infrastructure** | Centralized `DioClient` with `FailureInterceptor`, `GlobalErrorBus.dispatch()`, `mapDioException`, and `safeCall<T>()`. | Direct local database service wrappers with custom `safeLocalCall`. Missing Dio interceptor pipeline and error bus. | Implement `DioClient`, `FailureInterceptor`, `GlobalErrorBus`, and unified `safeCall` for network requests. |
| **Repository Implementation** | Uses `safeCall(() async { ... })`, followed by `response.fold(...)` to extract data, map models to entities (`toEntity()`), and log via `LoggerService`. | Uses direct database service calls wrapped in `safeLocalCall`. | Standardize repository error logging and model-to-entity mapping patterns across data layer. |

---

## 3. Parallel Task List for Smaller LLM Agents

The following tasks are designed to be self-contained and modular so that smaller LLM agents can execute them in parallel without merge conflicts.

```
+-----------------------------------------------------------------------------------+
|                            PARALLEL TASK MATRIX                                  |
+-----------------------------------------------------------------------------------+
| Task 1: Refactor Directory Structure to `lib/src/` Framework                      |
| Task 2: Split Domain Entities & Extract Mappers to `lib/data/mappers/`            |
| Task 3: Implement Dio Network Infrastructure & Global Error Bus Pipeline          |
| Task 4: Standardize Repository `Either` & `safeCall` Pattern                       |
| Task 5: Refactor `SessionBloc` to Subclassed States & Pure Event Model            |
| Task 6: Separate Views into `pages/` and `widgets/` Components                    |
+-----------------------------------------------------------------------------------+
```

---

### Task 1: Refactor Directory Structure to `lib/src/` Framework
- **Goal**: Align directory hierarchy with reference developer's feature-first layout under `lib/src/`.
- **Dependencies**: None.
- **Target Files**:
  - Move `lib/ui/features/*` -> `lib/src/*`
  - Reorganize `lib/src/<feature>/presentation/{bloc,pages,widgets}`
  - Create `lib/presentation/` for shared cross-feature widgets.
- **Instructions**:
  1. Move feature directories under `lib/src/<feature>/presentation/`.
  2. Create `pages/` and `widgets/` directories inside each feature presentation directory.
  3. Update relative imports across `lib/main.dart` and all feature files.
- **Acceptance Criteria**:
  - Code compiles without missing import errors (`flutter analyze` passes).
  - Directory structure matches `lib/src/<feature>/presentation/{bloc,pages,widgets}`.

---

### Task 2: Split Domain Entities & Extract Mappers to `lib/data/mappers/`
- **Goal**: Enforce pure domain entities and extract data mapping logic.
- **Dependencies**: None.
- **Target Files**:
  - `lib/domain/entities/prayer.dart` -> split into:
    - `lib/domain/entities/prayer_prompt_entity.dart`
    - `lib/domain/entities/prayer_session_entity.dart`
    - `lib/domain/entities/reminder_entity.dart`
  - Create `lib/data/mappers/reminder_mapper.dart` and `lib/data/mappers/session_mapper.dart`.
- **Instructions**:
  1. Extract `PrayerPrompt`, `PrayerSession`, and `Reminder` into individual entity files under `lib/domain/entities/`.
  2. Remove `toPlatform()`, `sessionToRow()`, `sessionFromRow()`, and date helper logic from entity classes.
  3. Place conversion functions into extension mappers under `lib/data/mappers/`.
- **Acceptance Criteria**:
  - No domain entity contains data transformation methods (`toPlatform`, `toMap`, `fromJson`).
  - Mappers in `lib/data/mappers/` handle all database row/json transformations.

---

### Task 3: Implement Dio Network Infrastructure & Global Error Bus Pipeline
- **Goal**: Implement `DioClient`, `FailureInterceptor`, `GlobalErrorBus`, and `safeCall` matching reference style.
- **Dependencies**: None.
- **Target Files**:
  - `lib/core/network/dio_client.dart`
  - `lib/core/network/failure_interceptor.dart`
  - `lib/core/network/safe_call.dart`
  - `lib/core/error/global_error_bus.dart`
  - `lib/core/error/logger_service.dart`
- **Instructions**:
  1. Implement `LoggerService` with static `log` and `error` methods formatting tags like `[ERROR][Tag] message`.
  2. Implement `GlobalErrorBus` using a `StreamController<AppError>.broadcast()`.
  3. Implement `FailureInterceptor` extending `Interceptor`:
     - Intercept `onError`, log using `LoggerService.error`.
     - Dispatch `AppError` to `GlobalErrorBus` for status codes `401`, `404`, `500`, and `connectionTimeout`.
  4. Implement `safeCall<T>(Future<T> Function() request)` returning `Future<Either<Failure, T>>` handling `DioException` and generic exceptions.
- **Acceptance Criteria**:
  - `safeCall` cleanly catches exceptions and returns `Left(Failure)` or `Right(T)`.
  - `FailureInterceptor` properly logs and dispatches errors to `GlobalErrorBus`.

---

### Task 4: Standardize Repository `Either` & `safeCall` Pattern
- **Goal**: Align repository implementations with `movies_repository_imp.dart` reference pattern.
- **Dependencies**: Task 2, Task 3.
- **Target Files**:
  - `lib/data/repositories/local_prayer_repository.dart`
- **Instructions**:
  1. Update repository methods to use `safeCall` or `safeLocalCall`.
  2. Perform model-to-entity mappings using `response.fold(...)` or mapper extensions.
  3. Log failure paths using `LoggerService.error("Repository", ...)`.
- **Acceptance Criteria**:
  - Every repository method returns `Either<Failure, T>`.
  - Failures are logged with `LoggerService.error` before returning `Left(Failure)`.

---

### Task 5: Refactor `SessionBloc` to Subclassed States & Pure Event Model
- **Goal**: Convert `SessionBloc` from imperative state machine to pure event-driven BLoC with subclassed states.
- **Dependencies**: None.
- **Target Files**:
  - `lib/src/prayer_session/presentation/bloc/session_bloc.dart`
  - `lib/src/prayer_session/presentation/bloc/session_event.dart`
  - `lib/src/prayer_session/presentation/bloc/session_state.dart`
- **Instructions**:
  1. Replace single `SessionState` with subclassed state hierarchy:
     - `SessionInitial`, `SessionStarting`, `SessionRecording`, `SessionStopping`, `SessionReview`, `SessionSaving`, `SessionSuccess`, `SessionFailure`.
  2. Remove imperative wrapper methods (`start()`, `finish()`, `save()`, `play()`) and public `Completer` parameters from events.
  3. Emit explicit state instances from `on<Event>` handlers.
- **Acceptance Criteria**:
  - UI interacts with BLoC exclusively via `bloc.add(Event())`.
  - States are distinct immutable subclasses extending an abstract base state or `Equatable`.

---

### Task 6: Separate Views into `pages/` and `widgets/` Components
- **Goal**: Align presentation UI files with reference developer's clean component separation.
- **Dependencies**: Task 1, Task 5.
- **Target Files**:
  - `lib/src/prayer_session/presentation/pages/session_page.dart`
  - `lib/src/prayer_session/presentation/widgets/session_recording_view.dart`
  - `lib/src/prayer_session/presentation/widgets/session_review_view.dart`
  - `lib/src/prayer_session/presentation/widgets/amplitude_visualizer.dart`
- **Instructions**:
  1. Extract full screen container into `session_page.dart` containing `BlocProvider` and `BlocConsumer`.
  2. Move UI controls, amplitude visualizer, and playback widgets into dedicated widget files under `widgets/`.
  3. Bind UI actions directly to BLoC event dispatches (`context.read<SessionBloc>().add(...)`).
- **Acceptance Criteria**:
  - `session_page.dart` acts purely as a page layout scaffold with BLoC wiring.
  - Sub-widgets reside in `widgets/` and receive pure parameters or context BLoC streams.
