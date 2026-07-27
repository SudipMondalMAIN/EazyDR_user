import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';
import 'widgets/otp_boxes.dart';
import 'widgets/success_view.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Note: backend emails the OTP only after the account is registered
  // (which needs name+password), so the order here is
  // phone -> email -> name+password (registers) -> otp -> success.
  int _step = 0;
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _otp = '';
  bool _loading = false;
  String? _error;

  static const _titles = [
    'Enter Mobile Number',
    'Enter Email Address',
    'Enter Your Name',
    'Verify Email (OTP)',
    'Sign Up Success'
  ];

  Future<void> _submitRegister() async {
    if (_nameCtrl.text.trim().length < 2) {
      setState(() => _error = 'Enter your full name');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).register(
            fullName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (mounted) setState(() => _step = 3);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .verifySignupOtp(email: _emailCtrl.text.trim(), otp: _otp);
      if (mounted) setState(() => _step = 4);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_phoneCtrl.text.trim().length < 10) {
          setState(() => _error = 'Enter a valid 10-digit mobile number');
          return;
        }
        setState(() => _step = 1);
        break;
      case 1:
        if (!_emailCtrl.text.contains('@')) {
          setState(() => _error = 'Enter a valid email address');
          return;
        }
        setState(() => _step = 2);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_step == 4) {
      return SuccessView(
        title: 'Sign Up Successful!',
        subtitle:
            'Welcome to EazyDoctor. Your account has been created successfully.',
        buttonLabel: 'Go to Home',
        onDone: () {
          try {
            context.go(Routes.home);
          } catch (e) {
            debugPrint('Navigation to home failed: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open Home: $e')));
            }
          }
        },
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
                        if (_step == 2) {
                          _submitRegister();
                        } else if (_step == 3) {
                          _verifyOtp();
                        } else {
                          _next();
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_step == 2
                        ? 'Create Account'
                        : (_step == 3 ? 'Verify & Continue' : 'Continue')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(ThemeData theme) {
    switch (_step) {
      case 0:
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('🇮🇳 +91'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                    hintText: '98765 43210', counterText: ''),
              ),
            ),
          ],
        );
      case 1:
        return TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@example.com'),
        );
      case 2:
        return Column(
          children: [
            TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Full name')),
            const SizedBox(height: 12),
            TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Create password')),
          ],
        );
      case 3:
      default:
        return Column(
          children: [
            Text("We've sent a 6-digit OTP to",
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            Text(_emailCtrl.text.trim(),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OtpBoxes(onChanged: (v) => _otp = v),
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
