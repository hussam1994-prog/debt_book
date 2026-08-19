import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/localization/l10n_extension.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pleaseFillFields)),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.pleaseFillFields)),
        );
      }
      return;
    }
    if (password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordTooShort)),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.checkEmailToConfirm)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    final l10n = context.l10n;

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.forgotPassword),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final value = emailController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: Text(l10n.send),
            ),
          ],
        );
      },
    );

    if (email == null || email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.example.mobile://login-callback',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.resetEmailSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.email),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _forgotPassword,
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              ElevatedButton(
                onPressed: _signIn,
                child: Text(l10n.login),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _register,
                child: Text(l10n.register),
              ),
            ],
          ],
        ),
      ),
    );
  }
}