import 'package:flutter/material.dart';

import '../../store.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'common.dart';

class _WTerm {
  final String id;
  final double fx; // 0..1 kenglik bo'yicha
  final double y;
  final bool phaseGroup;
  final String label;
  const _WTerm(this.id, this.fx, this.y, this.phaseGroup, this.label);
}

class _Wire {
  final String a;
  final String b;
  final String c;
  const _Wire(this.a, this.b, this.c);
}

class _Need {
  final String a;
  final String b;
  final String c;
  final String text;
  const _Need(this.a, this.b, this.c, this.text);
}

class WiringScreen extends StatefulWidget {
  final String projectId;
  const WiringScreen({super.key, required this.projectId});

  @override
  State<WiringScreen> createState() => _WiringScreenState();
}

class _WiringScreenState extends State<WiringScreen> {
  static const terms = <_WTerm>[
    _WTerm('QF0o', 0.13, 160, true, 'QF0 chiqish'),
    _WTerm('QF1i', 0.43, 40, true, 'QF1 kirish'),
    _WTerm('QF1o', 0.43, 160, true, 'QF1 chiqish'),
    _WTerm('QF2i', 0.66, 40, true, 'QF2 kirish'),
    _WTerm('QF2o', 0.66, 160, true, 'QF2 chiqish'),
    _WTerm('N', 0.86, 210, false, 'N shina'),
    _WTerm('PE', 0.29, 250, false, 'PE shina'),
    _WTerm('XL', 0.57, 306, true, 'X1 L klemma'),
    _WTerm('XN', 0.71, 306, false, 'X1 N klemma'),
    _WTerm('XPE', 0.86, 306, false, 'X1 PE klemma'),
  ];

  static const need = <_Need>[
    _Need('QF0o', 'QF1i', 'L', 'QF0 → QF1 kirishi (faza)'),
    _Need('QF0o', 'QF2i', 'L', 'QF0 → QF2 kirishi (faza)'),
    _Need('QF2o', 'XL', 'L', 'QF2 chiqishi → X1 L'),
    _Need('N', 'XN', 'N', 'N shina → X1 N'),
    _Need('PE', 'XPE', 'PE', 'PE shina → X1 PE'),
  ];

  String _color = 'L';
  String? _sel;
  final List<_Wire> _wires = [const _Wire('QF0o', 'QF1i', 'L')];

  _WTerm _t(String id) => terms.firstWhere((t) => t.id == id);

  bool _same(_Wire w, _Need n) => (w.a == n.a && w.b == n.b) || (w.a == n.b && w.b == n.a);

  void _tap(_WTerm t) {
    setState(() {
      if (_sel == null) {
        _sel = t.id;
      } else if (_sel == t.id) {
        _sel = null;
      } else {
        _wires.add(_Wire(_sel!, t.id, _color));
        _sel = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    final errors = <String>[];
    for (final w in _wires) {
      final a = _t(w.a), b = _t(w.b);
      _Need? req;
      for (final n in need) {
        if (_same(w, n)) req = n;
      }
      if (a.phaseGroup != b.phaseGroup) {
        errors.add('${a.label} — ${b.label}: qisqa tutashuv xavfi!');
      } else if (req == null) {
        errors.add('${a.label} — ${b.label}: bu ulanish sxemada yo\'q');
      } else if (req.c != w.c) {
        errors.add('${req.text}: sim rangi noto\'g\'ri');
      }
    }
    var done = 0;
    final checks = <(String, bool)>[];
    for (final n in need) {
      final ok = _wires.any((w) => _same(w, n) && w.c == n.c);
      if (ok) done++;
      checks.add((n.text, ok));
    }
    final allOk = done == need.length && errors.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'Sim ulash', subtitle: '${p?.name ?? ''} · mashq: rozetka liniyasi'),
            ModeBar(projectId: widget.projectId, current: 'wire'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      for (final c in const [('L', 'Faza L'), ('N', 'Nol N'), ('PE', 'PE')]) ...[
                        Expanded(
                          child: Pill(
                            label: c.$2,
                            selected: _color == c.$1,
                            leading: _swatch(c.$1),
                            onTap: () => setState(() => _color = c.$1),
                          ),
                        ),
                        if (c.$1 != 'PE') const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sel != null
                        ? '${_t(_sel!).label} tanlandi — endi ikkinchi klemmani bosing'
                        : 'Rangni tanlang, keyin ikkita klemmani ketma-ket bosing — sim o\'zi tortiladi.',
                    style: TextStyle(fontSize: 12, color: _sel != null ? C.warnText : C.soft, height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (context, cons) {
                    final w = cons.maxWidth;
                    return Container(
                      height: 340,
                      decoration: BoxDecoration(
                        color: const Color(0xFF262C34),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF343D4D)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: _BoardPainter(width: w))),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _WiresPainter(
                                  wires: _wires,
                                  pos: {for (final t in terms) t.id: Offset(t.fx * w, t.y)},
                                ),
                              ),
                            ),
                          ),
                          for (final t in terms)
                            Positioned(
                              left: t.fx * w - 21,
                              top: t.y - 21,
                              width: 42,
                              height: 42,
                              child: Semantics(
                                button: true,
                                label: '${t.label} — sim ulash',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _tap(t),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _sel == t.id ? const Color(0x33F5B731) : Colors.transparent,
                                      border: Border.all(
                                          color: _sel == t.id ? C.amber : Colors.transparent, width: 2.5),
                                    ),
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9AA3AE),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF6B7380), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: SectionLabel('Tekshiruv')),
                            Text(
                              '$done / ${need.length}${errors.isNotEmpty ? ' · ${errors.length} xato' : ''}',
                              style: mono(12,
                                  color: errors.isNotEmpty ? C.badText : (allOk ? const Color(0xFF5FD39A) : C.soft)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final ck in checks) _check(ck.$1, ck.$2 ? 'ok' : 'todo'),
                        for (final e in errors) _check(e, 'bad'),
                        if (allOk)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('Barakalla! Liniya to\'g\'ri ulandi.',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.okText)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: 'Oxirgisini o\'chirish',
                          onTap: _wires.isEmpty
                              ? null
                              : () => setState(() {
                                    _wires.removeLast();
                                    _sel = null;
                                  }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GhostButton(
                          label: 'Tozalash',
                          onTap: () => setState(() {
                            _wires.clear();
                            _sel = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(String c) {
    if (c == 'PE') {
      return Row(children: [
        Container(width: 8, height: 8, color: const Color(0xFFE3C42A)),
        Container(width: 8, height: 8, color: const Color(0xFF2FA24E)),
      ]);
    }
    return Container(width: 16, height: 8, color: c == 'L' ? const Color(0xFF8B5A2B) : C.blue);
  }

  Widget _check(String text, String kind) {
    final color = kind == 'ok' ? C.ok : (kind == 'bad' ? C.bad : const Color(0xFF2C3442));
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: kind == 'todo'
                ? null
                : Icon(kind == 'ok' ? Icons.check : Icons.priority_high, size: 12, color: C.bg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: kind == 'bad' ? C.badText : (kind == 'ok' ? C.text2 : C.muted))),
          ),
        ],
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double width;
  _BoardPainter({required this.width});

  void _module(Canvas c, Rect r, String label) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFE6E9ED));
    final tp = TextPainter(
      text: TextSpan(text: label, style: mono(10, color: const Color(0xFF1B1F26), weight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    _module(canvas, Rect.fromLTWH(w * 0.13 - 25, 30, 50, 140), 'QF0');
    _module(canvas, Rect.fromLTWH(w * 0.43 - 20, 30, 40, 140), 'QF1');
    _module(canvas, Rect.fromLTWH(w * 0.66 - 20, 30, 40, 140), 'QF2');
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.17, 204, w * 0.74, 12), const Radius.circular(3)),
        Paint()..color = C.blue);
    final pe = Rect.fromLTWH(w * 0.17, 244, w * 0.74, 12);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(pe, const Radius.circular(3)));
    for (double x = pe.left; x < pe.right; x += 24) {
      canvas.drawRect(Rect.fromLTWH(x, pe.top, 12, 12), Paint()..color = const Color(0xFFE3C42A));
      canvas.drawRect(Rect.fromLTWH(x + 12, pe.top, 12, 12), Paint()..color = const Color(0xFF2FA24E));
    }
    canvas.restore();
    final box = Rect.fromLTWH(w * 0.49, 284, w * 0.46, 44);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(10)), Paint()..color = const Color(0xFF1B212B));
    canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(10)),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF3A4352));
    final labels = [('N', w * 0.07, 203.0), ('PE', w * 0.07, 243.0), ('X1 →', w * 0.05, 298.0)];
    for (final l in labels) {
      final tp = TextPainter(
        text: TextSpan(text: l.$1, style: mono(11, color: C.soft)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(l.$2, l.$3));
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => old.width != width;
}

class _WiresPainter extends CustomPainter {
  final List<_Wire> wires;
  final Map<String, Offset> pos;
  _WiresPainter({required this.wires, required this.pos});

  @override
  void paint(Canvas canvas, Size size) {
    for (final w in wires) {
      final a = pos[w.a]!, b = pos[w.b]!;
      final my = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(a.dx, my)
        ..lineTo(b.dx, my)
        ..lineTo(b.dx, b.dy);
      final base = w.c == 'L'
          ? const Color(0xFF8B5A2B)
          : w.c == 'N'
              ? C.blue
              : const Color(0xFFE3C42A);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = base);
      if (w.c == 'PE') {
        for (final m in path.computeMetrics()) {
          for (double d = 0; d < m.length; d += 16) {
            canvas.drawPath(
                m.extractPath(d, (d + 8).clamp(0, m.length).toDouble()),
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = const Color(0xFF2FA24E));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
