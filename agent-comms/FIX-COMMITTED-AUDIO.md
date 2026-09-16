# FIX-COMMITTED-AUDIO

Status: complete locally; ownership released. No commit or push.
Base: `3aa07c74174ab111103a2ba597943e3e3d325459` on `main`.
Implementation: Astra low. Coordinator: root.

## Changes and findings

- `lib/src/app/bloc/app_bloc.dart`: separate repository write failure from
  subsequent refresh failure. The existing boolean result now remains true after
  a committed write, while refresh errors still reach AppState and its existing
  error listener. No repository or public method signatures changed.
- `lib/src/prayer_session/presentation/bloc/session_bloc.dart`: track committed
  audio independently of SessionPhase; wait for an active save before deciding
  whether cleanup may delete a draft. Reject queued saves during close and share
  the close future across repeated calls.
- `test/presentation/session_test.dart`: regression coverage for committed save
  followed by failed read, close during successful save plus failed read, close
  during failed save, close before queued save, and silent recording cleanup.
  Existing retry/no-duplicate and interruption cases remain covered.

The old `lib/ui/` paths in the report moved to `lib/src/` during T05. The route's
BlocProvider owns SessionBloc. Bloc.close cancels emitters, so it alone cannot
coordinate file deletion with underlying asynchronous persistence.

## Verification

- `dart format lib/src/app/bloc/app_bloc.dart lib/src/prayer_session/presentation/bloc/session_bloc.dart test/presentation/session_test.dart` — passed.
- `flutter test --no-pub test/presentation/session_test.dart` — 10 tests passed.
- `flutter analyze --no-pub` — no issues found.
- `git diff --check` — passed.
- Root reviewed the persistence boundary, caller wiring, and final cleanup diff.

First analysis found `must_call_super` when super.close was hidden in a helper;
fixed by invoking it in the cached close override, then verification passed.
No effort escalation. Flutter SDK cache access required approved escalation for
formatting. Full suite not run; focused tests and full analysis passed.

Existing delegation-policy edits are separate and preserved. No unresolved
implementation issues; review/commit these local changes when requested.
