# J01 - Auth Foundation

## Files Changed
- `lib/domain/entities/auth_user.dart`: Added small immutable AuthUser entity.
- `lib/domain/failures/auth_failure.dart`: Added AuthFailure which carries a stable reason.
- `lib/domain/repositories/auth_repository.dart`: Created AuthRepository with Expected `Either<Failure, T>` return values.
- `lib/data/repositories/fake_auth_repository.dart`: Implemented FakeAuthRepository.
- `test/domain/auth_failure_test.dart`: Added unit tests for AuthFailure equality and hashcode.
- `test/data/fake_auth_repository_test.dart`: Added unit tests for FakeAuthRepository.

## Decisions
- AuthUser contains id, email, and nullable name. Avoided using value object frameworks like Freezed.
- AuthFailure extends standard Failure and carries AuthFailureReason to support localization.
- AuthRepository implements currentUser, signInWithEmail, signUpWithEmail, signOut methods.
- FakeAuthRepository properly mimics a database tracking users internally via their normalized email.
- The single base demo user "demo@cercanoadios.app" is created with password "password123".

## Test Results
All unit tests in `test/domain/auth_failure_test.dart` and `test/data/fake_auth_repository_test.dart` pass correctly.

## Unresolved Issues
- Appwrite specific implementation not included (task requirement).

## Next Step
Continue to task J02.