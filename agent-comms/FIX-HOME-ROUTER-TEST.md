# FIX-HOME-ROUTER-TEST

Type: READY FOR REVIEW
Owner: root coordinator
Base: `d371df2`

## Objective

Repair `test/presentation/home_test.dart` after the navigation refactor made
`HomePage` require a `GoRouter` in its build context.

## Changes

- Added a minimal in-memory `/` `GoRouter` to the widget-test harness.
- Switched the harness to `MaterialApp.router` and preserved the 320x568,
  1.5 text-scale, localized copy, scroll-to-CTA, and no-exception assertions.
- Kept `_FakePrayerRepository`; no filesystem or SQLite setup was added.
- Removed stale tracked `flutter_test_output.log` and `flutter_tests.log` files.

## Verification

- `dart format test/presentation/home_test.dart` — passed.
- `flutter test --no-pub --reporter expanded test/presentation/home_test.dart` —
  passed (`+1`).
- `flutter test --no-pub --reporter expanded` — passed (`+41`).
- `flutter analyze --no-pub` — passed with no issues.
- `git diff --check` — passed.

## Remaining

Changes are local and uncommitted. GitHub issue #6 was readable but the browser
session was signed out, so no coordination comment was posted.
