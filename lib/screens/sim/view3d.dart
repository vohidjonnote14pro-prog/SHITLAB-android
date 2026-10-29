import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/painters.dart';
import '../../widgets/ui.dart';
import 'common.dart';

class View3DScreen extends StatefulWidget {
  final String projectId;
  const View3DScreen({super.key, required this.projectId});

  @override
  State<View3DScreen> createState() => _View3DScreenState();
}

class _View3DScreenState extends State<View3DScreen> with SingleTickerProviderStateMixin {
  double _rx = -0.2;
  double _ry = -0.5;
  late final AnimationController _door =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _doorCurve = CurvedAnimation(parent: _door, curve: Curves.easeInOutCubic);

  @override
  void dispose() {
    _door.dispose();
    super.dispose();
  }

  void _preset(double rx, double ry) => setState(() {
        _rx = rx;
        _ry = ry;
      });

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    if (p == null) return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
    final type = panelTypeByKey(p.panelType);
    final mods = buildMods(p);
    final usedPoles = mods.fold<int>(0, (s, m) => s + m.poles);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: '3D ko\'rinish', subtitle: '${type?.name ?? 'O\'z o\'lchami'} · ${p.ip}'),
            ModeBar(projectId: widget.projectId, current: '3d'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  GestureDetector(
                    onPanUpdate: (d) => setState(() {
                      _ry = (_ry + d.delta.dx * 0.01).clamp(-1.45, 1.45);
                      _rx = (_rx - d.delta.dy * 0.008).clamp(-0.9, 0.35);
                    }),
                    child: Container(
                      height: 430,
                      decoration: BoxDecoration(
                        gradient: const RadialGradient(
                          center: Alignment(0, -0.3),
                          radius: 0.9,
                          colors: [Color(0xFF232A35), Color(0xFF10141A)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: C.line),
                      ),
                      child: AnimatedBuilder(
                        animation: _doorCurve,
                        builder: (context, _) => CustomPaint(
                          painter: _BoxPainter(
                            rx: _rx,
                            ry: _ry,
                            door: _doorCurve.value,
                            mods: mods,
                            title: type?.name ?? 'Shit',
                            ip: p.ip,
                          ),
                          child: const Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text('Barmoq bilan suring — shit aylanadi',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF7C8698))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _door,
                          builder: (context, _) => PrimaryButton(
                            label: _door.value > 0.5 ? 'Eshikni yopish' : 'Eshikni ochish',
                            icon: _door.value > 0.5 ? Icons.door_front_door : Icons.door_front_door_outlined,
                            onTap: () => _door.value > 0.5 ? _door.reverse() : _door.forward(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Pill(label: 'Old', selected: _rx == -0.1 && _ry == 0, onTap: () => _preset(-0.1, 0))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Pill(label: 'Yon', selected: _rx == -0.15 && _ry == -1.2, onTap: () => _preset(-0.15, -1.2))),
                      const SizedBox(width: 8),
                      Expanded(
                          child:
                              Pill(label: 'Yuqori', selected: _rx == -0.8 && _ry == -0.35, onTap: () => _preset(-0.8, -0.35))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Box(
                    child: Row(
                      children: [
                        _info('O\'lcham', p.size.isEmpty ? '—' : p.size.replaceAll('≈', '')),
                        _info('Band', '${usedPoles + 2} / ${p.modules} modul'),
                        _info('Yuklama', '${p.loads.length} ta'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String k, String v) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(fontSize: 11, color: C.muted)),
            const SizedBox(height: 2),
            Text(v, maxLines: 2, style: mono(12)),
          ],
        ),
      );
}

class _V3 {
  final double x, y, z;
  const _V3(this.x, this.y, this.z);
}

class _Poly {
  final List<_V3> pts;
  final Color front;
  final Color back;
  final void Function(Canvas c, List<Offset> proj)? decal;
  _Poly(this.pts, this.front, this.back, {this.decal});
}

class _BoxPainter extends CustomPainter {
  final double rx, ry, door;
  final List<SimMod> mods;
  final String title;
  final String ip;

  _BoxPainter({
    required this.rx,
    required this.ry,
    required this.door,
    required this.mods,
    required this.title,
    required this.ip,
  });

  static const double w = 200, h = 260, d = 90;

  _V3 _rot(_V3 p) {
    // Y o'qi atrofida, keyin X o'qi atrofida aylantirish
    final cy = math.cos(ry), sy = math.sin(ry);
    final x1 = p.x * cy + p.z * sy;
    final z1 = -p.x * sy + p.z * cy;
    final cx = math.cos(rx), sx = math.sin(rx);
    final y2 = p.y * cx - z1 * sx;
    final z2 = p.y * sx + z1 * cx;
    return _V3(x1, y2, z2);
  }

  Offset _proj(_V3 p, Offset c) {
    const f = 900.0;
    final s = f / (f - p.z);
    return Offset(c.dx + p.x * s, c.dy + p.y * s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 10);
    // soya
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + h / 2 + 34), width: 260, height: 46),
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x8C000000), Color(0x00000000)])
            .createShader(Rect.fromCenter(center: Offset(c.dx, c.dy + h / 2 + 34), width: 260, height: 46)),
    );

    const hw = w / 2, hh = h / 2, hd = d / 2;
    _V3 v(double x, double y, double z) => _V3(x, y, z);

    final polys = <_Poly>[
      // orqa ichki plita (old tomondan ko'rinadi)
      _Poly([v(-hw, -hh, -hd + 1), v(hw, -hh, -hd + 1), v(hw, hh, -hd + 1), v(-hw, hh, -hd + 1)],
          const Color(0xFFC3C9CF), const Color(0xFF8E969E),
          decal: _interior),
      _Poly([v(-hw, -hh, -hd), v(-hw, -hh, hd), v(-hw, hh, hd), v(-hw, hh, -hd)], const Color(0xFFB4BBC2),
          const Color(0xFFA9B0B8)), // chap
      _Poly([v(hw, -hh, hd), v(hw, -hh, -hd), v(hw, hh, -hd), v(hw, hh, hd)], const Color(0xFF9AA1A8),
          const Color(0xFFA9B0B8)), // o'ng
      _Poly([v(-hw, -hh, -hd), v(hw, -hh, -hd), v(hw, -hh, hd), v(-hw, -hh, hd)], const Color(0xFFD2D7DC),
          const Color(0xFFB9BFC6)), // tepa
      _Poly([v(-hw, hh, hd), v(hw, hh, hd), v(hw, hh, -hd), v(-hw, hh, -hd)], const Color(0xFF7D858E),
          const Color(0xFF9AA1A8), decal: _glands), // past
    ];

    // Eshik: chap tomonda sharnir
    final a = door * 1.95; // ~112° gacha ochiladi
    _V3 dp(double x, double y) {
      final lx = x + hw; // sharnirdan masofa
      return _V3(-hw + lx * math.cos(a), y, hd + 1 + lx * math.sin(a));
    }

    final doorPts = [dp(-hw, -hh), dp(hw, -hh), dp(hw, hh), dp(-hw, hh)];
    polys.add(_Poly(doorPts, const Color(0xFFD5D9DD), const Color(0xFFB4BAC0), decal: _doorFace));

    // aylantirish, chuqurlik bo'yicha saralash
    final items = <({List<_V3> r, _Poly p, double depth})>[];
    for (final p in polys) {
      final r = p.pts.map(_rot).toList();
      final depth = r.fold<double>(0, (s, q) => s + q.z) / r.length;
      items.add((r: r, p: p, depth: depth));
    }
    items.sort((x, y) => x.depth.compareTo(y.depth));

    for (final it in items) {
      final pr = it.r.map((q) => _proj(q, c)).toList();
      final path = Path()..addPolygon(pr, true);
      // yuz kameraga qaraganmi (soat yo'nalishi)
      final cross = (pr[1].dx - pr[0].dx) * (pr[2].dy - pr[0].dy) - (pr[1].dy - pr[0].dy) * (pr[2].dx - pr[0].dx);
      final facing = cross > 0;
      canvas.drawPath(path, Paint()..color = facing ? it.p.front : it.p.back);
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0x33000000));
      if (it.p.decal != null && facing) it.p.decal!(canvas, pr);
    }
  }

  /// To'rtburchak ichidagi (u, v ∈ 0..1) nuqtani ekranga o'tkazish.
  static Offset _map(List<Offset> q, double u, double v) {
    final top = Offset.lerp(q[0], q[1], u)!;
    final bot = Offset.lerp(q[3], q[2], u)!;
    return Offset.lerp(top, bot, v)!;
  }

  static Path _quad(List<Offset> q, double u0, double v0, double u1, double v1) {
    return Path()
      ..addPolygon([_map(q, u0, v0), _map(q, u1, v0), _map(q, u1, v1), _map(q, u0, v1)], true);
  }

  void _interior(Canvas canvas, List<Offset> q) {
    // DIN-reyka
    canvas.drawPath(_quad(q, 0.07, 0.36, 0.93, 0.41), Paint()..color = const Color(0xFF8B95A2));
    // modullar
    final poles = mods.fold<int>(0, (s, m) => s + m.poles) + 2;
    final pw = math.min(0.86 / poles, 0.07);
    var u = 0.5 - pw * poles / 2;
    var first = true;
    for (final m in mods) {
      final n = m.poles;
      canvas.drawPath(_quad(q, u, 0.29, u + pw * n - 0.004, 0.49), Paint()..color = const Color(0xFFF2F3F5));
      canvas.drawPath(_quad(q, u, 0.45, u + pw * n - 0.004, 0.49), Paint()..color = const Color(0xFFD3D8DF));
      canvas.drawPath(_quad(q, u + pw * n * 0.3, 0.33, u + pw * n * 0.7, 0.38), Paint()..color = const Color(0xFF2A2F37));
      u += pw * n;
      if (first) {
        // UZO (2 modul)
        canvas.drawPath(_quad(q, u, 0.29, u + pw * 2 - 0.004, 0.49), Paint()..color = const Color(0xFFF2F3F5));
        canvas.drawPath(_quad(q, u, 0.45, u + pw * 2 - 0.004, 0.49), Paint()..color = const Color(0xFF3FB37F));
        u += pw * 2;
        first = false;
      }
    }
    // N va PE shinalar
    canvas.drawPath(_quad(q, 0.1, 0.62, 0.9, 0.65), Paint()..color = C.blue);
    canvas.drawPath(_quad(q, 0.1, 0.70, 0.9, 0.73), Paint()..color = const Color(0xFFE3C42A));
    for (var k = 0; k < 8; k++) {
      final a = 0.1 + k * 0.1;
      canvas.drawPath(_quad(q, a, 0.70, a + 0.05, 0.73), Paint()..color = const Color(0xFF2FA24E));
    }
    // kabellar pastdan
    for (final x in [0.2, 0.28, 0.36]) {
      canvas.drawPath(_quad(q, x, 0.78, x + 0.03, 1.0), Paint()..color = const Color(0xFF2B2F36));
    }
  }

  void _glands(Canvas canvas, List<Offset> q) {
    for (final x in [0.2, 0.4, 0.6]) {
      canvas.drawPath(_quad(q, x, 0.35, x + 0.09, 0.65), Paint()..color = const Color(0xFF2A2F37));
    }
  }

  void _doorFace(Canvas canvas, List<Offset> q) {
    canvas.drawPath(_quad(q, 0.02, 0.015, 0.98, 0.985),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF9AA1A8));
    canvas.drawPath(_quad(q, 0.3, 0.07, 0.7, 0.16), Paint()..color = const Color(0xFF1D2125));
    final mid = _map(q, 0.5, 0.115);
    final wpx = (_map(q, 0.7, 0.115) - _map(q, 0.3, 0.115)).distance;
    if (wpx > 30) {
      drawText(canvas, title, mid.translate(0, -6), size: math.min(11.0, wpx / 7), color: const Color(0xFFE9ECEE));
    }
    // ogohlantirish belgisi
    final t0 = _map(q, 0.5, 0.3), t1 = _map(q, 0.62, 0.45), t2 = _map(q, 0.38, 0.45);
    canvas.drawPath(Path()..addPolygon([t0, t1, t2], true), Paint()..color = const Color(0xFFF2C230));
    canvas.drawPath(
        Path()..addPolygon([t0, t1, t2], true),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF1D1D1D));
    // qulf
    canvas.drawPath(_quad(q, 0.86, 0.42, 0.92, 0.56), Paint()..color = const Color(0xFF4A515C));
    // ma'lumot oynasi
    canvas.drawPath(_quad(q, 0.18, 0.58, 0.82, 0.9),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF8E969E));
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => old.rx != rx || old.ry != ry || old.door != door;
}
