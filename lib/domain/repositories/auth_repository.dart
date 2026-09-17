import 'package:dartz/dartz.dart';

import '../entities/auth_user.dart';
import '../failures/failure.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser?>> currentUser();

  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates the account and establishes an authenticated session.
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, void>> signOut();
}
