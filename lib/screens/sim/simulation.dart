import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../calc.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'common.dart';

class _Log {
  final String t;
  final String text;
  final String kind;
  _Log(this.text, this.kind) : t = clock();
}

class SimulationScreen extends StatefulWidget {
  final String projectId;
  const SimulationScreen({super.key, required this.projectId});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  List<SimMod> _mods = [];
  final Map<String, bool> _on = {};
  final Map<String, String> _trip = {};
  String? _selected;
  String? _overloadId;
  double _overloadI = 0;
  String _scenario = 'normal';
  Timer? _timer;
  final List<_Log> _log = [];

  @override
  void initState() {
    super.initState();
    final p = app.byId(widget.projectId);
    if (p != null) {
      _mods = buildMods(p);
      for (final m in _mods) {
        _on[m.id] = true;
      }
      if (_mods.length > 1) _selected = _mods[1].id;
    }
    _add('Shit ishga tushirildi. Barcha avtomatlar yoqilgan.', 'ok');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add(String text, String kind) {
    _log.insert(0, _Log(text, kind));
    if (_log.length > 8) _log.removeLast();
  }

  SimMod? _mod(String? id) {
    for (final m in _mods) {
      if (m.id == id) return m;
    }
    return null;
  }

  bool _live(SimMod m) {
    if (_trip.containsKey('QF0') || _on['QF0'] != true) return false;
    if (m.main) return true;
    return _on[m.id] == true && !_trip.containsKey(m.id);
  }

  double _current(SimMod m) {
    if (!_live(m) || m.main) return 0;
    return m.id == _overloadId ? _overloadI : m.current;
  }

  Map<String, double> _phases() {
    final s = <String, double>{'L1': 0, 'L2': 0, 'L3': 0};
    for (final m in _mods) {
      if (m.main) continue;
      final i = _current(m);
      for (final ph in m.phases) {
        s[ph] = s[ph]! + i;
      }
    }
    return s;
  }

  void _checkMain() {
    final main = _mod('QF0');
    if (main == null || _trip.containsKey('QF0')) return;
    final mx = _phases().values.reduce(math.max);
    if (mx > main.rating * 1.45) {
      _trip['QF0'] = 'ty';
      _add('QF0 uzildi: umumiy tok ${fmt(mx)} A — kirish avtomati chegarasidan oshdi.', 'bad');
    }
  }

  void _normal() {
    _timer?.cancel();
    setState(() {
      for (final m in _mods) {
        _on[m.id] = true;
      }
      _trip.clear();
      _overloadId = null;
      _scenario = 'normal';
      _add('Barcha avtomatlar qayta yoqildi. Rejim: normal.', 'ok');
    });
  }

  void _overload() {
    final m = _mod(_selected);
    if (m == null || m.main) return;
    if (!_live(m)) {
      setState(() => _add('${m.id} o\'chiq — avval uni yoqing.', 'warn'));
      return;
    }
    _timer?.cancel();
    final over = m.rating * 1.4;
    setState(() {
      _scenario = 'overload';
      _overloadId = m.id;
      _overloadI = over;
      _add(
          '${m.id} ga qo\'shimcha yuklama ulandi: tok ${fmt(over)} A (1,4 × In). Issiqlik ajratgich qizimoqda…',
          'warn');
      _checkMain();
    });
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        if (_overloadId == m.id && _live(m)) {
          _trip[m.id] = 'ty';
          _add('${m.id} uzildi: o\'ta yuklama. Kabel qizib ketishdan saqlandi.', 'bad');
        }
      });
    });
  }

  void _short() {
    final m = _mod(_selected);
    if (m == null || m.main) return;
    if (!_live(m)) {
      setState(() => _add('${m.id} allaqachon o\'chiq.', 'warn'));
      return;
    }
    final mainMod = _mod('QF0');
    final mainR = mainMod?.rating ?? 32;
    setState(() {
      _scenario = 'short';
      _trip[m.id] = 'qt';
      final selective = m.rating < mainR;
      _add(
          '${m.id} liniyasida qisqa tutashuv. Elektromagnit ajratgich 0,01 s da uzdi.'
          '${selective ? ' QF0 ishlashda qoldi — selektivlik to\'g\'ri.' : ' Diqqat: selektivlik buzilgan!'}',
          'bad');
    });
  }

  void _leak() {
    var m = _mod(_selected);
    if (m == null || m.main) return;
    if (!m.uzo) {
      final alt = _mods.where((x) => x.uzo && !x.main).toList();
      if (alt.isEmpty) {
        setState(() {
          _scenario = 'leak';
          _add('Bu liniyada UZO yo\'q: tok oqishi odamga xavfli! Rozetka liniyalariga 30 mA UZO qo\'ying.', 'bad');
        });
        return;
      }
      m = alt.first;
    }
    if (!_live(m)) {
      setState(() => _add('${m!.id} o\'chiq.', 'warn'));
      return;
    }
    final target = m;
    setState(() {
      _scenario = 'leak';
      _selected = target.id;
      _trip[target.id] = 'uzo';
      _add('${target.id}: 45 mA tok yerga oqdi. UZO 30 mA 0,03 s da uzdi — odam xavfsiz.', 'bad');
    });
  }

  void _toggle(SimMod m) {
    setState(() {
      if (_trip.containsKey(m.id)) {
        _trip.remove(m.id);
        _on[m.id] = true;
        if (_overloadId == m.id) _overloadId = null;
        _add('${m.id} qayta yoqildi.', 'ok');
      } else {
        _on[m.id] = !(_on[m.id] ?? true);
        if (_on[m.id] != true && _overloadId == m.id) {
          _overloadId = null;
          _timer?.cancel();
        }
        _add('${m.id} ${_on[m.id] == true ? 'yoqildi.' : 'qo\'lda o\'chirildi.'}', _on[m.id] == true ? 'ok' : 'info');
      }
      _checkMain();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    final ph = _phases();
    final mainMod = _mod('QF0');
    final mainR = (mainMod?.rating ?? 32).toDouble();
    final mx = ph.values.isEmpty ? 0.0 : ph.values.reduce(math.max);
    final kw = (ph['L1']! + ph['L2']! + ph['L3']!) * 230 * 0.95 / 1000;
    final trips = _trip.keys.toList()..sort();
    final bad = trips.isNotEmpty;
    final warn = !bad && _overloadId != null;
    final sel = _mod(_selected);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'Simulyatsiya', subtitle: '${p?.name ?? ''} · 230/380 V'),
            ModeBar(projectId: widget.projectId, current: 'sim'),
            const SizedBox(height: 8),
            Expanded(
              child: _mods.length <= 1
                  ? const NoLoads()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        _banner(bad, warn, trips),
                        const SizedBox(height: 12),
                        Box(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(child: SectionLabel('Fazalar yuklamasi')),
                                  Text('Σ ${fmt(kw)} kVt', style: mono(13)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              for (final k in ['L1', 'L2', 'L3'])
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: PhaseBar(phase: k, current: ph[k]!, max: mainR),
                                ),
                              const Divider(color: Color(0xFF222936), height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text('Kirish QF0 · C${mainR.toInt()} 3P',
                                        style: const TextStyle(fontSize: 12, color: C.soft)),
                                  ),
                                  Text(
                                    _trip.containsKey('QF0') ? 'uzilgan' : '${fmt(mx / mainR * 100, 0)}% yuklangan',
                                    style: mono(12, color: mx > mainR || _trip.containsKey('QF0') ? C.badText : C.okText),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'VAZIYATNI SINAB KO\'RING · ${sel != null && !sel.main ? sel.id : ''}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted, letterSpacing: 1),
                          ),
                        ),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 3.4,
                          children: [
                            _scBtn('normal', 'Normal', C.ok, _normal),
                            _scBtn('overload', 'O\'ta yuklama', C.amber, _overload),
                            _scBtn('short', 'Qisqa tutashuv', C.bad, _short),
                            _scBtn('leak', 'Tok oqishi', const Color(0xFF5B8FD6), _leak),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Vaziyat tanlangan liniyada sinaladi. Liniyani tanlash uchun qatorni bosing.',
                            style: TextStyle(fontSize: 11.5, color: C.faint)),
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
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                                child: Row(
                                  children: [
                                    Expanded(child: SectionLabel('Avtomatlar')),
                                    Text('O\'ngdagi tugma — yoqish / o\'chirish',
                                        style: TextStyle(fontSize: 11, color: C.faint)),
                                  ],
                                ),
                              ),
                              for (final m in _mods) _row(m),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Box(
                          color: const Color(0xFF121820),
                          border: const Color(0xFF222A36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel('Hodisalar jurnali'),
                              const SizedBox(height: 8),
                              for (final e in _log)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.t, style: mono(11, color: const Color(0xFF7C8698), weight: FontWeight.w500)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(e.text,
                                            style: TextStyle(fontSize: 12.5, height: 1.4, color: _logColor(e.kind))),
                                      ),
                                    ],
                                  ),
                                ),
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

  Color _logColor(String k) {
    switch (k) {
      case 'ok':
        return const Color(0xFF9CC9B0);
      case 'warn':
        return C.warnText;
      case 'bad':
        return C.badText;
      default:
        return C.text2;
    }
  }

  Widget _banner(bool bad, bool warn, List<String> trips) {
    final bg = bad ? C.badSoft : (warn ? C.amberSoft : C.okSoft);
    final dot = bad ? C.bad : (warn ? C.amber : C.ok);
    final title = bad
        ? '${trips.join(', ')} uzildi'
        : (warn ? 'Ogohlantirish: o\'ta yuklama' : 'Tizim normal ishlayapti');
    final text = bad
        ? 'Himoya ishladi. O\'ngdagi tugma bilan qayta yoqing.'
        : (warn ? '$_overloadId bir necha soniyada uziladi' : 'Barcha himoyalar tayyor holatda');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withValues(alpha: 0.35), blurRadius: 0, spreadRadius: 5)],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: bad ? C.badText : (warn ? C.warnText : C.okText))),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 12, color: C.text2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scBtn(String key, String label, Color dot, VoidCallback onTap) {
    final act = _scenario == key;
    return Material(
      color: act ? C.amberSoft : C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: act ? C.amber : C.line2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: act ? C.amber : C.text)),
          ],
        ),
      ),
    );
  }

  Widget _row(SimMod m) {
    final tripped = _trip[m.id];
    final live = _live(m);
    final selfOn = _on[m.id] == true && tripped == null;
    String status;
    Color sc;
    Color dot;
    Color lever;
    Color bg = C.card;
    if (tripped != null) {
      status = tripped == 'qt'
          ? 'Qisqa tutashuv — uzildi'
          : tripped == 'uzo'
              ? 'UZO ishladi — oqish'
              : 'O\'ta yuklama — uzildi';
      sc = C.badText;
      dot = C.bad;
      lever = C.bad;
      bg = const Color(0xFF24161A);
    } else if (!selfOn) {
      status = 'O\'chirilgan';
      sc = C.muted;
      dot = const Color(0xFF5A6370);
      lever = C.muted;
    } else if (!live) {
      status = 'Kuchlanish yo\'q (QF0 o\'chiq)';
      sc = C.muted;
      dot = const Color(0xFF5A6370);
      lever = const Color(0xFF5B6573);
    } else if (m.id == _overloadId) {
      status = 'O\'ta yuklama — qizimoqda…';
      sc = C.warnText;
      dot = C.amber;
      lever = C.amber;
      bg = const Color(0xFF211C10);
    } else {
      status = 'Ishlayapti';
      sc = const Color(0xFF5FD39A);
      dot = C.ok;
      lever = const Color(0xFF5B6573);
    }
    final selected = _selected == m.id;
    final phLabel = m.poles == 3 ? '3F' : m.phases.first;
    final cur = m.main
        ? (live ? '${fmt(_phases().values.reduce(math.max))} A' : '0 A')
        : '${fmt(_current(m))} A';
    return Material(
      color: selected && !m.main ? const Color(0xFF1E1A0E) : bg,
      child: InkWell(
        onTap: m.main ? null : () => setState(() => _selected = m.id),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: Color(0xFF222936)),
              left: BorderSide(color: selected && !m.main ? C.amber : Colors.transparent, width: 3),
            ),
          ),
          child: Row(
            children: [
              MiniBreaker(on: selfOn, dot: dot, lever: lever),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${m.id} · ${m.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
                    const SizedBox(height: 2),
                    Text(status, style: TextStyle(fontSize: 12, color: sc)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(cur, style: mono(13)),
                  Text('$phLabel · C${m.rating}${m.uzo ? ' · UZO' : ''}',
                      style: mono(10, color: C.phase(phLabel), weight: FontWeight.w500)),
                ],
              ),
              IconButton(
                tooltip: selfOn ? 'O\'chirish' : 'Yoqish',
                onPressed: () => _toggle(m),
                icon: Icon(Icons.power_settings_new,
                    color: tripped != null ? C.bad : (selfOn ? const Color(0xFF5FD39A) : C.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
