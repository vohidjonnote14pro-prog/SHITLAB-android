import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../calc.dart';
import '../materials.dart';
import '../models.dart';
import '../pdfs.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/app_builder.dart';
import '../widgets/ui.dart';

/// Pastki menyudagi "Hisob-kitob" bo'limi.
class HisobPage extends StatefulWidget {
  const HisobPage({super.key});

  @override
  State<HisobPage> createState() => _HisobPageState();
}

class _HisobPageState extends State<HisobPage> {
  String? _projectId;
  bool _busy = false;

  Project? _current() {
    if (app.projects.isEmpty) return null;
    final p = _projectId == null ? null : app.byId(_projectId!);
    return p ?? app.projects.first;
  }

  Future<void> _pdf(Project p, {bool print = false}) async {
    setState(() => _busy = true);
    try {
      final bytes = await buildMaterials(p);
      final name = 'Materiallar_${p.name.replaceAll(' ', '_')}.pdf';
      if (print) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF yaratilmadi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBuilder(
      builder: (context) {
        final p = _current();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header(
              title: 'Hisob-kitob',
              subtitle: p == null ? 'Xonalar bo\'yicha nuqtalar va materiallar' : '${p.name} · ${p.address.isEmpty ? 'obyekt' : p.address}',
              back: false,
              actions: [
                if (p != null && p.calcRooms.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: C.card2,
                          title: const Text('Jadvalni tozalash'),
                          content: const Text('Bu loyihadagi barcha xonalar va nuqtalar o\'chiriladi.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Tozalash', style: TextStyle(color: C.bad))),
                          ],
                        ),
                      );
                      if (ok == true) {
                        p.calcRooms.clear();
                        app.save(p);
                      }
                    },
                    child: const Text('Tozalash', style: TextStyle(color: C.text2)),
                  ),
              ],
            ),
            Expanded(
              child: p == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Avval "Loyihalar" bo\'limida obyekt (shit) yarating — hisob-kitob o\'sha loyihaga bog\'lanadi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: C.muted, height: 1.45),
                        ),
                      ),
                    )
                  : _body(p),
            ),
          ],
        );
      },
    );
  }

  Widget _body(Project p) {
    final mat = computeMaterials(p);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        if (app.projects.length > 1) ...[
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final x in app.projects)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Pill(
                      label: x.name,
                      selected: x.id == p.id,
                      onTap: () => setState(() => _projectId = x.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Box(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kabel markasi · mijoz tanlovi', style: TextStyle(fontSize: 12, color: C.muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final m in const ['ВВГнг-LS', 'ВВГнг', 'NYM'])
                  Pill(
                    label: m,
                    monoText: true,
                    selected: p.calcMark == m,
                    onTap: () {
                      p.calcMark = m;
                      app.save(p);
                    },
                  ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (p.calcRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF343D4D), width: 1.5),
            ),
            child: Column(
              children: [
                const Text('Hali nuqta kiritilmagan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 8),
                const Text(
                  'Mijoz qayerga rozetka, vyklyuchatel yoki TV xohlasa, xona bo\'yicha kiriting — materiallar shu zahoti hisoblanadi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: C.muted, height: 1.45),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: PrimaryButton(label: '+ Xona', onTap: () => _addRoom(p))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GhostButton(
                        label: 'Namuna',
                        onTap: () {
                          p.calcRooms = sampleRooms();
                          app.save(p);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else ...[
          for (var i = 0; i < p.calcRooms.length; i++) ...[
            _RoomCard(project: p, room: p.calcRooms[i], index: i),
            const SizedBox(height: 10),
          ],
          GhostButton(label: '+ Xona qo\'shish', icon: Icons.add, onTap: () => _addRoom(p)),
        ],
        const SizedBox(height: 16),
        _MaterialsCard(mat: mat),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Chop etish',
                icon: Icons.print_outlined,
                onTap: _busy || p.calcRooms.isEmpty ? null : () => _pdf(p, print: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: _busy ? 'Tayyorlanmoqda…' : 'PDF yuborish',
                icon: Icons.send_rounded,
                onTap: _busy || p.calcRooms.isEmpty ? null : () => _pdf(p),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('PDF tayyor bo\'lgach, Telegram yoki boshqa ilova orqali mijozga yuborasiz.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: C.faint)),
      ],
    );
  }

  void _addRoom(Project p) {
    p.calcRooms.add(CalcRoom(
      id: newId(),
      name: 'Xona №${p.calcRooms.length + 1}',
      items: [PointRow(id: newId(), type: 'roz', qty: 1, cable: 'c25', len: 0)],
    ));
    app.save(p);
  }
}

class _RoomCard extends StatelessWidget {
  final Project project;
  final CalcRoom room;
  final int index;
  const _RoomCard({required this.project, required this.room, required this.index});

  @override
  Widget build(BuildContext context) {
    final meters = room.items.fold<double>(0, (s, it) => s + it.len);
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: C.card2,
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.amberSoft, borderRadius: BorderRadius.circular(9)),
                  child: Text('${index + 1}', style: mono(12, color: C.amber)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('room-${room.id}'),
                    initialValue: room.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: 'Xona nomi',
                    ),
                    onChanged: (v) {
                      room.name = v;
                      app.save(project);
                    },
                  ),
                ),
                Text('${fmt(meters, meters == meters.roundToDouble() ? 0 : 1)} m', style: mono(12, color: C.soft)),
                IconButton(
                  tooltip: 'Xonani o\'chirish',
                  onPressed: () {
                    project.calcRooms.remove(room);
                    app.save(project);
                  },
                  icon: const Icon(Icons.delete_outline, size: 20, color: C.muted),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 2),
            child: Row(
              children: [
                Expanded(flex: 15, child: _ColHead('NUQTA')),
                SizedBox(width: 4),
                SizedBox(width: 46, child: _ColHead('SONI')),
                SizedBox(width: 4),
                Expanded(flex: 10, child: _ColHead('KABEL')),
                SizedBox(width: 4),
                SizedBox(width: 56, child: _ColHead('METR')),
                SizedBox(width: 30),
              ],
            ),
          ),
          for (final it in room.items) _row(it),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.amber,
                  side: const BorderSide(color: Color(0xFF343D4D)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  room.items.add(PointRow(id: newId(), type: 'roz', qty: 1, cable: 'c25', len: 0));
                  app.save(project);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nuqta qo\'shish', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(PointRow it) {
    InputDecoration deco() => const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          hintText: '0',
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 15,
            child: _Drop(
              value: it.type,
              items: {for (final t in pointTypes) t.key: t.label},
              onChanged: (v) {
                it.type = v;
                it.cable = pointType(v).cable;
                app.save(project);
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 46,
            child: TextFormField(
              key: ValueKey('q-${it.id}'),
              initialValue: it.qty == 0 ? '' : '${it.qty}',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: mono(13),
              decoration: deco(),
              onChanged: (v) {
                it.qty = toNum(v).round();
                app.save(project);
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 10,
            child: _Drop(
              value: it.cable,
              items: {for (final c in pointCables) c.key: c.short},
              monoText: true,
              onChanged: (v) {
                it.cable = v;
                app.save(project);
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 56,
            child: TextFormField(
              key: ValueKey('l-${it.id}'),
              initialValue: it.len == 0 ? '' : fmt(it.len, it.len == it.len.roundToDouble() ? 0 : 1),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: mono(13),
              decoration: deco(),
              onChanged: (v) {
                it.len = toNum(v);
                app.save(project);
              },
            ),
          ),
          SizedBox(
            width: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Qatorni o\'chirish',
              onPressed: () {
                room.items.remove(it);
                app.save(project);
              },
              icon: const Icon(Icons.close, size: 18, color: C.faint),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHead extends StatelessWidget {
  final String text;
  const _ColHead(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C8698), letterSpacing: 0.5));
}

class _Drop extends StatelessWidget {
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final bool monoText;
  const _Drop({required this.value, required this.items, required this.onChanged, this.monoText = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.containsKey(value) ? value : items.keys.first,
          isExpanded: true,
          isDense: true,
          dropdownColor: C.card2,
          iconSize: 18,
          style: monoText ? mono(12, color: C.amber) : const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.text),
          items: [
            for (final e in items.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _MaterialsCard extends StatelessWidget {
  final Materials mat;
  const _MaterialsCard({required this.mat});

  @override
  Widget build(BuildContext context) {
    Widget section(String title, List<MatLine> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF8A5A00))),
            ),
            if (items.isEmpty)
              const Text('—', style: TextStyle(color: Color(0xFF5A6370)))
            else
              for (var k = 0; k < items.length; k++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    border: k == items.length - 1 ? null : const Border(bottom: BorderSide(color: Color(0xFFE1E4E8))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(items[k].label,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF14110A)))),
                      Text(items[k].value, style: mono(13, color: const Color(0xFF14110A))),
                    ],
                  ),
                ),
          ],
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text('Materiallar hisobi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF14110A))),
              ),
              Text('kabelga +10% zaxira', style: TextStyle(fontSize: 11, color: Color(0xFF5A6370))),
            ],
          ),
          section('KABELLAR', mat.cables),
          section('O\'RNATISH MAHSULOTLARI', mat.goods),
          if (mat.panel.isNotEmpty) section('SHIT UCHUN (YUKLAMA HISOBIDAN)', mat.panel),
        ],
      ),
    );
  }
}
