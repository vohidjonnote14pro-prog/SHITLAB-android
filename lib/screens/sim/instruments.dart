import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/painters.dart';
import '../../widgets/ui.dart';
import 'common.dart';

class _Term {
  final String id;
  final Offset pos;
  final String? mod;
  final String? phase;
  final String side; // in, out
  final String? kind; // N, PE
  final String label;
  const _Term({
    required this.id,
    required this.pos,
    this.mod,
    this.phase,
    this.side = '',
    this.kind,
    required this.label,
  });
}

class _ModRect {
  final SimMod mod;
  final Rect rect;
  final List<double> poleX;
  const _ModRect(this.mod, this.rect, this.poleX);
}

class _Probe {
  Offset tip;
  String? node;
  _Probe(this.tip);
}

class InstrumentsScreen extends StatefulWidget {
  final String projectId;
  const InstrumentsScreen({super.key, required this.projectId});

  @override
  State<InstrumentsScreen> createState() => _InstrumentsScreenState();
}

class _InstrumentsScreenState extends State<InstrumentsScreen> {
  static const double panelH = 450;
  static const double handleR = 30;
  static const double handleDrop = 48;

  List<SimMod> _mods = [];
  final Map<String, bool> _on = {};
  String _tool = 'mm';
  String _mmMode = 'V';
  String _active = 'red';
  String? _dragging;
  String? _clamp;
  late _Probe _red;
  late _Probe _black;
  double _w = 350;
  bool _placed = false;

  List<_ModRect> _rects = [];
  List<_Term> _terms = [];

  @override
  void initState() {
    super.initState();
    final p = app.byId(widget.projectId);
    if (p != null) {
      _mods = buildMods(p);
      for (final m in _mods) {
        _on[m.id] = true;
      }
    }
    _red = _Probe(const Offset(100, 372));
    _black = _Probe(const Offset(250, 372));
  }

  void _layout(double w) {
    if (_w == w && _rects.isNotEmpty) return;
    _w = w;
    final poles = _mods.fold<int>(0, (s, m) => s + m.poles);
    final gap = 3.0;
    final usable = w - 16 - gap * (_mods.length - 1);
    final pw = poles == 0 ? 30.0 : math.min(30.0, usable / poles);
    var x = (w - (pw * poles + gap * (_mods.length - 1))) / 2;
    final rects = <_ModRect>[];
    final terms = <_Term>[];
    for (final m in _mods) {
      final rect = Rect.fromLTWH(x, 70, pw * m.poles, 140);
      final px = <double>[];
      for (var k = 0; k < m.poles; k++) {
        final cx = x + pw * (k + 0.5);
        px.add(cx);
        final ph = m.phases[k];
        terms.add(_Term(
            id: '${m.id}-$ph-in', pos: Offset(cx, 84), mod: m.id, phase: ph, side: 'in', label: '${m.id} kirish $ph'));
        terms.add(_Term(
            id: '${m.id}-$ph-out',
            pos: Offset(cx, 196),
            mod: m.id,
            phase: ph,
            side: 'out',
            label: '${m.id} chiqish $ph'));
      }
      rects.add(_ModRect(m, rect, px));
      x += pw * m.poles + gap;
    }
    for (var k = 0; k < 5; k++) {
      final bx = 40 + k * (w - 80) / 4;
      terms.add(_Term(id: 'N$k', pos: Offset(bx, 262), kind: 'N', label: 'N shina'));
      terms.add(_Term(id: 'PE$k', pos: Offset(bx, 304), kind: 'PE', label: 'PE shina'));
    }
    _rects = rects;
    _terms = terms;
    if (!_placed) {
      _red = _Probe(Offset(w * 0.3, 372));
      _black = _Probe(Offset(w * 0.7, 372));
      _placed = true;
    }
  }

  _Term? _term(String? id) {
    if (id == null) return null;
    for (final t in _terms) {
      if (t.id == id) return t;
    }
    return null;
  }

  _Term? _nearest(Offset p) {
    _Term? best;
    var bd = 36.0;
    for (final t in _terms) {
      final d = (t.pos - p).distance;
      if (d < bd) {
        bd = d;
        best = t;
      }
    }
    return best;
  }

  String _pot(String id) {
    final t = _term(id);
    if (t == null) return 'off';
    if (t.kind != null) return t.kind!;
    final mainOn = _on['QF0'] == true;
    if (t.mod == 'QF0') return t.side == 'in' ? t.phase! : (mainOn ? t.phase! : 'off');
    if (t.side == 'in') return mainOn ? t.phase! : 'off';
    return mainOn && _on[t.mod] == true ? t.phase! : 'off';
  }

  bool _isPh(String p) => p == 'L1' || p == 'L2' || p == 'L3';

  double _volt(String a, String b) {
    if (a == 'off' || b == 'off') return 0;
    if (_isPh(a) && _isPh(b)) return a == b ? 0 : 400;
    if (_isPh(a) || _isPh(b)) return 230;
    return 0;
  }

  _Probe _probe(String c) => c == 'red' ? _red : _black;

  void _place(_Term t) {
    if (_tool == 'clamp') return;
    final color = _tool == 'ind' ? 'red' : _active;
    setState(() {
      final pr = _probe(color);
      pr.tip = t.pos;
      pr.node = t.id;
      if (_tool != 'ind') _active = color == 'red' ? 'black' : 'red';
    });
  }

  void _dragUpdate(String color, DragUpdateDetails d) {
    setState(() {
      final pr = _probe(color);
      final n = pr.tip + d.delta;
      pr.tip = Offset(n.dx.clamp(8.0, _w - 8), n.dy.clamp(8.0, panelH - handleDrop - 20));
      pr.node = null;
    });
  }

  void _dragEnd(String color) {
    setState(() {
      final pr = _probe(color);
      final t = _nearest(pr.tip);
      if (t != null) {
        pr.tip = t.pos;
        pr.node = t.id;
        _active = color == 'red' ? 'black' : 'red';
      }
      _dragging = null;
    });
  }

  ({String val, String unit, String sub, Color bg, Color fg, Color lamp}) _reading() {
    const normalBg = Color(0xFFA9BD93);
    const normalFg = Color(0xFF1F2A14);
    const badBg = Color(0xFFE9A39B);
    const badFg = Color(0xFF5A0F0B);
    const names = {
      'L1': 'L1 faza',
      'L2': 'L2 faza',
      'L3': 'L3 faza',
      'N': 'nol (N)',
      'PE': 'yerga ulash (PE)',
      'off': 'o\'chirilgan liniya',
    };
    final a = _red.node != null ? _pot(_red.node!) : null;
    final b = _black.node != null ? _pot(_black.node!) : null;
    final both = a != null && b != null;
    const lampOff = Color(0xFF3A3F48);

    if (_tool == 'mm' && _mmMode == 'V') {
      if (!both) {
        return (val: '- - -', unit: '', sub: 'Qizil va qora shchupni klemmalarga qo\'ying', bg: normalBg, fg: normalFg, lamp: lampOff);
      }
      final v = _volt(a, b);
      return (val: fmt(v), unit: 'V~', sub: '${names[a]} — ${names[b]}', bg: normalBg, fg: normalFg, lamp: lampOff);
    }
    if (_tool == 'mm' || _tool == 'meg') {
      final meg = _tool == 'meg';
      if (!both) {
        return (
          val: '- - -',
          unit: '',
          sub: 'Ikkala shchupni qo\'ying. Avval avtomatni o\'chiring (dastagini bosing).',
          bg: normalBg,
          fg: normalFg,
          lamp: lampOff
        );
      }
      if (_isPh(a) || _isPh(b)) {
        return (val: 'XAVF', unit: '', sub: 'Kuchlanish bor! Avtomatni o\'chirib, keyin o\'lchang.', bg: badBg, fg: badFg, lamp: lampOff);
      }
      if (_red.node == _black.node) {
        return (val: '0,0', unit: meg ? 'MΩ' : 'Ω', sub: 'Bitta nuqta', bg: normalBg, fg: normalFg, lamp: lampOff);
      }
      final np = (a == 'N' || a == 'PE') && (b == 'N' || b == 'PE');
      if (np) {
        return meg
            ? (val: '0,00', unit: 'MΩ', sub: 'N va PE kirishda ulangan — o\'lchash uchun ajrating', bg: normalBg, fg: normalFg, lamp: lampOff)
            : (val: '0,4', unit: 'Ω', sub: 'N–PE ulanishi butun (TN-C-S)', bg: normalBg, fg: normalFg, lamp: lampOff);
      }
      return meg
          ? (val: '> 500', unit: 'MΩ', sub: 'Izolyatsiya me\'yorda (kerak ≥ 0,5 MΩ)', bg: const Color(0xFFB9DDA0), fg: normalFg, lamp: lampOff)
          : (val: 'OL', unit: 'Ω', sub: 'Zanjir uzuq — tok o\'tmaydi', bg: normalBg, fg: normalFg, lamp: lampOff);
    }
    if (_tool == 'ind') {
      if (a == null) {
        return (val: '—', unit: '', sub: 'Qizil shchupni klemmaga tegizing', bg: normalBg, fg: normalFg, lamp: lampOff);
      }
      if (_isPh(a)) {
        return (val: 'FAZA', unit: '', sub: '${names[a]} — indikator yondi', bg: normalBg, fg: normalFg, lamp: const Color(0xFFFF5A3C));
      }
      return (val: 'yo\'q', unit: '', sub: '${names[a]} — faza yo\'q', bg: normalBg, fg: normalFg, lamp: lampOff);
    }
    // kleshi
    if (_clamp == null) {
      return (val: '- - -', unit: '', sub: 'Avtomat ostidagi sariq "QISISH" joyini bosing', bg: normalBg, fg: normalFg, lamp: lampOff);
    }
    SimMod? m;
    for (final x in _mods) {
      if (x.id == _clamp) m = x;
    }
    if (m == null) {
      return (val: '- - -', unit: '', sub: '', bg: normalBg, fg: normalFg, lamp: lampOff);
    }
    double i = 0;
    String sub;
    if (m.main) {
      if (_on['QF0'] == true) {
        for (final x in _mods) {
          if (!x.main && _on[x.id] == true && x.phases.contains('L1')) i += x.current;
        }
      }
      sub = 'QF0 · L1 faza simi';
    } else {
      i = _on['QF0'] == true && _on[m.id] == true ? m.current : 0;
      sub = '${m.id} · ${m.name}';
    }
    return (val: fmt(i), unit: 'A', sub: sub, bg: normalBg, fg: normalFg, lamp: lampOff);
  }

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    final devs = {
      'mm': ('MULTIMETR', const Color(0xFFE0A21B), const Color(0xFF6B4C08), const Color(0xFF1D1D1D)),
      'clamp': ('TOK KLESHISI', const Color(0xFFF2C21B), const Color(0xFF6B5408), const Color(0xFF1D1D1D)),
      'meg': ('MEGOMMETR 500 V', const Color(0xFFC9332A), const Color(0xFF5A120D), Colors.white),
      'ind': ('INDIKATOR', const Color(0xFF2D5FA8), const Color(0xFF13305C), Colors.white),
    };
    final hints = {
      'mm': 'Shchupni barmoq bilan suring yoki klemmani bosing: birinchi bosish — qizil, ikkinchisi — qora. '
          'Klemma yaqinida qo\'yib yuborsangiz, o\'zi yopishadi.',
      'clamp': 'Avtomat ostidagi sariq maydonni bosing. Dastakni bosib avtomatni o\'chirish mumkin.',
      'meg': 'Izolyatsiyani tekshirish: avtomatni o\'chiring, qizilni chiqish klemmasiga, qorani PE shinaga qo\'ying.',
      'ind': 'Indikator bitta shchup bilan ishlaydi: klemmani bosing yoki shchupni suring.',
    };
    final d = devs[_tool]!;
    final r = _reading();
    final showRed = _tool != 'clamp';
    final showBlack = _tool == 'mm' || _tool == 'meg';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'O\'lchov asboblari', subtitle: '${p?.name ?? ''} · virtual o\'lchash'),
            ModeBar(projectId: widget.projectId, current: 'tools'),
            Expanded(
              child: _mods.length <= 1
                  ? const NoLoads()
                  : ListView(
                      physics: _dragging != null ? const NeverScrollableScrollPhysics() : null,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      children: [
                        Row(
                          children: [
                            for (final t in const [
                              ('mm', 'Multimetr', Color(0xFFE0A21B)),
                              ('clamp', 'Kleshi', Color(0xFFF2C21B)),
                              ('meg', 'Megommetr', Color(0xFFC9332A)),
                              ('ind', 'Indikator', Color(0xFF2D5FA8)),
                            ]) ...[
                              Expanded(child: _toolBtn(t.$1, t.$2, t.$3)),
                              if (t.$1 != 'ind') const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(hints[_tool]!, style: const TextStyle(fontSize: 12, color: C.soft, height: 1.45)),
                        const SizedBox(height: 10),
                        LayoutBuilder(builder: (context, cons) {
                          _layout(cons.maxWidth);
                          return _panel(showRed, showBlack);
                        }),
                        const SizedBox(height: 14),
                        _device(d.$1, d.$2, d.$3, d.$4, r),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(String key, String label, Color sw) {
    final act = _tool == key;
    return Material(
      color: act ? C.amberSoft : C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: act ? C.amber : C.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _tool = key;
          _dragging = null;
        }),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 26,
                decoration: BoxDecoration(
                  color: sw,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.black38, width: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: act ? C.amber : C.text2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(bool showRed, bool showBlack) {
    final children = <Widget>[
      Positioned.fill(
        child: CustomPaint(
          painter: _PanelPainter(rects: _rects, on: _on, clamp: _tool == 'clamp' ? _clamp : null),
        ),
      ),
    ];
    // Dastaklar (yoqish/o'chirish)
    for (final mr in _rects) {
      children.add(Positioned(
        left: mr.rect.left,
        top: mr.rect.top + 32,
        width: mr.rect.width,
        height: 50,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _on[mr.mod.id] = !(_on[mr.mod.id] ?? true)),
        ),
      ));
      if (_tool == 'clamp') {
        children.add(Positioned(
          left: mr.rect.left,
          top: mr.rect.top + 98,
          width: mr.rect.width,
          height: 42,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _clamp = mr.mod.id),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x2EF5B731),
                border: Border.all(color: const Color(0xFFB07A0A), width: 1.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              alignment: Alignment.center,
              child: const FittedBox(
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text('QISISH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6B4E00))),
                ),
              ),
            ),
          ),
        ));
      }
    }
    // Klemmalar
    final cand = _dragging != null ? _nearest(_probe(_dragging!).tip) : null;
    for (final t in _terms) {
      Color ring = Colors.transparent;
      if (cand != null && cand.id == t.id) {
        ring = Colors.white;
      } else if (_tool != 'clamp' && _red.node == t.id) {
        ring = C.bad;
      } else if ((_tool == 'mm' || _tool == 'meg') && _black.node == t.id) {
        ring = C.text2;
      }
      children.add(Positioned(
        left: t.pos.dx - 18,
        top: t.pos.dy - 18,
        width: 36,
        height: 36,
        child: Semantics(
          button: true,
          label: '${t.label} — shchupni shu yerga qo\'yish',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _place(t),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 2.5)),
              alignment: Alignment.center,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF9AA3AE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6B7380), width: 2),
                ),
              ),
            ),
          ),
        ),
      ));
    }
    // Simlar
    children.add(Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _LeadsPainter(
            red: showRed ? _red.tip : null,
            black: showBlack ? _black.tip : null,
            width: _w,
            height: panelH,
            drop: handleDrop,
          ),
        ),
      ),
    ));
    // Tutqichlar
    if (showBlack) children.add(_handle('black'));
    if (showRed) children.add(_handle('red'));

    return Container(
      height: panelH,
      decoration: BoxDecoration(
        color: const Color(0xFF262C34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF343D4D)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  Widget _handle(String color) {
    final pr = _probe(color);
    final red = color == 'red';
    final active = _active == color && _tool != 'ind';
    final ring = _dragging == color ? Colors.white : (active ? C.amber : (red ? const Color(0xFF7A1E16) : const Color(0xFF4A515C)));
    return Positioned(
      left: pr.tip.dx - handleR,
      top: pr.tip.dy + handleDrop - handleR,
      width: handleR * 2,
      height: handleR * 2,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          // Darhol ushlaydi — sahifa aylanishi (scroll) shchupni "o'g'irlay olmaydi".
          ImmediateMultiDragGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ImmediateMultiDragGestureRecognizer>(
            () => ImmediateMultiDragGestureRecognizer(),
            (rec) {
              rec.onStart = (Offset _) {
                setState(() {
                  _dragging = color;
                  _active = color;
                });
                return _ProbeDrag(
                  onUpdate: (d) => _dragUpdate(color, d),
                  onEnd: () => _dragEnd(color),
                );
              };
            },
          ),
        },
        child: Container(
          decoration: BoxDecoration(
            color: red ? const Color(0xFFD9382C) : const Color(0xFF23272E),
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x73000000), blurRadius: 14, offset: Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: Text(red ? '+' : 'COM', style: mono(red ? 18 : 10, color: Colors.white, weight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _device(String title, Color bg, Color border, Color ink,
      ({String val, String unit, String sub, Color bg, Color fg, Color lamp}) r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: ink)),
              ),
              if (_tool == 'mm')
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      _modeBtn('V', 'V~'),
                      _modeBtn('R', 'Ω'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: r.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black38, width: 2),
            ),
            child: Row(
              children: [
                if (_tool == 'ind')
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: r.lamp,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: r.lamp, blurRadius: 16)],
                    ),
                  ),
                Expanded(
                  child: Text(r.val,
                      textAlign: TextAlign.right,
                      style: mono(38, color: r.fg, weight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                SizedBox(width: 36, child: Text(r.unit, style: mono(15, color: r.fg, weight: FontWeight.w700))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(r.sub, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink, height: 1.4)),
        ],
      ),
    );
  }

  Widget _modeBtn(String key, String label) {
    final act = _mmMode == key;
    return GestureDetector(
      onTap: () => setState(() => _mmMode = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: act ? const Color(0xFF1D1D1D) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: mono(13, color: act ? const Color(0xFFF2C21B) : const Color(0xFF1D1D1D), weight: FontWeight.w700)),
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  final List<_ModRect> rects;
  final Map<String, bool> on;
  final String? clamp;
  _PanelPainter({required this.rects, required this.on, required this.clamp});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(Rect.fromLTWH(6, 128, w - 12, 24), Paint()..color = const Color(0xFF8B95A2));
    for (final mr in rects) {
      final r = mr.rect;
      final live = on[mr.mod.id] == true;
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFE6E9ED));
      if (clamp == mr.mod.id) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = C.amber);
      }
      final band = Paint()..color = const Color(0xFFD3D8DF);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, 28), const Radius.circular(4)), band);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.bottom - 28, r.width, 28), const Radius.circular(4)), band);
      final win = Rect.fromLTWH(r.left + 4, r.top + 34, r.width - 8, 46);
      canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)), Paint()..color = const Color(0xFF2A2F37));
      final lw = win.width * 0.52;
      final lever = Rect.fromLTWH(win.center.dx - lw / 2, live ? win.top + 4 : win.top + 24, lw, 18);
      canvas.drawRRect(RRect.fromRectAndRadius(lever, const Radius.circular(3)),
          Paint()..color = live ? const Color(0xFFC7CDD5) : const Color(0xFF6B7380));
      drawText(canvas, 'C${mr.mod.rating}', Offset(r.center.dx, r.top + 84),
          size: math.min(11.0, r.width * 0.36), color: const Color(0xFF1B1F26), weight: FontWeight.w700);
      drawText(canvas, mr.mod.id, Offset(r.center.dx, r.bottom + 4),
          size: math.min(10.0, r.width * 0.34 + 2), color: live ? C.text2 : C.badText);
    }
    // N va PE shinalar
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(20, 254, w - 40, 16), const Radius.circular(3)),
        Paint()..color = C.blue);
    drawText(canvas, 'N', const Offset(4, 255), size: 11, color: const Color(0xFF7FA7EF), center: false);
    final pe = Rect.fromLTWH(20, 296, w - 40, 16);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(pe, const Radius.circular(3)));
    for (double x = pe.left; x < pe.right; x += 28) {
      canvas.drawRect(Rect.fromLTWH(x, pe.top, 14, pe.height), Paint()..color = const Color(0xFFE3C42A));
      canvas.drawRect(Rect.fromLTWH(x + 14, pe.top, 14, pe.height), Paint()..color = const Color(0xFF2FA24E));
    }
    canvas.restore();
    drawText(canvas, 'PE', const Offset(2, 297), size: 10, color: const Color(0xFF9CC9B0), center: false);
    // shchuplar joyi
    final park = RRect.fromRectAndRadius(Rect.fromLTWH(10, 340, w - 20, size.height - 348), const Radius.circular(14));
    canvas.drawRRect(
        park,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF3A4352));
    drawText(canvas, 'SHCHUPLAR JOYI', Offset(w / 2, 345), size: 10, color: const Color(0xFF6B7586), monoText: false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _LeadsPainter extends CustomPainter {
  final Offset? red;
  final Offset? black;
  final double width;
  final double height;
  final double drop;
  _LeadsPainter({required this.red, required this.black, required this.width, required this.height, required this.drop});

  void _lead(Canvas c, Offset tip, double sx, Color color) {
    final path = Path()
      ..moveTo(sx, height)
      ..cubicTo(sx, height - 30, tip.dx, tip.dy + drop + 70, tip.dx, tip.dy + drop + 26);
    c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = color);
    c.drawLine(
        tip,
        tip.translate(0, drop - 28),
        Paint()
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFC9D1DD));
    c.drawCircle(tip, 3, Paint()..color = Colors.white);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (black != null) _lead(canvas, black!, width * 0.7, const Color(0xFF111418));
    if (red != null) _lead(canvas, red!, width * 0.3, const Color(0xFFC0392B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ProbeDrag extends Drag {
  final void Function(DragUpdateDetails) onUpdate;
  final VoidCallback onEnd;
  _ProbeDrag({required this.onUpdate, required this.onEnd});

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd();

  @override
  void cancel() => onEnd();
}
