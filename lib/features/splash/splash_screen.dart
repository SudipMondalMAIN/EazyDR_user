import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/core_providers.dart';
import '../../core/routing/route_names.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _animController.forward();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final configAsync = await ref.read(appConfigProvider.future);
    if (!mounted) return;

    if (configAsync.forceUpdate) {
      final installedOk = await _versionSatisfies(configAsync.minAppVersion);
      if (!installedOk)
        return; // blocking dialog is rendered by build(); stay on splash
    }

    // Give the auth notifier a moment to resolve an existing session, and
    // let the logo animation finish playing before navigating away.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(Routes.home);
  }

  Future<bool> _versionSatisfies(String minVersion) async {
    try {
      final info = await PackageInfo.fromPlatform();
      return _compareVersions(info.version, minVersion) >= 0;
    } catch (_) {
      return true;
    }
  }

  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    ref.listen(authProvider, (_, __) {});

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) => Opacity(
                    opacity: _fadeAnim.value,
                    child:
                        Transform.scale(scale: _scaleAnim.value, child: child),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.local_hospital_rounded,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Text('EazyDoctor',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                    opacity: _fadeAnim,
                    child: const CircularProgressIndicator()),
              ],
            ),
          ),
          configAsync.maybeWhen(
            data: (config) {
              if (!config.forceUpdate) return const SizedBox.shrink();
              return FutureBuilder<bool>(
                future: _versionSatisfies(config.minAppVersion),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done ||
                      snap.data == true) {
                    return const SizedBox.shrink();
                  }
                  return _ForceUpdateOverlay(message: config.updateMessage);
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ForceUpdateOverlay extends StatelessWidget {
  final String message;
  const _ForceUpdateOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update_rounded,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('Update required',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'Please update the app to continue using EazyDoctor.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
