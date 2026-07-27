import 'dart:math' as math;

import 'package:flutter/material.dart';

// Brand marks — fixed to the EazyDoctor logo identity regardless of the
// superadmin-configurable app theme, matching splash_screen.dart so the
// same mark appears everywhere (splash, login, signup, forgot password).
const kBrandNavy = Color(0xFF163A73);
const kBrandTeal = Color(0xFF1AA391);
const kBrandTealLight = Color(0xFF6FD6C4);

/// Static (fully-revealed, non-animated) version of the splash screen's
/// stethoscope + "D" mark, for reuse as a header logo on auth screens.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StaticLogoPainter()),
    );
  }
}

/// Logo mark + "EazyDoctor" wordmark, stacked — the compact header used at
/// the top of the login/signup/forgot-password screens.
class BrandHeader extends StatelessWidget {
  final double logoSize;
  final String? tagline;
  const BrandHeader({super.key, this.logoSize = 72, this.tagline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandMark(size: logoSize),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.2),
            children: [
              TextSpan(text: 'Eazy', style: TextStyle(color: kBrandNavy)),
              TextSpan(text: 'Doctor', style: TextStyle(color: kBrandTeal)),
            ],
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 4),
          Text(tagline!,
              style: TextStyle(
                  color: Colors.black.withOpacity(0.55), fontSize: 13)),
        ],
      ],
    );
  }
}

class _StaticLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 200; // painter geometry was authored at 200px

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [kBrandNavy, kBrandTeal],
    ).createShader(Rect.fromCircle(center: center, radius: 90));

    // "D" outer ring.
    final ringRect = Rect.fromCircle(center: center, radius: 62);
    final ringPath = Path()..addArc(ringRect, -math.pi / 2, math.pi * 1.55);
    final ringPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(ringPath, ringPaint);

    // Stethoscope tube.
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
      ..color = kBrandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(tube, tubePaint);
    canvas.drawPath(tube2, tubePaint);

    // Chest-piece circle.
    final chestCenter = Offset(center.dx + 2, center.dy + 22);
    final outer = Paint()
      ..color = kBrandNavy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final inner = Paint()..color = kBrandTealLight;
    canvas.drawCircle(chestCenter, 8, outer);
    canvas.drawCircle(chestCenter, 4.5, inner);

    // Cross.
    final crossPaint = Paint()..color = kBrandTeal;
    final crossCenter = center + const Offset(10, -8);
    const armLong = 26.0;
    const armShort = 8.0;
    final vRect = Rect.fromCenter(
        center: crossCenter, width: armShort * 2, height: armLong * 2);
    final hRect = Rect.fromCenter(
        center: crossCenter, width: armLong * 2, height: armShort * 2);
    final rrV = RRect.fromRectAndRadius(vRect, Radius.circular(armShort * 0.5));
    final rrH = RRect.fromRectAndRadius(hRect, Radius.circular(armShort * 0.5));
    canvas.drawRRect(rrV, crossPaint);
    canvas.drawRRect(rrH, crossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StaticLogoPainter oldDelegate) => false;
}
