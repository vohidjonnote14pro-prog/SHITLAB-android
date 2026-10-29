import 'package:flutter/material.dart';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

double toNum(String s) {
  final v = double.tryParse(s.trim().replaceAll(',', '.'));
  return v ?? 0;
}

/// Bitta yuklama (guruh liniyasi).
class Load {
  String id;
  String name;
  String type; // light, socket, power, three
  double powerKw;
  double cosPhi;
  double lengthM;
  String phase; // L1, L2, L3, 3F
  String mark; // kabel markasi kaliti

  Load({
    required this.id,
    required this.name,
    required this.type,
    required this.powerKw,
    required this.cosPhi,
    required this.lengthM,
    required this.phase,
    required this.mark,
  });

  bool get threePhase => phase == '3F';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'p': powerKw,
        'cos': cosPhi,
        'len': lengthM,
        'phase': phase,
        'mark': mark,
      };

  factory Load.fromJson(Map<String, dynamic> j) => Load(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? 'socket').toString(),
        powerKw: (j['p'] as num?)?.toDouble() ?? 0,
        cosPhi: (j['cos'] as num?)?.toDouble() ?? 0.95,
        lengthM: (j['len'] as num?)?.toDouble() ?? 0,
        phase: (j['phase'] ?? 'L1').toString(),
        mark: (j['mark'] ?? 'VVGLS').toString(),
      );
}

/// Bitta loyiha (shit).
class Project {
  String id;
  String name;
  String address;
  String panelType;
  int modules;
  String ip;
  String size;
  DateTime updated;
  List<Load> loads;
  List<String> layout;
  // 3-bosqich: hisob-kitob, montaj rasmlari, hujjatlar
  List<CalcRoom> calcRooms;
  String calcMark;
  List<PhotoRoom> photoRooms;
  String client;
  String clientPhone;
  String measIns;
  String measUzo;
  String measEarth;

  Project({
    required this.id,
    required this.name,
    required this.address,
    required this.panelType,
    required this.modules,
    required this.ip,
    required this.size,
    required this.updated,
    required this.loads,
    List<String>? layout,
    List<CalcRoom>? calcRooms,
    this.calcMark = 'ВВГнг-LS',
    List<PhotoRoom>? photoRooms,
    this.client = '',
    this.clientPhone = '',
    this.measIns = '',
    this.measUzo = '',
    this.measEarth = '',
  })  : layout = layout ?? [],
        calcRooms = calcRooms ?? [],
        photoRooms = photoRooms ?? [];

  /// Telegram heshteg uchun qisqa belgi (faqat harf/raqam).
  String get tag => 'SL${id.length > 8 ? id.substring(id.length - 8) : id}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'panelType': panelType,
        'modules': modules,
        'ip': ip,
        'size': size,
        'updated': updated.toIso8601String(),
        'loads': loads.map((l) => l.toJson()).toList(),
        'layout': layout,
        'calcRooms': calcRooms.map((r) => r.toJson()).toList(),
        'calcMark': calcMark,
        'photoRooms': photoRooms.map((r) => r.toJson()).toList(),
        'client': client,
        'clientPhone': clientPhone,
        'measIns': measIns,
        'measUzo': measUzo,
        'measEarth': measEarth,
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? 'Shit').toString(),
        address: (j['address'] ?? '').toString(),
        panelType: (j['panelType'] ?? 'shrn12').toString(),
        modules: (j['modules'] as num?)?.toInt() ?? 12,
        ip: (j['ip'] ?? 'IP31').toString(),
        size: (j['size'] ?? '').toString(),
        updated: DateTime.tryParse((j['updated'] ?? '').toString()) ?? DateTime.now(),
        loads: ((j['loads'] as List?) ?? [])
            .map((e) => Load.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        layout: ((j['layout'] as List?) ?? []).map((e) => e.toString()).toList(),
        calcRooms: ((j['calcRooms'] as List?) ?? [])
            .map((e) => CalcRoom.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        calcMark: (j['calcMark'] ?? 'ВВГнг-LS').toString(),
        photoRooms: ((j['photoRooms'] as List?) ?? [])
            .map((e) => PhotoRoom.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        client: (j['client'] ?? '').toString(),
        clientPhone: (j['clientPhone'] ?? '').toString(),
        measIns: (j['measIns'] ?? '').toString(),
        measUzo: (j['measUzo'] ?? '').toString(),
        measEarth: (j['measEarth'] ?? '').toString(),
      );
}

/// Hisob-kitob: bitta xonadagi nuqta (rozetka, vyklyuchatel...).
class PointRow {
  String id;
  String type;
  int qty;
  String cable;
  double len;
  PointRow({required this.id, required this.type, required this.qty, required this.cable, required this.len});

  Map<String, dynamic> toJson() => {'id': id, 'type': type, 'qty': qty, 'cable': cable, 'len': len};

  factory PointRow.fromJson(Map<String, dynamic> j) => PointRow(
        id: (j['id'] ?? newId()).toString(),
        type: (j['type'] ?? 'roz').toString(),
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        cable: (j['cable'] ?? 'c25').toString(),
        len: (j['len'] as num?)?.toDouble() ?? 0,
      );
}

class CalcRoom {
  String id;
  String name;
  List<PointRow> items;
  CalcRoom({required this.id, required this.name, required this.items});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'items': items.map((e) => e.toJson()).toList()};

  factory CalcRoom.fromJson(Map<String, dynamic> j) => CalcRoom(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? '').toString(),
        items: ((j['items'] as List?) ?? [])
            .map((e) => PointRow.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

/// Montaj rasmlari: xona, rasmlar, izoh, Telegram postlari.
class PhotoItem {
  String path;
  bool sent;
  PhotoItem({required this.path, this.sent = false});
  Map<String, dynamic> toJson() => {'path': path, 'sent': sent};
  factory PhotoItem.fromJson(Map<String, dynamic> j) =>
      PhotoItem(path: (j['path'] ?? '').toString(), sent: j['sent'] == true);
}

class PhotoRoom {
  String id;
  String name;
  String note;
  List<PhotoItem> photos;
  List<int> posts;
  PhotoRoom({required this.id, required this.name, this.note = '', List<PhotoItem>? photos, List<int>? posts})
      : photos = photos ?? [],
        posts = posts ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'photos': photos.map((p) => p.toJson()).toList(),
        'posts': posts,
      };

  factory PhotoRoom.fromJson(Map<String, dynamic> j) => PhotoRoom(
        id: (j['id'] ?? newId()).toString(),
        name: (j['name'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        photos: ((j['photos'] as List?) ?? [])
            .map((e) => PhotoItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        posts: ((j['posts'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
      );
}

/// Hisob-kitob uchun nuqta turlari.
class PointType {
  final String key;
  final String label;
  final String cable;
  final bool box;
  final String mech;
  const PointType(this.key, this.label, this.cable, this.box, this.mech);
}

const pointTypes = <PointType>[
  PointType('roz', 'Rozetka', 'c25', true, 'Rozetka mexanizmi'),
  PointType('vkl', 'Vyklyuchatel', 'c15', true, 'Vyklyuchatel'),
  PointType('chir', 'Chiroq / lyustra', 'c15', false, ''),
  PointType('tv', 'TV rozetka', 'rg6', true, 'TV rozetka'),
  PointType('net', 'Internet', 'utp', true, 'Internet rozetka'),
  PointType('kond', 'Konditsioner', 'c25', false, ''),
  PointType('isit', 'Suv isitgich', 'c25', true, 'Rozetka mexanizmi'),
  PointType('plita', 'Elektr plita', 'c525', false, 'Plita rozetkasi'),
];

class PointCable {
  final String key;
  final String short;
  final String sec;
  final bool power;
  const PointCable(this.key, this.short, this.sec, this.power);
}

const pointCables = <PointCable>[
  PointCable('c15', '3×1,5', '3×1,5', true),
  PointCable('c25', '3×2,5', '3×2,5', true),
  PointCable('c4', '3×4', '3×4', true),
  PointCable('c525', '5×2,5', '5×2,5', true),
  PointCable('rg6', 'RG-6', 'Koaksial RG-6 (TV)', false),
  PointCable('utp', 'UTP', 'UTP cat.5e (internet)', false),
];

PointType pointType(String k) => pointTypes.firstWhere((t) => t.key == k, orElse: () => pointTypes.first);
PointCable pointCable(String k) => pointCables.firstWhere((t) => t.key == k, orElse: () => pointCables[1]);

/// Shit turlari ro'yxati.
class PanelType {
  final String key;
  final String name;
  final String desc;
  final String category;
  final int modules;
  final String ip;
  final String size;
  const PanelType(this.key, this.name, this.desc, this.category, this.modules, this.ip, this.size);
}

const panelTypes = <PanelType>[
  PanelType('shrn12', 'ЩРН-12', 'Devorga osiladigan, metall', 'Kvartira', 12, 'IP31', '≈220×300×120'),
  PanelType('shrn24', 'ЩРН-24', 'Devorga osiladigan, 2 qator', 'Kvartira', 24, 'IP31', '≈300×440×120'),
  PanelType('shrv18', 'ЩРВ-18', 'Devor ichiga o\'rnatiladigan', 'Kvartira', 18, 'IP31', '≈270×360×125'),
  PanelType('shurn', 'ЩУРН-1/12', 'Hisoblagich oynasi bilan', 'Hisoblagichli', 12, 'IP31', '≈310×540×160'),
  PanelType('ip65', 'Plastik boks IP65', 'Shaffof qopqoqli · nam joy, ko\'cha', 'Kvartira', 8, 'IP65', '≈200×250×110'),
  PanelType('shmp', 'ЩМП-3', 'Montaj panelli, 2 qulfli · sex', 'Sanoat', 36, 'IP54', '≈650×500×220'),
  PanelType('vru', 'ВРУ-1', 'Kirish-taqsimlash qurilmasi, polga', 'Sanoat', 48, 'IP31', '≈1800×450×450'),
  PanelType('rza', 'RZA paneli', 'Rele himoya va avtomatika', 'RZA', 48, 'IP54', '≈2200×800×600'),
];

PanelType? panelTypeByKey(String key) {
  for (final t in panelTypes) {
    if (t.key == key) return t;
  }
  return null;
}

/// Kabel markalari.
class CableMark {
  final String key;
  final String label;
  final bool aluminium;
  final String desc;
  final Color sheath;
  const CableMark(this.key, this.label, this.aluminium, this.desc, this.sheath);
}

const cableMarks = <CableMark>[
  CableMark('VVGLS', 'ВВГнг-LS', false, 'Mis · yonmaydi, kam tutun chiqaradi — kvartira va uy uchun eng yaxshi tanlov', Color(0xFF2B2F36)),
  CableMark('VVG', 'ВВГнг', false, 'Mis · yonishni tarqatmaydi, narxi arzonroq', Color(0xFF2B2F36)),
  CableMark('NYM', 'NYM', false, 'Mis · yumaloq kulrang kabel, ichki montaj uchun', Color(0xFFB9BEC5)),
  CableMark('PVS', 'ПВС', false, 'Mis · ko\'p tolali, egiluvchan — devor ichi uchun emas', Color(0xFFE9ECEF)),
  CableMark('AVVG', 'АВВГ', true, 'Alyuminiy · arzon, lekin turar joyda mis kabel talab qilinadi (PUE 7.1)', Color(0xFF2B2F36)),
];

CableMark markByKey(String key) {
  for (final m in cableMarks) {
    if (m.key == key) return m;
  }
  return cableMarks.first;
}

/// Yuklama turlari.
class LoadType {
  final String key;
  final String label;
  final IconData icon;
  const LoadType(this.key, this.label, this.icon);
}

const loadTypes = <LoadType>[
  LoadType('light', 'Yoritish', Icons.lightbulb_outline),
  LoadType('socket', 'Rozetka', Icons.power_outlined),
  LoadType('power', 'Texnika', Icons.kitchen_outlined),
  LoadType('three', '3 fazali', Icons.electric_bolt_outlined),
];

String loadTypeLabel(String key) {
  for (final t in loadTypes) {
    if (t.key == key) return t.label;
  }
  return 'Yuklama';
}
