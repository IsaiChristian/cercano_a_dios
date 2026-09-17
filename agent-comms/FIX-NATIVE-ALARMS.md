# FIX-NATIVE-ALARMS

Focused Astra low review completed: iOS stop-race finding fixed and re-reviewed.
Android stale-open concern withdrawn: opening only navigates; explicit recording
invokes the existing global silence contract. No remaining concrete findings.
Implementation ownership released; native builds/device checks remain pending.

- Owner: Astra low native worker; coordinator owns shared status and board updates.
- Board: https://github.com/IsaiChristian/cercano_a_dios/issues/6; coordinator supplied current context and claim `issuecomment-5703564276` (no overlapping native claims).
- Actual implementation base: main `e6023aebb5c874eb8edbcd35d010278ab47038ca`; original dispatch base `339914f8` advanced externally before edits. Preserved unrelated files.
- Write scope: `android/app/src/main/kotlin/com/cercanoadios/app/PrayerAlarm.kt`, `ios/Runner/AppDelegate.swift`, this note, scoped native validation documentation.
- Local only, no commit/push. First low-effort implementation attempt; no failed implementation attempts or escalation.

## Decisions and contracts

Android uses first-ringing-wins. A different reminder arriving during the two-minute ring is durably deferred ten minutes using the existing snooze slot. Repeated delivery of the active reminder is ignored. Multiple deferred reminders can overlap again and defer again. Each reminder has one snooze slot; overlap replaces that reminder's existing snooze. Stopping, timing out, or starting recording stops only the current service and leaves other reminders' persisted snoozes scheduled. Opening prayer only navigates; the active ring continues until explicit stop, recording, or timeout. Canceling a reminder still removes its own deferred snooze; cancel-all clears all.

Stop/Snooze notification intents carry reminder ID plus a UUID for the ringing occurrence in both the intent identity URI and extras. The service rejects stale actions, including old occurrences of the same reminder. Open content intents also have distinct identities so newer notifications cannot rewrite their reminder extras. Failed user Snooze leaves the current alarm actionable. Deferred overlap state is persisted before scheduling, allowing restore while its target time is still in the future if permissions recover; revoked exact-alarm access can prevent delivery, and past snoozes retain the existing restore policy of expiring.

iOS uses the user-selected **Stop & pray + Snooze** layout. `OpenPrayerIntent` opens the app and attempts to stop the named alarm before requesting reminder-aware navigation; Snooze remains unchanged. Stop is best-effort because the system stop action may already have stopped the alarm; a stop error cannot suppress prayer entry. Device verification must confirm the system silences the alarm. The durable pending entry is consumed once by `consumeOpenPrayer` on cold start. After that handshake, warm intents invoke `openPrayer` immediately. Fallback notification entry shares this readiness handling. No prayer completion/recording is required to silence an alarm. Existing already-scheduled AlarmKit configurations need rescheduling to gain the new Stop & pray intent.

Source contract: `lib/main.dart` installs `openPrayer` handler then calls `consumeOpenPrayer`; both carry integer reminder identity into `/prayer/p01?reminder=...`. Session start calls global `stopAlarm`, so durable Android deferral avoids discarding other reminders when that service is stopped.

## Verification

- `flutter analyze --no-pub`: passed, no issues.
- `xcrun swiftc -frontend -parse ios/Runner/AppDelegate.swift`: passed syntax parsing only.
- `git diff --check`: passed at implementation time.
- `flutter test --no-pub test/presentation/session_test.dart`: all 14 passed; regression check for session lifecycle, not native alarm behavior.
- Android compile unavailable: no Java runtime or Kotlin compiler found. iOS 26 AlarmKit typecheck unavailable: installed Xcode 16.4 has iOS 18.5 only. No alarm/device behavior tested; review and matrix below remain required.

## Device acceptance matrix (not executed)

| Environment | Action | Expected |
| --- | --- | --- |
| Android, locked/background | A and B fire simultaneously | A remains audible/actionable; B scheduled ten minutes later |
| Android | Stop, timeout, or start recording A while B deferred | A stops; B remains scheduled with B identity |
| Android | Open A while B deferred | Prayer opens with A identity; A keeps ringing until stop/record/timeout; B remains scheduled |
| Android | Snooze A while B deferred | Both IDs remain scheduled; a later overlap follows first-ringing policy |
| Android | Replay stale A Stop/Snooze after B starts, or after another A occurrence | No effect on current alarm |
| Android | Delete B / cancel-all before deferred delivery | Only B / all deferred reminders canceled |
| Android | Kill process/reboot after B deferred | Future B snooze restored with B identity |
| Android | Revoke exact alarm permission during overlap then recover before deadline | Persisted B retried by restore; current A remains actionable |
| iOS 26, cold/warm/locked | Stop & pray for A | Named alarm silenced; app opens prayer with A reminder exactly once |
| iOS 26 | Snooze A | A rescheduled ten minutes; no app entry |
| iOS 26 | Two scheduled alarms with different reminder IDs | Each Stop & pray carries its own reminder; verify OS stop-action lifecycle |
| iOS 18 fallback, cold/warm | Tap reminder/Pray now | Matching reminder enters once; Snooze remains functional |

Next: focused Astra review, Xcode 26 build, Android build and physical-device acceptance matrix. Coordinator relays readiness to board and releases ownership after review.

Completion cancels the linked reminder's snooze through the existing `cancelSnooze` contract, including overlap deferrals. Permission recovery alone does not trigger retry: existing restore entry points (app engine configuration, boot/time-related receivers) must run before the deferred deadline. `AlarmClockInfo` show intent intentionally remains the existing general app entry (system upcoming-alarm affordance); the ringing notification content/action intents carry the reminder context.
