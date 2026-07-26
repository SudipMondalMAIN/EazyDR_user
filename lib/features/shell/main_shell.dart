import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config_model.dart';
import '../../core/config/app_config_provider.dart';
import '../bookings_list/bookings_list_screen.dart';
import '../favorites/favorites_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../wallet/wallet_screen.dart';

IconData _iconFor(String name) {
  switch (name) {
    case 'home':
      return Icons.home_rounded;
    case 'search':
      return Icons.search_rounded;
    case 'calendar':
    case 'bookings':
      return Icons.calendar_month_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    case 'favorites':
    case 'heart':
      return Icons.favorite_rounded;
    case 'notifications':
    case 'bell':
      return Icons.notifications_rounded;
    case 'user':
    case 'profile':
      return Icons.person_rounded;
    default:
      return Icons.circle_outlined;
  }
}

Widget _screenFor(String screen) {
  switch (screen) {
    case 'home':
      return const HomeScreen();
    case 'search':
      return const SearchScreen();
    case 'bookings':
      return const BookingsListScreen();
    case 'wallet':
      return const WalletScreen();
    case 'favorites':
      return const FavoritesScreen();
    case 'notifications':
      return const NotificationsScreen();
    case 'profile':
      return const ProfileScreen();
    default:
      return const HomeScreen();
  }
}

/// Bottom nav is fully config-driven from app_config.nav_config: order,
/// visibility, label, icon, and target screen all come from the backend —
/// never hardcoded tabs.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    return configAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Failed to load app config: $e'))),
      data: (config) {
        final List<NavItem> items = config.visibleSortedNav;
        if (items.isEmpty) return const Scaffold(body: HomeScreen());
        final safeIndex = _index < items.length ? _index : 0;
        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: items.map((n) => _screenFor(n.screen)).toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (i) => setState(() => _index = i),
            items: items
                .map((n) => BottomNavigationBarItem(icon: Icon(_iconFor(n.icon)), label: n.label))
                .toList(),
          ),
        );
      },
    );
  }
}
