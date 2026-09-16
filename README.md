# Cercano a Dios

A Flutter Catholic prayer companion with scheduled alarms, private voice recordings, a daily streak, and personal milestones.

**Status: first implementation, awaiting Flutter build and device validation.** No mobile binary has been produced yet.

## Included

- Today screen and 20 original draft Catholic prayer prompts.
- Record, review, re-record, save, play, and delete private AAC audio.
- Silent reflection, local SQLite history, and idempotent completion.
- Current/best streak, a weekly progress strip, and six personal badges.
- Up to five weekly alarm schedules, permission states, Stop, Snooze, and test alarms.
- English and Spanish UI translations using Flutter ARB resources; the device locale selects the language and English remains the fallback.
- Android native alarm service; iOS notification reminders; conditional iOS 26 AlarmKit adapter.
- Storage usage, audio-only deletion, and full data reset.

No account, AI call, speech transcription, analytics, or prayer upload is included. Native audio capture does not verify speech content.

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

Install a supported Flutter stable SDK with Dart 3.9 or later. Android requires JDK 17 and the Android SDK. iOS requires Xcode and CocoaPods; use Xcode 26 or later to compile the AlarmKit branch. With older Xcode, that branch is excluded and the build offers reminder mode.

From this directory:

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run
```

`flutter pub get` will generate `pubspec.lock`; commit it after dependency resolution and validation. It has not been fabricated or copied from the reference app.

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

## Tests and validation

The actual tests are **Dart tests using `flutter_test`**, under `test/`. They cover date boundaries, duplicate saves, file cleanup, deletion semantics, microphone denial, save retry, interruption, and a small-screen widget layout. Native hardware behavior requires the device checklist.

See [validation status](docs/VALIDATION.md), [implementation plan](docs/IMPLEMENTATION_PLAN.md), and [PRD](docs/PRD.md).

Temporary file-generation and syntax-check scripts used during development live outside this project. Python is not a runtime, build, or test dependency of this Flutter app.
