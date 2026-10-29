import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'calc.dart';
import 'materials.dart';
import 'models.dart';
import 'store.dart';

final _amber = PdfColor.fromInt(0xFFF5B731);
final _brown = PdfColor.fromInt(0xFF8A5A00);
final _ink = PdfColor.fromInt(0xFF14161A);
final _muted = PdfColor.fromInt(0xFF5A6370);
final _line = PdfColor.fromInt(0xFFE3E6EA);
final _head = PdfColor.fromInt(0xFFF3F4F6);
final _okc = PdfColor.fromInt(0xFF1F8A55);
final _badc = PdfColor.fromInt(0xFFBB3326);

class _Fonts {
  final pw.Font base;
  final pw.Font bold;
  final pw.Font mono;
  _Fonts(this.base, this.bold, this.mono);
}

_Fonts? _cache;

Future<_Fonts> _fonts() async {
  if (_cache != null) return _cache!;
  final b = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final bb = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
  final m = await rootBundle.load('assets/fonts/DejaVuSansMono.ttf');
  _cache = _Fonts(pw.Font.ttf(b), pw.Font.ttf(bb), pw.Font.ttf(m));
  return _cache!;
}

String _date(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

String docNumber(Project p) => 'SL-${p.tag.substring(2)}';

pw.Widget _header(_Fonts f, Project p, String right1, String right2) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Row(children: [
        pw.Container(
          width: 30,
          height: 30,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: _amber,
            borderRadius: pw.BorderRadius.circular(7),
          ),
          child: pw.Text('VM', style: pw.TextStyle(font: f.bold, fontSize: 11)),
        ),
        pw.SizedBox(width: 8),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('SHITLAB', style: pw.TextStyle(font: f.bold, fontSize: 12, letterSpacing: 1.5)),
          pw.Text('Elektr shitlarini loyihalash', style: pw.TextStyle(fontSize: 9, color: _muted)),
        ]),
      ]),
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text(right1, style: pw.TextStyle(font: f.mono, fontSize: 10)),
        pw.Text(right2, style: pw.TextStyle(fontSize: 9, color: _muted)),
      ]),
    ],
  );
}

pw.Widget _title(_Fonts f, String t, String sub) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 6),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.5))),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(t, style: pw.TextStyle(font: f.bold, fontSize: 19)),
        pw.SizedBox(height: 2),
        pw.Text(sub, style: pw.TextStyle(fontSize: 10.5, color: _muted)),
      ]),
    );

pw.Widget _h2(_Fonts f, String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Text(t, style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brown, letterSpacing: 0.8)),
    );

pw.Widget _kv(String k, String v) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6))),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Text(k, style: pw.TextStyle(fontSize: 9.5, color: _muted))),
        pw.Text(v, style: const pw.TextStyle(fontSize: 9.5)),
      ]),
    );

pw.Widget _table(_Fonts f, List<String> headers, List<List<String>> rows, {Map<int, pw.Alignment>? align}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.6)),
    headerDecoration: pw.BoxDecoration(color: _head),
    headerStyle: pw.TextStyle(font: f.bold, fontSize: 8.5),
    cellStyle: const pw.TextStyle(fontSize: 8.5),
    cellAlignments: align ?? {},
    headerAlignments: align ?? {},
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
  );
}

pw.Widget _footer(_Fonts f, String text, pw.Context ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6))),
      child: pw.Row(children: [
        pw.Expanded(child: pw.Text(text, style: pw.TextStyle(fontSize: 8, color: _muted))),
        pw.Text('${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(font: f.mono, fontSize: 8, color: _muted)),
      ]),
    );

pw.ThemeData _theme(_Fonts f) => pw.ThemeData.withFont(base: f.base, bold: f.bold);

pw.Widget _accent() => pw.Container(height: 5, color: _amber);

/// Montaj pasporti + bir chiziqli sxema (mijoz uchun).
Future<Uint8List> buildPassport(Project p) async {
  final f = await _fonts();
  final r = Calc.panel(p);
  final type = panelTypeByKey(p.panelType);
  final doc = pw.Document(title: 'Montaj pasporti — ${p.name}', author: app.installer.isEmpty ? 'ShitLab' : app.installer);
  final link = app.channelSearchLink(p.tag);
  final now = DateTime.now();

  final rows = <List<String>>[];
  for (var i = 0; i < p.loads.length; i++) {
    final l = p.loads[i];
    final lr = Calc.load(l);
    rows.add([
      'QF${i + 1}',
      l.name,
      l.threePhase ? '3F' : l.phase,
      fmt(l.powerKw),
      lr.ready ? fmt(lr.current) : '—',
      lr.breakerText,
      lr.uzo ? '30 mA' : '—',
      lr.cableText,
    ]);
  }

  String m(String v, String unit) => v.trim().isEmpty ? '________' : '${v.trim()} $unit';
  String verdict(String v, bool Function(double) ok) {
    final x = toNum(v);
    if (v.trim().isEmpty) return '________';
    return ok(x) ? 'Me\'yorda' : 'Me\'yordan tashqari';
  }

  final checks = <(String, bool)>[];
  var anyLoadIssue = false;
  var cableOk = true, duOk = true, alu = false;
  for (final l in p.loads) {
    final lr = Calc.load(l);
    if (lr.issues.isNotEmpty) anyLoadIssue = true;
    if (lr.section <= 0 || lr.breaker <= 0) cableOk = false;
    if (lr.du > Calc.maxDu) duOk = false;
    if (markByKey(l.mark).aluminium) alu = true;
  }
  final socketsUzo = p.loads.where((l) => l.type == 'socket').every((l) => Calc.load(l).uzo);
  checks.add(('Kabel kesimi avtomat nominaliga mos', cableOk));
  checks.add(('Kuchlanish tushishi 5% dan kam', duOk));
  checks.add(('Rozetka liniyalarida UZO 30 mA', socketsUzo));
  checks.add(('Selektivlik: guruh < kirish avtomati', r.mainBreaker > 0));
  checks.add(('Turar joyda mis o\'tkazgichlar', !alu));
  checks.add(('Fazalar muvozanati: farq ${fmt(r.imbalance, 0)}%', r.imbalance <= 30 || r.totalKw < 3));

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    theme: _theme(f),
    margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 28),
    header: (ctx) => ctx.pageNumber == 1 ? _accent() : pw.SizedBox(),
    footer: (ctx) => _footer(
        f, 'Montaj pasporti mijoz uchun ma\'lumot sifatida ShitLab ilovasida tuzildi.${link.isEmpty ? '' : ' Montaj rasmlari QR orqali ochiladi.'}', ctx),
    build: (ctx) => [
      pw.SizedBox(height: 10),
      _header(f, p, '№ ${docNumber(p)}', 'Sana: ${_date(now)}'),
      pw.SizedBox(height: 10),
      _title(f, 'ELEKTR MONTAJ PASPORTI', 'va elektr ta\'minoti loyihasi · mijoz uchun'),
      _h2(f, '1. OBYEKT VA SHIT'),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(children: [
            _kv('Obyekt', p.name),
            _kv('Manzil', p.address.isEmpty ? '________' : p.address),
            _kv('Mijoz', p.client.isEmpty ? '________' : '${p.client}${p.clientPhone.isEmpty ? '' : ', ${p.clientPhone}'}'),
            _kv('Bajaruvchi',
                app.installer.isEmpty ? '________' : '${app.installer}${app.installerPhone.isEmpty ? '' : ', ${app.installerPhone}'}'),
          ]),
        ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          child: pw.Column(children: [
            _kv('Shit turi', '${type?.name ?? 'O\'z o\'lchami'} · ${p.modules} modul · ${p.ip}'),
            _kv('Tarmoq', 'TN-C-S · 380/220 V'),
            _kv('Kirish', '${r.mainCable} · QF0 ${r.mainBreaker > 0 ? 'C${r.mainBreaker} 3P' : '—'}'),
            _kv('Hisobiy quvvat', '${fmt(r.totalKw)} kVt'),
          ]),
        ),
      ]),
      _h2(f, '2. YUKLAMALAR VA HIMOYA APPARATLARI'),
      if (rows.isEmpty)
        pw.Text('Yuklamalar kiritilmagan', style: pw.TextStyle(fontSize: 9, color: _muted))
      else
        _table(f, ['№', 'Yuklama', 'Faza', 'P, kVt', 'I, A', 'Avtomat', 'UZO', 'Kabel'], rows,
            align: {3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight}),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4),
        child: pw.Text(
          'Fazalar: L1 ${fmt(r.phaseI['L1']!)} A · L2 ${fmt(r.phaseI['L2']!)} A · L3 ${fmt(r.phaseI['L3']!)} A',
          style: pw.TextStyle(fontSize: 8.5, color: _muted),
        ),
      ),
      _h2(f, '3. O\'LCHOV NATIJALARI (o\'tkazilgan bo\'lsa)'),
      _table(f, [
        'Ko\'rsatkich',
        'Me\'yor',
        'O\'lchangan',
        'Xulosa'
      ], [
        ['Izolyatsiya qarshiligi', '≥ 0,5 MΩ', m(p.measIns, 'MΩ'), verdict(p.measIns, (x) => x >= 0.5)],
        ['UZO ishlash vaqti (IΔn da)', '≤ 300 ms', m(p.measUzo, 'ms'), verdict(p.measUzo, (x) => x > 0 && x <= 300)],
        ['Yerga ulash qarshiligi', '≤ 30 Ω', m(p.measEarth, 'Ω'), verdict(p.measEarth, (x) => x > 0 && x <= 30)],
      ]),
      _h2(f, '4. PUE TALABLARIGA MUVOFIQLIK'),
      pw.Wrap(spacing: 18, runSpacing: 4, children: [
        for (final c in checks)
          pw.SizedBox(
            width: 250,
            child: pw.Row(children: [
              pw.Text(c.$2 ? '✓' : '!', style: pw.TextStyle(font: f.bold, fontSize: 10, color: c.$2 ? _okc : _badc)),
              pw.SizedBox(width: 6),
              pw.Expanded(child: pw.Text(c.$1, style: const pw.TextStyle(fontSize: 9))),
            ]),
          ),
      ]),
      pw.SizedBox(height: 12),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF7F8FA),
              border: pw.Border.all(color: _line),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Xulosa', style: pw.TextStyle(font: f.bold, fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.Text(
                anyLoadIssue
                    ? 'Elektr montaj ishlari ushbu loyiha bo\'yicha bajarildi. Loyihada e\'tibor talab qiladigan bandlar bor (yuqoridagi "!" belgilari).'
                    : 'Elektr montaj ishlari ushbu loyiha bo\'yicha bajarildi. Kabel, avtomat va himoya tanlovi PUE talablari asosida hisoblangan. Elektr tarmoq foydalanishga topshirildi.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Ilova: bir chiziqli sxema (keyingi bet)${link.isEmpty ? '' : ', montaj rasmlari (QR orqali)'}.',
                  style: pw.TextStyle(fontSize: 8.5, color: _muted)),
            ]),
          ),
        ),
        if (link.isNotEmpty) ...[
          pw.SizedBox(width: 14),
          pw.Column(children: [
            pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: link, width: 78, height: 78),
            pw.SizedBox(height: 3),
            pw.Text('Montaj rasmlari', style: pw.TextStyle(fontSize: 8, color: _muted)),
          ]),
        ],
      ]),
      pw.SizedBox(height: 22),
      pw.Row(children: [
        pw.Expanded(child: _sign('Bajaruvchi', app.installer)),
        pw.SizedBox(width: 20),
        pw.Expanded(child: _sign('Qabul qildi (mijoz)', p.client)),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 64,
          height: 64,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
          ),
          child: pw.Text("M.O'.", style: pw.TextStyle(fontSize: 8, color: _muted)),
        ),
      ]),
    ],
  ));

  if (p.loads.isNotEmpty) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      theme: _theme(f),
      margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 24),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _accent(),
        pw.SizedBox(height: 8),
        _header(f, p, '№ ${docNumber(p)} · 2-bet', p.name),
        pw.SizedBox(height: 6),
        _title(f, 'BIR CHIZIQLI SXEMA', 'Avtomatik chizilgan · ${type?.name ?? ''} · Σ ${fmt(r.totalKw)} kVt'),
        pw.SizedBox(height: 10),
        _schema(f, p, r),
      ]),
    ));
  }
  return doc.save();
}

pw.Widget _sign(String label, String name) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _muted)),
      pw.SizedBox(height: 22),
      pw.Container(height: 0.8, color: _ink),
      pw.SizedBox(height: 3),
      pw.Text(name.isEmpty ? '[F.I.Sh.] · imzo' : '$name · imzo', style: pw.TextStyle(fontSize: 8.5, color: _muted)),
    ]);

pw.Widget _schema(_Fonts f, Project p, PanelResult r) {
  final n = p.loads.length;
  const w = 780.0;
  const h = 400.0;
  {
    final col = n == 0 ? w : (w / n).clamp(40.0, 110.0);
    final total = col * n;
    final startX = (w - total) / 2 + col / 2;
    final cx = w / 2;
    // y — yuqoridan pastga (pdf koordinatasi teskari, shuning uchun h - y)
    double y(double v) => h - v;
    final busY = 150.0;
    final texts = <pw.Widget>[];
    pw.Widget at(double x, double top, String t, {double size = 8, bool bold = false, PdfColor? color, double width = 100}) =>
        pw.Positioned(
          left: x - width / 2,
          top: top,
          child: pw.SizedBox(
            width: width,
            child: pw.Text(t,
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                style: pw.TextStyle(fontSize: size, font: bold ? f.bold : f.base, color: color ?? _ink)),
          ),
        );
    texts.add(at(cx, 4, 'Kirish · TN-C-S · ${r.mainCable} · 380/220 V', size: 9, bold: true, width: 300));
    texts.add(at(cx + 70, 46, 'PI · 3F hisoblagich', size: 8, color: _muted, width: 120));
    texts.add(at(cx + 60, 98, 'QF0 · ${r.mainBreaker > 0 ? 'C${r.mainBreaker} 3P' : '—'}', size: 9, bold: true, width: 120));
    for (var i = 0; i < n; i++) {
      final l = p.loads[i];
      final lr = Calc.load(l);
      final x = startX + i * col;
      texts.add(at(x, busY + 92, 'QF${i + 1}', size: 9, bold: true, width: col));
      texts.add(at(x, busY + 104, lr.breakerText.replaceAll(' 1P', ''), size: 8, width: col));
      texts.add(at(x, busY + 115, lr.section > 0 ? '${lr.cores}×${secLabel(lr.section)}' : '—', size: 8, color: _muted, width: col));
      if (lr.uzo) texts.add(at(x, busY + 22, '30mA', size: 7, color: _okc, width: col));
      texts.add(at(x, busY + 168, l.threePhase ? '3F' : l.phase, size: 8, bold: true, width: col));
      texts.add(at(x, busY + 180, l.name, size: 8, width: col - 4));
      texts.add(at(x, busY + 204, '${fmt(l.powerKw)} kVt', size: 8, color: _muted, width: col));
    }
    return pw.SizedBox(width: w, height: h, child: pw.Stack(children: [
      pw.CustomPaint(
        size: PdfPoint(w, h),
        painter: (PdfGraphics c, PdfPoint size) {
          c
            ..setStrokeColor(_ink)
            ..setLineWidth(1.4);
          void line(double x1, double y1, double x2, double y2) {
            c
              ..moveTo(x1, y(y1))
              ..lineTo(x2, y(y2))
              ..strokePath();
          }

          void breaker(double x, double top) {
            line(x, top, x, top + 10);
            line(x, top + 24, x, top + 34);
            c.setStrokeColor(_amber);
            c.setLineWidth(2);
            line(x, top + 24, x + 7, top + 10);
            c.setStrokeColor(_ink);
            c.setLineWidth(1.1);
            line(x - 3, top + 7, x + 3, top + 13);
            line(x + 3, top + 7, x - 3, top + 13);
            c.setLineWidth(1.4);
          }

          line(cx, 18, cx, 40);
          c
            ..drawRect(cx - 20, y(68), 40, 26)
            ..strokePath();
          line(cx, 68, cx, 84);
          breaker(cx, 84);
          line(cx, 118, cx, busY);
          final left = n == 0 ? cx : (startX < cx ? startX : cx);
          final right = n == 0 ? cx : ((startX + (n - 1) * col) > cx ? startX + (n - 1) * col : cx);
          c
            ..setFillColor(_amber)
            ..drawRect(left, y(busY + 3), right - left, 4)
            ..fillPath();
          for (var i = 0; i < n; i++) {
            final l = p.loads[i];
            final lr = Calc.load(l);
            final x = startX + i * col;
            if (lr.uzo) {
              line(x, busY + 3, x, busY + 18);
              c
                ..setStrokeColor(_okc)
                ..drawRRect(x - 16, y(busY + 34), 32, 16, 3, 3)
                ..strokePath()
                ..setStrokeColor(_ink);
              line(x, busY + 34, x, busY + 50);
            } else {
              line(x, busY + 3, x, busY + 50);
            }
            breaker(x, busY + 50);
            line(x, busY + 84, x, busY + 90);
            line(x, busY + 128, x, busY + 146);
            c
              ..drawEllipse(x, y(busY + 156), 9, 9)
              ..strokePath();
          }
        },
      ),
      ...texts,
    ]));
  }
}

/// Materiallar hisobi (xonalar jadvali + kerakli mahsulotlar).
Future<Uint8List> buildMaterials(Project p) async {
  final f = await _fonts();
  final mat = computeMaterials(p);
  final doc = pw.Document(title: 'Materiallar hisobi — ${p.name}');
  final rows = <List<String>>[];
  for (var i = 0; i < p.calcRooms.length; i++) {
    final r = p.calcRooms[i];
    for (var k = 0; k < r.items.length; k++) {
      final it = r.items[k];
      final c = pointCable(it.cable);
      rows.add([
        k == 0 ? '${i + 1} · ${r.name}' : '',
        pointType(it.type).label,
        '${it.qty}',
        c.power ? c.sec : c.short,
        fmt(it.len, it.len == it.len.roundToDouble() ? 0 : 1),
      ]);
    }
  }
  rows.add(['', 'Jami kabel (zaxirasiz)', '', '', fmt(mat.totalLen, 0)]);

  pw.Widget list(String title, List<MatLine> items) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        _h2(f, title),
        if (items.isEmpty) pw.Text('—', style: pw.TextStyle(fontSize: 9, color: _muted)),
        for (final m in items) _kv(m.label, m.value),
      ]);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    theme: _theme(f),
    margin: const pw.EdgeInsets.fromLTRB(36, 30, 36, 28),
    header: (ctx) => ctx.pageNumber == 1 ? _accent() : pw.SizedBox(),
    footer: (ctx) => _footer(f, 'Hisob ShitLab ilovasida tuzildi. Kabel uzunligiga 10% zaxira qo\'shilgan.', ctx),
    build: (ctx) => [
      pw.SizedBox(height: 10),
      _header(f, p, p.address.isEmpty ? p.name : p.address,
          'Sana: ${_date(DateTime.now())}${p.client.isEmpty ? '' : ' · Mijoz: ${p.client}'}'),
      pw.SizedBox(height: 10),
      _title(f, 'MATERIALLAR HISOBI', 'Xonalar bo\'yicha nuqtalar va kerakli mahsulotlar · kabel: ${p.calcMark}'),
      _h2(f, '1. XONALAR BO\'YICHA NUQTALAR'),
      _table(f, ['Xona', 'Nuqta', 'Soni', 'Kabel', 'Metr'], rows,
          align: {2: pw.Alignment.centerRight, 4: pw.Alignment.centerRight}),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: list('2. KABELLAR (+10% ZAXIRA)', mat.cables)),
        pw.SizedBox(width: 22),
        pw.Expanded(child: list('3. O\'RNATISH MAHSULOTLARI', mat.goods)),
      ]),
      if (mat.panel.isNotEmpty) list('4. SHIT UCHUN (YUKLAMA HISOBIDAN)', mat.panel),
      pw.SizedBox(height: 24),
      pw.Row(children: [
        pw.Expanded(child: _sign('Hisobladi (elektrik)', app.installer)),
        pw.SizedBox(width: 24),
        pw.Expanded(child: _sign('Tanishdi (mijoz)', p.client)),
      ]),
    ],
  ));
  return doc.save();
}

/// QR stiker (shit eshigiga yopishtirish uchun).
Future<Uint8List> buildSticker(Project p, String link, {String? room}) async {
  final f = await _fonts();
  final doc = pw.Document(title: 'QR stiker — ${p.name}');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a6,
    theme: _theme(f),
    margin: const pw.EdgeInsets.all(18),
    build: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _ink, width: 1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Row(children: [
            pw.Container(
              width: 22,
              height: 22,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(color: _amber, borderRadius: pw.BorderRadius.circular(5)),
              child: pw.Text('VM', style: pw.TextStyle(font: f.bold, fontSize: 8)),
            ),
            pw.SizedBox(width: 6),
            pw.Text('SHITLAB', style: pw.TextStyle(font: f.bold, fontSize: 10, letterSpacing: 1)),
          ]),
          pw.Text('380/220 V', style: pw.TextStyle(font: f.mono, fontSize: 8)),
        ]),
        pw.Spacer(),
        pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: link, width: 170, height: 170),
        pw.Spacer(),
        pw.Text(room == null ? p.name : '${p.name} · $room',
            textAlign: pw.TextAlign.center, style: pw.TextStyle(font: f.bold, fontSize: 12)),
        pw.SizedBox(height: 3),
        pw.Text('Skanerlang: devordagi kabel yo\'llari rasmlari',
            textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
    ),
  ));
  return doc.save();
}
