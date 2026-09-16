# FIX-INDEPENDENT-CLEANUP

Status: complete locally; ownership released to coordinator for integration.
Owner: Astra low worker / root coordinator. Branch: main.
Base/current commit: `339914f8dbf8bf49bf43e233dbe1bf4f1e2ec3a8`.
No commit or push. Board claim: issue #6 comment 5703330725.

## Scope and changes

- `lib/src/prayer_session/presentation/bloc/session_bloc.dart`: independently
  catch recording, playback, and draft deletion failures during close. A failed
  platform call no longer skips subsequent cleanup. Pending-save ordering,
  committed-audio guard, cached close future, and super.close remain unchanged.
- `test/presentation/session_test.dart`: cover recorder-only, playback-only,
  and combined failures. Verify both shutdown calls are attempted once, drafts
  disappear, repeated close shares its future, and the bloc closes. A separate
  combined-failure case verifies committed audio remains intact.
- This note. Coordinator owns CURRENT_STATUS.md.

## Verification

- `dart format lib/src/app/bloc/app_bloc.dart lib/src/prayer_session/presentation/bloc/session_bloc.dart test/presentation/session_test.dart`: passed;
  incidental out-of-scope AppBloc formatting was restored exactly (no diff).
- `flutter test --no-pub test/presentation/session_test.dart`: all 14 passed.
- `flutter analyze --no-pub`: no issues found.
- `git diff --check`: passed.

Single implementation attempt, no failed checks or effort escalation. Full test
suite not run because the targeted session suite exercises the affected lifecycle.
Worker GitHub read failed due unavailable network; coordinator supplied current
board context and reserved scope, and will relay the completion update.
No unresolved implementation issues. Next: coordinator inspect final diff and
update board/status; changes remain local and uncommitted.
