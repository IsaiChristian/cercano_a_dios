# Cercano a Dios — implementation plan

## Decisions

- Follow the layered architecture skill: feature UI, event-driven BLoCs with BlocBuilder/BlocListener, provider DI, go_router and Either failures.
- Reference inspected at commit 95e769d4258da2ceeee151dd1735a7e6d340b26a.
- English first, matching the planning conversation. Prompt content is centralized; interface localization remains a follow-up.
- SQLite metadata, private AAC recordings, native audio/alarm bridges. No AI, account, or network runtime dependency.
- Android API 24; iOS 15 with explicit reminder mode, iOS 26 AlarmKit.
- Build against the available Flutter 3.35.5 API baseline; validate stable-version upgrades in CI before claiming broader toolchain compatibility.

## Work sequence and current status

1. Implemented in source: date-based streaks, milestones, next-reminder display and idempotent completion.
2. Implemented in source: SQLite schema v1, audio references, orphan cleanup, deletion and reset.
3. Implemented in source: native recording/playback, permissions, Android alarms, iOS reminders and an SDK-gated AlarmKit adapter. Native runtime validation remains open.
4. Implemented in source: onboarding, Today, prayer/review, reminders, history, progress and settings.
5. Written: 19 Dart tests using Flutter's test framework for domain, persistence, session state, and small-screen UI. Execution is blocked by the local runtime.
6. Open: Flutter analyze/test, dependency lockfile generation, Android debug APK, iOS simulator build, visual QA and physical-device measurements. Build workflow is included but has not been dispatched.

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

The installed Dart 3.9.2 process aborts when the execution sandbox rejects its CPU sysctl call. Xcode 16.4 cannot compile AlarmKit; simulator services are inaccessible in this execution environment. These are validation blockers, not passing checks. Continue source work and provide reproducible CI/local checks; do not claim a tested mobile build until those checks run.

## Localization

- Follow Flutter's official `flutter_localizations` and `gen-l10n` workflow.
- `lib/l10n/app_en.arb` is the source locale and `lib/l10n/app_es.arb` is the Spanish translation.
- `l10n.yaml` keeps Flutter's generated source in `lib/l10n/generated_localizations.dart`; run `flutter gen-l10n` after changing ARB files. The app imports a small `app_localizations.dart` facade so the generated file can change with Flutter versions without touching feature code.
- Prompt titles, prompt text, categories, navigation, permissions, recording, alarm, streak, badge, and privacy copy are localized.
- English remains the fallback for unsupported device locales. The device locale controls the language in this first pass.
