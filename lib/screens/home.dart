import 'package:flutter/material.dart';

import '../calc.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/painters.dart';
import '../widgets/ui.dart';
import 'new_panel.dart';
import 'panel.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const ProjectsPage(),
      const SoonPage(
        title: 'QR montaj',
        icon: Icons.photo_camera_outlined,
        text: 'Kabel yo\'llarini rasmga olish, QR stiker va Telegram orqali uy egasiga ko\'rsatish.',
        stage: 3,
      ),
      const SoonPage(
        title: 'Hisob-kitob',
        icon: Icons.calculate_outlined,
        text: 'Xonalar bo\'yicha nuqtalar jadvali va materiallar hisobi (PDF bilan).',
        stage: 3,
      ),
      const SoonPage(
        title: 'AI yordamchi',
        icon: Icons.chat_bubble_outline,
        text: 'PUE bo\'yicha savol-javob.',
        stage: 4,
      ),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: _BottomNav(index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      [Icons.grid_view_rounded, 'Loyihalar'],
      [Icons.photo_camera_outlined, 'QR montaj'],
      [Icons.calculate_outlined, 'Hisob-kitob'],
      [Icons.chat_bubble_outline, 'AI yordamchi'],
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141922),
        border: Border(top: BorderSide(color: Color(0xFF232A36))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i][0] as IconData, size: 23, color: i == index ? C.amber : C.muted),
                        const SizedBox(height: 4),
                        Text(
                          items[i][1] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == index ? FontWeight.w700 : FontWeight.w600,
                            color: i == index ? C.amber : C.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String text;
  final int stage;

  const SoonPage({super.key, required this.title, required this.icon, required this.text, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(title: title, back: false),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: C.amberSoft, borderRadius: BorderRadius.circular(22)),
                    child: Icon(icon, color: C.amber, size: 34),
                  ),
                  const SizedBox(height: 18),
                  Text('$stage-bosqichda qo\'shiladi',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.text)),
                  const SizedBox(height: 8),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: C.muted, height: 1.45)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const VmLogo(size: 42),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SHITLAB',
                                  style: TextStyle(
                                      fontSize: 12, color: C.muted, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              Text('Loyihalarim',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ma\'lumotnoma',
                          onPressed: () => soon(context, 'Ma\'lumotnoma', 4),
                          icon: const Icon(Icons.menu_book_outlined, color: C.text2),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!app.loaded)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (app.projects.isEmpty)
                  SliverFillRemaining(hasScrollBody: false, child: _EmptyProjects())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProjectCard(project: app.projects[i]),
                        ),
                        childCount: app.projects.length,
                      ),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                backgroundColor: C.amber,
                foregroundColor: C.ink,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const NewPanelScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Yangi shit', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF343D4D), width: 1.5),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.electrical_services_outlined, color: C.amber, size: 40),
            SizedBox(height: 14),
            Text('Hali loyiha yo\'q',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.text)),
            SizedBox(height: 8),
            Text(
              '"Yangi shit" tugmasini bosing: shit turini tanlaysiz, keyin yuklamalarni kiritasiz. '
              'Har bir loyiha telefon xotirasiga avtomatik saqlanadi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: C.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final r = Calc.panel(project);
    final type = panelTypeByKey(project.panelType);
    final ok = r.issues.isEmpty;
    return Material(
      color: C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: C.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => PanelScreen(projectId: project.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.text)),
                        const SizedBox(height: 3),
                        Text(
                          '${type?.name ?? 'O\'z o\'lchami'} · ${project.modules} modul · ${project.ip}',
                          style: const TextStyle(fontSize: 13, color: C.muted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_android, size: 12, color: Color(0xFF7FA894)),
                            const SizedBox(width: 4),
                            Text('Telefonda saqlangan · ${savedLabel(project.updated)}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF7FA894))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.loads.isEmpty ? const Color(0xFF3A2E12) : (ok ? const Color(0xFF16301F) : C.badSoft),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project.loads.isEmpty ? 'Bo\'sh' : (ok ? 'Tayyor' : 'Tekshiring'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: project.loads.isEmpty ? C.amber : (ok ? const Color(0xFF5FD39A) : C.badText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat('Quvvat', '${fmt(r.totalKw)} kVt'),
                  _stat('Yuklamalar', '${project.loads.length}'),
                  _stat('Kirish', r.mainBreaker > 0 ? 'C${r.mainBreaker} 3P' : '—'),
                ],
              ),
              if (project.loads.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final ph in ['L1', 'L2', 'L3'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: PhaseBar(
                      phase: ph,
                      current: r.phaseI[ph] ?? 0,
                      max: r.mainBreaker > 0 ? r.mainBreaker.toDouble() : 32,
                      labelColor: C.muted,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String k, String v) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: const TextStyle(fontSize: 11, color: C.muted)),
            const SizedBox(height: 2),
            Text(v, style: mono(15)),
          ],
        ),
      );
}
