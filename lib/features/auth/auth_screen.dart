import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';
import 'forgot_password_screen.dart';
import 'otp_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.local_hospital_rounded, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text('EazyDoctor', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TabBar(
              controller: _tab,
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [Tab(text: 'Log in'), Tab(text: 'Sign up')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LoginTab(onSwitchToSignup: () => _tab.animateTo(1)),
                  _SignupTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTab extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToSignup;
  const _LoginTab({required this.onSwitchToSignup});
  @override
  ConsumerState<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends ConsumerState<_LoginTab> {
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Enter phone and password');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).loginWithPassword(phone: _phoneCtrl.text.trim(), password: _passwordCtrl.text);
      if (mounted) context.go(Routes.home);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone number')),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
              child: const Text('Forgot password?'),
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _login,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Log in'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account?"),
              TextButton(onPressed: widget.onSwitchToSignup, child: const Text('Sign up')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignupTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SignupTab> createState() => _SignupTabState();
}

class _SignupTabState extends ConsumerState<_SignupTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    if (_nameCtrl.text.trim().length < 2 ||
        _phoneCtrl.text.trim().length < 10 ||
        !_emailCtrl.text.contains('@') ||
        _passwordCtrl.text.length < 6) {
      setState(() => _error = 'Fill all fields correctly (password min 6 characters)');
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
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(email: _emailCtrl.text.trim(), purpose: OtpPurpose.signup),
      ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone number')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Password')),
          const SizedBox(height: 12),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _signup,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create account'),
          ),
        ],
      ),
    );
  }
}
