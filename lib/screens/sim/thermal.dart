import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/painters.dart';
import '../../widgets/ui.dart';
import 'common.dart';

/// Haroratni rangga aylantirish (20 °C — binafsha, 90 °C — oq).
Color heatColor(double t) {
  const stops = [
    (20.0, Color(0xFF12002A)),
    (30.0, Color(0xFF3B0A6E)),
    (40.0, Color(0xFF8A0F8A)),
    (50.0, Color(0xFFD0273C)),
    (60.0, Color(0xFFF2621A)),
    (70.0, Color(0xFFF9A51D)),
    (80.0, Color(0xFFFDE050)),
    (90.0, Color(0xFFFFFFFF)),
  ];
  if (t <= stops.first.$1) return stops.first.$2;
  for (var i = 1; i < stops.length; i++) {
    if (t <= stops[i].$1) {
      final a = stops[i - 1], b = stops[i];
      return Color.lerp(a.$2, b.$2, (t - a.$1) / (b.$1 - a.$1))!;
    }
  }
  return stops.last.$2;
}

class _Hot {
  final SimMod mod;
  final double temp;
  final double current;
  _Hot(this.mod, this.temp, this.current);
}

class ThermalScreen extends StatefulWidget {
  final String projectId;
  const ThermalScreen({super.key, required this.projectId});

  @override
  State<ThermalScreen> createState() => _ThermalScreenState();
}

class _ThermalScreenState extends State<ThermalScreen> {
  double _load = 1.0;
  static const double ambient = 25;

  List<_Hot> _compute(List<SimMod> mods) {
    final out = <_Hot>[];
    final mainPh = <String, double>{'L1': 0, 'L2': 0, 'L3': 0};
    for (final m in mods) {
      if (m.main) continue;
      final i = m.current * _load;
      for (final ph in m.phases) {
        mainPh[ph] = mainPh[ph]! + i;
      }
      final ratio = i / m.rating;
      out.add(_Hot(m, ambient + 45 * ratio * ratio, i));
    }
    final main = mods.firstWhere((m) => m.main);
    final mi = mainPh.values.reduce(math.max);
    final mr = mi / main.rating;
    out.insert(0, _Hot(main, ambient + 45 * mr * mr, mi));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    final mods = p == null ? <SimMod>[] : buildMods(p);
    final hot = mods.length <= 1 ? <_Hot>[] : _compute(mods);
    final sorted = [...hot]..sort((a, b) => b.temp.compareTo(a.temp));
    final tmax = sorted.isEmpty ? ambient : sorted.first.temp;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'Issiqlik kamerasi', subtitle: 'Yuklama bo\'yicha hisoblangan qizish'),
            ModeBar(projectId: widget.projectId, current: 'heat'),
            Expanded(
              child: mods.length <= 1
                  ? const NoLoads()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            color: const Color(0xFF07020F),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A1F3A)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CustomPaint(painter: _ThermalPainter(hot: hot, tmax: tmax)),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(colors: [for (double t = 20; t <= 90; t += 10) heatColor(t)]),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('20 °C', style: mono(11, color: C.muted, weight: FontWeight.w500)),
                            Text('55 °C', style: mono(11, color: C.muted, weight: FontWeight.w500)),
                            Text('90 °C', style: mono(11, color: C.muted, weight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Box(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(child: SectionLabel('Yuklama darajasi')),
                                  Text('${(_load * 100).round()}%', style: mono(14, color: C.amber)),
                                ],
                              ),
                              Slider(
                                value: _load,
                                min: 0.3,
                                max: 1.6,
                                divisions: 13,
                                activeColor: C.amber,
                                onChanged: (v) => setState(() => _load = v),
                              ),
                              const Text('Yuklamani oshirib, qaysi joy birinchi qizishini ko\'ring.',
                                  style: TextStyle(fontSize: 12, color: C.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: C.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: C.line),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var k = 0; k < math.min(5, sorted.length); k++) _row(sorted[k], k == 0),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kabel izolyatsiyasi (ПВХ) uchun chegara — 70 °C. Haqiqiy shitda qizigan joyni '
                          'issiqlik kamerasi yoki pirometr bilan tekshiring.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7C8698), height: 1.45),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(_Hot h, bool first) {
    String note;
    Color dot;
    Color bg = C.card;
    if (h.temp >= 70) {
      note = 'Xavfli: izolyatsiya chegarasi. Avtomat tez orada uziladi';
      dot = C.bad;
      bg = C.badSoft;
    } else if (h.temp >= 55) {
      note = 'Iliq — klemma boltlarini tekshiring';
      dot = C.amber;
      bg = C.amberSoft;
    } else {
      note = 'Me\'yorda';
      dot = C.ok;
    }
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${h.mod.id} · ${h.mod.name} · ${fmt(h.temp, 0)} °C',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
                const SizedBox(height: 2),
                Text('$note · ${fmt(h.current)} A / C${h.mod.rating}',
                    style: const TextStyle(fontSize: 12, color: C.soft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThermalPainter extends CustomPainter {
  final List<_Hot> hot;
  final double tmax;
  _ThermalPainter({required this.hot, required this.tmax});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Rect.fromLTWH(6, 118, w - 12, 22), Paint()..color = const Color(0xFF1A1326));
    final poles = hot.fold<int>(0, (s, h) => s + h.mod.poles);
    const gap = 3.0;
    final pw = math.min(30.0, (w - 16 - gap * (hot.length - 1)) / poles);
    var x = (w - (pw * poles + gap * (hot.length - 1))) / 2;
    for (final h in hot) {
      final r = Rect.fromLTWH(x, 60, pw * h.mod.poles, 140);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF120B1E));
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = const Color(0xFF3A2F4F));
      final hotSpot = Offset(r.center.dx, r.bottom - 14);
      final rad = 18 + (h.temp - 25).clamp(0.0, 70.0) * 0.9;
      final col = heatColor(h.temp);
      canvas.drawCircle(
        hotSpot,
        rad,
        Paint()
          ..shader = RadialGradient(colors: [
            col,
            col.withValues(alpha: 0.6),
            heatColor(math.max(20.0, h.temp - 25)).withValues(alpha: 0.35),
            const Color(0x00000000),
          ], stops: const [0, 0.3, 0.6, 1])
              .createShader(Rect.fromCircle(center: hotSpot, radius: rad)),
      );
      // kabel pastga
      canvas.drawRect(
        Rect.fromLTWH(r.center.dx - 4, r.bottom, 8, size.height - r.bottom),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [heatColor(h.temp - 5), heatColor(math.max(20.0, h.temp - 30))],
          ).createShader(Rect.fromLTWH(r.center.dx - 4, r.bottom, 8, size.height - r.bottom)),
      );
      if (h.temp >= 40 || h == hot.first) {
        drawText(canvas, '${h.temp.round()}°', Offset(r.center.dx, r.top - 18),
            size: 10, color: h.temp >= 55 ? const Color(0xFFFDE050) : const Color(0xFFE8ECF2));
      }
      x += pw * h.mod.poles + gap;
    }
    final label = 'MAX ${tmax.round()} °C';
    final tp = Rect.fromLTWH(10, 10, 92, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(tp, const Radius.circular(6)), Paint()..color = const Color(0x99000000));
    drawText(canvas, label, Offset(tp.center.dx, 14), size: 11, color: Colors.white);
    final tr = Rect.fromLTWH(w - 102, 10, 92, 22);
    canvas.drawRRect(RRect.fromRectAndRadius(tr, const Radius.circular(6)), Paint()..color = const Color(0x99000000));
    drawText(canvas, 'Muhit 25 °C', Offset(tr.center.dx, 14), size: 11, color: Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
