import 'package:flutter/material.dart';

import '../reference.dart';
import '../theme.dart';
import '../widgets/device_painter.dart';
import '../widgets/ui.dart';

class ReferenceScreen extends StatefulWidget {
  final String? initialQuery;
  const ReferenceScreen({super.key, this.initialQuery});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  String _cat = 'Hammasi';
  late final TextEditingController _q = TextEditingController(text: widget.initialQuery ?? '');

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final list = refItems.where((r) {
      if (_cat != 'Hammasi' && r.category != _cat) return false;
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.code.toLowerCase() == q ||
          r.short.toLowerCase().contains(q) ||
          r.keywords.any((k) => k.contains(q) || q.contains(k) && k.length > 2);
    }).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(title: 'Ma\'lumotnoma', subtitle: 'Qurilma nima qiladi va qanday tanlanadi'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Qidirish: UZO, kontaktor, kabel…',
                  prefixIcon: const Icon(Icons.search, color: C.muted),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: C.muted),
                          onPressed: () => setState(() => _q.clear()),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final c in refCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Pill(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Hech narsa topilmadi', style: TextStyle(color: C.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _card(list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(RefItem r) {
    return Material(
      color: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RefDetailScreen(item: r))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 72,
                decoration: BoxDecoration(color: const Color(0xFF232A36), borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(6),
                child: CustomPaint(painter: DevicePainter(r)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text)),
                        ),
                        if (r.code.isNotEmpty) Text(r.code, style: mono(12, color: C.amber)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(r.short, style: const TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RefDetailScreen extends StatelessWidget {
  final RefItem item;
  const RefDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Widget block(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SectionLabel(title), const SizedBox(height: 8), child],
            ),
          ),
        );
    Widget bullets(List<String> xs, Color dot) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final x in xs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(x, style: const TextStyle(fontSize: 13.5, color: C.text2, height: 1.45))),
                  ],
                ),
              ),
          ],
        );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(title: item.name, subtitle: item.code.isEmpty ? item.category : 'Sxemadagi belgisi: ${item.code}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                children: [
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: C.card2,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF2A3240)),
                    ),
                    child: CustomPaint(painter: DevicePainter(item)),
                  ),
                  block('Nima qiladi', Text(item.what, style: const TextStyle(fontSize: 14, color: C.text2, height: 1.5))),
                  block('Qayerga qo\'yiladi', Text(item.where, style: const TextStyle(fontSize: 14, color: C.text2, height: 1.5))),
                  block('Qanday tanlanadi', bullets(item.choose, C.amber)),
                  block('Ko\'p uchraydigan xatolar', bullets(item.mistakes, C.bad)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
