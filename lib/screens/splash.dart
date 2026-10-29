import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/painters.dart';
import 'home.dart';

/// Kirish ekrani (B variant — chizma uslubi).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logo =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _rings =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _logo.dispose();
    _rings.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.blueprint,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BlueprintPainter())),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_logo, _rings]),
                    builder: (context, _) {
                      final a = _logo.value * 2 * math.pi;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: _rings.value * 2 * math.pi,
                            child: CustomPaint(size: const Size(220, 220), painter: _RingPainter(dashed: true)),
                          ),
                          Transform.rotate(
                            angle: -_rings.value * 2 * math.pi * 2.5,
                            child: CustomPaint(size: const Size(180, 180), painter: _RingPainter(dashed: false)),
                          ),
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(a),
                            child: const VmLogo(size: 132),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Text('SHITLAB',
                    style: mono(36, color: Colors.white, weight: FontWeight.w600).copyWith(letterSpacing: 2)),
                const SizedBox(height: 6),
                Text('LOYIHA · SXEMA · HISOB',
                    style: mono(12, color: const Color(0xFFBCD3F0), weight: FontWeight.w500)
                        .copyWith(letterSpacing: 1)),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _start,
                      child: SizedBox(
                        height: 58,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('BOSHLASH',
                                style: mono(16, color: C.blueprint).copyWith(letterSpacing: 2)),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward, color: C.blueprint, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Elektr shitlarini PUE bo\'yicha loyihalash',
                    style: TextStyle(fontSize: 12, color: Color(0xFFBCD3F0))),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final bool dashed;
  _RingPainter({required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    if (dashed) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x99DCEBFF);
      const n = 48;
      for (var k = 0; k < n; k++) {
        final a0 = k * 2 * math.pi / n;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0, math.pi / n, false, p);
      }
    } else {
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x59DCEBFF));
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          math.pi / 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ko'k chizma qog'ozi: katakchalar, ramka, bir chiziqli sxema va shtamp.
class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final minor = Paint()..color = const Color(0x09FFFFFF);
    final major = Paint()..color = const Color(0x17FFFFFF);
    for (double x = 0; x < w; x += 20) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, h), x % 100 == 0 ? major : minor);
    }
    for (double y = 0; y < h; y += 20) {
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1), y % 100 == 0 ? major : minor);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x73DCEBFF)
      ..strokeWidth = 1.2;
    canvas.drawRect(Rect.fromLTWH(14, 14, w - 28, h - 28), line);
    canvas.drawRect(
        Rect.fromLTWH(20, 20, w - 40, h - 40),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x33DCEBFF)
          ..strokeWidth = 0.8);

    final s = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x8CDCEBFF)
      ..strokeWidth = 1.6;
    final top = h * 0.09;
    final cx = w / 2;
    canvas.drawLine(Offset(cx, top - 30), Offset(cx, top), s);
    _breaker(canvas, Offset(cx, top), s);
    canvas.drawLine(Offset(cx, top + 44), Offset(cx, top + 56), s);
    canvas.drawLine(Offset(48, top + 56), Offset(w - 48, top + 56), Paint()..color = const Color(0x8CDCEBFF)..strokeWidth = 2.4);
    final n = 5;
    for (var k = 0; k < n; k++) {
      final x = 78 + k * (w - 156) / (n - 1);
      canvas.drawLine(Offset(x, top + 56), Offset(x, top + 70), s);
      _breaker(canvas, Offset(x, top + 70), s);
      canvas.drawLine(Offset(x, top + 114), Offset(x, top + 128), s);
      canvas.drawCircle(Offset(x, top + 136), 8, s);
      drawText(canvas, 'QF${k + 1}', Offset(x + 16, top + 86), size: 8, color: const Color(0x8CDCEBFF), center: false);
    }
    drawText(canvas, 'QF0 C32 3P', Offset(cx + 12, top + 18), size: 9, color: const Color(0x8CDCEBFF), center: false);

    final dim = Paint()
      ..color = const Color(0x59DCEBFF)
      ..strokeWidth = 1;
    final by = h * 0.76;
    canvas.drawLine(Offset(40, by), Offset(160, by), dim);
    canvas.drawLine(Offset(40, by - 6), Offset(40, by + 6), dim);
    canvas.drawLine(Offset(160, by - 6), Offset(160, by + 6), dim);
    drawText(canvas, '300 mm', Offset(100, by - 16), size: 9, color: const Color(0x73DCEBFF));

    final tb = Rect.fromLTWH(w - 154, 30, 128, 40);
    final tp = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x99DCEBFF)
      ..strokeWidth = 1;
    canvas.drawRect(tb, tp);
    canvas.drawLine(Offset(tb.left, tb.top + 20), Offset(tb.right, tb.top + 20), tp);
    canvas.drawLine(Offset(tb.left + 64, tb.top), Offset(tb.left + 64, tb.bottom), tp);
    const tc = Color(0x99DCEBFF);
    drawText(canvas, 'SHITLAB', Offset(tb.left + 6, tb.top + 5), size: 8, color: tc, center: false);
    drawText(canvas, 'VARAQ 1', Offset(tb.left + 70, tb.top + 5), size: 8, color: tc, center: false);
    drawText(canvas, 'PUE · 7.1', Offset(tb.left + 6, tb.top + 25), size: 8, color: tc, center: false);
    drawText(canvas, '1:1', Offset(tb.left + 70, tb.top + 25), size: 8, color: tc, center: false);
  }

  void _breaker(Canvas c, Offset o, Paint p) {
    c.drawLine(o, o.translate(0, 14), p);
    c.drawLine(o.translate(0, 30), o.translate(0, 44), p);
    c.drawLine(o.translate(0, 30), o.translate(9, 14), p);
    c.drawLine(o.translate(-3, 11), o.translate(3, 17), p);
    c.drawLine(o.translate(3, 11), o.translate(-3, 17), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
