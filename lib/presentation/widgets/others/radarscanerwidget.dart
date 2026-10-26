import 'dart:math';
import 'package:flutter/material.dart';

class RadarScanWidget extends StatefulWidget {
  final double size;

  const RadarScanWidget({Key? key, this.size = 200}) : super(key: key);

  @override
  State<RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<RadarScanWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(painter: _RadarPainter(_controller.value));
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double rotation;

  _RadarPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw radar background
    final bgPaint =
        Paint()
          ..color = Colors.green.withOpacity(0.05)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw concentric circles
    final circlePaint =
        Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, circlePaint);
    }

    // Draw cross lines
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      circlePaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      circlePaint,
    );

    // Draw rotating triangle beam
    final beamPaint =
        Paint()
          ..color = Colors.green.withOpacity(0.4)
          ..style = PaintingStyle.fill;

    const beamAngle = pi / 4; // ~10 degrees

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(2 * pi * rotation);

    Path triangle = Path()..moveTo(0, 0);
    triangle.arcTo(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      0,
      beamAngle,
      false,
    );
    triangle.close();

    canvas.drawPath(triangle, beamPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
