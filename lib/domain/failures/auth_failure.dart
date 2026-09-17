import 'failure.dart';

enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyUsed,
  invalidInput,
  network,
  configuration,
  accountCreatedButSignInFailed,
  unknown,
}

class AuthFailure extends Failure {
  final AuthFailureReason reason;

  const AuthFailure(this.reason, [String message = '']) : super(message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          runtimeType == other.runtimeType &&
          reason == other.reason &&
          message == other.message;

  @override
  int get hashCode => reason.hashCode ^ message.hashCode;
}
