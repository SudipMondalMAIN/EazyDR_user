import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/route_names.dart';

// Brand marks — fixed to the EazyDoctor logo identity regardless of the
// superadmin-configurable app theme, so the splash always matches the logo.
const _navy = Color(0xFF163A73);
const _teal = Color(0xFF1AA391);
const _tealLight = Color(0xFF6FD6C4);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final AnimationController _c;

  // Stage intervals (0..1 of total animation), matching the 6-stage preview:
  // 1 Starting -> 2 Shape Formation -> 3 Logo Reveal -> 4 Pulse -> 5 Brand -> 6 Finish
  static const _dotEnd = 0.12;
  static const _shapeEnd = 0.46;
  static const _revealEnd = 0.62;
  static const _pulseEnd = 0.8;
  static const _brandEnd = 0.93;

  late final Animation<double> _dotFade = CurvedAnimation(
      parent: _c, curve: const Interval(0.0, _dotEnd, curve: Curves.easeIn));
  late final Animation<double> _shapeDraw = CurvedAnimation(
      parent: _c,
      curve: const Interval(_dotEnd, _shapeEnd, curve: Curves.easeInOut));
  late final Animation<double> _reveal = CurvedAnimation(
      parent: _c,
      curve: const Interval(_shapeEnd, _revealEnd, curve: Curves.easeOut));
  late final Animation<double> _pulse = CurvedAnimation(
      parent: _c,
      curve: const Interval(_revealEnd, _pulseEnd, curve: Curves.easeOut));
  late final Animation<double> _brand = CurvedAnimation(
      parent: _c,
      curve: const Interval(_pulseEnd, _brandEnd, curve: Curves.easeOut));
  late final Animation<double> _finish = CurvedAnimation(
      parent: _c, curve: const Interval(_brandEnd, 1.0, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600));
    _c.forward();
    Future.microtask(_bootstrap);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final configAsync = await ref.read(appConfigProvider.future);
    if (!mounted) return;

    if (configAsync.forceUpdate) {
      final installedOk = await _versionSatisfies(configAsync.minAppVersion);
      if (!installedOk)
        return; // blocking overlay is rendered by build(); stay on splash
    }

    // Let the logo animation finish playing before navigating away.
    await Future.delayed(const Duration(milliseconds: 2600));
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom teal wave — appears in the "Finish" stage.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _finish,
              builder: (context, _) => Opacity(
                opacity: _finish.value,
                child: SizedBox(
                  height: 160 * _finish.value,
                  width: double.infinity,
                  child: CustomPaint(painter: _WavePainter()),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _LogoPainter(
                        dot: _dotFade.value,
                        draw: _shapeDraw.value,
                        reveal: _reveal.value,
                        pulse: _pulse.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _brand,
                  builder: (context, child) => Opacity(
                    opacity: _brand.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - _brand.value)),
                      child: child,
                    ),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2),
                      children: [
                        TextSpan(text: 'Eazy', style: TextStyle(color: _navy)),
                        TextSpan(
                            text: 'Doctor', style: TextStyle(color: _teal)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _finish,
                  builder: (context, _) => Opacity(
                    opacity: _finish.value,
                    child: Text('Your health, our priority',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontSize: 14)),
                  ),
                ),
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
                  return _ForceUpdateOverlay(
                      message: config.updateMessage,
                      updateUrl: config.updateUrl);
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

/// Draws the EazyDoctor mark in four progressive stages driven by the
/// splash animation controller: a starting dot, the outline stroke of the
/// stethoscope + "D" ring being drawn on, the cross/circle solidifying in,
/// and an expanding pulse ring behind it all.
class _LogoPainter extends CustomPainter {
  final double dot; // 0..1 starting dot fade
  final double draw; // 0..1 stroke reveal of stethoscope + D ring
  final double reveal; // 0..1 fill-in of cross + chest-piece circle
  final double pulse; // 0..1 pulse ring expansion

  _LogoPainter(
      {required this.dot,
      required this.draw,
      required this.reveal,
      required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Stage 1 — starting dot.
    if (draw <= 0) {
      final dotPaint = Paint()..color = _navy.withOpacity(dot);
      canvas.drawCircle(center, 5 * dot, dotPaint);
      return;
    }

    // Stage 4 — pulse rings behind the mark.
    if (pulse > 0) {
      for (final delay in [0.0, 0.4]) {
        final t = ((pulse - delay).clamp(0.0, 1.0)) / (1 - delay);
        if (t <= 0) continue;
        final ringPaint = Paint()
          ..color = _teal.withOpacity((1 - t) * 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, 55 + 45 * t, ringPaint);
      }
    }

    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_navy, _teal],
    ).createShader(Rect.fromCircle(center: center, radius: 90));

    // "D" outer ring — a thick open arc from top, around the right side.
    final ringRect = Rect.fromCircle(center: center, radius: 62);
    final ringPath = Path()..addArc(ringRect, -math.pi / 2, math.pi * 1.55);
    final ringPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    _drawProgressive(canvas, ringPath, ringPaint, draw);

    // Stethoscope tube — a rounded U shape from the top-left ear tips down
    // to a loop that ends near the bottom-left of the ring.
    final tube = Path();
    final left = center + const Offset(-34, -46);
    final right = center + const Offset(-2, -46);
    tube.moveTo(left.dx, left.dy);
    tube.quadraticBezierTo(
        left.dx - 14, left.dy + 4, left.dx - 12, left.dy + 18);
    tube.cubicTo(left.dx - 14, left.dy + 46, center.dx - 30, center.dy + 6,
        center.dx - 20, center.dy + 22);
    tube.cubicTo(center.dx - 14, center.dy + 34, center.dx - 4, center.dy + 34,
        center.dx + 2, center.dy + 22);
    final tube2 = Path();
    tube2.moveTo(right.dx, right.dy);
    tube2.quadraticBezierTo(
        right.dx + 6, right.dy + 6, right.dx + 4, right.dy + 20);

    final tubePaint = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawProgressive(canvas, tube, tubePaint, draw);
    _drawProgressive(canvas, tube2, tubePaint, draw);

    // Chest-piece circle at the end of the tube — fades/scales in on reveal.
    final chestCenter = Offset(center.dx + 2, center.dy + 22);
    if (reveal > 0) {
      final outer = Paint()
        ..color = _navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      final inner = Paint()..color = _tealLight.withOpacity(reveal);
      canvas.drawCircle(chestCenter, 8 * reveal, outer..strokeWidth = 5);
      canvas.drawCircle(chestCenter, 4.5 * reveal, inner);
    }

    // Cross — fades/scales in during reveal, centered slightly right of the mark.
    if (reveal > 0) {
      final crossPaint = Paint()..color = _teal.withOpacity(reveal);
      final crossCenter = center + const Offset(10, -8);
      final armLong = 26.0 * reveal;
      final armShort = 8.0 * reveal;
      final vRect = Rect.fromCenter(
          center: crossCenter, width: armShort * 2, height: armLong * 2);
      final hRect = Rect.fromCenter(
          center: crossCenter, width: armLong * 2, height: armShort * 2);
      final rrV =
          RRect.fromRectAndRadius(vRect, Radius.circular(armShort * 0.5));
      final rrH =
          RRect.fromRectAndRadius(hRect, Radius.circular(armShort * 0.5));
      canvas.drawRRect(rrV, crossPaint);
      canvas.drawRRect(rrH, crossPaint);
    }
  }

  void _drawProgressive(Canvas canvas, Path path, Paint paint, double t) {
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      final extract = m.extractPath(0, m.length * t.clamp(0.0, 1.0));
      canvas.drawPath(extract, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.dot != dot ||
      old.draw != draw ||
      old.reveal != reveal ||
      old.pulse != pulse;
}

/// Soft teal wave decoration for the bottom of the "Finish" stage.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_tealLight.withOpacity(0.0), _tealLight.withOpacity(0.55)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(size.width * 0.25, size.height * 0.25, size.width * 0.4,
          size.height * 0.75, size.width * 0.65, size.height * 0.5)
      ..cubicTo(size.width * 0.85, size.height * 0.3, size.width * 0.95,
          size.height * 0.55, size.width, size.height * 0.45)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}

class _ForceUpdateOverlay extends StatelessWidget {
  final String message;
  final String updateUrl;
  const _ForceUpdateOverlay({required this.message, required this.updateUrl});

  Future<void> _openStore(BuildContext context) async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }

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
                if (updateUrl.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openStore(context),
                      icon: const Icon(Icons.system_update_alt_rounded),
                      label: const Text('Update Now'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
