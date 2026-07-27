import 'dart:async';
import 'package:flutter/material.dart';

/// Big green check + title/subtitle + "redirecting in N seconds", matching
/// the "Login Successful" / "Sign Up Successful" / "Password Reset
/// Successful" screens in the reference design.
class SuccessView extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDone;
  final Widget? extra;
  final String buttonLabel;
  final int seconds;

  const SuccessView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onDone,
    this.extra,
    this.buttonLabel = 'Continue',
    this.seconds = 3,
  });

  @override
  State<SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<SuccessView> {
  late int _remaining = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        widget.onDone();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      width: 6),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(widget.title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(widget.subtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              if (widget.extra != null) ...[
                const SizedBox(height: 20),
                widget.extra!
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  child: Text(widget.buttonLabel),
                ),
              ),
              const SizedBox(height: 12),
              Text('Redirecting in $_remaining seconds…',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
