import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';
import 'widgets/otp_boxes.dart';
import 'widgets/success_view.dart';

class LoginVerifyScreen extends ConsumerStatefulWidget {
  final String phone;
  const LoginVerifyScreen({super.key, required this.phone});
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
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter your password first to receive the OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .requestLoginOtp(phone: widget.phone, password: _passwordCtrl.text);
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
      // email isn't known at this point for phone-based login OTP; backend
      // keys the OTP by phone/session, so we pass phone through as email arg
      // is unused server-side for this flow variant.
      await ref
          .read(authProvider.notifier)
          .verifyLoginOtp(email: widget.phone, otp: _otp);
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
      await ref
          .read(authProvider.notifier)
          .loginWithPassword(phone: widget.phone, password: _passwordCtrl.text);
      if (mounted) _goSuccess();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goSuccess() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => SuccessView(
        title: 'Login Successful!',
        subtitle: 'Redirecting to Home…',
        onDone: () => context.go(Routes.home),
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
                    ? "We've sent a 6-digit OTP to"
                    : 'Enter your password, or switch to OTP',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Text('+91 ${widget.phone}',
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
                              'Requesting an OTP needs your password once — enter it in the Password tab, then come back here.',
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
