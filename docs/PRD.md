# Cercano a Dios — Product Requirements Document

**Version:** 0.2 · **Date:** September 15, 2026 · **Status:** Revised product scope

## 1. Product vision

Help Catholics build a daily prayer and gratitude habit through a simple loop: hear a scheduled alarm, pause, say a short prayer or gratitude phrase aloud, and acknowledge the moment.

The first release should make that loop dependable and meaningful. Later versions can generate personalized prayers and show a sense of shared participation.

**Primary user:** A Catholic who wants a regular moment of prayer or gratitude but forgets during a busy day.

**Core user story:** “At the time I choose, remind me to pause and help me express something I am grateful for in less than two minutes.”

## 2. Scope and working assumptions

### Requested foundation

- A new Flutter app based on the architecture documented in [TechTest](https://github.com/IsaiChristian/TechTest#architecture).
- User-selected reminder times, with notification/alarm behavior.
- A gratitude phrase or prayer spoken using the microphone.
- Future AI APIs for personalized prayers.
- A possible future counter of people praying.

### Confirmed product decisions

- Ringing alarms that users dismiss are part of the MVP.
- The app is named **Cercano a Dios** and its content and spiritual tone are Catholic.
- Prioritize broad device compatibility, including older and slower phones.
- Save prayer audio locally in the MVP; add transcription and detection in a later iteration.
- Include a daily streak and light, personal gamification in the MVP.

### Proposed defaults to refine

- Android and iOS first; no web or desktop release initially.
- Guest use without sign-in; first-release data stays on the device.
- Recordings stay on the device, with playback and deletion. Transcription and spoken-content detection follow the recording MVP; the exact detection behavior remains to be defined.
- One launch language, to be selected; all interface strings support later localization.

This document defines the product before project scaffolding. Confirmed decisions are listed separately from proposed implementation defaults.

## 3. MVP experience

1. The user sees a short introduction and can try a prayer immediately.
2. They choose a daily time or specific weekdays and enable reminders.
3. The app explains alarm and notification access and requests the necessary permissions in context.
4. At the scheduled time, a ringing alarm with a system alert invites them to pray, with Stop and Snooze controls.
5. After stopping the alarm, the user can open a short prompt, such as: “Lord, thank you for ___. Help me recognize your gifts today.”
6. They tap **Speak**, grant microphone access if needed, and speak in their own words.
7. They tap **Finish**, review or re-record their audio, then **Save and complete**. They can instead choose **Reflect silently**.
8. The recording and moment are saved locally. The first completion of the day advances the streak and weekly progress, with a small celebration when a milestone is earned.

The user can start a moment from the home screen at any time. Stopping an alarm or dismissing a notification never counts as completing a prayer. Stopping an alarm does not automatically open the app; the user can enter through the supported system action or launch it normally.

## 4. Functional requirements and acceptance criteria

| ID | Requirement | Acceptance criteria |
|---|---|---|
| FR-01 | Simple onboarding | A new user can start a moment without an account or notification permission. Reminder setup can be skipped. |
| FR-02 | Reminder management | Create, edit, pause, and delete reminders with a local time and selected weekdays. Show the next occurrence and whether scheduling succeeded. Proposed limit: five active reminders. |
| FR-03 | Notification routing | The alarm’s prayer action or associated notification opens its intended session from foreground, background, or a cold app launch. Repeated taps do not create duplicate sessions. |
| FR-04 | Postpone or dismiss | Offer Stop and a ten-minute Snooze on the alarm surface. Snoozing changes only that occurrence; dismissing does not disable the recurring schedule. Stop ends the current sound without requiring a microphone, network connection, or completed prayer. |
| FR-05 | Prompt library | Bundle at least 20 reviewed Catholic prompts for gratitude, hope, peace, and reflection, with prayers addressed to God and optional traditional prayers using verified texts. Users can choose another prompt before starting. All work offline. |
| FR-06 | Speak a prayer | Start microphone capture only after an explicit tap and permission. Show active input and elapsed time. Finish, cancel, leaving the screen, backgrounding, and interruptions stop capture. Automatically stop after two minutes and present the recording for review; stopping capture alone does not complete a session. |
| FR-07 | Inclusive completion | Support silent reflection when speaking is inconvenient or unavailable. Completion requires an explicit confirmation; silence, background noise, or opening the screen never automatically completes a moment. |
| FR-08 | Local history | Save completed sessions and show moments completed today and this week. Repeated completion taps produce one record. Persist records across app restarts. |
| FR-09 | Settings and deletion | Edit reminder preferences, view permission status, and delete local history. Delete individual audio files without deleting the completed moment. Deleting history also removes associated audio and recalculates progress. A full reset cancels scheduled reminders and removes recordings, history, streaks, and badges. |
| FR-10 | Recoverable failures | If scheduling or saving fails, explain the issue and provide retry. Never display “Reminder set” or “Moment saved” before the operation succeeds. |
| FR-11 | Save and replay audio | Save one recording per spoken session in private app storage; replay, replace before completion, or delete it. A failed save offers retry or explicit completion without audio and does not create duplicate progress. |
| FR-12 | Daily streak | Show current and best streaks. One or more completed moments on a day contribute exactly one streak day. Spoken and silent sessions qualify equally. |
| FR-13 | Light gamification | Show a seven-day progress strip and personal milestone badges. Awards are granted once per badge and work offline; no leaderboard or points economy. |

### Recording lifecycle and storage

- Before first use, explain that audio will be saved privately on the device. Recording starts only after an explicit tap and microphone permission.
- Record to a temporary file using a lightweight native encoder. Proposed format: mono AAC in M4A at approximately 32 kbps, subject to device validation; a two-minute recording is approximately 0.5 MB before overhead.
- An input meter indicates sound, not verified speech or prayer content. Use “Recording,” not “Prayer recognized.” No transcription or speech-content validation is required for MVP completion.
- Finish opens a review state with Play, Re-record, Discard, and Save and complete. Cancel discards the temporary recording. Interrupted sessions never auto-complete; recover a playable draft if possible, otherwise explain the interruption and offer retry.
- On successful completion, persist the audio reference and session consistently before updating progress. Reconcile orphaned temporary files after a crash. Capture never resumes automatically.
- If microphone access is denied or hardware is unavailable, offer silent reflection. If storage is full, preserve any recoverable draft and offer retry, cleanup, or explicit completion without audio.
- Keep recordings in private app storage, exclude them from automatic cloud backup where supported, and never include audio in logs, analytics, or uploads. Explain that uninstalling or losing the device can lose recordings in this local-only release.
- Show recording storage usage and individual/bulk deletion controls. Proposed audio budget: 100 MB; warn at 80 MB and ask the user to free space at the cap. Do not silently delete saved prayers. Session metadata and silent reflection remain available.
- Deleting audio leaves its completed session and streak credit intact. Deleting a session removes its audio and recomputes affected progress. Full reset removes all local progress and files.

### Streak and light gamification rules

- **Daily goal:** Complete one moment. Additional moments remain in history without adding extra streak days.
- **Current streak:** Consecutive completed calendar days ending today, or ending yesterday while today's opportunity is still open. It becomes zero after a whole local day is missed; the next completion starts at one.
- **Best streak:** Longest consecutive run in retained history. Example: completions Monday and Tuesday show 2 on Wednesday before prayer; if Wednesday is missed, Thursday shows 0 until a new completion starts 1.
- **Calendar policy:** Assign the completion date using the device time zone at completion and keep that date fixed afterward. Repeated dates during travel count once; skipped dates break a streak. Explain this limitation in help. No server-based anti-cheat or date backfill in the MVP.
- **Milestones:** First completed moment; 3-, 7-, and 30-day streaks; and 10 and 50 total moments. Badges acknowledge a practice, not spiritual merit.
- **Weekly view:** Seven day indicators, Monday through Sunday, and “X of 7 days.” Use a short, skippable celebration on a newly earned milestone and respect reduced-motion settings.
- Persist session completion and progress updates idempotently. Restarting, repeated taps, and multiple alarms never duplicate credit. Recompute streaks and badges from retained history after deletions; deleting only audio does not affect awards.
- Use encouraging recovery language such as “A new moment begins today.” No public rankings, streak purchases, freezes, penalties, or repeated guilt-based reminders in the MVP.

### Scheduling rules

- A reminder follows the device's local wall-clock time: a 7:00 AM reminder remains 7:00 AM after travel when schedules are reconciled.
- Reconcile schedules on app launch/resume and supported system time-zone or reboot events. Validate platform-specific behavior during the technical spike.
- For daylight-saving gaps, move the occurrence to the next valid local time; during a repeated hour, trigger once.
- Editing, disabling, or deleting a reminder cancels its old pending occurrences and snoozes.
- Completing the linked session cancels its pending snooze. Other reminders remain scheduled.
- Do not replay a backlog of missed reminders after a device has been off.
- Explain disabled permissions and degraded timing; allow manual prayer sessions throughout.

## 5. Notifications versus alarms

**Confirmed MVP behavior:** A user-scheduled ringing alarm with a system alert, Stop, and Snooze. A normal notification alone does not satisfy the alarm requirement.

- The alarm must ring while the app is backgrounded or terminated in supported OS conditions, using system scheduling rather than an in-app timer.
- Stop always ends the active alarm without requiring prayer, speech, or internet. Snooze schedules one new occurrence ten minutes later.
- Use one bundled alarm sound initially. Ringing duration and any system-imposed timeout must be specified and verified during the device spike before implementation; do not promise indefinite ringing.
- Provide a Test alarm action during setup so users can check sound and access.
- Show explicit readiness states: Ready, Permission needed, Unsupported, or Scheduling failed. Do not show a successful alarm setup when required access is missing.
- A notification-only fallback requires the user's explicit selection and must be labeled as a reminder, not an alarm. Keep older supported devices available through the clearly labeled reminder tier described below.
- Prevent overlapping occurrences from producing layered audio. Define and verify the native stop/snooze behavior when two schedules overlap.
- The microphone starts only after the user opens the app and taps Speak. Alarm audio must stop before microphone capture starts.

Apple's AlarmKit provides prominent alarms with authorization and can override focus and silent mode. Use AlarmKit on iOS 26 and later; retain older supported iPhones through a notification-reminder tier. Validate the native integration and OS availability checks during the device spike. [Apple alarm scheduling documentation](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit).

Android distinguishes inexact and exact scheduling, and exact alarms have additional access requirements. Notification permission is also a separate concern on Android 13 and later. The first engineering milestone must validate permissions, delivery behavior, and relevant distribution requirements for the chosen mode. [Android scheduling](https://developer.android.com/develop/background-work/services/alarms) · [Android notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission).

### Broad device support

**Proposed baseline:** Android 7.0 / API 24 and iOS 15, subject to validating the selected Flutter release and every required plugin. The current Flutter deployment matrix lists Android API 24+ (including Arm32 and Arm64) and iOS 15+ on Arm64. Preserve these floors wherever possible; compare alternative plugins or small native adapters before raising them. Do not select an obsolete toolchain solely to reach older OS versions. [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms).

| Device tier | Experience |
|---|---|
| Android API 24+ | Full app and scheduled ringing alarms, subject to OS permissions and verified native behavior; handle newer Android restrictions by capability. |
| iOS 26+ | Full app with native AlarmKit ringing alarms after authorization. |
| iOS 15–18 | Prayer, audio, streaks, and badges; local notifications with sound as an explicitly labeled reminder mode. No promise of persistent ringing or bypassing silent/focus modes. |

AlarmKit was introduced with iOS 26. Broad installation support therefore needs different reminder capabilities on older iPhones; it does not require raising the whole app's minimum to iOS 26. This tiered approach is the proposed resolution of broad reach plus ringing alarms. [Apple AlarmKit introduction](https://developer.apple.com/videos/play/wwdc2025/230/).

- Select alarm capability at runtime and explain it during setup. Do not load unsupported native APIs on older OS versions.
- Preserve 32-bit Android support when the chosen toolchain and dependencies permit it. No universal 64-bit-only requirement for Android.
- Minimum OS and device speed are separate concerns: validate the prayer loop on a physical low-end Android phone with 2 GB RAM and an older supported iPhone, plus current devices.
- Final compatibility claims require release-build device tests; framework support alone does not prove every plugin or alarm behavior works.

## 6. Screens and interaction principles

| Screen | Main content and action |
|---|---|
| Welcome | Explain the Catholic daily practice; try a moment or set an alarm. |
| Today | Current prompt, Start a moment, next reminder, current streak, weekly progress, and today's completion count. |
| Reminders | List schedules, enabled state, delivery status, add/edit controls. |
| Prayer moment | Prompt, Speak/Finish, microphone indicator, silent option, explicit completion. |
| Completion | Acknowledgement, updated streak, and a brief celebration for a newly earned badge. |
| History | Completed moments by date, prompt, duration, audio playback/deletion, and progress badges. |
| Settings | Permissions, reminder preferences, recording storage, privacy explanation, delete/reset. |

Use a quiet visual style, readable type, large controls, screen-reader labels, dynamic text sizing, and reduced-motion support. Keep streaks personal and encouraging; avoid guilt-based messages or competitive rankings. Missing a day should feel easy to recover from.

### Catholic content requirements

- Use a warm, recognizably Catholic voice. Include gratitude to God, brief morning/evening prayers, and optional traditional prayers.
- Have a knowledgeable Catholic reviewer check the starter library before beta; attribute quoted scripture and verify permissions for the chosen translation or prayer text.
- Do not imply that app completion measures faith, fulfills an obligation, or replaces participation in sacramental life.
- Liturgical calendars, rosary guidance, saint-of-the-day content, and parish features are later scope, not required for the first daily prayer loop.

## 7. Architecture direction

The reference README documents layered Clean Architecture, feature presentation modules, BLoC, provider-based dependency injection, go_router, Either-style failures, and centralized error handling. Retain those conventions. Its listed stack also includes Dio, shared_preferences, mockito, and bloc_test. This review uses the repository README; source-file retrieval was unavailable, so implementation details and package versions still need verification. [TechTest architecture and stack](https://github.com/IsaiChristian/TechTest#architecture).

**Proposed new project organization:**

```text
lib/
  core/
    di/           # Service and repository composition
    error/        # Shared failure boundary
    router/
  data/
    models/
    repositories/
    services/     # SQLite, platform, and local-file adapters
  domain/
    entities/
    failures/
    repositories/
    use_cases/    # Scheduling and completion rules
  ui/
    core/         # Shared UI and theme
    features/     # Views and event-driven BLoCs by feature
  main.dart
test/             # Mirrors lib
```

### Responsibilities

- BLoCs manage screen state and call domain operations.
- Domain logic defines reminders, prompts, and sessions without importing platform plugins.
- Repository implementations persist data; adapters encapsulate native notification and microphone behavior.
- Add use cases for schedule reconciliation, recording finalization/deletion, idempotent session completion, streak calculation, and badge awards.
- Store audio in files and references in the local database. Keep streak rules in the domain layer and recording/transcription behind separate interfaces; the MVP implements recording only.
- Keep simple preferences separate from session history; choose a structured local store after checking migration and retention needs.
- Select a supported stable Flutter/Dart toolchain during scaffolding. Do not blindly copy experimental flags or dependency versions.
- Add remote networking when AI or community features require it. AI provider secrets belong on a backend, never in the mobile bundle.

### Initial data model

| Entity | Essential fields |
|---|---|
| Reminder | ID, local time, weekdays, enabled, time-zone policy, scheduling status, platform IDs |
| Prompt | ID, text, category, locale, content version |
| PrayerSession | ID, optional reminder occurrence ID, prompt ID/version, start/completion timestamps, local completion date, duration, spoken/silent mode |
| AudioRecording | ID, session ID, private relative path, codec, duration, byte size, creation timestamp, ready/deleted state |
| Progress | Derived current/best streak, unique completed dates, milestone eligibility; rebuildable from sessions |
| Preferences | Onboarding state, locale, reminder sound preference, future content preference |

Completion timestamps are stored in UTC with the local date/time-zone context used for history. Audio is stored in private files referenced by session metadata. Transcripts and detection results arrive in a later schema migration; a saved recording must never be treated as a verified prayer.

## 8. Quality and release criteria

- The full reminder-to-completion flow works offline after installation.
- No network calls are required for starter prompts, microphone feedback, or history.
### Performance targets for slower phones

Proposed release-build budgets, to validate during the device spike:

- On a physical 2 GB Android device and an older supported iPhone: cold interactive launch p95 within four seconds across 20 launches; recording starts within one second after permission is granted.
- Target peak process memory below 150 MB during a two-minute recording, measured with platform profiling tools. Stream to disk rather than keeping a complete uncompressed recording in memory.
- Target device-specific initial download below 40 MB, excluding recordings; use split delivery where supported. Audit any package that materially increases size or minimum OS.
- Keep primary navigation responsive; target p95 frame time within the device's refresh budget on the core flow. Measure release/profile builds, not debug builds.
- Use simple layouts, bounded lists, a modest microphone meter update rate, and optional lightweight celebrations. Avoid continuous decorative animations, video backgrounds, and bundled speech/AI models.
- Paginate history and keep streak calculations independent of loading audio files. Validate with 1,000 session records and recordings near the storage cap.
- Use system alarm scheduling, not background polling or an always-on microphone. No ongoing app recording/processing while idle.

### Verification

- Device testing covers screen lock, background/terminated state, reboot, time-zone change, daylight saving, battery restrictions, denied/revoked permissions, and audio interruptions. Explicit force-stop restrictions must be documented rather than treated as guaranteed delivery scenarios.
- Test reminder replacement/cancellation, snooze linkage, duplicate taps, local data persistence, and deletion.
- Verify streak midnight transitions, yesterday carry-over, missed days, time-zone travel, repeated dates, silent completion, multiple same-day sessions, milestone deduplication, and progress rebuild after deleting a session.
- Verify that leaving a session releases the microphone and recordings are saved only as intended, remain playable after restart, and are never transmitted. Test storage full, interrupted recording, cancellation, orphan cleanup, and deletion.
- Release requires passing core flows on physical iOS and Android devices and a documented compatibility matrix for reminder delivery. Ringing alarms require a verified device matrix covering Stop, Snooze, screen lock, app termination, silent/focus modes, system volume behavior, and denied alarm access. Any limitations must appear in setup.

## 9. Success measures

**Primary outcome:** Completed prayer days per active user per week, where a prayer day contains at least one explicitly completed session.

Supporting measures: first-session completion, first-reminder setup, sessions started versus completed, seven-day return rate, and notification permission acceptance.

For the local-only MVP, validate these through an opt-in beta study and local summaries. Aggregate analytics require a separate deliberate addition. Never include prayer text or audio in analytics. Scheduling success and notification opens must not be mislabeled as proof of notification delivery. Set numeric product targets after the first beta baseline.

## 10. Future releases

### Phase 1.1 — Transcription and detection

- Add transcription of a user-selected recording, with editable text and clear processing/error states.
- Define detection precisely before implementation: speech activity, successful transcription, and matching a prompted phrase are separate capabilities. Initial intent is to detect spoken prayer/gratitude content; this does not measure sincerity or belief.
- Evaluate recognition quality for the launch language, accents, short prayers, and noisy rooms. Choose on-device or server processing after measuring accuracy, older-device performance, cost, and privacy.
- Keep recording and manual completion available without transcription. Unavailable processing or recognition mistakes must not erase streak credit or prevent alarm dismissal.
- Ask before uploading audio; previously saved files are not automatically processed. Define transcript deletion and retention together with audio controls.
- Do not bundle a large recognition model into the MVP or make newer speech APIs a condition of installation.

### Phase 2 — Personalized prayers

- Optional user-selected intention, mood, and preferred length within the Catholic content direction.
- A backend calls the selected AI provider and returns a short prayer.
- Explicit disclosure of what input leaves the device; stored preferences remain editable and deletable.
- Bundled prompts remain available during outages or offline use.
- Generated prayers follow Catholic content guidelines and are labeled as generated. Evaluate them against a reviewed content rubric; they should not claim divine authority or invent scripture quotations.
- Use transcripts for personalization only when the user explicitly selects that input; follow the processing and retention rules from Phase 1.1.

### Phase 3 — Shared presence, subject to validation

- Optional “People praying now” aggregate, with no public names or prayer content.
- Define this honestly as an estimate of participating active app sessions, not verified people praying worldwide.
- Proposed mechanism: foreground session heartbeat every 30 seconds, expiry after 90 seconds, one active session per installation, and immediate removal on completion where possible.
- Participation is opt-in. Backend expiry handles disconnects. Show an unavailable/stale state during failures rather than a fabricated count.
- Consider “Moments completed today” if live activity is too sparse to be useful. This is a separate metric with explicit deduplication rules.

Accounts, cross-device synchronization, public prayer feeds, social chat, monetization, transcription/content detection, and speech-based alarm unlocking are outside the MVP.

## 11. Delivery sequence and open decisions

1. Confirm launch language and validate the proposed Android API 24 / iOS 15 baseline, including the older-iPhone reminder tier.
2. Run a small device spike for scheduling, notification routing, recording lifecycle, low-end performance, and offline persistence.
3. Scaffold the Flutter project using the documented architecture and agreed stable toolchain.
4. Build one complete flow: reminder → prompt → record/reflect → save → completion → streak → history/playback.
5. Add badges, weekly progress, recording storage controls, reminder management, permission recovery, accessibility, and device validation.
6. Run a small beta and validate the daily practice, then add transcription/detection before prioritizing AI personalization and shared presence.

**Decisions still open:** Launch language; final dependency-validated OS floors; native alarm duration/timeout behavior; precise detection behavior for Phase 1.1. Proposed defaults for review: 100 MB audio cap, badge milestones, and older-iPhone reminder mode.
