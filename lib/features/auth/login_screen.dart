import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import 'forgot_password_screen.dart';
import 'login_verify_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  String? _error;

  void _continue() {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginVerifyScreen(phone: phone)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(
                child: BrandHeader(
                    logoSize: 88, tagline: 'Your health, our priority'),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(kRadiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome back',
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('Enter your mobile number to continue',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text('Mobile Number', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(kRadiusSm),
                          ),
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
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _continue, child: const Text('Continue')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen())),
                  child: const Text('Forgot password?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
