import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../reference.dart';
import '../theme.dart';
import 'painters.dart';

/// Ma'lumotnomadagi qurilmaning chizmasi.
class DevicePainter extends CustomPainter {
  final RefItem item;
  DevicePainter(this.item);

  @override
  void paint(Canvas canvas, Size size) {
    switch (item.face) {
      case 'breaker':
        BreakerPainter(label: item.label).paint(canvas, size);
        return;
      case 'cable':
        CablePainter(sheath: const Color(0xFF2B2F36), label: 'ВВГнг-LS ${item.label}').paint(canvas, size);
        return;
      case 'tip':
        _tip(canvas, size);
        return;
    }
    final w = size.width, h = size.height;
    final n = math.max(1, item.modules);
    final mw = math.min(w / n, h * 0.42);
    final bw = mw * n;
    final left = (w - bw) / 2;
    final top = 4.0;
    final bh = h - 14;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left - 4, h - 12, bw + 8, 10), const Radius.circular(2)),
        Paint()..color = const Color(0xFF5A6370));
    final body = Rect.fromLTWH(left, top, bw, bh);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), Paint()..color = const Color(0xFFE6E9ED));
    for (var k = 1; k < n; k++) {
      canvas.drawLine(Offset(left + mw * k, top + 2), Offset(left + mw * k, top + bh - 2),
          Paint()..color = const Color(0xFFC9CFD6));
    }
    final band = Paint()..color = const Color(0xFFD3D8DF);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, bw, bh * 0.17), const Radius.circular(6)), band);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top + bh * 0.83, bw, bh * 0.17), const Radius.circular(6)), band);
    // klemmalar
    final screw = Paint()..color = const Color(0xFF9AA3AE);
    for (var k = 0; k < n; k++) {
      final cx = left + mw * (k + 0.5);
      final rr = math.min(mw * 0.15, 6.0);
      canvas.drawCircle(Offset(cx, top + bh * 0.085), rr, screw);
      canvas.drawCircle(Offset(cx, top + bh * 0.915), rr, screw);
    }
    // rang chizig'i
    canvas.drawRect(Rect.fromLTWH(left + 3, top + bh * 0.77, bw - 6, 5), Paint()..color = item.stripe);
    final face = Rect.fromLTWH(left + bw * 0.1, top + bh * 0.24, bw * 0.8, bh * 0.48);

    switch (item.face) {
      case 'uzo':
      case 'dif':
        {
          final lever = Rect.fromLTWH(left + mw * 0.2, face.top + 4, mw * 0.6, face.height * 0.42);
          canvas.drawRRect(RRect.fromRectAndRadius(lever, const Radius.circular(3)), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawCircle(Offset(left + mw * 1.5, face.top + face.height * 0.22), math.min(mw * 0.22, 9.0),
              Paint()..color = const Color(0xFFF2C230));
          drawText(canvas, 'T', Offset(left + mw * 1.5, face.top + face.height * 0.22 - 6), size: 9, color: C.ink);
          drawText(canvas, item.label, Offset(left + bw / 2, face.top + face.height * 0.6),
              size: math.min(12.0, bw * 0.16), color: const Color(0xFF1B1F26));
          break;
        }
      case 'lcd':
        {
          final lcd = Rect.fromLTWH(face.left, face.top + 4, face.width, face.height * 0.36);
          canvas.drawRRect(RRect.fromRectAndRadius(lcd, const Radius.circular(3)), Paint()..color = const Color(0xFF173A28));
          drawText(canvas, item.label, Offset(lcd.center.dx, lcd.top + lcd.height * 0.18),
              size: math.min(13.0, lcd.height * 0.55), color: const Color(0xFF6BE09F));
          for (final dx in [0.3, 0.7]) {
            canvas.drawCircle(Offset(left + bw * dx, face.top + face.height * 0.72), math.min(bw * 0.07, 6.0),
                Paint()..color = const Color(0xFF9AA3AE));
          }
          break;
        }
      case 'contactor':
        {
          canvas.drawRRect(
              RRect.fromRectAndRadius(Rect.fromLTWH(face.left, face.top, face.width, face.height * 0.55), const Radius.circular(3)),
              Paint()..color = const Color(0xFF2A2F37));
          drawText(canvas, item.label, Offset(face.center.dx, face.top + face.height * 0.62),
              size: math.min(12.0, bw * 0.17), color: const Color(0xFF1B1F26));
          break;
        }
      case 'led':
        {
          canvas.drawCircle(Offset(face.center.dx, face.top + face.height * 0.3), math.min(bw * 0.22, 10.0),
              Paint()..color = item.stripe);
          drawText(canvas, item.label, Offset(face.center.dx, face.top + face.height * 0.6),
              size: math.min(11.0, bw * 0.3), color: const Color(0xFF1B1F26));
          break;
        }
      case 'fuse':
        {
          final f = Rect.fromLTWH(face.left + face.width * 0.15, face.top, face.width * 0.7, face.height * 0.7);
          canvas.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(4)), Paint()..color = const Color(0xFF2A2F37));
          canvas.drawRRect(RRect.fromRectAndRadius(f.deflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFFD9C9A3));
          drawText(canvas, item.label, Offset(face.center.dx, face.top + face.height * 0.74),
              size: math.min(10.0, bw * 0.28), color: const Color(0xFF1B1F26));
          break;
        }
      case 'switch':
        {
          final lever = Rect.fromLTWH(face.left + face.width * 0.1, face.top + 2, face.width * 0.8, face.height * 0.45);
          canvas.drawRRect(RRect.fromRectAndRadius(lever, const Radius.circular(3)), Paint()..color = const Color(0xFFD9382C));
          drawText(canvas, item.label, Offset(face.center.dx, face.top + face.height * 0.58),
              size: math.min(12.0, bw * 0.17), color: const Color(0xFF1B1F26));
          break;
        }
      case 'meter':
        {
          final lcd = Rect.fromLTWH(face.left, face.top, face.width, face.height * 0.36);
          canvas.drawRRect(RRect.fromRectAndRadius(lcd, const Radius.circular(3)), Paint()..color = const Color(0xFF173A28));
          drawText(canvas, '012345', Offset(lcd.center.dx, lcd.top + lcd.height * 0.2),
              size: math.min(13.0, lcd.height * 0.55), color: const Color(0xFF6BE09F));
          drawText(canvas, item.label, Offset(face.center.dx, face.top + face.height * 0.55),
              size: math.min(12.0, bw * 0.12), color: const Color(0xFF1B1F26));
          canvas.drawCircle(Offset(face.right - 8, face.top + face.height * 0.62), 3, Paint()..color = C.bad);
          break;
        }
    }
  }

  void _tip(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cy = h / 2;
    // sim
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, cy - 9, w * 0.4, 18), const Radius.circular(6)),
        Paint()..color = const Color(0xFF8B5A2B));
    // plastik yubka
    final skirt = Path()
      ..moveTo(w * 0.36, cy - 14)
      ..lineTo(w * 0.56, cy - 9)
      ..lineTo(w * 0.56, cy + 9)
      ..lineTo(w * 0.36, cy + 14)
      ..close();
    canvas.drawPath(skirt, Paint()..color = const Color(0xFF2F6FD6));
    // metall gilza
    canvas.drawRect(Rect.fromLTWH(w * 0.56, cy - 6, w * 0.38, 12), Paint()..color = const Color(0xFFC9CED6));
    for (double x = w * 0.6; x < w * 0.92; x += 8) {
      canvas.drawLine(Offset(x, cy - 6), Offset(x, cy + 6), Paint()..color = const Color(0xFF9AA3AE));
    }
    drawText(canvas, 'НШВИ ${item.label}', Offset(w / 2, h * 0.8), size: 11, color: C.text2);
  }

  @override
  bool shouldRepaint(covariant DevicePainter old) => old.item.key != item.key;
}
