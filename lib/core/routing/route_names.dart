class Routes {
  static const splash = '/';
  static const auth = '/auth';
  static const forgotPassword = '/auth/forgot-password';
  static const home = '/home';
  static const search = '/search';
  static const bookings = '/bookings';
  static const wallet = '/wallet';
  static const profile = '/profile';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const facilityDetail = '/facility';
  static const doctorDetail = '/doctor';
  static const booking = '/booking';
  static const bookingResult = '/booking/result';

  /// Maps the backend-driven nav_config `screen` string to a route path.
  static String forNavScreen(String screen) {
    switch (screen) {
      case 'home':
        return home;
      case 'search':
        return search;
      case 'bookings':
        return bookings;
      case 'wallet':
        return wallet;
      case 'favorites':
        return favorites;
      case 'notifications':
        return notifications;
      case 'profile':
        return profile;
      default:
        return home;
    }
  }
}
