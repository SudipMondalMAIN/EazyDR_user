import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/auth/auth_provider.dart';
import 'core/core_providers.dart';
import 'core/push/push_service.dart';
import 'core/routing/route_names.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await LocalStorage.create();

  // Firebase is optional at this stage — no firebase_options.dart has been
  // generated yet (run `flutterfire configure` when push notifications are
  // wired up server-side). Guard so a missing/failed config never blocks
  // app startup.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // no-op — app runs fine without push notifications
  }

  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
      ],
      child: const EazyDrApp(),
    ),
  );
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
          path: Routes.splash,
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: Routes.auth, builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: Routes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: Routes.home, builder: (context, state) => const MainShell()),
    ],
  );
});

class EazyDrApp extends ConsumerStatefulWidget {
  const EazyDrApp({super.key});

  @override
  ConsumerState<EazyDrApp> createState() => _EazyDrAppState();
}

class _EazyDrAppState extends ConsumerState<EazyDrApp> {
  @override
  void initState() {
    super.initState();
    // Best-effort push init; harmless no-op if Firebase never initialized.
    Future.microtask(() async {
      try {
        pushService.onTokenRegister = (token) {
          ref.read(authProvider.notifier).registerPushToken(token);
        };
        await pushService.init();
      } catch (_) {
        // push notifications unavailable on this build/device — ignore
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep auth state alive at the app root so token refresh / logout is
    // observed globally even while deep inside a feature screen.
    ref.watch(authProvider);
    final theme = ref.watch(effectiveThemeProvider);
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'EazyDoctor',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
