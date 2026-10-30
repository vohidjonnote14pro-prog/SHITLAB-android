import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../models.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'common.dart';

class _Dev {
  final String key;
  final String label;
  final String short;
  final String tag;
  final int n;
  final Color c;
  const _Dev(this.key, this.label, this.short, this.tag, this.n, this.c);
}

const _devs = <_Dev>[
  _Dev('a1', 'Avtomat 1P', 'C16', 'QF', 1, Color(0xFF5B6573)),
  _Dev('a3', 'Avtomat 3P', 'C32', 'QF 3P', 3, Color(0xFF5B6573)),
  _Dev('uzo', 'UZO 2P', '30mA', 'QD', 2, Color(0xFF3FB37F)),
  _Dev('dif', 'Difavtomat', 'C16', 'QFD', 2, Color(0xFF3FB37F)),
  _Dev('km', 'Kontaktor', '25A', 'KM', 2, Color(0xFF2F6FD6)),
  _Dev('kv', 'Kuchl. relesi', '230V', 'KV', 2, Color(0xFFF5B731)),
  _Dev('fv', 'Impuls himoya', 'FV', 'FV', 1, Color(0xFFE5534B)),
  _Dev('kwh', 'Hisoblagich', 'kWh', 'PI', 4, Color(0xFF1F6B44)),
];

_Dev? _dev(String key) {
  final k = key.split(':').first;
  for (final d in _devs) {
    if (d.key == k) return d;
  }
  return null;
}

/// Loyihadan avtomatik joylashuv: kirish 3P, har ikki UZO-li liniyaga bitta UZO, keyin liniyalar.
List<String> autoLayout(Project p) {
  final r = Calc.panel(p);
  final out = <String>['a3:C${r.mainBreaker > 0 ? r.mainBreaker : 32}'];
  var uzoLines = 0;
  for (final l in p.loads) {
    if (Calc.load(l).uzo) uzoLines++;
  }
  for (var k = 0; k < (uzoLines + 1) ~/ 2; k++) {
    out.add('uzo:30mA');
  }
  for (final l in p.loads) {
    final lr = Calc.load(l);
    out.add('${l.threePhase ? 'a3' : 'a1'}:C${lr.breaker > 0 ? lr.breaker : 16}');
  }
  return out;
}

class PlacementScreen extends StatefulWidget {
  final String projectId;
  const PlacementScreen({super.key, required this.projectId});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  @override
  void initState() {
    super.initState();
    final p = app.byId(widget.projectId);
    if (p != null && p.layout.isEmpty && p.loads.isNotEmpty) {
      p.layout = autoLayout(p);
      WidgetsBinding.instance.addPostFrameCallback((_) => app.save(p));
    }
  }

  int _used(Project p) => p.layout.fold<int>(0, (s, k) => s + (_dev(k)?.n ?? 1));

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    if (p == null) return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
    final used = _used(p);
    final free = p.modules - used;
    final perRow = p.modules <= 12 ? p.modules : (p.modules % 18 == 0 && p.modules <= 36 ? 18 : 12);
    final rows = (p.modules / perRow).ceil();

    // modullarni qatorlarga bo'lish
    final rowItems = List.generate(rows, (_) => <({String key, int index})>[]);
    final rowUsed = List.filled(rows, 0);
    var ri = 0;
    for (var i = 0; i < p.layout.length; i++) {
      final n = _dev(p.layout[i])?.n ?? 1;
      while (ri < rows - 1 && rowUsed[ri] + n > perRow) {
        ri++;
      }
      rowItems[ri].add((key: p.layout[i], index: i));
      rowUsed[ri] += n;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'Joylashtirish', subtitle: 'DIN-reykaga apparat qo\'yish'),
            ModeBar(projectId: widget.projectId, current: 'place'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${panelTypeByKey(p.panelType)?.name ?? 'Shit'} · $rows qator',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.text)),
                      ),
                      Text('$used / ${p.modules} modul', style: mono(13, color: free < 0 ? C.badText : C.soft)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (context, cons) {
                    final mw = math.min(28.0, (cons.maxWidth - 24) / perRow);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262C34),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF343D4D)),
                      ),
                      child: Column(
                        children: [
                          for (var r = 0; r < rows; r++) ...[
                            SizedBox(
                              height: 130,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 52,
                                    height: 22,
                                    child: Container(color: const Color(0xFF8B95A2)),
                                  ),
                                  Row(
                                    children: [
                                      for (final it in rowItems[r]) _module(p, it.key, it.index, mw),
                                      for (var k = 0;
                                          k < math.max(0, perRow - rowUsed[r]);
                                          k++)
                                        Container(
                                          width: mw,
                                          height: 126,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFF4A5363), width: 1.2),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('+', style: TextStyle(color: Color(0xFF6B7586))),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (r < rows - 1) const SizedBox(height: 14),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  const Text(
                    'Pastdan apparatni bosing — birinchi bo\'sh joyga qo\'yiladi. Qo\'yilgan apparatni bossangiz, olib tashlanadi.',
                    style: TextStyle(fontSize: 12, color: C.soft, height: 1.45),
                  ),
                  if (free < 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: StatusBox(
                        ok: false,
                        title: 'Shitga sig\'maydi',
                        text: '${-free} modul ortiqcha — kattaroq shit tanlang',
                      ),
                    ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                    children: [for (final d in _devs) _paletteItem(p, d, free)],
                  ),
                  const SizedBox(height: 14),
                  GhostButton(
                    label: 'Loyihaga mos qilib qayta joylash',
                    icon: Icons.auto_fix_high,
                    onTap: () {
                      p.layout = autoLayout(p);
                      app.touch(p);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _module(Project p, String key, int index, double mw) {
    final d = _dev(key);
    final n = d?.n ?? 1;
    final label = key.contains(':') ? key.split(':')[1] : (d?.short ?? '');
    return GestureDetector(
      onTap: () {
        p.layout.removeAt(index);
        app.touch(p);
        setState(() {});
      },
      child: Container(
        width: mw * n,
        height: 126,
        decoration: BoxDecoration(
          color: const Color(0xFFE6E9ED),
          borderRadius: BorderRadius.circular(3),
          border: const Border(right: BorderSide(color: Color(0xFFB7BEC8))),
        ),
        child: Column(
          children: [
            Container(height: 24, color: const Color(0xFFD3D8DF)),
            const SizedBox(height: 8),
            Container(
              width: mw * n * 0.56,
              height: 28,
              decoration: BoxDecoration(color: const Color(0xFF2A2F37), borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 6),
            FittedBox(child: Text(label, style: mono(9, color: const Color(0xFF1B1F26), weight: FontWeight.w700))),
            const SizedBox(height: 2),
            FittedBox(child: Text(d?.tag ?? '', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: d?.c ?? C.muted))),
            const Spacer(),
            Container(height: 24, color: const Color(0xFFD3D8DF)),
          ],
        ),
      ),
    );
  }

  Widget _paletteItem(Project p, _Dev d, int free) {
    final fits = d.n <= free;
    return Opacity(
      opacity: fits ? 1 : 0.45,
      child: Material(
        color: C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: fits ? C.line : const Color(0xFF3A2A2A)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: fits
              ? () {
                  p.layout.add('${d.key}:${d.short}');
                  app.touch(p);
                  setState(() {});
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Row(
                  children: [
                    for (var k = 0; k < d.n; k++)
                      Container(
                        width: 11,
                        height: 34,
                        margin: const EdgeInsets.only(right: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E9ED),
                          borderRadius: BorderRadius.circular(2),
                          border: Border(bottom: BorderSide(color: d.c, width: 6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.text)),
                      Text('${d.n} modul', style: mono(11, color: C.muted, weight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
