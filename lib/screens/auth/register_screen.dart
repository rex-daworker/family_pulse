import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Re-run validation on the confirm fields as the user edits the
    // originals, so a fixed typo clears the "doesn't match" error without
    // needing to also touch the confirm field itself.
    _emailController.addListener(_revalidateConfirmEmail);
    _passwordController.addListener(_revalidateConfirmPassword);
  }

  @override
  void dispose() {
    _emailController.removeListener(_revalidateConfirmEmail);
    _passwordController.removeListener(_revalidateConfirmPassword);
    _nameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _revalidateConfirmEmail() {
    if (_confirmEmailController.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  void _revalidateConfirmPassword() {
    if (_confirmPasswordController.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  String? _validateName(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return AppLocalizations.of(context).nameRequiredError;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.emailRequiredError;
    if (!email.contains('@') || !email.contains('.')) {
      return l10n.emailInvalidError;
    }
    return null;
  }

  String? _validateConfirmEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    final confirmEmail = value?.trim().toLowerCase() ?? '';
    if (confirmEmail.isEmpty) return l10n.confirmEmailRequiredError;
    if (confirmEmail != _emailController.text.trim().toLowerCase()) {
      return l10n.emailsDontMatchError;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    final password = value ?? '';
    if (password.isEmpty) return l10n.passwordRequiredError;
    if (password.length < 6) return l10n.passwordTooShortError;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context);
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) return l10n.confirmPasswordRequiredError;
    if (confirmPassword != _passwordController.text) {
      return l10n.passwordsDontMatchError;
    }
    return null;
  }

  Future<void> _register() async {
    // Inline field errors (name/email/password) show automatically — bail
    // before touching Firebase if any of them fail.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedErrorMessage(context, e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmEmailController,
                decoration: InputDecoration(labelText: l10n.confirmEmailLabel),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateConfirmEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: _obscurePassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: l10n.confirmPasswordLabel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    tooltip: _obscureConfirmPassword
                        ? l10n.showPassword
                        : l10n.hidePassword,
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: Text(l10n.signUpButton),
                    ),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(l10n.loginPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
