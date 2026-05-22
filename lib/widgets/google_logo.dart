import 'package:flutter/material.dart';

/// Paints the official Google "G" logo using brand colors.
/// Usage: CustomPaint(painter: GoogleLogoPainter(), size: Size(20, 20))
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    const colorBlue   = Color(0xFF4285F4);
    const colorRed    = Color(0xFFEA4335);
    const colorYellow = Color(0xFFFBBC05);
    const colorGreen  = Color(0xFF34A853);

    final paint = Paint()..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    final double strokeW = w * 0.22;

    paint.strokeWidth = strokeW;
    paint.strokeCap = StrokeCap.butt;

    // Red arc (top)
    paint.color = colorRed;
    canvas.drawArc(rect.deflate(strokeW / 2), _deg(225), _deg(90), false, paint);

    // Yellow arc (bottom-left)
    paint.color = colorYellow;
    canvas.drawArc(rect.deflate(strokeW / 2), _deg(135), _deg(90), false, paint);

    // Green arc (bottom-right)
    paint.color = colorGreen;
    canvas.drawArc(rect.deflate(strokeW / 2), _deg(45), _deg(90), false, paint);

    // Blue arc (top-right, partial — stops at horizontal midpoint)
    paint.color = colorBlue;
    canvas.drawArc(rect.deflate(strokeW / 2), _deg(-45), _deg(90), false, paint);

    // Blue horizontal crossbar of the "G"
    final barPaint = Paint()
      ..color = colorBlue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        w / 2,
        h / 2 - strokeW / 2,
        w / 2 - strokeW * 0.15,
        strokeW,
      ),
      barPaint,
    );

    // White inner circle to create the hollow center
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2 - strokeW, whitePaint);
  }

  double _deg(double degrees) => degrees * 3.14159265358979 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
