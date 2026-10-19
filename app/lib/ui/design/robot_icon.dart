import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Robot vacuum seen from above (round body, laser turret, bumper in front).
/// Material's icons only have "toy" robots; this is the one users recognise.
class RobotVacuumIcon extends StatelessWidget {
  final double size;
  final Color? color;

  /// Charging bolt over the robot (charging on the dock).
  final bool charging;

  const RobotVacuumIcon({super.key, this.size = 24, this.color, this.charging = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: charging ? context.l.robotCharging : context.l.robot,
      child: CustomPaint(size: Size.square(size), painter: _RobotPainter(c, charging)),
    );
  }
}

class _RobotPainter extends CustomPainter {
  final Color color;
  final bool charging;

  _RobotPainter(this.color, this.charging);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s * 0.42;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..color = color;
    // Corpo.
    canvas.drawCircle(c, r, stroke);
    // Bumper: an arc in front (at the top), slightly inside the body.
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.72), -math.pi * 0.82, math.pi * 0.64, false, stroke);
    if (charging) {
      final bolt = Path()
        ..moveTo(c.dx + s * 0.05, c.dy - s * 0.10)
        ..lineTo(c.dx - s * 0.09, c.dy + s * 0.05)
        ..lineTo(c.dx + s * 0.01, c.dy + s * 0.05)
        ..lineTo(c.dx - s * 0.04, c.dy + s * 0.20)
        ..lineTo(c.dx + s * 0.10, c.dy + s * 0.01)
        ..lineTo(c.dx, c.dy + s * 0.01)
        ..close();
      canvas.drawPath(bolt, Paint()..color = color);
    } else {
      // Laser turret in the middle.
      canvas.drawCircle(c.translate(0, s * 0.06), s * 0.11, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RobotPainter old) => old.color != color || old.charging != charging;
}
