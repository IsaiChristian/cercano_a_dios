# Cercano a Dios

A Flutter Catholic prayer companion with scheduled alarms, private voice recordings, a daily streak, and personal milestones.

**Status: verified core implementation (182 automated tests passing), awaiting native packaging and physical device validation.** No production mobile binary has been distributed yet.

## Included

- User accounts with local profile isolation (`profiles/<hex_user_id>/`) using Appwrite authentication or an offline test backend, with reactive routing guards, settings sign-out, native alarm gating, and legacy anonymous data preservation.
- Today screen and 20 original draft Catholic prayer prompts.
- Record, review, re-record, save, play, and delete private AAC audio.
- Silent reflection, local SQLite history, and idempotent completion.
- Current/best streak, a weekly progress strip, and six personal badges.
- Up to five weekly alarm schedules, permission states, Stop, Snooze, and test alarms.
- English and Spanish UI translations using Flutter ARB resources; honors device locale on first launch and persists explicit language choice in settings.
- Immediate synchronization of history and audio storage totals upon recorded session completion and audio deletion.
- Resilient audio deletion with domain outcome tracking (`AudioDeleteResult`), partial failure retention, retry, and dismissal.
- Android native alarm service; iOS notification reminders; conditional iOS 26 AlarmKit adapter.
- Storage usage, audio-only deletion, and full data reset.

No AI call, speech transcription, analytics, or prayer upload is included. Native audio capture does not verify speech content. User accounts are supported for local profile isolation (via Appwrite or an offline fake backend); prayer audio and journal data remain strictly on-device in isolated profile directories.

## Architecture

Uses the [TechTest](https://github.com/IsaiChristian/TechTest) architecture as a reference, inspected at `95e769d4258da2ceeee151dd1735a7e6d340b26a`:

```text
lib/core/          dependency composition, router, and shared failure boundary
lib/domain/        entities, repository contracts, streak and scheduling rules
lib/data/          SQLite repository, raw data services, mapping, offline prompts
lib/presentation/  theme and reusable widgets
lib/src/<feature>/presentation/ feature views and event-driven BLoCs
android/           Kotlin audio and alarm adapters
ios/               Swift audio, notifications, and AlarmKit adapter
test/              Dart unit, persistence, state, and widget tests
```

Dependency injection uses provider/BlocProvider, routing uses go_router, and state uses event-driven `Bloc`s rendered with `BlocBuilder`/`BlocListener`. Repository results use `Either<Failure, T>`. Native functionality is behind a data-layer method-channel service; views dispatch Bloc commands and do not call native APIs directly.

## Run

Tested on Flutter 3.35.5 (channel stable) and Dart 3.9.2. Android requires JDK 17 and the Android SDK. iOS requires Xcode and CocoaPods; use Xcode 26 or later to compile the AlarmKit branch. With older Xcode, that branch is excluded and the build offers reminder mode.

The dependency lockfile (`pubspec.lock`) is tracked in version control.

From this directory:

```sh
flutter pub get
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub
```

To run the app locally, select an authentication backend:

```sh
# Option A: Offline / Fake Auth Backend (recommended for development and testing)
flutter run --dart-define=AUTH_BACKEND=fake

# Option B: Appwrite Authentication Backend (requires a running Appwrite instance)
flutter run \
  --dart-define=APPWRITE_ENDPOINT=https://your-appwrite-server/v1 \
  --dart-define=APPWRITE_PROJECT_ID=your_project_id
```

```sh
flutter build apk --debug
flutter build ios --simulator --debug
```

The Android application ID / iOS bundle ID is provisionally `com.cercanoadios.app`. Android release signing currently uses the Flutter scaffold's debug signing configuration and must be replaced before distribution. Set your Apple development team for physical iPhone builds.

## Device support

| Platform | Intended experience |
|---|---|
| Android API 24+ | Recording and local history, with ringing alarms after required permissions |
| iOS 15–18 | Recording, history, and notification reminders that follow device sound/Focus settings |
| iOS 26+ with Xcode 26 build | Native AlarmKit ringing alarms |

These are build targets, not verified device-compatibility claims. The app explains reminder mode on older iPhones. Android exact-alarm and notification permission changes can prevent alarms; setup remains visibly incomplete until scheduling succeeds.

## Authentication & Per-User Isolation

Cercano a Dios isolates all journal data, SQLite databases, and audio recordings per authenticated user account under `profiles/<hex_user_id>/`.

### Configuration
- **Appwrite Backend (Default)**: Production builds target Appwrite authentication. Both endpoint and project ID must be supplied at compile/run time:
  ```sh
  flutter run \
    --dart-define=APPWRITE_ENDPOINT=https://your-appwrite-server/v1 \
    --dart-define=APPWRITE_PROJECT_ID=your_project_id
  ```
  Missing or empty Appwrite configuration throws a fail-fast `StateError` on startup, displaying a recoverable error screen with a retry button instead of silently falling back.
- **Fake Backend (Testing / Offline)**: For local testing and automated tests without an Appwrite instance, explicitly select the fake backend:
  ```sh
  flutter run --dart-define=AUTH_BACKEND=fake
  ```

### Data Isolation & Legacy Data Preservation
- Each user's database, welcomed state, and voice recordings live in an isolated directory keyed deterministically by hexadecimal user ID (`profiles/<hex_user_id>/`).
- **Legacy Data Guarantee**: Any pre-existing files in the un-scoped root directory (`baseRoot`) from prior single-user installations are preserved untouched. The app neither moves, modifies, nor deletes legacy data.

### Alarm Gating & Cross-Profile Boundary (R17)
- Native alarm callbacks (`openPrayer` and `consumeOpenPrayer`) are gated by `AppSessionBloc.isValidReminderId(reminderId)`. Alarms referencing reminder IDs not present in the currently active authenticated profile are dropped to avoid stale cross-user navigation.
- **Limitation (Tracked in R17)**: The platform alarm channel transmits only integer reminder IDs without user ownership metadata. In the edge case where two distinct profiles register identical reminder IDs and the app restarts under a different profile, native channel disambiguation is tracked as part of task R17.

## Tests and validation

The test suite consists of **182 automated Dart tests** using `flutter_test` under `test/` (100% pass rate). They cover date boundaries, duplicate saves, file cleanup, deletion semantics, microphone denial, save retry, interruption, authentication routing, profile lifecycle, storage/history mutation synchronization, audio delete results and retry, device locale resolution and persistence, and full-app integration flows. Native hardware behavior requires the device checklist.

See [validation status](docs/VALIDATION.md), [implementation plan](docs/IMPLEMENTATION_PLAN.md), and [PRD](docs/PRD.md).

Temporary file-generation and syntax-check scripts used during development live outside this project. Python is not a runtime, build, or test dependency of this Flutter app.
