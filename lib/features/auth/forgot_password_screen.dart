import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/brand_logo.dart';
import 'widgets/otp_boxes.dart';
import 'widgets/success_view.dart';

/// Reference design keys this by mobile number; the backend keys it by
/// registered email instead, so the first field collects email but the
/// step structure/order otherwise matches the mockup 1:1.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step =
      0; // 0 email, 1 otp, 2 new password, 3 confirm password, 4 success
  final _emailCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _otp = '';
  bool _loading = false;
  String? _error;

  static const _titles = [
    'Reset Your Password',
    'Verify OTP',
    'Create New Password',
    'Confirm New Password',
    'Reset Successful'
  ];

  Future<void> _sendOtp() async {
    if (!_emailCtrl.text.contains('@')) {
      setState(() => _error = 'Enter your registered email');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .forgotPassword(email: _emailCtrl.text.trim());
      if (mounted) setState(() => _step = 1);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verifyOtpLocally() {
    if (_otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  void _checkNewPassword() {
    if (_newPasswordCtrl.text.length < 6) {
      setState(() => _error = 'Minimum 6 characters');
      return;
    }
    setState(() {
      _error = null;
      _step = 3;
    });
  }

  Future<void> _confirmAndReset() async {
    if (_confirmPasswordCtrl.text != _newPasswordCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).resetPassword(
            email: _emailCtrl.text.trim(),
            otp: _otp,
            newPassword: _newPasswordCtrl.text,
          );
      if (mounted) setState(() => _step = 4);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ref
          .read(authProvider.notifier)
          .forgotPassword(email: _emailCtrl.text.trim());
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP resent to your email')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_step == 4) {
      return SuccessView(
        title: 'Password Reset Successful!',
        subtitle: 'Your password has been updated successfully.',
        buttonLabel: 'Go to Login',
        onDone: () => Navigator.of(context).popUntil((r) => r.isFirst),
      );
    }
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () {
        if (_step == 0) {
          Navigator.of(context).pop();
        } else {
          setState(() => _step -= 1);
        }
      })),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandMark(size: 56)),
              const SizedBox(height: 16),
              _Stepper(step: _step, total: 4),
              const SizedBox(height: 20),
              Text(_titles[_step],
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              _buildStepBody(theme),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        switch (_step) {
                          case 0:
                            _sendOtp();
                            break;
                          case 1:
                            _verifyOtpLocally();
                            break;
                          case 2:
                            _checkNewPassword();
                            break;
                          case 3:
                            _confirmAndReset();
                            break;
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(const [
                        'Send OTP',
                        'Verify OTP',
                        'Continue',
                        'Reset Password'
                      ][_step]),
              ),
              if (_step == 1) ...[
                const SizedBox(height: 8),
                Center(
                    child: TextButton(
                        onPressed: _resendOtp,
                        child: const Text('Resend OTP'))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(ThemeData theme) {
    switch (_step) {
      case 0:
        return Column(
          children: [
            Text('Enter your registered email to receive an OTP',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email')),
          ],
        );
      case 1:
        return Column(
          children: [
            Text('Enter the 6-digit OTP sent to',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            Text(_emailCtrl.text.trim(),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OtpBoxes(onChanged: (v) => _otp = v),
          ],
        );
      case 2:
        return Column(
          children: [
            Text(
                'Your new password must be different from your previous password',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
                controller: _newPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'New password')),
          ],
        );
      case 3:
      default:
        return Column(
          children: [
            Text('Re-enter your new password to confirm',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
                controller: _confirmPasswordCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: 'Confirm password')),
          ],
        );
    }
  }
}

class _Stepper extends StatelessWidget {
  final int step;
  final int total;
  const _Stepper({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: List.generate(total + 1, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == total ? 0 : 4),
            decoration: BoxDecoration(
              color: active ? theme.colorScheme.primary : theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
