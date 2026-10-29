import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

void drawText(Canvas canvas, String text, Offset at,
    {double size = 10,
    Color color = C.text,
    FontWeight weight = FontWeight.w600,
    bool center = true,
    bool monoText = true,
    double maxWidth = 200}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontFamily: monoText ? monoFont : null,
      ),
    ),
    textAlign: center ? TextAlign.center : TextAlign.left,
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(maxWidth: maxWidth);
  final dx = center ? at.dx - tp.width / 2 : at.dx;
  tp.paint(canvas, Offset(dx, at.dy));
}

/// VM logotipi (shisha uslub): binafsha-moviy fon, VM harflari, avtomatlar.
class VmLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    final r = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 108, 108), const Radius.circular(26));
    canvas.clipRRect(r);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 108, 108),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
        ).createShader(const Rect.fromLTWH(0, 0, 108, 108)),
    );
    canvas.drawCircle(const Offset(92, 14), 22, Paint()..color = const Color(0x29FFFFFF));
    canvas.drawCircle(const Offset(10, 100), 24, Paint()..color = const Color(0x1AFFFFFF));
    final inner = RRect.fromRectAndRadius(const Rect.fromLTWH(13, 13, 82, 82), const Radius.circular(15));
    canvas.drawRRect(inner, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawRRect(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x99FFFFFF));

    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xBFFFFFFF);
    canvas.drawLine(const Offset(21, 21), const Offset(87, 21), thin);
    for (final x in [33.0, 54.0, 75.0]) {
      canvas.drawLine(Offset(x, 21), Offset(x, 26), thin);
      canvas.drawLine(Offset(x, 26), Offset(x + 4, 22.5), thin);
      canvas.drawLine(Offset(x, 29), Offset(x, 32), thin);
    }

    final vm = Path()
      ..moveTo(26, 38)
      ..lineTo(36, 63)
      ..lineTo(46, 38)
      ..moveTo(57, 63)
      ..lineTo(57, 38)
      ..lineTo(68, 53)
      ..lineTo(79, 38)
      ..lineTo(79, 63);
    canvas.drawPath(
        vm,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white);

    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, 78, 70, 3), const Radius.circular(1.5)),
        Paint()..color = const Color(0xB3FFFFFF));
    final white = Paint()..color = Colors.white;
    final amber = Paint()..color = const Color(0xFFF59E0B);
    final green = Paint()..color = const Color(0xFF22C55E);
    for (final x in [24.0, 38.0, 52.0]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 71, 11, 17), const Radius.circular(2)), white);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 3.5, 74, 4, 6), const Radius.circular(1)), amber);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 71, 18, 17), const Radius.circular(2)), white);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(69, 74, 4, 6), const Radius.circular(1)), green);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(77, 74, 4, 6), const Radius.circular(1)), green);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VmLogo extends StatelessWidget {
  final double size;
  const VmLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: VmLogoPainter()));
}

/// Modulli avtomat ko'rinishi.
class BreakerPainter extends CustomPainter {
  final String label;
  final String sub;
  final int poles;
  final bool on;

  BreakerPainter({required this.label, this.sub = '4500 · 230V', this.poles = 1, this.on = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyW = math.min(w, h * 0.42 * poles);
    final left = (w - bodyW) / 2;
    final rail = Paint()..color = const Color(0xFF5A6370);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left - 4, h - 12, bodyW + 8, 10), const Radius.circular(2)), rail);
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(left, 4, bodyW, h - 12), const Radius.circular(6));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFE6E9ED));
    canvas.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFB7BEC8));
    final band = Paint()..color = const Color(0xFFD3D8DF);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, 4, bodyW, h * 0.17), const Radius.circular(6)), band);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, h - 8 - h * 0.18, bodyW, h * 0.18), const Radius.circular(6)),
        band);
    final screw = Paint()..color = const Color(0xFF9AA3AE);
    final slot = Paint()
      ..color = const Color(0xFF5A6370)
      ..strokeWidth = 2;
    final poleW = bodyW / poles;
    for (var k = 0; k < poles; k++) {
      final cx = left + poleW * (k + 0.5);
      final rr = math.min(poleW * 0.16, 7.0);
      canvas.drawCircle(Offset(cx, 4 + h * 0.085), rr, screw);
      canvas.drawLine(Offset(cx - rr * 0.7, 4 + h * 0.085), Offset(cx + rr * 0.7, 4 + h * 0.085), slot);
      final by = h - 8 - h * 0.09;
      canvas.drawCircle(Offset(cx, by), rr, screw);
      canvas.drawLine(Offset(cx - rr * 0.7, by), Offset(cx + rr * 0.7, by), slot);
    }
    final face = Rect.fromLTWH(left + bodyW * 0.11, h * 0.25, bodyW * 0.78, h * 0.47);
    canvas.drawRRect(RRect.fromRectAndRadius(face, const Radius.circular(4)), Paint()..color = const Color(0xFFF5F6F8));
    final win = Rect.fromLTWH(left + bodyW * 0.25, h * 0.29, bodyW * 0.5, h * 0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(3)), Paint()..color = const Color(0xFF2A2F37));
    final lever = Rect.fromLTWH(win.left + 2, on ? win.top + 2 : win.center.dy, win.width - 4, win.height / 2 - 2);
    canvas.drawRRect(RRect.fromRectAndRadius(lever, const Radius.circular(2)),
        Paint()..color = on ? const Color(0xFF5B6573) : const Color(0xFF8A94A6));
    drawText(canvas, label, Offset(left + bodyW / 2, h * 0.52), size: math.min(13.0, bodyW * 0.22), color: const Color(0xFF1B1F26));
    drawText(canvas, sub, Offset(left + bodyW / 2, h * 0.62),
        size: math.min(7.0, bodyW * 0.12), color: const Color(0xFF5A6370), weight: FontWeight.w500);
  }

  @override
  bool shouldRepaint(covariant BreakerPainter old) => old.label != label || old.poles != poles || old.on != on;
}

/// Kabel uchi: qobiq va rangli tomirlar.
class CablePainter extends CustomPainter {
  final Color sheath;
  final String label;
  final int cores;

  CablePainter({required this.sheath, required this.label, this.cores = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cy = h / 2;
    final sheathW = w * 0.5;
    final sh = RRect.fromRectAndRadius(Rect.fromLTWH(0, cy - h * 0.15, sheathW, h * 0.3), const Radius.circular(6));
    canvas.drawRRect(sh, Paint()..color = sheath);
    final light = sheath.computeLuminance() > 0.5;
    drawText(canvas, label, Offset(sheathW / 2, cy - 5),
        size: 7.5, color: light ? const Color(0xFF2B2F36) : const Color(0xFFB7BEC8), weight: FontWeight.w700);
    canvas.drawOval(Rect.fromCenter(center: Offset(sheathW, cy), width: 10, height: h * 0.3),
        Paint()..color = const Color(0xFF3A3F48));

    final colors = cores == 5
        ? [const Color(0xFF8B5A2B), const Color(0xFF1E1E1E), const Color(0xFF8C939A), const Color(0xFF2F6FD6), const Color(0xFFE3C42A)]
        : [const Color(0xFF8B5A2B), const Color(0xFF2F6FD6), const Color(0xFFE3C42A)];
    final spread = h * 0.32;
    final end = w * 0.86;
    for (var k = 0; k < colors.length; k++) {
      final t = colors.length == 1 ? 0.0 : k / (colors.length - 1) - 0.5;
      final y0 = cy + t * h * 0.14;
      final y1 = cy + t * 2 * spread;
      final path = Path()
        ..moveTo(sheathW, y0)
        ..cubicTo(sheathW + w * 0.12, y0, end - w * 0.14, y1, end, y1);
      final isPe = k == colors.length - 1;
      final stroke = cores == 5 ? 5.5 : 8.0;
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = colors[k]);
      if (isPe) {
        // sariq-yashil chiziqlar
        final metric = path.computeMetrics().first;
        final green = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = const Color(0xFF2FA24E);
        for (double d = 4; d < metric.length; d += 12) {
          canvas.drawPath(metric.extractPath(d, math.min(d + 6, metric.length)), green);
        }
      }
      canvas.drawLine(
          Offset(end, y1),
          Offset(w - 2, y1),
          Paint()
            ..strokeWidth = cores == 5 ? 3.5 : 5
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFC98A3D));
    }
  }

  @override
  bool shouldRepaint(covariant CablePainter old) =>
      old.sheath != sheath || old.label != label || old.cores != cores;
}

/// Shit korpusi kichik rasmi (ro'yxat uchun).
class PanelThumbPainter extends CustomPainter {
  final String kind;
  PanelThumbPainter(this.kind);

  void _modules(Canvas c, Rect row, int n) {
    c.drawRRect(RRect.fromRectAndRadius(row, const Radius.circular(2)), Paint()..color = const Color(0xFF2A2F37));
    final mw = (row.width - 6) / n;
    for (var k = 0; k < n; k++) {
      c.drawRect(Rect.fromLTWH(row.left + 3 + k * mw + 0.6, row.top + 3, mw - 1.2, row.height - 6),
          Paint()..color = const Color(0xFFE6E9ED));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final metal = Paint()..color = const Color(0xFFC9CED6);
    final metalIn = Paint()..color = const Color(0xFFB3BAC4);
    final dark = Paint()..color = const Color(0xFF8B95A2);
    switch (kind) {
      case 'shrn24':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.72, height: h * 0.92);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), metal);
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(3)), metalIn);
          _modules(canvas, Rect.fromLTWH(r.left + 8, r.top + r.height * 0.15, r.width - 16, r.height * 0.22), 5);
          _modules(canvas, Rect.fromLTWH(r.left + 8, r.top + r.height * 0.46, r.width - 16, r.height * 0.22), 4);
          break;
        }
      case 'shrv18':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.86, height: h * 0.86);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFE1E4E8));
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(7), const Radius.circular(3)), metalIn);
          _modules(canvas, Rect.fromLTWH(r.left + 12, r.top + r.height * 0.36, r.width - 24, r.height * 0.26), 7);
          break;
        }
      case 'shurn':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.66, height: h * 0.94);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), metal);
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(3)), metalIn);
          final m = Rect.fromLTWH(r.left + 8, r.top + 8, r.width - 16, r.height * 0.32);
          canvas.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2)), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawRect(m.deflate(5), Paint()..color = const Color(0xFFE6E9ED));
          canvas.drawRect(Rect.fromLTWH(m.left + 8, m.top + 8, m.width - 16, 6), Paint()..color = const Color(0xFF173A28));
          _modules(canvas, Rect.fromLTWH(r.left + 8, r.top + r.height * 0.52, r.width - 16, r.height * 0.22), 4);
          break;
        }
      case 'ip65':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.8, height: h * 0.74);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = const Color(0xFFEEF0F3));
          _modules(canvas, Rect.fromLTWH(r.left + 8, r.top + r.height * 0.3, r.width - 16, r.height * 0.32), 6);
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 5, r.top + r.height * 0.2, r.width - 10, r.height * 0.52),
                  const Radius.circular(5)),
              Paint()..color = const Color(0x595B8FD6));
          break;
        }
      case 'shmp':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.9, height: h * 0.7);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF9EA7B3));
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(2)), Paint()..color = const Color(0xFF8B95A2));
          final lock = Paint()..color = const Color(0xFF2A2F37);
          canvas.drawCircle(Offset(r.right - 10, r.top + r.height * 0.3), 3, lock);
          canvas.drawCircle(Offset(r.right - 10, r.top + r.height * 0.7), 3, lock);
          break;
        }
      case 'vru':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.5, height: h * 0.96);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFF9EA7B3));
          canvas.drawLine(Offset(r.center.dx, r.top + 2), Offset(r.center.dx, r.bottom - 2),
              Paint()..color = const Color(0xFF76808D)..strokeWidth = 1.5);
          canvas.drawRect(Rect.fromLTWH(r.center.dx - 6, r.center.dy - 4, 2, 8), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawRect(Rect.fromLTWH(r.center.dx + 4, r.center.dy - 4, 2, 8), Paint()..color = const Color(0xFF2A2F37));
          break;
        }
      case 'rza':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.56, height: h * 0.96);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFB9C0CA));
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(2)), Paint()..color = const Color(0xFFA7AFBA));
          final colors = [const Color(0xFFE5534B), const Color(0xFF3FB37F), const Color(0xFFF2C230)];
          for (var k = 0; k < 3; k++) {
            canvas.drawCircle(Offset(r.left + r.width * (0.25 + k * 0.25), r.top + 12), 3, Paint()..color = colors[k]);
          }
          canvas.drawRect(Rect.fromLTWH(r.left + 7, r.top + 22, r.width / 2 - 10, 12), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawRect(Rect.fromLTWH(r.center.dx + 3, r.top + 22, r.width / 2 - 10, 12), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawCircle(Offset(r.left + r.width * 0.3, r.center.dy + 8), 4, Paint()..color = const Color(0xFF5A6370));
          canvas.drawCircle(Offset(r.left + r.width * 0.7, r.center.dy + 8), 4, Paint()..color = const Color(0xFF5A6370));
          break;
        }
      case 'custom':
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.72, height: h * 0.84);
          final p = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = C.amber;
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), p);
          canvas.drawLine(Offset(r.left, r.bottom + 5), Offset(r.right, r.bottom + 5), p..strokeWidth = 1);
          canvas.drawLine(Offset(r.right + 5, r.top), Offset(r.right + 5, r.bottom), p);
          break;
        }
      default:
        {
          final r = Rect.fromCenter(center: Offset(w / 2, h / 2), width: w * 0.72, height: h * 0.86);
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), metal);
          canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(3)), metalIn);
          _modules(canvas, Rect.fromLTWH(r.left + 8, r.top + r.height * 0.32, r.width - 16, r.height * 0.28), 6);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.right - 9, r.top + r.height * 0.7, 3, 10), const Radius.circular(1.5)), dark);
        }
    }
  }

  @override
  bool shouldRepaint(covariant PanelThumbPainter old) => old.kind != kind;
}
