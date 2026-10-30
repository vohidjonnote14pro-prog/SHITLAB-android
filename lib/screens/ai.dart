import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../calc.dart';
import '../models.dart';
import '../reference.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'reference_screen.dart';

class _Msg {
  final bool me;
  final String text;
  final List<(String, String)> table;
  final RefItem? ref;
  final String? ask; // Claude'ga yuboriladigan savol
  _Msg({required this.me, required this.text, this.table = const [], this.ref, this.ask});
}

/// Savolga ilovaning o'z hisoblari bilan javob beradi (internetsiz).
class LocalBrain {
  static double? _num(String s, RegExp re) {
    final m = re.firstMatch(s);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  static _Msg answer(String raw) {
    final s = raw.toLowerCase();

    // 1) Mening shitim
    if (s.contains('shitim') || s.contains('loyiham') || s.contains('mening shit')) {
      if (app.projects.isEmpty) {
        return _Msg(me: false, text: 'Hali loyiha yo\'q. "Loyihalar" bo\'limida shit yarating, keyin tekshirib beraman.');
      }
      final p = app.projects.first;
      final r = Calc.panel(p);
      final t = r.issues.isEmpty
          ? '"${p.name}" — PUE bo\'yicha kamchilik topilmadi. Quvvat ${fmt(r.totalKw)} kVt, kirish C${r.mainBreaker} 3P.'
          : '"${p.name}" da ${r.issues.length} ta band diqqat talab qiladi:\n• ${r.issues.join('\n• ')}';
      return _Msg(me: false, text: t, ask: 'Shitimni tekshirib ber: ${_projectText(p)}');
    }

    // 2) Hisob: quvvat bor bo'lsa
    var kw = _num(s, RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:kvt|kw|квт|kilovatt)'));
    final w = _num(s, RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:vt|w|вт|vatt)\b'));
    if (kw == null && w != null) kw = w / 1000;
    if (kw != null && kw > 0) {
      final len = _num(s, RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:m|metr|метр|м)\b')) ?? 0;
      final three = s.contains('3 faza') || s.contains('uch faza') || s.contains('3f') || s.contains('380');
      var type = 'power';
      if (RegExp(r'chiroq|yorit|lyustra|lampa|svet').hasMatch(s)) type = 'light';
      if (RegExp(r'rozetka|розетка').hasMatch(s)) type = 'socket';
      if (three) type = 'three';
      final l = Load(
        id: 'q',
        name: 'savol',
        type: type,
        powerKw: kw,
        cosPhi: RegExp(r'dvigatel|nasos|kompressor|konditsioner').hasMatch(s) ? 0.85 : 0.95,
        lengthM: len,
        phase: three ? '3F' : 'L1',
        mark: 'VVGLS',
      );
      final r = Calc.load(l);
      final table = <(String, String)>[
        ('Hisobiy tok', '${fmt(r.current)} A'),
        ('Avtomat', r.breakerText),
        ('Kabel', r.cableText),
        if (len > 0) ('Kuchlanish tushishi', '${fmt(r.du)} %'),
        ('UZO', r.uzo ? '30 mA kerak' : 'shart emas'),
        ('Nakonechnik', r.tip),
      ];
      final notes = <String>[];
      if (len == 0) notes.add('Kabel uzunligini ham yozsangiz (masalan "25 m"), kuchlanish tushishini tekshiraman.');
      notes.addAll(r.issues);
      if (RegExp(r'dvigatel|nasos|kompressor').hasMatch(s)) {
        notes.add('Dvigatel uchun D xarakteristikali avtomat ishga tushirish tokida uzib qo\'ymaydi.');
      }
      return _Msg(
        me: false,
        text: '${fmt(kw, kw < 1 ? 2 : 1)} kVt ${three ? 'uch fazali' : 'bir fazali'} yuklama uchun:'
            '${notes.isEmpty ? '' : '\n\n${notes.join('\n')}'}',
        table: table,
        ask: raw,
      );
    }

    // 3) Qurilma haqida
    RefItem? best;
    var bestScore = 0;
    for (final r in refItems) {
      var sc = 0;
      for (final k in r.keywords) {
        if (k.length > 1 && s.contains(k)) sc += k.length;
      }
      if (sc > bestScore) {
        bestScore = sc;
        best = r;
      }
    }
    if (best != null && bestScore >= 3) {
      return _Msg(me: false, text: '${best.name}: ${best.short.toLowerCase()}.\n\n${best.what}', ref: best, ask: raw);
    }

    return _Msg(
      me: false,
      text: 'Bu savolga ilova ichida tayyor javob yo\'q. Quvvatni yozsangiz (masalan "konditsioner 2,2 kVt 18 m"), '
          'avtomat va kabelni hisoblab beraman. Batafsil javob uchun pastdagi tugma bilan Claude\'dan so\'rang.',
      ask: raw,
    );
  }

  static String _projectText(Project p) {
    final b = StringBuffer('${p.name}, ${panelTypeByKey(p.panelType)?.name ?? 'shit'}, ${p.modules} modul. Yuklamalar: ');
    for (var i = 0; i < p.loads.length; i++) {
      final l = p.loads[i];
      final r = Calc.load(l);
      b.write('QF${i + 1} ${l.name} ${fmt(l.powerKw)} kVt, ${l.threePhase ? '3F' : l.phase}, ${fmt(l.lengthM, 0)} m, '
          '${r.breakerText}, ${r.cableText}; ');
    }
    return b.toString();
  }
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [
    _Msg(
      me: false,
      text: 'Salom! Men PUE bo\'yicha yordamchiman. Yuklamani yozing — avtomat, kabel va UZO\'ni hisoblayman. '
          'Qurilma nomini yozsangiz, nima qilishini tushuntiraman. Bu javoblar internetsiz ishlaydi.',
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final t = (preset ?? _input.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(me: true, text: t));
      _msgs.add(LocalBrain.answer(t));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _askClaude(String q) async {
    final prompt = 'Men elektrikman. O\'zbek tilida, PUE qoidalariga tayanib javob ber: $q';
    final uri = Uri.parse('https://claude.ai/new?q=${Uri.encodeComponent(prompt)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brauzer ochilmadi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Header(title: 'AI yordamchi', subtitle: 'PUE bo\'yicha savol bering', back: false),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              for (final m in _msgs) _bubble(m),
              if (_msgs.length <= 1) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in const [
                      'Konditsioner 2,2 kVt 18 m',
                      'Elektr plita 7,5 kVt 3 faza',
                      'UZO nima uchun kerak?',
                      'Shitimni tekshir',
                    ])
                      ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 13, color: C.text2)),
                        backgroundColor: C.card,
                        side: const BorderSide(color: Color(0xFF343D4D)),
                        shape: const StadiumBorder(),
                        onPressed: () => _send(s),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1E2530)))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Savolingizni yozing…',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: C.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: C.amber, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: C.amber,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _send(),
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: Icon(Icons.arrow_upward_rounded, color: C.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(_Msg m) {
    if (m.me) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            color: C.amber,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(m.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.ink, height: 1.4)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card,
          border: Border.all(color: C.line),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.text, style: const TextStyle(fontSize: 14, color: C.text2, height: 1.5)),
            if (m.table.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    for (final r in m.table)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 13, color: C.muted))),
                            Text(r.$2, style: mono(13, color: C.amber)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (m.ref != null || m.ask != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (m.ref != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.text,
                        side: const BorderSide(color: Color(0xFF343D4D)),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => RefDetailScreen(item: m.ref!))),
                      icon: const Icon(Icons.menu_book_outlined, size: 16),
                      label: const Text('Ma\'lumotnomada'),
                    ),
                  if (m.ask != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.amber,
                        side: const BorderSide(color: Color(0xFF5A4A1F)),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => _askClaude(m.ask!),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Claude\'dan batafsil'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ma'lumotnomani ochish uchun yordamchi.
void openReference(BuildContext context) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferenceScreen()));
