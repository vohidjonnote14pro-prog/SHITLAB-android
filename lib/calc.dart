import 'dart:math' as math;

import 'models.dart';

String fmt(double v, [int d = 1]) => v.toStringAsFixed(d).replaceAll('.', ',');

String secLabel(double s) =>
    s == s.roundToDouble() ? s.toInt().toString() : fmt(s, 1);

/// Bitta yuklama hisobining natijasi.
class LoadResult {
  final bool ready;
  final double current;
  final int breaker;
  final double section;
  final int cores;
  final double du;
  final bool uzo;
  final String tip;
  final List<String> issues;
  final String cableText;
  final String breakerText;

  const LoadResult({
    required this.ready,
    required this.current,
    required this.breaker,
    required this.section,
    required this.cores,
    required this.du,
    required this.uzo,
    required this.tip,
    required this.issues,
    required this.cableText,
    required this.breakerText,
  });

  bool get ok => ready && issues.isEmpty;

  static const empty = LoadResult(
    ready: false,
    current: 0,
    breaker: 0,
    section: 0,
    cores: 3,
    du: 0,
    uzo: false,
    tip: '—',
    issues: [],
    cableText: '—',
    breakerText: '—',
  );
}

/// Shit bo'yicha umumiy natija.
class PanelResult {
  final Map<String, double> phaseI;
  final double totalKw;
  final int mainBreaker;
  final String mainCable;
  final double imbalance;
  final int usedModules;
  final List<String> issues;

  const PanelResult({
    required this.phaseI,
    required this.totalKw,
    required this.mainBreaker,
    required this.mainCable,
    required this.imbalance,
    required this.usedModules,
    required this.issues,
  });
}

/// PUE bo'yicha hisoblar.
///
/// Kabelning ruxsat etilgan toki — mis va alyuminiy o'tkazgichlar,
/// yashirin (quvur yoki devor ichida) yotqizilgan uch tomirli kabel uchun.
class Calc {
  static const breakers = [6, 10, 13, 16, 20, 25, 32, 40, 50, 63];
  static const mainBreakers = [16, 20, 25, 32, 40, 50, 63, 80, 100, 125];

  static const copper = <List<double>>[
    [1.5, 19],
    [2.5, 25],
    [4, 35],
    [6, 42],
    [10, 55],
    [16, 75],
    [25, 95],
    [35, 120],
    [50, 145],
  ];

  static const aluminium = <List<double>>[
    [2.5, 19],
    [4, 27],
    [6, 32],
    [10, 42],
    [16, 60],
    [25, 75],
    [35, 90],
  ];

  static const double voltPhase = 230;
  static const double voltLine = 380;
  static const double maxDu = 5;

  static String tipFor(double s) {
    if (s <= 1.5) return 'НШВИ 1,5-8';
    if (s <= 2.5) return 'НШВИ 2,5-8';
    if (s <= 4) return 'НШВИ 4-9';
    if (s <= 6) return 'НШВИ 6-12';
    if (s <= 10) return 'НШВИ 10-12';
    if (s <= 16) return 'НШВИ 16-12';
    if (s <= 25) return 'НШВИ 25-16';
    return 'НШВИ 35-16';
  }

  static double current(Load l) {
    final cos = (l.cosPhi <= 0 || l.cosPhi > 1) ? 0.95 : l.cosPhi;
    if (l.powerKw <= 0) return 0;
    return l.threePhase
        ? l.powerKw * 1000 / (math.sqrt(3) * voltLine * cos)
        : l.powerKw * 1000 / (voltPhase * cos);
  }

  static double dropPercent(Load l, double i, double s, bool alu) {
    if (l.lengthM <= 0 || s <= 0) return 0;
    final rho = alu ? 0.028 : 0.0175;
    if (l.threePhase) {
      return math.sqrt(3) * l.lengthM * i * rho / s / voltLine * 100;
    }
    return 2 * l.lengthM * i * rho / s / voltPhase * 100;
  }

  static LoadResult load(Load l) {
    if (l.powerKw <= 0) return LoadResult.empty;
    final mark = markByKey(l.mark);
    final alu = mark.aluminium;
    final i = current(l);
    final issues = <String>[];

    var brk = 0;
    for (final b in breakers) {
      if (b >= i) {
        brk = b;
        break;
      }
    }

    final table = alu ? aluminium : copper;
    var minSec = l.type == 'socket' ? 2.5 : 1.5;
    if (alu && minSec < 2.5) minSec = 2.5;

    var ci = -1;
    if (brk > 0) {
      for (var k = 0; k < table.length; k++) {
        if (table[k][0] >= minSec && table[k][1] >= brk) {
          ci = k;
          break;
        }
      }
    }

    var du = 0.0;
    if (ci >= 0) {
      du = dropPercent(l, i, table[ci][0], alu);
      while (du > maxDu && ci < table.length - 1) {
        ci++;
        du = dropPercent(l, i, table[ci][0], alu);
      }
    }

    if (brk == 0) {
      issues.add('Tok 63 A dan katta — yuklamani bo\'ling yoki 3 fazaga o\'tkazing');
    } else if (ci < 0) {
      issues.add('Mos kabel kesimi topilmadi');
    }
    if (du > maxDu) {
      issues.add('Kuchlanish tushishi ${fmt(du)}% — 5% dan oshdi');
    }
    if (alu) {
      issues.add('Turar joyda mis kabel ishlating (PUE 7.1)');
    }
    if (mark.key == 'PVS') {
      issues.add('ПВС devor ichiga yotqizilmaydi — ВВГнг yoki NYM tanlang');
    }

    final sec = ci >= 0 ? table[ci][0] : 0.0;
    final cores = l.threePhase ? 5 : 3;
    final uzo = l.type == 'socket' || l.type == 'power';

    return LoadResult(
      ready: true,
      current: i,
      breaker: brk,
      section: sec,
      cores: cores,
      du: du,
      uzo: uzo,
      tip: sec > 0 ? (alu ? 'Cu-Al klemma' : tipFor(sec)) : '—',
      issues: issues,
      cableText: sec > 0 ? '${mark.label} $cores×${secLabel(sec)}' : '—',
      breakerText: brk > 0 ? 'C$brk ${l.threePhase ? '3P' : '1P'}' : '—',
    );
  }

  static PanelResult panel(Project p) {
    final phaseI = <String, double>{'L1': 0, 'L2': 0, 'L3': 0};
    var totalKw = 0.0;
    var maxGroup = 0;
    var modules = 0;
    var uzoCount = 0;
    final issues = <String>[];

    for (final l in p.loads) {
      final r = load(l);
      if (!r.ready) continue;
      totalKw += l.powerKw;
      if (r.breaker > maxGroup) maxGroup = r.breaker;
      if (l.threePhase) {
        phaseI['L1'] = phaseI['L1']! + r.current;
        phaseI['L2'] = phaseI['L2']! + r.current;
        phaseI['L3'] = phaseI['L3']! + r.current;
        modules += 3;
      } else {
        phaseI[l.phase] = (phaseI[l.phase] ?? 0) + r.current;
        modules += 1;
      }
      if (r.uzo) uzoCount++;
    }

    final maxI = [phaseI['L1']!, phaseI['L2']!, phaseI['L3']!].reduce(math.max);
    final minI = [phaseI['L1']!, phaseI['L2']!, phaseI['L3']!].reduce(math.min);
    final avg = (phaseI['L1']! + phaseI['L2']! + phaseI['L3']!) / 3;

    var main = 0;
    if (p.loads.isNotEmpty) {
      for (final b in mainBreakers) {
        if (b >= maxI && b > maxGroup) {
          main = b;
          break;
        }
      }
      if (main == 0) {
        issues.add('Kirish toki juda katta — ВРУ yoki alohida kirish kerak');
      }
    }

    var mainCable = '—';
    if (main > 0) {
      for (final row in copper) {
        if (row[1] >= main) {
          mainCable = 'ВВГнг-LS 5×${secLabel(row[0])}';
          break;
        }
      }
    }

    // UZO 2 modul: har ikki rozetka/texnika guruhiga bittadan hisoblaymiz.
    final uzoModules = ((uzoCount + 1) ~/ 2) * 2;
    final used = p.loads.isEmpty ? 0 : modules + uzoModules + 3;
    if (used > p.modules) {
      issues.add('Shitga sig\'maydi: $used modul kerak, shitda ${p.modules} ta');
    }

    final imbalance = avg > 0 ? (maxI - minI) / avg * 100 : 0.0;
    if (avg > 3 && imbalance > 30) {
      issues.add('Fazalar nomutanosib (${fmt(imbalance, 0)}%) — "Avto taqsimlash"ni bosing');
    }

    for (var k = 0; k < p.loads.length; k++) {
      final r = load(p.loads[k]);
      if (r.issues.isNotEmpty) {
        issues.add('QF${k + 1}: ${r.issues.first}');
      }
    }

    return PanelResult(
      phaseI: phaseI,
      totalKw: totalKw,
      mainBreaker: main,
      mainCable: mainCable,
      imbalance: imbalance,
      usedModules: used,
      issues: issues,
    );
  }

  /// Bir fazali yuklamalarni eng kam yuklangan fazaga taqsimlaydi.
  static void autoBalance(Project p) {
    final sum = <String, double>{'L1': 0, 'L2': 0, 'L3': 0};
    for (final l in p.loads) {
      if (l.threePhase) {
        final i = current(l);
        sum['L1'] = sum['L1']! + i;
        sum['L2'] = sum['L2']! + i;
        sum['L3'] = sum['L3']! + i;
      }
    }
    final singles = p.loads.where((l) => !l.threePhase).toList()
      ..sort((a, b) => current(b).compareTo(current(a)));
    for (final l in singles) {
      var best = 'L1';
      for (final ph in ['L2', 'L3']) {
        if (sum[ph]! < sum[best]!) best = ph;
      }
      l.phase = best;
      sum[best] = sum[best]! + current(l);
    }
  }

  /// Yangi yuklama uchun eng kam yuklangan faza.
  static String lightestPhase(Project p) {
    final r = panel(p).phaseI;
    var best = 'L1';
    for (final ph in ['L2', 'L3']) {
      if (r[ph]! < r[best]!) best = ph;
    }
    return best;
  }
}
