import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';
import 'widgets/otp_boxes.dart';
import 'widgets/success_view.dart';

class LoginVerifyScreen extends ConsumerStatefulWidget {
  final String identifier;
  const LoginVerifyScreen({super.key, required this.identifier});
  @override
  ConsumerState<LoginVerifyScreen> createState() => _LoginVerifyScreenState();
}

class _LoginVerifyScreenState extends ConsumerState<LoginVerifyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _passwordCtrl = TextEditingController();
  String _otp = '';
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    // OTP login needs only the phone/email identifier — password is not
    // required. The backend emails the OTP to the account's registered
    // email regardless of which identifier was typed.
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .requestLoginOtp(identifier: widget.identifier);
      setState(() => _otpSent = true);
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
          .verifyLoginOtp(identifier: widget.identifier, otp: _otp);
      if (mounted) _goSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithPassword() async {
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithPassword(
          identifier: widget.identifier, password: _passwordCtrl.text);
      if (mounted) _goSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goSuccess() {
    // Capture the router HERE, while `context` is still this (mounted)
    // screen's context — not inside onDone, which fires after
    // pushReplacement has already disposed this State, making any
    // `context` lookup inside the callback silently fail.
    final router = GoRouter.of(context);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessView(
        title: 'Login Successful!',
        subtitle: 'Redirecting to Home…',
        onDone: () {
          router.go(Routes.home);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verify Your Identity',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? "We've sent a 6-digit OTP to your registered email"
                    : 'Choose OTP or Password to continue',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Text(widget.identifier,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TabBar(
                  controller: _tab,
                  tabs: const [Tab(text: 'OTP'), Tab(text: 'Password')],
                  onTap: (_) => setState(() => _error = null)),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // OTP tab
                    Column(
                      children: [
                        if (_otpSent)
                          OtpBoxes(onChanged: (v) => _otp = v)
                        else
                          Text(
                              'Tap "Send OTP" below to get a 6-digit code on your registered email.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center),
                      ],
                    ),
                    // Password tab
                    Column(
                      children: [
                        TextField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration:
                                const InputDecoration(hintText: 'Password')),
                      ],
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        if (_tab.index == 0) {
                          _otpSent ? _verifyOtp() : _sendOtp();
                        } else {
                          _loginWithPassword();
                        }
                      },
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_tab.index == 0
                        ? (_otpSent ? 'Verify & Login' : 'Send OTP')
                        : 'Verify & Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
