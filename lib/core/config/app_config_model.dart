import 'dart:convert';

class NavItem {
  final String key;
  final String label;
  final String icon;
  final int order;
  final bool visible;
  final String screen;

  NavItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.order,
    required this.visible,
    required this.screen,
  });

  factory NavItem.fromJson(Map<String, dynamic> json) => NavItem(
        key: json['key'] ?? '',
        label: json['label'] ?? '',
        icon: json['icon'] ?? 'circle',
        order: json['order'] ?? 0,
        visible: json['visible'] ?? true,
        screen: json['screen'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'icon': icon,
        'order': order,
        'visible': visible,
        'screen': screen,
      };
}

class AppConfig {
  final List<NavItem> navConfig;
  final String themeMode; // "light" | "dark"
  final String primaryColor; // hex
  final String secondaryColor; // hex
  final String minAppVersion;
  final bool forceUpdate;
  final String updateMessage;
  final String updateUrl;

  AppConfig({
    required this.navConfig,
    required this.themeMode,
    required this.primaryColor,
    required this.secondaryColor,
    required this.minAppVersion,
    required this.forceUpdate,
    required this.updateMessage,
    required this.updateUrl,
  });

  List<NavItem> get visibleSortedNav {
    final items = navConfig.where((n) => n.visible).toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        navConfig: (json['nav_config'] as List? ?? [])
            .map((e) => NavItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        themeMode: json['theme_mode'] ?? 'light',
        primaryColor: json['primary_color'] ?? '#0f766e',
        secondaryColor: json['secondary_color'] ?? '#d97706',
        minAppVersion: json['min_app_version'] ?? '1.0.0',
        forceUpdate: json['force_update'] ?? false,
        updateMessage: json['update_message'] ?? '',
        updateUrl: json['update_url'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'nav_config': navConfig.map((n) => n.toJson()).toList(),
        'theme_mode': themeMode,
        'primary_color': primaryColor,
        'secondary_color': secondaryColor,
        'min_app_version': minAppVersion,
        'force_update': forceUpdate,
        'update_message': updateMessage,
        'update_url': updateUrl,
      };

  static AppConfig fallback() => AppConfig(
        navConfig: [
          NavItem(key: 'home', label: 'Home', icon: 'home', order: 0, visible: true, screen: 'home'),
          NavItem(key: 'search', label: 'Search', icon: 'search', order: 1, visible: true, screen: 'search'),
          NavItem(key: 'bookings', label: 'Bookings', icon: 'calendar', order: 2, visible: true, screen: 'bookings'),
          NavItem(key: 'wallet', label: 'Rewards', icon: 'wallet', order: 3, visible: true, screen: 'wallet'),
          NavItem(key: 'profile', label: 'Profile', icon: 'user', order: 4, visible: true, screen: 'profile'),
        ],
        themeMode: 'light',
        primaryColor: '#0f766e',
        secondaryColor: '#d97706',
        minAppVersion: '1.0.0',
        forceUpdate: false,
        updateMessage: '',
        updateUrl: '',
      );

  static AppConfig fromCache(String jsonStr) => AppConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  String toCacheString() => jsonEncode(toJson());
}
