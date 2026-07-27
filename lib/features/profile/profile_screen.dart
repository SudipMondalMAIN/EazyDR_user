import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/core_providers.dart';
import '../../core/models/booking.dart';
import '../../core/repositories/bookings_repository.dart';
import '../../core/repositories/misc_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '../bookings_list/bookings_list_screen.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.status == SessionStatus.loggedOut) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 40, color: context.tokens.text3),
                const SizedBox(height: 12),
                Text('Log in to view your profile',
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

    final user = auth.user;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bookingsAsync = ref.watch(myBookingsProvider);
    final favoritesAsync = ref.watch(myFavoritesProvider);
    final balanceAsync = ref.watch(rewardBalanceProvider);

    int total = 0, upcoming = 0, completed = 0;
    bookingsAsync.whenData((list) {
      total = list.length;
      upcoming = list.where((b) => isUpcoming(b.status)).length;
      completed = list.where((b) => b.status == BookingStatus.completed).length;
    });
    final favCount = favoritesAsync.whenOrNull(data: (l) => l.length) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authProvider.notifier).refreshCurrentUser();
          ref.invalidate(myBookingsProvider);
          ref.invalidate(myFavoritesProvider);
          ref.invalidate(rewardBalanceProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Teal gradient header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withOpacity(0.75)],
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(kRadiusLg),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              backgroundImage: user?.photoUrl != null
                                  ? NetworkImage(user!.photoUrl!)
                                  : null,
                              child: user?.photoUrl == null
                                  ? const Icon(Icons.person,
                                      size: 32, color: Colors.white)
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child:
                                    Icon(Icons.edit, size: 12, color: primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.fullName ?? '',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(user?.phone ?? '',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.9))),
                              if ((user?.email ?? '').isNotEmpty)
                                Text(user!.email!,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12)),
                              const SizedBox(height: 8),
                              if (user?.isPhoneVerified == true ||
                                  user?.isEmailVerified == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Verified',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.2), height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatItem(
                          icon: Icons.calendar_today_rounded,
                          value: '$total',
                          label: 'Total Bookings'),
                      _StatItem(
                          icon: Icons.access_time_rounded,
                          value: '$upcoming',
                          label: 'Upcoming'),
                      _StatItem(
                          icon: Icons.check_circle_rounded,
                          value: '$completed',
                          label: 'Completed'),
                      _StatItem(
                          icon: Icons.favorite_rounded,
                          value: '$favCount',
                          label: 'Favourites'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Wallet card
            InkWell(
              borderRadius: BorderRadius.circular(kRadiusLg),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WalletScreen())),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.tokens.primarySoft,
                              borderRadius: BorderRadius.circular(kRadiusSm),
                            ),
                            child: Icon(Icons.account_balance_wallet_rounded,
                                color: primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text('EazyDoctor Wallet',
                                  style: theme.textTheme.titleMedium)),
                          Icon(Icons.chevron_right_rounded,
                              color: context.tokens.text3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                balanceAsync.when(
                                  data: (b) => Text('$b pts',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                              color: primary,
                                              fontWeight: FontWeight.w800)),
                                  loading: () => const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                  error: (_, __) => Text('—',
                                      style: theme.textTheme.headlineSmall),
                                ),
                                Text('Wallet Balance',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const WalletScreen())),
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 18),
                            label: const Text('Add Money'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Promo banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.tokens.successSoft,
                borderRadius: BorderRadius.circular(kRadius),
                border: Border.all(
                    color: context.tokens.successColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.tokens.successColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_user_rounded,
                        color: context.tokens.successColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Book Appointments, Save Time',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text('Quick booking • Live queue • Easy payments',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.tokens.text3),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Menu list
            Card(
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    label: 'My Bookings',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BookingsListScreen())),
                  ),
                  const Divider(height: 1),
                  _MenuTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'My Favourites',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FavoritesScreen())),
                  ),
                  const Divider(height: 1),
                  _MenuTile(
                      icon: Icons.location_on_outlined,
                      label: 'My Addresses',
                      onTap: () {}),
                  const Divider(height: 1),
                  _MenuTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payment Methods',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const WalletScreen())),
                  ),
                  const Divider(height: 1),
                  _MenuTile(
                      icon: Icons.description_outlined,
                      label: 'Invoices & Bills',
                      onTap: () {}),
                  const Divider(height: 1),
                  _MenuTile(
                      icon: Icons.headset_mic_outlined,
                      label: 'Help & Support',
                      onTap: () {}),
                  const Divider(height: 1),
                  FutureBuilder<PackageInfo>(
                    future: ref.read(packageInfoProvider.future),
                    builder: (context, snap) => _MenuTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About EazyDoctor',
                      subtitle: snap.data != null
                          ? '${snap.data!.version} (${snap.data!.buildNumber})'
                          : null,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Preferences'),
            Card(child: Column(children: const [_ThemeTile()])),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.tokens.dangerColor),
                  foregroundColor: context.tokens.dangerColor,
                ),
                icon: Icon(Icons.logout_rounded,
                    color: context.tokens.dangerColor),
                label: Text('Logout',
                    style: TextStyle(
                        color: context.tokens.dangerColor,
                        fontWeight: FontWeight.w600)),
                onPressed: () => _confirmLogout(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            'You can log back in anytime with your phone and password.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: context.tokens.primarySoft,
            borderRadius: BorderRadius.circular(kRadiusSm)),
        child:
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Icon(Icons.chevron_right_rounded, color: context.tokens.text3),
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(themeModeOverrideProvider);
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: const Text('Theme'),
      subtitle: Text(override == null
          ? 'Follow app default'
          : (override == 'dark' ? 'Dark' : 'Light')),
      trailing: DropdownButton<String>(
        value: override ?? 'system',
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'system', child: Text('Default')),
          DropdownMenuItem(value: 'light', child: Text('Light')),
          DropdownMenuItem(value: 'dark', child: Text('Dark')),
        ],
        onChanged: (value) {
          ref
              .read(themeModeOverrideProvider.notifier)
              .setOverride(value == 'system' ? null : value);
        },
      ),
    );
  }
}
