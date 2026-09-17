import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

abstract class AppwriteAuthService {
  Future<models.User> createAccount({
    required String userId,
    required String email,
    required String password,
    String? name,
  });

  Future<models.Session> createEmailPasswordSession({
    required String email,
    required String password,
  });

  Future<models.User> getAccount();

  Future<void> deleteSession({required String sessionId});
}

class AppwriteAuthServiceImpl implements AppwriteAuthService {
  final Account _account;

  AppwriteAuthServiceImpl(this._account);

  @override
  Future<models.User> createAccount({
    required String userId,
    required String email,
    required String password,
    String? name,
  }) {
    return _account.create(
      userId: userId,
      email: email,
      password: password,
      name: name,
    );
  }

  @override
  Future<models.Session> createEmailPasswordSession({
    required String email,
    required String password,
  }) {
    return _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  @override
  Future<models.User> getAccount() {
    return _account.get();
  }

  @override
  Future<void> deleteSession({required String sessionId}) {
    return _account.deleteSession(sessionId: sessionId);
  }
}
