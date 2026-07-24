import 'package:flutter/material.dart';

/// Paleta + helperi pentru stilul neomorfic "Silk" (soft UI).
/// Suporta mod deschis/intunecat prin flag-ul [dark] (setat in StressyApp).
class Silk {
  /// Tema curenta. Setat de StressyApp inainte de build.
  static bool dark = false;

  // culori de brand (la fel pe ambele teme)
  static const primary = Color(0xFF6366F1); // indigo
  static const violet = Color(0xFF7C3AED);
  static const success = Color(0xFF22B07D);

  // culori dependente de tema
  static Color get bg =>
      dark ? const Color(0xFF14161C) : const Color(0xFFE8EAF0);
  static Color get surface =>
      dark ? const Color(0xFF23262F) : Colors.white;
  static Color get onSurface =>
      dark ? const Color(0xFFECEEF3) : const Color(0xFF2A2D3A);
  static Color get onSurfaceVar =>
      dark ? const Color(0xFF9BA0AE) : const Color(0xFF8A8FA3);
  static Color get track =>
      dark ? const Color(0xFF31343E) : const Color(0xFFDDE0E8);
  static Color get inset =>
      dark ? const Color(0xFF1A1C22) : const Color(0xFFDFE2EA);
  static Color get divider =>
      dark ? const Color(0x1FFFFFFF) : const Color(0x11000000);

  /// Umbre pentru element RIDICAT (extrudat din suprafata).
  static List<BoxShadow> raised({double d = 6, double blur = 12}) => dark
      ? [
          BoxShadow(
              color: const Color(0x80000000),
              offset: Offset(d, d),
              blurRadius: blur),
          BoxShadow(
              color: const Color(0x0DFFFFFF),
              offset: Offset(-d, -d),
              blurRadius: blur),
        ]
      : [
          BoxShadow(
              color: const Color(0x14000000),
              offset: Offset(d, d),
              blurRadius: blur),
          BoxShadow(
              color: const Color(0x99FFFFFF),
              offset: Offset(-d, -d),
              blurRadius: blur),
        ];

  /// Umbre subtile pentru element ridicat mic.
  static List<BoxShadow> raisedSoft() => raised(d: 4, blur: 8);
}

/// Antet de bottom sheet: titlu centrat + buton X de inchidere.
class SheetHeader extends StatelessWidget {
  final String title;
  const SheetHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Silk.onSurface)),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Silk.bg,
              shape: BoxShape.circle,
              boxShadow: Silk.raisedSoft(),
            ),
            child: Icon(Icons.close_rounded,
                color: Silk.onSurfaceVar, size: 20),
          ),
        ),
      ],
    );
  }
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
    // fundal infundat
    canvas.drawRRect(rrect, Paint()..color = Silk.inset);
    canvas.save();
    canvas.clipRRect(rrect);
    // umbra interioara sus-stanga (intunecat)
    final dark = Paint()
      ..color = Silk.dark ? const Color(0x40000000) : const Color(0x12000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
        rrect.shift(const Offset(3, 3)),
        dark..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // lumina interioara jos-dreapta
    final light = Paint()
      ..color =
          Silk.dark ? const Color(0x0DFFFFFF) : const Color(0x80FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(rrect.shift(const Offset(-3, -3)), light);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter old) => true;
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
