import 'package:cercano_a_dios/data/repositories/fake_auth_repository.dart';
import 'package:cercano_a_dios/domain/entities/auth_user.dart';
import 'package:cercano_a_dios/domain/failures/auth_failure.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  group('FakeAuthRepository', () {
    test('currentUser returns Right(null) initially', () async {
      final result = await repository.currentUser();
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Expected Right'),
        (user) => expect(user, isNull),
      );
    });

    group('signInWithEmail', () {
      test('succeeds with valid demo credentials', () async {
        final result = await repository.signInWithEmail(
          email: 'demo@cercanoadios.app',
          password: 'password123',
        );

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Expected Right'), (user) {
          expect(user.id, 'demo_user_id');
          expect(user.email, 'demo@cercanoadios.app');
        });

        // Also updates current user
        final currentUserResult = await repository.currentUser();
        currentUserResult.fold(
          (l) => fail('Expected Right'),
          (user) => expect(user?.id, 'demo_user_id'),
        );
      });

      test('succeeds with different casing in email', () async {
        final result = await repository.signInWithEmail(
          email: '  Demo@cercanoAdios.app  ',
          password: 'password123',
        );

        expect(result.isRight(), isTrue);
      });

      test('fails with invalid password', () async {
        final result = await repository.signInWithEmail(
          email: 'demo@cercanoadios.app',
          password: 'wrong',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            (failure as AuthFailure).reason,
            AuthFailureReason.invalidCredentials,
          );
        }, (r) => fail('Expected Left'));
      });

      test('fails with non-existent email', () async {
        final result = await repository.signInWithEmail(
          email: 'nobody@example.com',
          password: 'password',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            (failure as AuthFailure).reason,
            AuthFailureReason.invalidCredentials,
          );
        }, (r) => fail('Expected Left'));
      });

      test('fails with invalid input', () async {
        final result = await repository.signInWithEmail(
          email: ' ',
          password: '',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            (failure as AuthFailure).reason,
            AuthFailureReason.invalidInput,
          );
        }, (r) => fail('Expected Left'));
      });
    });

    group('signUpWithEmail', () {
      test('succeeds and signs in new user', () async {
        final result = await repository.signUpWithEmail(
          email: 'new@example.com',
          password: 'new_password',
          name: 'New User',
        );

        expect(result.isRight(), isTrue);
        AuthUser? createdUser;
        result.fold((l) => fail('Expected Right'), (user) {
          createdUser = user;
          expect(user.email, 'new@example.com');
          expect(user.name, 'New User');
          expect(user.id, isNotEmpty);
        });

        // check currentUser updated
        final currentUserResult = await repository.currentUser();
        currentUserResult.fold(
          (l) => fail('Expected Right'),
          (user) => expect(user, equals(createdUser)),
        );
      });

      test(
        'fails when email is already in use (including demo user)',
        () async {
          final result = await repository.signUpWithEmail(
            email: 'demo@cercanoadios.app',
            password: 'new_password',
            name: 'Imposter',
          );

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<AuthFailure>());
            expect(
              (failure as AuthFailure).reason,
              AuthFailureReason.emailAlreadyUsed,
            );
          }, (r) => fail('Expected Left'));
        },
      );

      test('fails with invalid input', () async {
        final result = await repository.signUpWithEmail(
          email: '',
          password: 'pass',
          name: '',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(
            (failure as AuthFailure).reason,
            AuthFailureReason.invalidInput,
          );
        }, (r) => fail('Expected Left'));
      });
    });

    group('signOut', () {
      test('clears current session and is idempotent', () async {
        // Sign in first
        await repository.signInWithEmail(
          email: 'demo@cercanoadios.app',
          password: 'password123',
        );

        // Ensure signed in
        var current = await repository.currentUser();
        current.fold((l) => null, (u) => expect(u, isNotNull));

        // Sign out
        final signOutResult1 = await repository.signOut();
        expect(signOutResult1.isRight(), isTrue);

        current = await repository.currentUser();
        current.fold((l) => null, (u) => expect(u, isNull));

        // Sign out again (idempotent)
        final signOutResult2 = await repository.signOut();
        expect(signOutResult2.isRight(), isTrue);
      });
    });
  });
}
