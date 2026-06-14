// lib/screens/home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = Preferences.instance.getCompletedCount();
    final totalStars = Preferences.instance.getTotalStars();

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _BubblesPainter(_ctrl.value),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),
            // mini tube emblem
            SizedBox(
              width: 170,
              height: 110,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _miniTube([0, 0, 1]),
                  const SizedBox(width: 14),
                  _miniTube([1, 1, 0]),
                  const SizedBox(width: 14),
                  _miniTube([4, 4, 4, 4], done: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('SORTLAB',
                style: techno(44,
                    color: kAccent, weight: FontWeight.w900, letterSpacing: 9)),
            const SizedBox(height: 8),
            Text('POUR  ·  SORT  ·  PERFECT',
                style: techno(12, color: kTextDim, letterSpacing: 4)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _chip(Icons.check_circle_outline, '$completed / $kTotalLevels',
                  kEasyColor),
              const SizedBox(width: 14),
              _chip(Icons.star, '$totalStars', kStarOn),
            ]),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(children: [
                _btn('PLAY', Icons.play_arrow_rounded, true, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen()));
                }),
                const SizedBox(height: 14),
                _btn('SETTINGS', Icons.tune_rounded, false, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                }),
              ]),
            ),
            const SizedBox(height: 56),
          ]),
        ),
      ]),
    );
  }

  Widget _miniTube(List<int> balls, {bool done = false}) => Container(
        width: 34,
        height: 96,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(17)),
          border: Border.all(
              color: done ? kAccent : kGlassEdge, width: done ? 2 : 1.4),
          boxShadow: done
              ? [BoxShadow(color: kAccent.withOpacity(0.35), blurRadius: 14)]
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: balls.reversed
              .map((b) => Container(
                    width: 24,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.4),
                        colors: [
                          Color.lerp(kBallColors[b], Colors.white, 0.4)!,
                          kBallColors[b],
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: techno(13)),
        ]),
      );

  Widget _btn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF0C9D7B), Color(0xFF14C99C)])
                : null,
            color: primary ? null : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.7) : kBorder,
                width: primary ? 1.5 : 1),
            boxShadow: primary
                ? [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 22)]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? kBg : kTextDim, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: techno(15,
                    color: primary ? kBg : kTextDim, letterSpacing: 3)),
          ]),
        ),
      );
}

/// Slow bubbles rising through the lab
class _BubblesPainter extends CustomPainter {
  final double t;
  _BubblesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(31);
    for (int i = 0; i < 26; i++) {
      final x = rng.nextDouble() * size.width +
          sin(t * 2 * pi + i) * 12;
      final speed = 0.4 + rng.nextDouble();
      final y = size.height -
          ((t * speed + rng.nextDouble()) % 1.0) * (size.height + 60) +
          30;
      final r = 2.0 + rng.nextDouble() * 5;
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = kAccent.withOpacity(0.07 + rng.nextDouble() * 0.06)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter o) => o.t != t;
}
