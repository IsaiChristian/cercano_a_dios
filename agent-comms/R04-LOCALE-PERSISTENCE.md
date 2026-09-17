# R04-LOCALE-PERSISTENCE Ownership Note

## Objective

Implement review task R04: honor device locale and persist the user's language choice in Cercano a Dios.
Ensure that:
1. First launch uses supported device-locale resolution:
   - If platform/device locale languageCode is Spanish ('es'), default to 'es'.
   - If English ('en'), default to 'en'.
   - Unsupported locales fall back consistently to 'en'.
2. An explicit language choice in Settings survives app restart (persisted via `LocalStorageService`).
3. AppState, AppBloc, and SettingsPage correctly reflect resolved locale and persisted choices.
4. Comprehensive tests cover English, Spanish, unsupported locale fallback, and persisted overrides.

## Owner and scope

- Owner: Codex / Astra low
- Branch: `codex/r04-locale-persistence`
- Base commit: `78209d5` (main)
- Write allowlist:
  - `lib/src/app/bloc/app_state.dart`
  - `lib/src/app/bloc/app_bloc.dart`
  - `lib/src/app/bloc/app_event.dart`
  - `lib/data/services/local_storage_service.dart`
  - `lib/src/settings/presentation/pages/settings_page.dart`
  - `test/src/app/bloc/app_state_test.dart`
  - `test/src/app/bloc/app_locale_test.dart`
  - `test/presentation/settings_page_test.dart`
  - `agent-comms/R04-LOCALE-PERSISTENCE.md`
- Excluded / Disjoint from R03:
  - Preserved `lib/src/audio/` and `test/src/audio/` untouched.

## Implementation Details

1. **Locale Resolution & Validation (`AppState`)**:
   - Added `defaultLocale` (`Locale('en')`) and `supportedLocales` (`[Locale('en'), Locale('es')]`).
   - Added `AppState.resolveLocale(Locale? locale)`: normalizes case and matches languageCode against supported languages; falls back to English for null or unsupported locales.
   - Added `AppState.resolveInitialLocale({String? persistedLanguageCode, Locale? deviceLocale})`: prioritizes valid persisted preference, then resolves device locale, and finally defaults to English.

2. **Persistence (`LocalStorageService`)**:
   - Added `readLanguageCode()`, `readLanguageCodeSync()`, `writeLanguageCode()`, and `writeLanguageCodeSync()`.
   - Stored in `<storage-root>/language`.

3. **Coordination & Reactive Updates (`AppBloc`)**:
   - `AppBloc` accepts optional `initialLocale` and `deviceLocale`. Initial state resolves from storage and device locale synchronously on boot.
   - Handled `AppLocaleChanged`: normalizes locale, persists synchronously to avoid `FakeAsync` timing gaps, and emits updated `AppState(locale: ...)`.
   - `AppRefreshRequested`: checks persisted language code on disk and updates `state.locale` if needed.
   - Added `setLocale(Locale locale)` helper returning `Future<void>`.

4. **Settings UI Integration (`SettingsPage`)**:
   - Updated language dropdown to bind value to `AppState.resolveLocale(app.state.locale)` and dispatch `app.setLocale(locale)` on selection.

5. **Settings Page Testing Discovery**:
   - In widget tests running inside Flutter's `FakeAsyncZone`, asynchronous `dart:io` operations (such as `await storage.readLanguageCode()`) hang waiting on real event loop native I/O. Using `readLanguageCodeSync()` and `writeLanguageCodeSync()` resolved the 30-second timeout hang.

## Verification

- `dart format` clean across all touched files.
- `flutter analyze --no-pub`: 0 issues found.
- Focused unit and widget tests:
  - `test/src/app/bloc/app_state_test.dart` (5 tests pass)
  - `test/src/app/bloc/app_locale_test.dart` (15 tests pass)
  - `test/presentation/settings_page_test.dart` (3 tests pass)
  - Total: 23/23 tests pass.
- Full test suite:
  - `flutter test`: 179/179 tests pass.
