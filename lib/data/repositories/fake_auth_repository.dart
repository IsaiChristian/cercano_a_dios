import 'package:dartz/dartz.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/auth_repository.dart';

class _FakeAccount {
  final AuthUser user;
  final String password;

  _FakeAccount(this.user, this.password);
}

class FakeAuthRepository implements AuthRepository {
  final Map<String, _FakeAccount> _accounts = {};
  AuthUser? _currentUser;
  int _nextId = 1;

  FakeAuthRepository() {
    // Seed demo account
    final demoUser = AuthUser(
      id: 'demo_user_id',
      email: 'demo@cercanoadios.app',
      name: 'Demo User',
    );
    _accounts[demoUser.email] = _FakeAccount(demoUser, 'password123');
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  @override
  Future<Either<Failure, AuthUser?>> currentUser() async {
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const Left(
        AuthFailure(AuthFailureReason.invalidInput, 'Invalid input'),
      );
    }

    final account = _accounts[normalizedEmail];
    if (account == null || account.password != password) {
      return const Left(
        AuthFailure(
          AuthFailureReason.invalidCredentials,
          'Invalid email or password',
        ),
      );
    }

    _currentUser = account.user;
    return Right(_currentUser!);
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty || password.isEmpty || name.trim().isEmpty) {
      return const Left(
        AuthFailure(AuthFailureReason.invalidInput, 'Invalid input'),
      );
    }

    if (_accounts.containsKey(normalizedEmail)) {
      return const Left(
        AuthFailure(
          AuthFailureReason.emailAlreadyUsed,
          'Email is already in use',
        ),
      );
    }

    final newUser = AuthUser(
      id: 'fake_user_id_${_nextId++}',
      email: normalizedEmail,
      name: name.trim(),
    );

    _accounts[normalizedEmail] = _FakeAccount(newUser, password);
    _currentUser = newUser;

    return Right(newUser);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _currentUser = null;
    return const Right(null);
  }
}
