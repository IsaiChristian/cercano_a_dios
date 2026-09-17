import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cercano_a_dios/domain/failures/auth_failure.dart';
import 'package:cercano_a_dios/domain/failures/failure.dart';
import 'package:cercano_a_dios/l10n/app_localizations.dart';
import 'package:cercano_a_dios/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:cercano_a_dios/src/auth/presentation/widgets/auth_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _mode = AuthMode.signIn;

  void _toggleMode() {
    context.read<AuthBloc>().add(const AuthFailureDismissed());
    setState(() {
      _mode = _mode == AuthMode.signIn
          ? AuthMode.createAccount
          : AuthMode.signIn;
    });
  }

  String _getFailureMessage(BuildContext context, Failure failure) {
    final l10n = AppLocalizations.of(context)!;
    if (failure is AuthFailure) {
      switch (failure.reason) {
        case AuthFailureReason.invalidCredentials:
          return l10n.authFailureInvalidCredentials;
        case AuthFailureReason.emailAlreadyUsed:
          return l10n.authFailureEmailAlreadyUsed;
        case AuthFailureReason.invalidInput:
          return l10n.authFailureInvalidInput;
        case AuthFailureReason.network:
          return l10n.authFailureNetwork;
        case AuthFailureReason.configuration:
          return l10n.authFailureConfiguration;
        case AuthFailureReason.accountCreatedButSignInFailed:
          return l10n.authFailureAccountCreatedButSignInFailed;
        case AuthFailureReason.unknown:
          return l10n.authFailureUnknown;
      }
    }
    return l10n.authFailureUnknown;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _mode == AuthMode.signIn ? l10n.signIn : l10n.createAccount,
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listenWhen: (previous, current) => previous.failure != current.failure,
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getFailureMessage(context, state.failure!)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSubmitting =
              state.operationStatus == AuthOperationStatus.submitting ||
              state.operationStatus == AuthOperationStatus.checking;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.1),
                        AuthForm(
                          mode: _mode,
                          isSubmitting: isSubmitting,
                          onSignIn: (email, password) {
                            context.read<AuthBloc>().add(
                              AuthSignInRequested(
                                email: email,
                                password: password,
                              ),
                            );
                          },
                          onSignUp: (email, password, name) {
                            context.read<AuthBloc>().add(
                              AuthSignUpRequested(
                                email: email,
                                password: password,
                                name: name,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isSubmitting ? null : _toggleMode,
                          child: Text(
                            _mode == AuthMode.signIn
                                ? l10n.switchToCreateAccount
                                : l10n.switchToSignIn,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          l10n.privacyDescription,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
