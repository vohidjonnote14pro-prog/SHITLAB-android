import 'calc.dart';
import 'models.dart';

class MatLine {
  final String label;
  final String value;
  const MatLine(this.label, this.value);
}

class Materials {
  final List<MatLine> cables;
  final List<MatLine> goods;
  final List<MatLine> panel;
  final double totalLen;
  const Materials(this.cables, this.goods, this.panel, this.totalLen);
}

/// Xonalar jadvali va shit loyihasidan materiallar ro'yxatini hisoblaydi.
Materials computeMaterials(Project p) {
  final cabSum = <String, double>{};
  var boxes = 0;
  final mech = <String, int>{};
  var total = 0.0;
  var usedRooms = 0;
  for (final r in p.calcRooms) {
    if (r.items.isNotEmpty) usedRooms++;
    for (final it in r.items) {
      final t = pointType(it.type);
      total += it.len;
      cabSum[it.cable] = (cabSum[it.cable] ?? 0) + it.len;
      if (t.box) boxes += it.qty;
      if (t.mech.isNotEmpty) mech[t.mech] = (mech[t.mech] ?? 0) + it.qty;
    }
  }

  final cables = <MatLine>[];
  for (final c in pointCables) {
    final v = cabSum[c.key] ?? 0;
    if (v <= 0) continue;
    final label = c.power ? '${p.calcMark} ${c.sec}' : c.sec;
    cables.add(MatLine(label, '${(v * 1.1).ceil()} m'));
  }
  if (total > 0) cables.add(MatLine('Gofra truba Ø20', '${(total * 1.1).ceil()} m'));

  final goods = <MatLine>[];
  if (boxes > 0) goods.add(MatLine('Podrozetnik (kalso)', '$boxes dona'));
  mech.forEach((k, v) {
    if (v > 0) goods.add(MatLine(k, '$v dona'));
  });
  if (usedRooms > 0) {
    goods.add(MatLine('Taqsimlash qutisi', '$usedRooms dona'));
    goods.add(MatLine('WAGO klemma (har qutiga 5)', '${usedRooms * 5} dona'));
  }

  // Shit uchun: loyiha yuklamalaridan
  final panel = <MatLine>[];
  if (p.loads.isNotEmpty) {
    final r = Calc.panel(p);
    final type = panelTypeByKey(p.panelType);
    panel.add(MatLine('Shit ${type?.name ?? '(o\'z o\'lchami)'}', '1 dona'));
    if (r.mainBreaker > 0) panel.add(MatLine('Avtomat C${r.mainBreaker} 3P (kirish)', '1 dona'));
    final counts = <String, int>{};
    var uzoLines = 0;
    for (final l in p.loads) {
      final lr = Calc.load(l);
      if (lr.breaker <= 0) continue;
      final k = 'Avtomat C${lr.breaker} ${l.threePhase ? '3P' : '1P'}';
      counts[k] = (counts[k] ?? 0) + 1;
      if (lr.uzo) uzoLines++;
    }
    counts.forEach((k, v) => panel.add(MatLine(k, '$v dona')));
    if (uzoLines > 0) panel.add(MatLine('UZO 30 mA 2P', '${(uzoLines + 1) ~/ 2} dona'));
    if (r.mainCable != '—') panel.add(MatLine('Kirish kabeli ${r.mainCable}', 'uzunligi joyida'));
  }
  return Materials(cables, goods, panel, total);
}

List<CalcRoom> sampleRooms() {
  var n = 0;
  String id() => '${DateTime.now().microsecondsSinceEpoch}${n++}';
  PointRow r(String t, int q, String c, double l) => PointRow(id: id(), type: t, qty: q, cable: c, len: l);
  return [
    CalcRoom(id: id(), name: 'Zal', items: [
      r('roz', 4, 'c25', 17),
      r('vkl', 2, 'c15', 9),
      r('chir', 1, 'c15', 6),
      r('tv', 1, 'rg6', 12),
      r('net', 1, 'utp', 14),
    ]),
    CalcRoom(id: id(), name: 'Oshxona', items: [
      r('roz', 5, 'c25', 21),
      r('vkl', 1, 'c15', 6),
      r('isit', 1, 'c25', 8),
      r('plita', 1, 'c525', 7),
    ]),
  ];
}
