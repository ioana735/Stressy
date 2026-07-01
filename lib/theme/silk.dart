import 'package:flutter/material.dart';

/// Paleta + helperi pentru stilul neomorfic "Silk" (soft UI).
class Silk {
  // culori
  static const bg = Color(0xFFE8EAF0); // "clay"
  static const primary = Color(0xFF6366F1); // indigo
  static const violet = Color(0xFF7C3AED);
  static const onSurface = Color(0xFF2A2D3A);
  static const onSurfaceVar = Color(0xFF8A8FA3);
  static const success = Color(0xFF22B07D);

  // umbre neomorfice
  static const _dark = Color(0x14000000); // rgba(0,0,0,0.08)
  static const _light = Color(0x99FFFFFF); // rgba(255,255,255,0.6)

  /// Umbre pentru element RIDICAT (extrudat din suprafata).
  static List<BoxShadow> raised({double d = 6, double blur = 12}) => [
        BoxShadow(color: _dark, offset: Offset(d, d), blurRadius: blur),
        BoxShadow(color: _light, offset: Offset(-d, -d), blurRadius: blur),
      ];

  /// Umbre subtile pentru element ridicat mic.
  static List<BoxShadow> raisedSoft() => raised(d: 4, blur: 8);
}

/// Card / suprafata ridicata neomorfica.
class Neu extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool small;

  const Neu({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Silk.bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: small ? Silk.raisedSoft() : Silk.raised(),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

/// Suprafata "infundata" (inset) — aproximata cu gradient + umbra interioara.
class NeuInset extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const NeuInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsetPainter(radius),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _InsetPainter extends CustomPainter {
  final double radius;
  _InsetPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, Radius.circular(radius));
    // fundal usor mai inchis
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFDFE2EA));
    canvas.save();
    canvas.clipRRect(rrect);
    // umbra interioara sus-stanga (intunecat)
    final dark = Paint()
      ..color = const Color(0x12000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
        rrect.shift(const Offset(3, 3)),
        dark..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // lumina interioara jos-dreapta
    final light = Paint()
      ..color = const Color(0x80FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(rrect.shift(const Offset(-3, -3)), light);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter old) => false;
}

/// Buton neomorfic ridicat (varianta plina indigo sau pe suprafata).
class NeuButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool filled;
  final EdgeInsetsGeometry padding;
  final double radius;

  const NeuButton({
    super.key,
    required this.child,
    required this.onTap,
    this.filled = false,
    this.padding = const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
    this.radius = 20,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: filled ? Silk.primary : Silk.bg,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _down
              ? []
              : (filled
                  ? [
                      BoxShadow(
                          color: Silk.primary.withValues(alpha: 0.4),
                          offset: const Offset(0, 6),
                          blurRadius: 14),
                    ]
                  : Silk.raised()),
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}
