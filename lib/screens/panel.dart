import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/app_builder.dart';
import '../widgets/ui.dart';
import 'ai.dart';
import 'docs.dart';
import 'load_edit.dart';
import 'qr.dart';
import 'schema.dart';
import 'sim/simulation.dart';

class PanelScreen extends StatelessWidget {
  final String projectId;
  const PanelScreen({super.key, required this.projectId});

  Future<void> _rename(BuildContext context, Project p) async {
    final c = TextEditingController(text: p.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card2,
        title: const Text('Loyiha nomi'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Saqlash')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      p.name = c.text.trim();
      app.touch(p);
    }
  }

  Future<void> _delete(BuildContext context, Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card2,
        title: const Text('Loyihani o\'chirish'),
        content: Text('"${p.name}" telefondan butunlay o\'chiriladi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('O\'chirish', style: TextStyle(color: C.bad)),
          ),
        ],
      ),
    );
    if (ok == true) {
      app.remove(p);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBuilder(
      builder: (context) {
        final p = app.byId(projectId);
        if (p == null) {
          return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
        }
        final r = Calc.panel(p);
        final type = panelTypeByKey(p.panelType);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Header(
                  title: p.name,
                  subtitle:
                      '${type?.name ?? 'O\'z o\'lchami'} · ${p.modules} modul · ${r.usedModules > 0 ? '${r.usedModules} band' : 'bo\'sh'}',
                  actions: [
                    PopupMenuButton<String>(
                      color: C.card2,
                      icon: const Icon(Icons.more_vert, color: C.text2),
                      onSelected: (v) {
                        if (v == 'rename') _rename(context, p);
                        if (v == 'docs') {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocsScreen(projectId: p.id)));
                        }
                        if (v == 'photos') {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => ObjectPhotosScreen(projectId: p.id)));
                        }
                        if (v == 'delete') _delete(context, p);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'docs', child: Text('Mijoz hujjatlari (PDF)')),
                        PopupMenuItem(value: 'photos', child: Text('Montaj rasmlari va QR')),
                        PopupMenuItem(value: 'rename', child: Text('Nomini o\'zgartirish')),
                        PopupMenuItem(value: 'delete', child: Text('Loyihani o\'chirish')),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    children: [
                      _Hero(result: r),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Tile(
                            icon: Icons.account_tree_outlined,
                            label: 'Sxema',
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => SchemaScreen(projectId: p.id))),
                          ),
                          const SizedBox(width: 8),
                          _Tile(
                            icon: Icons.play_arrow_rounded,
                            label: 'Simulyatsiya',
                            onTap: p.loads.isEmpty
                                ? () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Avval yuklama qo\'shing')),
                                    )
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => SimulationScreen(projectId: p.id))),
                          ),
                          const SizedBox(width: 8),
                          _Tile(
                            icon: Icons.balance,
                            label: 'Avto faza',
                            onTap: p.loads.isEmpty
                                ? null
                                : () {
                                    Calc.autoBalance(p);
                                    app.touch(p);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Yuklamalar fazalarga teng taqsimlandi')),
                                    );
                                  },
                          ),
                          const SizedBox(width: 8),
                          _Tile(
                            icon: Icons.menu_book_outlined,
                            label: 'Qurilmalar',
                            onTap: () => openReference(context),
                          ),
                        ],
                      ),
                      if (r.issues.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: C.badSoft, borderRadius: BorderRadius.circular(18)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PUE tekshiruvi: diqqat',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.badText)),
                              const SizedBox(height: 6),
                              for (final s in r.issues)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('• $s',
                                      style: const TextStyle(fontSize: 13, color: C.text2, height: 1.4)),
                                ),
                            ],
                          ),
                        ),
                      ] else if (p.loads.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const StatusBox(
                          ok: true,
                          title: 'PUE talablariga mos',
                          text: 'Kabel, avtomat, UZO, kuchlanish tushishi va selektivlik tekshirildi',
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Yuklamalar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text)),
                          ),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => LoadEditScreen(projectId: p.id))),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (p.loads.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF343D4D), width: 1.5),
                          ),
                          child: const Text(
                            'Hali yuklama yo\'q. Yoritish, rozetkalar, konditsioner, plita kabi har bir liniyani '
                            'alohida qo\'shing — avtomat va kabel o\'zi hisoblanadi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.45),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: C.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: C.line),
                          ),
                          child: Column(
                            children: [
                              for (var i = 0; i < p.loads.length; i++)
                                _LoadRow(
                                  index: i,
                                  load: p.loads[i],
                                  last: i == p.loads.length - 1,
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => LoadEditScreen(projectId: p.id, loadId: p.loads[i].id))),
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: C.amber,
            foregroundColor: C.ink,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => LoadEditScreen(projectId: p.id))),
            icon: const Icon(Icons.add),
            label: const Text('Yuklama', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final PanelResult result;
  const _Hero({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    final max = r.mainBreaker > 0 ? r.mainBreaker.toDouble() : 32.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: C.amber, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UMUMIY QUVVAT',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xBF14110A))),
                    Text('${fmt(r.totalKw)} kVt', style: mono(32, color: C.ink)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('KIRISH',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xBF14110A))),
                  Text(r.mainBreaker > 0 ? 'C${r.mainBreaker} 3P' : '—', style: mono(15, color: C.ink)),
                  Text(r.mainCable,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.ink)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final ph in ['L1', 'L2', 'L3'])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PhaseBar(
                phase: ph,
                current: r.phaseI[ph] ?? 0,
                max: max,
                track: const Color(0x2614110A),
                fill: C.ink,
                labelColor: C.ink,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Material(
          color: C.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: C.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: SizedBox(
              height: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: C.amber, size: 22),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.text)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadRow extends StatelessWidget {
  final int index;
  final Load load;
  final bool last;
  final VoidCallback onTap;

  const _LoadRow({required this.index, required this.load, required this.last, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = Calc.load(load);
    final ph = load.threePhase ? '3F' : load.phase;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: Color(0xFF222936))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.phaseSoft(ph), borderRadius: BorderRadius.circular(10)),
              child: Text(ph, style: mono(11, color: C.phase(ph), weight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QF${index + 1} · ${load.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text)),
                  const SizedBox(height: 2),
                  Text('${fmt(load.powerKw)} kVt · ${r.cableText}${r.uzo ? ' · UZO' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: r.ok ? C.muted : C.badText)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(r.breakerText.replaceAll(' 1P', ''), style: mono(13, color: C.text2)),
          ],
        ),
      ),
    );
  }
}
