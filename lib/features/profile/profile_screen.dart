import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/core_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/shared_widgets.dart';
import '../auth/auth_screen.dart';

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
                      MaterialPageRoute(builder: (_) => const AuthScreen())),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).refreshCurrentUser(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(user?.phone ?? '',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? '—',
                      verified: user?.isEmailVerified),
                  const Divider(height: 1),
                  _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user?.phone ?? '—',
                      verified: user?.isPhoneVerified),
                ],
              ),
            ),
            const SectionHeader(title: 'Preferences'),
            Card(
              child: Column(
                children: [
                  const _ThemeTile(),
                ],
              ),
            ),
            const SectionHeader(title: 'About'),
            Card(
              child: FutureBuilder<PackageInfo>(
                future: ref.read(packageInfoProvider.future),
                builder: (context, snap) => ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App version'),
                  subtitle: Text(snap.data != null
                      ? '${snap.data!.version} (${snap.data!.buildNumber})'
                      : '—'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.logout_rounded,
                    color: context.tokens.dangerColor),
                label: Text('Log out',
                    style: TextStyle(color: context.tokens.dangerColor)),
                onPressed: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: 24),
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool? verified;
  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      this.verified});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: verified == null
          ? null
          : StatusPill(
              label: verified! ? 'Verified' : 'Unverified',
              color: verified! ? tokens.successColor : tokens.text3,
              background: verified! ? tokens.successSoft : tokens.surface2,
            ),
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
