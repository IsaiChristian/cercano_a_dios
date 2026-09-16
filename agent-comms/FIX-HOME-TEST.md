# FIX-HOME-TEST

Type: READY FOR REVIEW / MERGED
Owner: root coordinator; implementation by local Terra worker
Base: `55502bb` (pre-fix main)
Integrated commit: `fc952eb` (T05 merge on `main`)

## Objective

Unblock `test/presentation/home_test.dart` while preserving its 320x568 viewport,
1.5 text scale, localized copy checks and no-render-exception assertion.

## Finding and fix

The test created an FFI SQLite database and temporary filesystem during a static
widget render. That setup could leave the test run stalled even though `HomePage`
does not read the repository for this assertion. The test now uses an in-memory
`PrayerRepository` stub, keeps the real `AppBloc`, `DeviceServices` and widget
tree, and scrolls to the CTA before asserting it is reachable below the viewport.

During T05 integration, the test also needed the new `presentation/` and `src/`
imports. The conflict was resolved by retaining the fixture fix and applying
those moved paths. T05's session test had one unbraced `if`; braces were added so
analysis stays clean.

## Verification

- `flutter analyze --no-pub` — No issues found.
- `flutter test --no-pub --reporter expanded test/presentation/home_test.dart test/presentation/session_test.dart` — 6 tests passed.
- `flutter test --no-pub --reporter expanded` — 35 tests passed.
- `git diff --check` — passed before commit.

No application or dependency behavior was changed by the home-test repair.
