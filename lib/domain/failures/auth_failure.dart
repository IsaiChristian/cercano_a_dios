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
  List<Object?> get props => [reason, message];
}
