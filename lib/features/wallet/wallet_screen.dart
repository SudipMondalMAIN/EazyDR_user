import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/login_screen.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.status == SessionStatus.loggedOut) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rewards')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 40, color: context.tokens.text3),
                const SizedBox(height: 12),
                Text('Log in to see your rewards',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final balanceAsync = ref.watch(rewardBalanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rewardBalanceProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: theme.colorScheme.primary,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reward points',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.onPrimary)),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (points) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$points',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary)),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('pts',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary)),
                          ),
                        ],
                      ),
                      loading: () => SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: theme.colorScheme.onPrimary),
                      ),
                      error: (_, __) => Text('—',
                          style: theme.textTheme.headlineLarge
                              ?.copyWith(color: theme.colorScheme.onPrimary)),
                    ),
                  ],
                ),
              ),
            ),
            const SectionHeader(title: 'How it works'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HowItWorksRow(
                        icon: Icons.event_available_rounded,
                        text: 'Earn points every time you complete a booking.'),
                    const SizedBox(height: 12),
                    _HowItWorksRow(
                        icon: Icons.group_add_rounded,
                        text:
                            'Refer friends and earn bonus points when they book.'),
                    const SizedBox(height: 12),
                    _HowItWorksRow(
                        icon: Icons.card_giftcard_rounded,
                        text:
                            'Redeem points for discounts on future bookings.'),
                  ],
                ),
              ),
            ),
            if (balanceAsync.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ErrorRetryView(
                    message: 'Could not load your balance',
                    onRetry: () => ref.invalidate(rewardBalanceProvider)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HowItWorksRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
