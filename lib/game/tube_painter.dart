// lib/game/tube_painter.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Paints one glass test tube with its stack of glowing orbs.
/// When [selected], the top run of same-colored orbs hovers above the rim.
class TubePainter extends CustomPainter {
  final List<int> balls;
  final bool selected;
  final bool done;

  const TubePainter(
      {required this.balls, this.selected = false, this.done = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Reserve headroom above the tube for the lifted orb
    final lift = w * 1.05;
    final tubeTop = lift;
    final tubeRect = Rect.fromLTWH(w * 0.08, tubeTop, w * 0.84, h - tubeTop);
    final radius = Radius.circular(w * 0.42);

    final tubePath = Path()
      ..addRRect(RRect.fromRectAndCorners(tubeRect,
          bottomLeft: radius, bottomRight: radius));

    // glass body
    canvas.drawPath(tubePath, Paint()..color = kSurface.withOpacity(0.85));
    canvas.drawPath(
        tubePath,
        Paint()
          ..color = done
              ? kAccent.withOpacity(0.9)
              : selected
                  ? kAccent.withOpacity(0.8)
                  : kGlassEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected || done ? 2.4 : 1.6);
    if (done) {
      canvas.drawPath(
          tubePath,
          Paint()
            ..color = kAccent.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
    // rim
    canvas.drawLine(
        Offset(w * 0.02, tubeTop),
        Offset(w * 0.98, tubeTop),
        Paint()
          ..color = kGlassEdge
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
    // glass shine
    canvas.drawLine(
        Offset(w * 0.20, tubeTop + h * 0.06),
        Offset(w * 0.20, h - w * 0.45),
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..strokeWidth = w * 0.09
          ..strokeCap = StrokeCap.round);

    // orbs
    final orbR = w * 0.33;

    int liftedRun = 0;
    if (selected && balls.isNotEmpty) {
      final c = balls.last;
      for (int k = balls.length - 1; k >= 0 && balls[k] == c; k--) {
        liftedRun++;
      }
    }

    for (int i = 0; i < balls.length; i++) {
      final color = kBallColors[balls[i] % kBallColors.length];
      final isLifted = selected && i >= balls.length - liftedRun;
      double cy;
      if (isLifted) {
        final stackPos = balls.length - 1 - i; // 0 = topmost
        cy = lift * 0.55 + stackPos * orbR * 0.9;
      } else {
        cy = h - w * 0.14 - (i * orbR * 2.02) - orbR;
      }
      final cx = w / 2;
      // glow
      canvas.drawCircle(
          Offset(cx, cy),
          orbR * 1.12,
          Paint()
            ..color = color.withOpacity(isLifted ? 0.55 : 0.30)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, orbR * 0.35));
      // body with highlight
      canvas.drawCircle(
          Offset(cx, cy),
          orbR,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [
                Color.lerp(color, Colors.white, 0.45)!,
                color,
                Color.lerp(color, Colors.black, 0.25)!,
              ],
              stops: const [0.0, 0.65, 1.0],
            ).createShader(
                Rect.fromCircle(center: Offset(cx, cy), radius: orbR)));
    }
  }

  @override
  bool shouldRepaint(TubePainter old) =>
      old.balls != balls || old.selected != selected || old.done != done;
}
