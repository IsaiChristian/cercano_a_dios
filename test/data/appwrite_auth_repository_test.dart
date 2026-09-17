import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cercano_a_dios/data/repositories/appwrite_auth_repository.dart';
import 'package:cercano_a_dios/data/services/appwrite_auth_service.dart';
import 'package:cercano_a_dios/domain/failures/auth_failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAppwriteAuthService implements AppwriteAuthService {
  AppwriteException? _nextException;
  models.Session? _session;
  models.User? _user;

  void setNextException(AppwriteException exception) {
    _nextException = exception;
  }

  void reset() {
    _nextException = null;
    _session = null;
    _user = null;
  }

  @override
  Future<models.User> createAccount({
    required String userId,
    required String email,
    required String password,
    String? name,
  }) async {
    if (_nextException != null) throw _nextException!;
    return models.User(
      $id: userId,
      $createdAt: '',
      $updatedAt: '',
      name: name ?? '',
      password: password,
      hash: '',
      hashOptions: {},
      registration: '',
      status: true,
      labels: [],
      passwordUpdate: '',
      email: email,
      phone: '',
      emailVerification: false,
      phoneVerification: false,
      mfa: false,
      prefs: models.Preferences(data: {}),
      targets: [],
      accessedAt: '',
    );
  }

  @override
  Future<models.Session> createEmailPasswordSession({
    required String email,
    required String password,
  }) async {
    if (_nextException != null) throw _nextException!;
    _session = models.Session(
      $id: 'session-id',
      $createdAt: '',
      $updatedAt: '',
      userId: 'user-id',
      expire: '',
      provider: 'email',
      providerUid: email,
      providerAccessToken: '',
      providerAccessTokenExpiry: '',
      providerRefreshToken: '',
      ip: '',
      osCode: '',
      osName: '',
      osVersion: '',
      clientType: '',
      clientCode: '',
      clientName: '',
      clientVersion: '',
      clientEngine: '',
      clientEngineVersion: '',
      deviceName: '',
      deviceBrand: '',
      deviceModel: '',
      countryCode: '',
      countryName: '',
      current: true,
      factors: [],
      secret: '',
      mfaUpdatedAt: '',
    );
    _user = models.User(
      $id: 'user-id',
      $createdAt: '',
      $updatedAt: '',
      name: 'Test Name',
      password: password,
      hash: '',
      hashOptions: {},
      registration: '',
      status: true,
      labels: [],
      passwordUpdate: '',
      email: email,
      phone: '',
      emailVerification: false,
      phoneVerification: false,
      mfa: false,
      prefs: models.Preferences(data: {}),
      targets: [],
      accessedAt: '',
    );
    return _session!;
  }

  @override
  Future<void> deleteSession({required String sessionId}) async {
    if (_nextException != null) throw _nextException!;
    if (_session == null) {
      throw AppwriteException('No active session', 401, 'general_unauthorized');
    }
    _session = null;
    _user = null;
  }

  @override
  Future<models.User> getAccount() async {
    if (_nextException != null) throw _nextException!;
    if (_user == null) {
      throw AppwriteException('No active session', 401, 'general_unauthorized');
    }
    return _user!;
  }
}

void main() {
  late FakeAppwriteAuthService fakeService;
  late AppwriteAuthRepository repository;

  setUp(() {
    fakeService = FakeAppwriteAuthService();
    repository = AppwriteAuthRepository(fakeService);
  });

  group('AppwriteAuthRepository', () {
    test('currentUser returns Right(null) when no active session', () async {
      final result = await repository.currentUser();
      expect(result, const Right(null));
    });

    test('currentUser returns Right(AuthUser) when active session', () async {
      await fakeService.createEmailPasswordSession(
        email: 'test@example.com',
        password: 'password',
      );
      final result = await repository.currentUser();
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (r) {
        expect(r, isNotNull);
        expect(r!.email, 'test@example.com');
        expect(r.name, 'Test Name');
      });
    });

    test('currentUser maps unknown AppwriteException to Left', () async {
      fakeService.setNextException(
        AppwriteException('Server error', 500, 'server_error'),
      );
      final result = await repository.currentUser();
      expect(result.isLeft(), isTrue);
      result.fold((l) {
        expect(l, isA<AuthFailure>());
        expect((l as AuthFailure).reason, AuthFailureReason.network);
      }, (r) => fail('Should be left'));
    });

    test('signInWithEmail success', () async {
      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );
      expect(result.isRight(), isTrue);
    });

    test('signInWithEmail maps invalid credentials', () async {
      fakeService.setNextException(
        AppwriteException('Invalid creds', 401, 'user_invalid_credentials'),
      );
      final result = await repository.signInWithEmail(
        email: 'test@example.com',
        password: 'password',
      );
      result.fold(
        (l) => expect(
          (l as AuthFailure).reason,
          AuthFailureReason.invalidCredentials,
        ),
        (r) => fail('Should be left'),
      );
    });

    test('signUpWithEmail success', () async {
      final result = await repository.signUpWithEmail(
        email: 'new@example.com',
        password: 'password',
        name: 'New',
      );
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should be right'), (r) {
        expect(r.email, 'new@example.com');
      });
    });

    test('signUpWithEmail account created but sign in failed', () async {
      // Custom fake behavior: we need it to succeed account creation but fail session creation
      // We can use a subclass or override inside the test
      final partialFailureService = _PartialFailureFakeService();
      final repo = AppwriteAuthRepository(partialFailureService);

      final result = await repo.signUpWithEmail(
        email: 'test@example.com',
        password: 'password',
        name: 'Test',
      );
      expect(result.isLeft(), isTrue);
      result.fold((l) {
        expect(l, isA<AuthFailure>());
        expect(
          (l as AuthFailure).reason,
          AuthFailureReason.accountCreatedButSignInFailed,
        );
      }, (r) => fail('Should be left'));
    });

    test('signOut success', () async {
      await fakeService.createEmailPasswordSession(
        email: 'test@example.com',
        password: 'password',
      );
      final result = await repository.signOut();
      expect(result, const Right(null));
      final current = await repository.currentUser();
      expect(current, const Right(null));
    });

    test('idempotent sign-out when no current session', () async {
      final result = await repository.signOut();
      expect(result, const Right(null));
    });

    test('configuration issue mapping', () async {
      fakeService.setNextException(
        AppwriteException('Project not found', 400, 'project_not_found'),
      );
      final result = await repository.currentUser();
      result.fold(
        (l) =>
            expect((l as AuthFailure).reason, AuthFailureReason.configuration),
        (r) => fail('Should be left'),
      );
    });
  });
}

class _PartialFailureFakeService extends FakeAppwriteAuthService {
  @override
  Future<models.Session> createEmailPasswordSession({
    required String email,
    required String password,
  }) async {
    throw AppwriteException('Failed to create session', 500, 'server_error');
  }
}
