import 'package:appwrite/appwrite.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/appwrite_auth_service.dart';

class AppwriteAuthRepository implements AuthRepository {
  final AppwriteAuthService _service;

  AppwriteAuthRepository(this._service);

  @override
  Future<Either<Failure, AuthUser?>> currentUser() async {
    try {
      final account = await _service.getAccount();
      return Right(
        AuthUser(
          id: account.$id,
          email: account.email,
          name: account.name.isEmpty ? null : account.name,
        ),
      );
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        return const Right(null);
      }
      return Left(_mapAppwriteException(e));
    } catch (_) {
      return const Left(
        AuthFailure(AuthFailureReason.unknown, 'An unknown error occurred.'),
      );
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _service.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final account = await _service.getAccount();
      return Right(
        AuthUser(
          id: account.$id,
          email: account.email,
          name: account.name.isEmpty ? null : account.name,
        ),
      );
    } on AppwriteException catch (e) {
      return Left(_mapAppwriteException(e));
    } catch (_) {
      return const Left(
        AuthFailure(AuthFailureReason.unknown, 'An unknown error occurred.'),
      );
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _service.createAccount(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
    } on AppwriteException catch (e) {
      return Left(_mapAppwriteException(e));
    } catch (_) {
      return const Left(
        AuthFailure(
          AuthFailureReason.unknown,
          'An unknown error occurred during account creation.',
        ),
      );
    }

    try {
      await _service.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final account = await _service.getAccount();
      return Right(
        AuthUser(
          id: account.$id,
          email: account.email,
          name: account.name.isEmpty ? null : account.name,
        ),
      );
    } on AppwriteException {
      // Return accountCreatedButSignInFailed if session creation fails
      return const Left(
        AuthFailure(
          AuthFailureReason.accountCreatedButSignInFailed,
          'Account created successfully, but automatic sign in failed. Please sign in.',
        ),
      );
    } catch (_) {
      return const Left(
        AuthFailure(
          AuthFailureReason.accountCreatedButSignInFailed,
          'Account created successfully, but automatic sign in failed. Please sign in.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _service.deleteSession(sessionId: 'current');
      return const Right(null);
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // Idempotent sign-out when no session exists
        return const Right(null);
      }
      return Left(_mapAppwriteException(e));
    } catch (_) {
      return const Left(
        AuthFailure(AuthFailureReason.unknown, 'An unknown error occurred.'),
      );
    }
  }

  AuthFailure _mapAppwriteException(AppwriteException e) {
    switch (e.code) {
      case 401:
        return const AuthFailure(
          AuthFailureReason.invalidCredentials,
          'Invalid credentials.',
        );
      case 409:
        return const AuthFailure(
          AuthFailureReason.emailAlreadyUsed,
          'Email is already in use.',
        );
      case 400:
        if (e.type == 'project_not_found' || e.type == 'project_invalid_id') {
          return const AuthFailure(
            AuthFailureReason.configuration,
            'Server configuration issue.',
          );
        }
        return const AuthFailure(
          AuthFailureReason.invalidInput,
          'Invalid input provided.',
        );
      case 0:
      case 408: // Timeout/Network issues
      case 503:
      case 504:
      case 500:
        if (e.type == 'general_unknown') {
          // If the network is entirely unreachable, Appwrite SDK might return type general_unknown
          return const AuthFailure(AuthFailureReason.network, 'Network error.');
        }
        return const AuthFailure(AuthFailureReason.network, 'Network error.');
      default:
        // Configuration issues or others
        if (e.type == 'project_not_found' || e.type == 'project_invalid_id') {
          return const AuthFailure(
            AuthFailureReason.configuration,
            'Server configuration issue.',
          );
        }
        return const AuthFailure(
          AuthFailureReason.unknown,
          'An unknown error occurred.',
        );
    }
  }
}
