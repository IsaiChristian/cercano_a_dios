# Validation status

## Native alarm correction, 2026-09-16

Android now keeps the first alarm ringing and defers overlapping reminders ten
minutes using persisted snoozes. Notification actions validate both reminder and
ringing occurrence. iOS 26 uses **Stop & pray** plus **Snooze**, with reminder-aware
cold/warm entry through the existing Flutter bridge. Previously scheduled iOS
alarms must be rescheduled to use the new intent.

Flutter analysis and all 14 focused session tests passed. Swift syntax parsing
passed; it does not typecheck AlarmKit. Android compilation remains unavailable
without Java/Android tooling; Xcode 26 is required for the AlarmKit build.
Native device tests were not run. The precise overlap policy, limitations and
required device matrix are in
[`FIX-NATIVE-ALARMS.md`](../agent-comms/FIX-NATIVE-ALARMS.md).

The older environment notes below describe the earlier validation snapshot.

## Checks performed in this environment

- Dart and Kotlin source syntax parsed successfully. This does **not** substitute for their compilers or analyzers.
- Swift audio/notification bridge type-checked against the iOS 18.5 simulator SDK and the installed Flutter framework. A temporary no-op plugin registrant was used only for this isolated type check; the actual app uses Flutter-generated registration.
- iOS property list and Xcode project passed `plutil -lint`.
- Podfile passed `ruby -c`.

## Checks not yet run

### Running Flutter locally

The SDK is installed at `/Users/christianisia/flutter`. The Codex-hosted shell
blocks the macOS CPU-information syscall used by Dart, so Flutter commands
must be run from Terminal, iTerm, or VS Code:

```bash
cd /path/to/cercano_a_dios
source tool/flutter_env.sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

- `flutter pub get`, `flutter analyze`, `flutter test`, and Flutter builds: the current execution environment has neither `flutter` nor `dart` available on `PATH`.
- Android compile: the environment has no usable Java runtime or Android SDK configured.
- AlarmKit compile/runtime: installed Xcode 16.4 provides iOS 18.5, so `canImport(AlarmKit)` is false. The iOS 26 branch requires Xcode 26+.
- Simulator/device UI, microphone playback, alarm delivery, real low-memory behavior, performance budgets, and visual screenshots: not verified here.
- GitHub Actions workflow has been written, not uploaded or executed.

No automated test pass or installable build is claimed. The 19 test cases are implemented in Dart and must be executed using Flutter.

## Device checklist before beta

- Fresh installation, onboarding, denied/granted/revoked microphone and notification permissions.
- Record a short prayer, preview, replace, save, restart, replay, delete audio while preserving streak.
- Silent completion, repeated taps, save error/retry, interrupted recording, full storage, reset.
- Alarm while screen locked, app backgrounded/terminated, doze, reboot, time-zone change, daylight-saving change.
- Stop and ten-minute snooze, editing/deleting/pausing reminders, overlapping alarms, completion cancels only the linked snooze.
- Android native sound, notification-channel settings, two-minute timeout, and exact-alarm access recovery.
- iOS 15/18 reminder mode and iOS 26 AlarmKit authorization, Stop/Snooze, and app entry behavior.
- VoiceOver/TalkBack, large text, a 320-point wide screen, and reduced motion.
- Low-end 2 GB Android and older supported iPhone: launch, recording latency, memory, frame times, and 1,000-session history.
- Review original prayer text with a knowledgeable Catholic reviewer.

## Remaining product work

- Visual/device QA, dependency locking, and signing/release setup.
- Execute the Flutter localization generation and test commands from a normal
  macOS terminal; ARB translations for English and Spanish are included.
- Finalize/review store privacy disclosures and iOS required-reason API privacy manifest before distribution.
- Transcription/detection, AI prayers, and shared presence remain later phases as agreed.
