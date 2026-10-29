import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/painters.dart';
import '../widgets/ui.dart';
import 'docs.dart';

class SchemaScreen extends StatelessWidget {
  final String projectId;
  const SchemaScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final p = app.byId(projectId);
    if (p == null) {
      return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
    }
    final r = Calc.panel(p);
    final screenW = MediaQuery.of(context).size.width;
    final width = math.max(screenW - 24, 40.0 + p.loads.length * 76);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: 'Bir chiziqli sxema',
              subtitle: '${p.name} · avtomatik chizilgan',
              actions: [
                IconButton(
                  tooltip: 'PDF',
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => DocsScreen(projectId: p.id))),
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: C.text2),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF121820),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF222A36)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: p.loads.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Text('Sxema chizilishi uchun avval yuklama qo\'shing',
                                textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: CustomPaint(
                              size: Size(width, 430),
                              painter: _SchemaPainter(project: p, result: r),
                            ),
                          ),
                  ),
                  if (p.loads.length > 4)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Sxemani chapga-o\'ngga suring',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: C.muted)),
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Avtomat', const Color(0xFFF5B731)),
                      _chip('UZO 30 mA', const Color(0xFF5FD39A)),
                      _chip('Σ ${fmt(r.totalKw)} kVt', null),
                      _chip('Kirish: ${r.mainCable}', null),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (p.loads.isNotEmpty)
                    StatusBox(
                      ok: r.mainBreaker > 0,
                      title: r.mainBreaker > 0 ? 'Selektivlik to\'g\'ri' : 'Selektivlik buzilgan',
                      text: r.mainBreaker > 0
                          ? 'Guruh avtomatlari kirish avtomati C${r.mainBreaker} dan kichik'
                          : 'Kirish avtomatini tanlab bo\'lmadi — yuklamani kamaytiring',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color? dot) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 14, height: 4, color: dot),
              const SizedBox(width: 6),
            ],
            Text(text, style: const TextStyle(fontSize: 11.5, color: C.soft)),
          ],
        ),
      );
}

class _SchemaPainter extends CustomPainter {
  final Project project;
  final PanelResult result;
  _SchemaPainter({required this.project, required this.result});

  static const wire = Color(0xFFC9D1DD);

  void _breaker(Canvas c, Offset o, {double scale = 1}) {
    final p = Paint()
      ..color = wire
      ..strokeWidth = 2 * scale;
    c.drawLine(o, o.translate(0, 12 * scale), p);
    c.drawLine(o.translate(0, 28 * scale), o.translate(0, 40 * scale), p);
    c.drawLine(
        o.translate(0, 28 * scale),
        o.translate(8 * scale, 12 * scale),
        Paint()
          ..color = C.amber
          ..strokeWidth = 2.5 * scale
          ..strokeCap = StrokeCap.round);
    final x = Paint()
      ..color = wire
      ..strokeWidth = 1.6 * scale;
    c.drawLine(o.translate(-3 * scale, 9 * scale), o.translate(3 * scale, 15 * scale), x);
    c.drawLine(o.translate(3 * scale, 9 * scale), o.translate(-3 * scale, 15 * scale), x);
  }

  void _loadSymbol(Canvas c, Offset center, String type) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = wire;
    switch (type) {
      case 'light':
        c.drawCircle(center, 11, p);
        c.drawLine(center.translate(-8, -8), center.translate(8, 8), p);
        c.drawLine(center.translate(8, -8), center.translate(-8, 8), p);
        break;
      case 'socket':
        c.drawArc(Rect.fromCircle(center: center.translate(0, 5), radius: 10), math.pi, math.pi, false, p);
        c.drawLine(center.translate(-10, 5), center.translate(10, 5), p);
        c.drawLine(center.translate(0, -11), center.translate(0, -5), p);
        break;
      case 'three':
        c.drawRect(Rect.fromCenter(center: center, width: 22, height: 18), p);
        final z = Path()
          ..moveTo(center.dx - 7, center.dy)
          ..lineTo(center.dx - 4, center.dy - 4)
          ..lineTo(center.dx - 1, center.dy + 4)
          ..lineTo(center.dx + 2, center.dy - 4)
          ..lineTo(center.dx + 5, center.dy + 4)
          ..lineTo(center.dx + 7, center.dy);
        c.drawPath(z, p..strokeWidth = 1.6);
        break;
      default:
        c.drawCircle(center, 11, p);
        drawText(c, 'M', center.translate(0, -7), size: 12, color: wire);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final loads = project.loads;
    final n = loads.length;
    const col = 76.0;
    final total = n * col;
    final startX = (size.width - total) / 2 + col / 2;
    final cx = size.width / 2;
    final line = Paint()
      ..color = wire
      ..strokeWidth = 3;

    // Kirish
    final inRect = Rect.fromCenter(center: Offset(cx, 28), width: 210, height: 36);
    canvas.drawRRect(RRect.fromRectAndRadius(inRect, const Radius.circular(10)), Paint()..color = const Color(0xFF161C25));
    canvas.drawRRect(
        RRect.fromRectAndRadius(inRect, const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF3A4352));
    drawText(canvas, 'Kirish · TN-C-S', Offset(cx, 13), size: 9.5, color: C.muted, weight: FontWeight.w500);
    drawText(canvas, '${result.mainCable} · 380/220 V', Offset(cx, 26), size: 10.5, color: C.text);
    canvas.drawLine(Offset(cx, 46), Offset(cx, 62), line);

    // Hisoblagich
    final meter = Rect.fromCenter(center: Offset(cx, 79), width: 46, height: 34);
    canvas.drawRRect(
        RRect.fromRectAndRadius(meter, const Radius.circular(6)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = wire);
    drawText(canvas, 'kWh', Offset(cx, 73), size: 11, color: C.text);
    drawText(canvas, 'PI', Offset(cx + 30, 72), size: 10, color: C.soft, center: false);
    canvas.drawLine(Offset(cx, 96), Offset(cx, 108), line);

    // Kirish avtomati
    _breaker(canvas, Offset(cx, 108), scale: 1.1);
    drawText(canvas, 'QF0', Offset(cx + 16, 116), size: 11, color: C.amber, center: false);
    drawText(canvas, result.mainBreaker > 0 ? 'C${result.mainBreaker} 3P' : '—', Offset(cx + 16, 130),
        size: 10, color: C.soft, center: false);
    canvas.drawLine(Offset(cx, 152), Offset(cx, 164), line);

    // Shina
    final left = math.min(startX, cx);
    final right = math.max(startX + (n - 1) * col, cx);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(left, 163, right, 168), const Radius.circular(3)),
        Paint()..color = C.amber);

    final thin = Paint()
      ..color = wire
      ..strokeWidth = 2;
    for (var i = 0; i < n; i++) {
      final l = loads[i];
      final r = Calc.load(l);
      final x = startX + i * col;
      final ph = l.threePhase ? '3F' : l.phase;
      if (r.uzo) {
        canvas.drawLine(Offset(x, 168), Offset(x, 176), thin);
        final box = Rect.fromCenter(center: Offset(x, 187), width: 42, height: 22);
        canvas.drawRRect(
            RRect.fromRectAndRadius(box, const Radius.circular(5)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = const Color(0xFF5FD39A));
        drawText(canvas, '30mA', Offset(x, 181), size: 9, color: const Color(0xFF5FD39A));
        canvas.drawLine(Offset(x, 198), Offset(x, 205), thin);
      } else {
        canvas.drawLine(Offset(x, 168), Offset(x, 205), thin);
      }
      _breaker(canvas, Offset(x, 205));
      canvas.drawLine(Offset(x, 245), Offset(x, 256), thin);
      drawText(canvas, 'QF${i + 1}', Offset(x, 258), size: 11, color: C.amber);
      drawText(canvas, r.breakerText.replaceAll(' 1P', ''), Offset(x, 273), size: 10, color: C.text2);
      drawText(canvas, r.section > 0 ? '${r.cores}×${secLabel(r.section)}' : '—', Offset(x, 287),
          size: 10, color: C.soft);
      canvas.drawLine(
          Offset(x, 302),
          Offset(x, 316),
          Paint()
            ..color = l.threePhase ? wire : C.phase(ph)
            ..strokeWidth = 2);
      _loadSymbol(canvas, Offset(x, 329), l.type);
      final chip = Rect.fromCenter(center: Offset(x, 356), width: 28, height: 16);
      canvas.drawRRect(RRect.fromRectAndRadius(chip, const Radius.circular(5)), Paint()..color = C.phaseSoft(ph));
      drawText(canvas, ph, Offset(x, 350), size: 9.5, color: C.phase(ph));
      drawText(canvas, l.name, Offset(x, 370),
          size: 10, color: C.soft, monoText: false, maxWidth: col - 6, weight: FontWeight.w500);
      drawText(canvas, '${fmt(l.powerKw)} kVt', Offset(x, 400), size: 10, color: C.muted);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
