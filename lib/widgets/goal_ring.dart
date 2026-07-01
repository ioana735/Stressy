import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/silk.dart';

/// Inel circular de progres catre obiectivul zilnic, stil Silk.
class GoalRing extends StatelessWidget {
  final int minutesToday;
  final int goalMinutes;
  final double size;

  const GoalRing({
    super.key,
    required this.minutesToday,
    required this.goalMinutes,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        goalMinutes == 0 ? 0.0 : (minutesToday / goalMinutes).clamp(0.0, 1.0);
    final reached = minutesToday >= goalMinutes;
    final color = reached ? Silk.success : Silk.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Silk.bg,
        boxShadow: Silk.raised(d: 8, blur: 16),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, value, __) => CustomPaint(
          painter: _RingPainter(value, color),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$minutesToday / $goalMinutes',
                    style: TextStyle(
                        fontSize: size * 0.16,
                        fontWeight: FontWeight.w800,
                        color: Silk.onSurface,
                        height: 1)),
                Text('MIN',
                    style: TextStyle(
                        fontSize: size * 0.06,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        color: Silk.onSurfaceVar)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      reached ? '✓ 100%' : '${(progress * 100).round()}%',
                      style: TextStyle(
                          fontSize: size * 0.07,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 22;
    final track = Paint()
      ..color = const Color(0xFFDDE0E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [color, Silk.violet, color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
