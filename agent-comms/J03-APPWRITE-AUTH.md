Task J03 is completed.

Appwrite flutter sdk (17.0.0) is integrated.
`AuthConfig` is implemented, requiring explicit `AUTH_BACKEND=fake` for the fake mode and falling back to Appwrite by default. Missing Appwrite config fails fast with `StateError`.
`AppwriteAuthService` is the only direct SDK wrapper using the Client Account API.
`AppwriteAuthRepository` correctly implements `AuthRepository` (mapping AppwriteException to `AuthFailure` and `AuthUser`).

Dependencies locked in pubspec.lock. No credentials added.
Tests implemented without mockito by writing `FakeAppwriteAuthService`.

Ready for integration.
