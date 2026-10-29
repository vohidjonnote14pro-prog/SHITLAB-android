import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/painters.dart';
import '../widgets/ui.dart';

class LoadEditScreen extends StatefulWidget {
  final String projectId;
  final String? loadId;
  const LoadEditScreen({super.key, required this.projectId, this.loadId});

  @override
  State<LoadEditScreen> createState() => _LoadEditScreenState();
}

class _LoadEditScreenState extends State<LoadEditScreen> {
  final _name = TextEditingController();
  final _power = TextEditingController();
  final _cos = TextEditingController();
  final _len = TextEditingController();
  String _type = 'socket';
  String _phase = 'L1';
  String _mark = 'VVGLS';
  Project? _project;
  Load? _existing;

  @override
  void initState() {
    super.initState();
    _project = app.byId(widget.projectId);
    final p = _project;
    if (p != null && widget.loadId != null) {
      for (final l in p.loads) {
        if (l.id == widget.loadId) _existing = l;
      }
    }
    final e = _existing;
    if (e != null) {
      _name.text = e.name;
      _power.text = _numText(e.powerKw);
      _cos.text = e.cosPhi == 0.95 ? '' : _numText(e.cosPhi);
      _len.text = e.lengthM > 0 ? _numText(e.lengthM) : '';
      _type = e.type;
      _phase = e.phase;
      _mark = e.mark;
    } else if (p != null) {
      _phase = Calc.lightestPhase(p);
      if (p.loads.isNotEmpty) _mark = p.loads.last.mark;
    }
  }

  static String _numText(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

  @override
  void dispose() {
    _name.dispose();
    _power.dispose();
    _cos.dispose();
    _len.dispose();
    super.dispose();
  }

  Load _draft() {
    final cos = toNum(_cos.text);
    return Load(
      id: _existing?.id ?? newId(),
      name: _name.text.trim().isEmpty ? loadTypeLabel(_type) : _name.text.trim(),
      type: _type,
      powerKw: toNum(_power.text),
      cosPhi: cos > 0 && cos <= 1 ? cos : 0.95,
      lengthM: toNum(_len.text),
      phase: _type == 'three' ? '3F' : (_phase == '3F' ? 'L1' : _phase),
      mark: _mark,
    );
  }

  void _clear() {
    setState(() {
      _name.clear();
      _power.clear();
      _cos.clear();
      _len.clear();
    });
  }

  void _save() {
    final p = _project;
    if (p == null) return;
    final d = _draft();
    if (d.powerKw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quvvatni kiriting (kVt)')));
      return;
    }
    final e = _existing;
    if (e != null) {
      e
        ..name = d.name
        ..type = d.type
        ..powerKw = d.powerKw
        ..cosPhi = d.cosPhi
        ..lengthM = d.lengthM
        ..phase = d.phase
        ..mark = d.mark;
    } else {
      p.loads.add(d);
    }
    app.touch(p);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final p = _project;
    final e = _existing;
    if (p == null || e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card2,
        title: const Text('Yuklamani o\'chirish'),
        content: Text('"${e.name}" ro\'yxatdan olib tashlanadi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('O\'chirish', style: TextStyle(color: C.bad))),
        ],
      ),
    );
    if (ok == true) {
      p.loads.remove(e);
      app.touch(p);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Widget _field(String label, TextEditingController c, {String hint = '0', bool number = true}) {
    return TextField(
      controller: c,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
      onChanged: (_) => setState(() {}),
      style: number ? mono(15) : const TextStyle(fontSize: 14, color: C.text),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    if (p == null) {
      return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
    }
    final d = _draft();
    final r = Calc.load(d);
    final mark = markByKey(_mark);
    final ready = r.ready;
    final index = _existing != null ? p.loads.indexOf(_existing!) + 1 : p.loads.length + 1;

    String statusText;
    if (r.ok) {
      statusText = 'Kabel avtomat tokiga chidaydi${d.lengthM > 0 ? ', ΔU 5% dan kam' : ''}';
    } else {
      statusText = r.issues.isNotEmpty ? r.issues.first : '';
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              title: _name.text.trim().isEmpty ? 'QF$index · Yangi yuklama' : 'QF$index · ${_name.text.trim()}',
              subtitle: '${p.name} · ${d.threePhase ? '3 faza' : 'faza ${d.phase}'}',
              actions: [
                if (_existing != null)
                  IconButton(
                    tooltip: 'O\'chirish',
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, color: C.muted),
                  ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: SectionLabel('Ma\'lumot kiriting')),
                            TextButton(onPressed: _clear, child: const Text('Tozalash')),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in loadTypes)
                              Pill(
                                label: t.label,
                                selected: _type == t.key,
                                leading: Icon(t.icon, size: 16, color: _type == t.key ? C.amber : C.muted),
                                onTap: () => setState(() => _type = t.key),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _field('Yuklama nomi', _name, hint: 'Masalan: Oshxona rozetkalari', number: false),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _field('Quvvat, kVt', _power)),
                            const SizedBox(width: 8),
                            Expanded(child: _field('cos φ', _cos, hint: '0,95')),
                            const SizedBox(width: 8),
                            Expanded(child: _field('Uzunlik, m', _len)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Faza', style: TextStyle(fontSize: 12, color: C.muted)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (final ph in ['L1', 'L2', 'L3']) ...[
                              Expanded(
                                child: Pill(
                                  label: ph,
                                  monoText: true,
                                  accent: C.phase(ph),
                                  selected: _type != 'three' && d.phase == ph,
                                  onTap: _type == 'three' ? null : () => setState(() => _phase = ph),
                                ),
                              ),
                              if (ph != 'L3') const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        if (_type == 'three')
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('3 fazali yuklama uchala fazaga teng ulanadi',
                                style: TextStyle(fontSize: 12, color: C.muted)),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: Color(0xFF222936)),
                        ),
                        const Text('Kabel markasi · mijoz tanlaydi', style: TextStyle(fontSize: 12, color: C.muted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final m in cableMarks)
                              Pill(
                                label: m.label,
                                monoText: true,
                                selected: _mark == m.key,
                                leading: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: m.aluminium ? const Color(0xFF9AA3AE) : m.sheath,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF5A6370)),
                                  ),
                                ),
                                onTap: () => setState(() => _mark = m.key),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(mark.desc, style: const TextStyle(fontSize: 12, color: C.soft, height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: SectionLabel('Tanlangan jihozlar'),
                  ),
                  Opacity(
                    opacity: ready ? 1 : 0.45,
                    child: Row(
                      children: [
                        Expanded(
                          child: _DeviceCard(
                            title: r.breakerText,
                            sub: 'Avtomat',
                            child: CustomPaint(
                              painter: BreakerPainter(
                                label: r.breaker > 0 ? 'C${r.breaker}' : '—',
                                poles: d.threePhase ? 3 : 1,
                                sub: d.threePhase ? '4500 · 400V' : '4500 · 230V',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DeviceCard(
                            title: r.section > 0 ? '${r.cores}×${secLabel(r.section)} mm²' : '—',
                            sub: mark.aluminium ? 'Alyuminiy kabel' : 'Mis kabel',
                            child: CustomPaint(
                              painter: CablePainter(
                                sheath: mark.sheath,
                                label: r.section > 0 ? '${mark.label} ${r.cores}×${secLabel(r.section)}' : mark.label,
                                cores: r.cores,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _Legend(color: Color(0xFF8B5A2B), text: 'L — faza'),
                      _Legend(color: Color(0xFF2F6FD6), text: 'N — nol'),
                      _Legend(color: Color(0xFFE3C42A), text: 'PE — yerga'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Hisob natijasi'),
                        const SizedBox(height: 6),
                        KV('Hisobiy tok', ready ? '${fmt(r.current)} A' : '—'),
                        KV('Avtomat', r.breakerText, vColor: C.amber),
                        KV('Kabel', r.cableText, vColor: C.amber),
                        KV('Kuchlanish tushishi', ready && d.lengthM > 0 ? '${fmt(r.du)} %' : '—'),
                        KV('UZO', ready ? (r.uzo ? '30 mA' : 'shart emas') : '—'),
                        KV('Nakonechnik', r.tip, last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (ready)
                    StatusBox(
                      ok: r.ok,
                      title: r.ok ? 'PUE talablariga mos' : 'Diqqat: tekshiring',
                      text: statusText,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF343D4D), width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: C.muted),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Quvvatni kiriting — avtomat, kabel va tekshiruv shu zahoti chiqadi',
                                style: TextStyle(fontSize: 13, color: C.soft, height: 1.45)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                color: C.bg,
                border: Border(top: BorderSide(color: Color(0xFF1E2530))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(label: 'Saqlash', icon: Icons.check, onTap: ready ? _save : null),
                  const SizedBox(height: 6),
                  const Text('Loyiha telefon xotirasiga saqlanadi',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7C8698))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String title;
  final String sub;
  final Widget child;
  const _DeviceCard({required this.title, required this.sub, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      decoration: BoxDecoration(
        color: C.card2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3240)),
      ),
      child: Column(
        children: [
          SizedBox(height: 150, width: double.infinity, child: child),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: mono(14, color: C.amber)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 12, color: C.muted)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: C.soft)),
      ],
    );
  }
}
