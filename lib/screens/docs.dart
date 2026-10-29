import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../calc.dart';
import '../models.dart';
import '../pdfs.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// Mijoz hujjatlari: montaj pasporti + sxema, materiallar hisobi.
class DocsScreen extends StatefulWidget {
  final String projectId;
  const DocsScreen({super.key, required this.projectId});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  String? _busy;

  Future<void> _run(String key, Future<void> Function() job) async {
    setState(() => _busy = key);
    try {
      await job();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xato: $e')));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _file(Project p, String kind) => '${kind}_${p.name.replaceAll(RegExp(r'[^\wЀ-ӿ]+'), '_')}.pdf';

  @override
  Widget build(BuildContext context) {
    final p = app.byId(widget.projectId);
    if (p == null) return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
    final r = Calc.panel(p);
    final photos = p.photoRooms.fold<int>(0, (s, x) => s + x.photos.length);
    final sent = p.photoRooms.fold<int>(0, (s, x) => s + x.photos.where((y) => y.sent).length);
    final rows = <(String, String, bool?)>[
      ('Bir chiziqli sxema', p.loads.isEmpty ? 'Yuklama kiritilmagan' : 'Avtomatik tuziladi', p.loads.isNotEmpty),
      ('Loyiha va hisob jadvali', '${p.loads.length} yuklama · ${fmt(r.totalKw)} kVt', p.loads.isNotEmpty),
      ('PUE tekshiruvi', r.issues.isEmpty ? 'Kamchilik yo\'q' : '${r.issues.length} ta band diqqat talab qiladi',
          p.loads.isEmpty ? null : r.issues.isEmpty),
      ('Montaj rasmlari va QR', photos == 0 ? 'Rasm yo\'q (ixtiyoriy)' : '$photos rasm · $sent kanalda', photos == 0 ? null : sent == photos),
      ('Materiallar hisobi', p.calcRooms.isEmpty ? 'Hisob-kitob kiritilmagan' : '${p.calcRooms.length} xona', p.calcRooms.isEmpty ? null : true),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: 'Mijoz hujjatlari', subtitle: '${p.name}${p.address.isEmpty ? '' : ' · ${p.address}'}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: i == rows.length - 1
                                  ? null
                                  : const Border(bottom: BorderSide(color: Color(0xFF222936))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: rows[i].$3 == null
                                        ? const Color(0xFF232A36)
                                        : (rows[i].$3! ? C.okSoft : C.badSoft),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    rows[i].$3 == null ? Icons.remove : (rows[i].$3! ? Icons.check : Icons.priority_high),
                                    size: 17,
                                    color: rows[i].$3 == null
                                        ? C.muted
                                        : (rows[i].$3! ? const Color(0xFF5FD39A) : C.badText),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(rows[i].$1,
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
                                      Text(rows[i].$2, style: const TextStyle(fontSize: 12, color: C.muted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Mijoz'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _field('F.I.Sh.', p.client, (v) {
                                p.client = v;
                                app.save(p);
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field('Telefon', p.clientPhone, (v) {
                                p.clientPhone = v;
                                app.save(p);
                              }, phone: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _field('Obyekt manzili', p.address, (v) {
                          p.address = v;
                          app.save(p);
                        }),
                        const SizedBox(height: 16),
                        const SectionLabel('Bajaruvchi (siz)'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _field('F.I.Sh.', app.installer, (v) {
                                app.installer = v;
                                app.saveSettings();
                              }),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field('Telefon', app.installerPhone, (v) {
                                app.installerPhone = v;
                                app.saveSettings();
                              }, phone: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Bajaruvchi ma\'lumoti bir marta yoziladi, barcha hujjatlarga o\'zi qo\'yiladi.',
                            style: TextStyle(fontSize: 11.5, color: C.faint)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Expanded(child: SectionLabel('O\'lchov natijalari')),
                            Text('ixtiyoriy', style: TextStyle(fontSize: 11, color: C.faint)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _field('Izolyatsiya, MΩ', p.measIns, (v) {
                                p.measIns = v;
                                app.save(p);
                              }, hint: '≥ 0,5', number: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field('UZO, ms', p.measUzo, (v) {
                                p.measUzo = v;
                                app.save(p);
                              }, hint: '≤ 300', number: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _field('Yerga ulash, Ω', p.measEarth, (v) {
                                p.measEarth = v;
                                app.save(p);
                              }, hint: '≤ 30', number: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Kiritilsa pasportga yoziladi, kiritilmasa bo\'sh qator qoladi.',
                            style: TextStyle(fontSize: 11.5, color: C.faint)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _busy == 'pass' ? 'Tayyorlanmoqda…' : 'Montaj pasporti PDF — yuborish',
                    icon: Icons.send_rounded,
                    onTap: _busy != null
                        ? null
                        : () => _run('pass', () async {
                              final b = await buildPassport(p);
                              await Printing.sharePdf(bytes: b, filename: _file(p, 'Montaj_pasporti'));
                            }),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: 'Chop etish',
                          icon: Icons.print_outlined,
                          onTap: _busy != null
                              ? null
                              : () => _run('print', () async {
                                    final b = await buildPassport(p);
                                    await Printing.layoutPdf(onLayout: (_) async => b, name: _file(p, 'Montaj_pasporti'));
                                  }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GhostButton(
                          label: 'Materiallar PDF',
                          icon: Icons.calculate_outlined,
                          onTap: _busy != null || p.calcRooms.isEmpty
                              ? null
                              : () => _run('mat', () async {
                                    final b = await buildMaterials(p);
                                    await Printing.sharePdf(bytes: b, filename: _file(p, 'Materiallar'));
                                  }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pasport ikki betdan iborat: montaj pasporti va bir chiziqli sxema. '
                    'Yuborish tugmasi bosilganda Telegram yoki boshqa ilovani tanlaysiz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: C.faint, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged,
      {String? hint, bool number = false, bool phone = false}) {
    return TextFormField(
      initialValue: value,
      keyboardType: phone
          ? TextInputType.phone
          : (number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
      style: number ? mono(14) : const TextStyle(fontSize: 14, color: C.text),
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: onChanged,
    );
  }
}
