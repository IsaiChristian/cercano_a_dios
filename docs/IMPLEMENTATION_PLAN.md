# Cercano a Dios — implementation plan

## Decisions

- Follow the layered architecture skill: feature UI, event-driven BLoCs with BlocBuilder/BlocListener, provider DI, go_router and Either failures.
- Reference inspected at commit 95e769d4258da2ceeee151dd1735a7e6d340b26a.
- English and Spanish supported with Flutter ARB localizations; honors device locale and persists settings choice.
- SQLite metadata, private AAC recordings, native audio/alarm bridges. User accounts are supported for local profile isolation (via Appwrite or an offline fake backend); no AI, speech transcription, or prayer upload dependency.
- Android API 24; iOS 15 with explicit reminder mode, iOS 26 AlarmKit.
- Build against the available Flutter 3.35.5 API baseline; validate stable-version upgrades in CI before claiming broader toolchain compatibility.

## Work sequence and implementation history

### Initial plan snapshot (2026-09-15)

1. Implemented in source: date-based streaks, milestones, next-reminder display and idempotent completion.
2. Implemented in source: SQLite schema v1, audio references, orphan cleanup, deletion and reset.
3. Implemented in source: native recording/playback, permissions, Android alarms, iOS reminders and an SDK-gated AlarmKit adapter. Native runtime validation remains open.
4. Implemented in source: onboarding, Today, prayer/review, reminders, history, progress and settings.
5. Written: 19 Dart tests using Flutter's test framework for domain, persistence, session state, and small-screen UI.

### Integrated implementation review tasks (2026-09-17)

- **R01 (PR #16)**: Complete authentication and per-user app integration with Appwrite/Fake backends, reactive routing guards, settings sign-out, native alarm validation, and isolated profiles.
- **R02 (PR #17)**: Keep history and audio storage totals consistent across mutations (session completion, single and bulk audio deletion).
- **R03 (PR #18)**: Resilient audio deletion outcome reporting (`AudioDeleteResult`), partial failure preservation, retry, and dismissal.
- **R04 (PR #19)**: Honor device locale on first launch and persist explicit language choice in settings across restarts.
- **Current test baseline**: 182 automated unit, widget, and integration tests passing on Flutter 3.35.5 and Dart 3.9.2 (`flutter analyze --no-pub` clean).

## Implementation choices to verify

- Android rings using the device's alarm tone and stops after two minutes unless stopped/snoozed sooner. iOS AlarmKit uses the system alarm sound and behavior. These replace the draft's proposed bundled sound.
- Audio capture has a two-minute native and Dart limit; reserve approximately 1 MB below the 100 MB budget before starting a recording.
- The initial streak screen uses static badges and confirmation copy, without animated celebration.
- Notification taps carry the reminder ID for linked snooze cancellation. AlarmKit provides Stop/Snooze; opening the prayer screen directly from its alarm surface remains to be validated on iOS 26.
- Reminder schedules exist in the local database and native scheduling store. Pending setup is shown as incomplete and retried explicitly; do not advertise delivery guarantees.

## Required release gates

- Native alarm tests on Android API 24 and current Android, including reboot, process death, permission revocation and doze.
- iOS 15/18 reminder tests; Xcode 26+ build and iOS 26 AlarmKit stop/snooze tests.
- Low-end physical-device memory, launch, frame-time and recording measurements.
- Catholic content review; all starter texts are original draft prayers.
- Choose release signing identifiers/team; current ID is provisional com.cercanoadios.app.

## Environment constraints

The toolchain is verified with Flutter 3.35.5 and Dart 3.9.2 running static analysis (`flutter analyze --no-pub` clean) and automated tests (182 tests passing). Physical device compilation and hardware validation (Android APK distribution signing, Xcode 26+ AlarmKit compilation, and physical device alarm delivery) remain the active validation gates.

## Localization

- Follow Flutter's official `flutter_localizations` and `gen-l10n` workflow.
- `lib/l10n/app_en.arb` is the source locale and `lib/l10n/app_es.arb` is the Spanish translation.
- `l10n.yaml` keeps Flutter's generated source in `lib/l10n/generated_localizations.dart`; run `flutter gen-l10n` after changing ARB files. The app imports a small `app_localizations.dart` facade so the generated file can change with Flutter versions without touching feature code.
- Prompt titles, prompt text, categories, navigation, permissions, recording, alarm, streak, badge, and privacy copy are localized.
- English remains the fallback for unsupported device locales. The device locale controls the language in this first pass.
