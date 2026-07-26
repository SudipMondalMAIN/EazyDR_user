import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';

enum OtpPurpose { signup, login, forgotPassword }

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  final OtpPurpose purpose;
  /// Only used for [OtpPurpose.forgotPassword] — the new password to set
  /// once the OTP is verified.
  final String? newPassword;

  const OtpScreen({super.key, required this.email, required this.purpose, this.newPassword});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _resend() async {
    try {
      final purpose = switch (widget.purpose) {
        OtpPurpose.signup => 'signup',
        OtpPurpose.login => 'login',
        OtpPurpose.forgotPassword => 'forgot_password',
      };
      await ref.read(authProvider.notifier).resendOtp(email: widget.email, purpose: purpose);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent to your email')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().length < 4) {
      setState(() => _error = 'Enter the code you received by email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifier = ref.read(authProvider.notifier);
      switch (widget.purpose) {
        case OtpPurpose.signup:
          await notifier.verifySignupOtp(email: widget.email, otp: _otpCtrl.text.trim());
          break;
        case OtpPurpose.login:
          await notifier.verifyLoginOtp(email: widget.email, otp: _otpCtrl.text.trim());
          break;
        case OtpPurpose.forgotPassword:
          await notifier.resetPassword(email: widget.email, otp: _otpCtrl.text.trim(), newPassword: widget.newPassword!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset — please log in')));
            context.go(Routes.auth);
            return;
          }
      }
      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('We emailed a verification code to', style: Theme.of(context).textTheme.bodyMedium),
              Text(widget.email, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                maxLength: 8,
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _loading ? null : _resend, child: const Text('Resend code')),
            ],
          ),
        ),
      ),
    );
  }
}
