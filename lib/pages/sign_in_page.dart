import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/storage_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = !StorageService.hasAnyLocalAccount();
    _emailController.text =
        StorageService.getCurrentAccountEmail() ?? 'hariganessh@gmail.com';
    _loginEmailController.text = _emailController.text;
    _registerUsernameController.text =
        StorageService.getCurrentAccountUsername() ?? '';
  }

  @override
  void dispose() {
    _registerUsernameController.dispose();
    _emailController.dispose();
    _loginEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _registerUsernameController.text.trim();
    final email = _emailController.text.trim();
    final loginEmail = _loginEmailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isRegisterMode &&
        (username.isEmpty || email.isEmpty || password.isEmpty)) {
      _showMessage('Username, email and password are required');
      return;
    }
    if (!_isRegisterMode && (loginEmail.isEmpty || password.isEmpty)) {
      _showMessage('Email and password are required');
      return;
    }

    setState(() => _isSubmitting = true);
    if (_isRegisterMode) {
      final created = await StorageService.registerLocalAccount(
        username,
        email,
        password,
      );
      if (!mounted) return;
      if (!created) {
        setState(() => _isSubmitting = false);
        _showMessage('Email already registered, please login');
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isRegisterMode = false;
      });
      _showMessage('Account created and logged in');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
      return;
    }

    if (!StorageService.hasAnyLocalAccount()) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('No account found, please register first');
      return;
    }

    final success = await StorageService.signInLocal(loginEmail, password);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!success) {
      _showMessage('Invalid email or password');
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = _isRegisterMode ? 'Register' : 'Login';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                color: scheme.surfaceContainerHigh,
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? 'Create an account with username, email and password'
                            : 'Use your local account credentials',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      if (_isRegisterMode)
                        TextField(
                          controller: _registerUsernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                      if (_isRegisterMode) const SizedBox(height: 12),
                      TextField(
                        controller: _isRegisterMode
                            ? _emailController
                            : _loginEmailController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _isSubmitting ? null : _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isRegisterMode ? 'Register' : 'Login'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isRegisterMode)
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() => _isRegisterMode = true);
                                },
                          child: const Text('Register (if no account)'),
                        )
                      else
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() => _isRegisterMode = false);
                                },
                          child: const Text('Back to Login'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
