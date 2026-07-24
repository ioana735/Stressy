import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/silk.dart';

/// Afiseaza o animatie de sarbatoare (cupa + confetti) daca [passed] e true,
/// sau un mesaj de incurajare daca e false.
Future<void> showResultCelebration(BuildContext context,
    {required bool passed}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'rezultat',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => _ResultDialog(passed: passed),
  );
}

class _ResultDialog extends StatefulWidget {
  final bool passed;
  const _ResultDialog({required this.passed});
  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  late final AnimationController _confetti = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500));

  @override
  void initState() {
    super.initState();
    if (widget.passed) _confetti.forward();
  }

  @override
  void dispose() {
    _pop.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.passed;
    return Stack(
      children: [
        if (passed)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confetti.value),
                ),
              ),
            ),
          ),
        Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Silk.bg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: Silk.raised(d: 10, blur: 20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(passed ? '🏆' : '💪',
                      style: TextStyle(fontSize: 76)),
                  const SizedBox(height: 12),
                  Text(
                    passed ? 'Felicitări! 🎉' : 'O să fie bine!',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Silk.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    passed
                        ? 'Ai trecut examenul! Munca ta a dat roade. 🌟'
                        : 'Nu-i nimic — data viitoare reușești. Fiecare încercare te face mai bun. 💜',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: Silk.onSurfaceVar,
                        height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  NeuButton(
                    filled: true,
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(passed ? 'Mulțumesc! 🎊' : 'Merg mai departe',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Confetti simplu, desenat procedural (fara pachet extern).
class _ConfettiPainter extends CustomPainter {
  final double t; // 0..1
  _ConfettiPainter(this.t);

  static final _rnd = math.Random(42);
  static final List<_Piece> _pieces = List.generate(
      60,
      (i) => _Piece(
            x: _rnd.nextDouble(),
            delay: _rnd.nextDouble() * 0.3,
            speed: 0.7 + _rnd.nextDouble() * 0.6,
            drift: (_rnd.nextDouble() - 0.5) * 0.3,
            color: [
              const Color(0xFF6366F1),
              const Color(0xFF7C3AED),
              const Color(0xFF22B07D),
              const Color(0xFFF2A93B),
              const Color(0xFFE5484D),
            ][i % 5],
            size: 6 + _rnd.nextDouble() * 8,
            rot: _rnd.nextDouble() * math.pi,
          ));

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final localT = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;
      final y = -20 + (size.height + 40) * localT * p.speed;
      final x = size.width * (p.x + p.drift * localT);
      final paint = Paint()..color = p.color.withValues(alpha: 1 - localT * 0.4);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + localT * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class _Piece {
  final double x, delay, speed, drift, size, rot;
  final Color color;
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.size,
    required this.rot,
    required this.color,
  });
}
