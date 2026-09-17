import 'package:flutter/material.dart';

import 'package:cercano_a_dios/l10n/app_localizations.dart';

enum AuthMode { signIn, createAccount }

class AuthForm extends StatefulWidget {
  final AuthMode mode;
  final bool isSubmitting;
  final void Function(String email, String password) onSignIn;
  final void Function(String email, String password, String name) onSignUp;

  const AuthForm({
    super.key,
    required this.mode,
    required this.isSubmitting,
    required this.onSignIn,
    required this.onSignUp,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.mode == AuthMode.signIn) {
        widget.onSignIn(_emailController.text.trim(), _passwordController.text);
      } else {
        widget.onSignUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.mode == AuthMode.createAccount) ...[
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              enabled: !widget.isSubmitting,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.validationRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            enabled: !widget.isSubmitting,
            decoration: InputDecoration(
              labelText: l10n.email,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.validationRequired;
              }
              if (!value.contains('@')) {
                return l10n.validationEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            enabled: !widget.isSubmitting,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: const OutlineInputBorder(),
              suffixIcon: Semantics(
                label: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                child: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: widget.isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                ),
              ),
            ),
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: [
              if (widget.mode == AuthMode.signIn) AutofillHints.password,
              if (widget.mode == AuthMode.createAccount)
                AutofillHints.newPassword,
            ],
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.validationRequired;
              }
              if (value.length < 8) {
                return l10n.validationPasswordLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: Text(
              widget.isSubmitting
                  ? l10n.submitting
                  : (widget.mode == AuthMode.signIn
                        ? l10n.signIn
                        : l10n.createAccount),
            ),
          ),
        ],
      ),
    );
  }
}
