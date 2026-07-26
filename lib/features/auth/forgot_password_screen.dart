import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    if (email.isEmpty || newPassword.length < 6) {
      setState(() => _error = 'Enter your email and a new password (min 6 characters)');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).forgotPassword(email: email);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(email: email, purpose: OtpPurpose.forgotPassword, newPassword: newPassword),
      ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter your account email and choose a new password. We will email you a code to confirm.',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: _newPasswordCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'New password')),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
