import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/painters.dart';
import '../widgets/ui.dart';
import 'panel.dart';

class NewPanelScreen extends StatefulWidget {
  const NewPanelScreen({super.key});

  @override
  State<NewPanelScreen> createState() => _NewPanelScreenState();
}

class _NewPanelScreenState extends State<NewPanelScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _h = TextEditingController();
  final _w = TextEditingController();
  final _d = TextEditingController();
  final _rows = TextEditingController();
  final _perRow = TextEditingController();

  String _category = 'Hammasi';
  String _selected = 'shrn12';
  String _mount = 'Osma';
  String _ip = 'IP31';

  static const _categories = ['Hammasi', 'Kvartira', 'Hisoblagichli', 'Sanoat', 'RZA'];

  @override
  void dispose() {
    for (final c in [_name, _address, _h, _w, _d, _rows, _perRow]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _customModules {
    final r = toNum(_rows.text).round();
    final m = toNum(_perRow.text).round();
    return r > 0 && m > 0 ? r * m : 0;
  }

  void _create() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Loyiha nomini kiriting (masalan: Uy shiti)')));
      return;
    }
    Project p;
    if (_selected == 'custom') {
      if (_customModules <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('O\'z o\'lchamingiz uchun DIN qatorlar va modul sonini kiriting')));
        return;
      }
      final size = [_h.text, _w.text, _d.text].map((e) => e.trim()).where((e) => e.isNotEmpty).join('×');
      p = Project(
        id: newId(),
        name: name,
        address: _address.text.trim(),
        panelType: 'custom',
        modules: _customModules,
        ip: _ip,
        size: size.isEmpty ? '' : '$size mm · $_mount',
        updated: DateTime.now(),
        loads: [],
      );
    } else {
      final t = panelTypeByKey(_selected)!;
      p = Project(
        id: newId(),
        name: name,
        address: _address.text.trim(),
        panelType: t.key,
        modules: t.modules,
        ip: t.ip,
        size: t.size,
        updated: DateTime.now(),
        loads: [],
      );
    }
    app.add(p);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PanelScreen(projectId: p.id)));
  }

  @override
  Widget build(BuildContext context) {
    final list = panelTypes.where((t) => _category == 'Hammasi' || t.category == _category).toList();
    final selectedType = panelTypeByKey(_selected);
    final selectedLabel = _selected == 'custom'
        ? 'O\'z o\'lchami · ${_customModules > 0 ? '$_customModules modul' : 'kiriting'}'
        : '${selectedType?.name} · ${selectedType?.modules} modul';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(title: 'Yangi shit', subtitle: 'Shit turini tanlang yoki o\'lchamini kiriting'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Loyiha nomi', hintText: 'Masalan: Uy shiti'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Obyekt manzili (ixtiyoriy)'),
                  ),
                  const SizedBox(height: 18),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final c in _categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Pill(
                              label: c,
                              selected: _category == c,
                              onTap: () => setState(() => _category = c),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final t in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TypeCard(
                        type: t,
                        selected: _selected == t.key,
                        onTap: () => setState(() => _selected = t.key),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _customBox(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: C.bg,
                border: Border(top: BorderSide(color: Color(0xFF1E2530))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Tanlandi', style: TextStyle(fontSize: 11, color: C.muted)),
                        Text(selectedLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.text)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: PrimaryButton(label: 'Davom etish', icon: Icons.arrow_forward, onTap: _create),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(String label, TextEditingController c) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: mono(15),
          decoration: InputDecoration(labelText: label, hintText: '0'),
        ),
      );

  Widget _customBox() {
    final sel = _selected == 'custom';
    return GestureDetector(
      onTap: () => setState(() => _selected = 'custom'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF1E1A0E) : C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? C.amber : const Color(0xFF343D4D), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 44, height: 44, child: CustomPaint(painter: PanelThumbPainter('custom'))),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('O\'z o\'lchamingiz',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
                      Text('Ro\'yxatda yo\'q bo\'lsa, real o\'lchamni kiriting',
                          style: TextStyle(fontSize: 12, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (sel) ...[
              const SizedBox(height: 14),
              Row(children: [
                _num('Balandlik, mm', _h),
                const SizedBox(width: 8),
                _num('Kenglik, mm', _w),
                const SizedBox(width: 8),
                _num('Chuqurlik, mm', _d),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _num('DIN qatorlar', _rows),
                const SizedBox(width: 8),
                _num('Qatordagi modul', _perRow),
              ]),
              const SizedBox(height: 14),
              const Text('O\'rnatilishi', style: TextStyle(fontSize: 12, color: C.muted)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in ['Osma', 'O\'rnatma', 'Polga'])
                  Pill(label: m, selected: _mount == m, onTap: () => setState(() => _mount = m)),
              ]),
              const SizedBox(height: 12),
              const Text('Himoya darajasi', style: TextStyle(fontSize: 12, color: C.muted)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final ip in ['IP31', 'IP54', 'IP65'])
                  Pill(label: ip, monoText: true, selected: _ip == ip, onTap: () => setState(() => _ip = ip)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final PanelType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1E1A0E) : C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? C.amber : C.line, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 92,
                decoration: BoxDecoration(color: const Color(0xFF232A36), borderRadius: BorderRadius.circular(14)),
                child: CustomPaint(painter: PanelThumbPainter(type.key)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(type.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
                        ),
                        if (selected)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 15, color: C.ink),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${type.desc} · ${type.category.toLowerCase()}',
                        style: const TextStyle(fontSize: 12, color: C.soft)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tag('${type.modules} modul', true),
                        _tag(type.ip, false),
                        _tag(type.size, false),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String t, bool accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent ? C.amberSoft : const Color(0xFF232A36),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t, style: mono(11, color: accent ? C.amber : C.text2, weight: FontWeight.w500)),
      );
}
