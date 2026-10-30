import 'package:flutter/material.dart';

/// Ma'lumotnoma: bitta qurilma yoki material.
class RefItem {
  final String key;
  final String code; // sxemadagi belgi
  final String name;
  final String category;
  final String short;
  final String what; // nima qiladi
  final String where; // qayerda qo'yiladi
  final List<String> choose; // qanday tanlanadi
  final List<String> mistakes; // ko'p uchraydigan xatolar
  final List<String> keywords;
  final int modules;
  final Color stripe;
  final String face; // breaker, uzo, dif, lcd, contactor, led, fuse, switch, cable, tip, meter
  final String label;

  const RefItem({
    required this.key,
    required this.code,
    required this.name,
    required this.category,
    required this.short,
    required this.what,
    required this.where,
    required this.choose,
    required this.mistakes,
    required this.keywords,
    required this.modules,
    required this.stripe,
    required this.face,
    required this.label,
  });
}

const refCategories = ['Hammasi', 'Himoya', 'Avtomatika', 'O\'lchash', 'Kabel'];

const refItems = <RefItem>[
  RefItem(
    key: 'qf',
    code: 'QF',
    name: 'Avtomatik o\'chirgich',
    category: 'Himoya',
    short: 'Qisqa tutashuv va o\'ta yuklanishda liniyani uzadi',
    what:
        'Ichida ikki xil ajratgich bor. Issiqlik ajratgichi (bimetall plastina) tok uzoq vaqt nominaldan oshsa qiziydi va bir necha soniya–daqiqada uzadi. '
        'Elektromagnit ajratgich qisqa tutashuvda sekundning yuzdan bir ulushida uzadi. Avtomat kabelni himoya qiladi, iste\'molchini emas.',
    where: 'Har bir guruh liniyasining boshida va shitning kirishida (kirish avtomati).',
    choose: [
      'Nominal tok (In) hisobiy tokdan katta, kabelning ruxsat etilgan tokidan kichik bo\'lsin',
      'Xarakteristika: B — yoritish, uzun liniya; C — rozetka, maishiy texnika; D — dvigatel, nasos',
      'Uzish qobiliyati: kvartirada kamida 4,5 kA, yaxshisi 6 kA',
      'Qutblar: 1P — bir faza, 3P — uch fazali iste\'molchi yoki kirish',
    ],
    mistakes: [
      'Kabelga nisbatan katta avtomat (3×1,5 ga C25) — kabel qizib yonadi, avtomat uzmaydi',
      'Nol simini avtomat orqali uzish (1P avtomatni N ga qo\'yish)',
      'Guruh avtomati kirish avtomatidan katta yoki teng — selektivlik buziladi',
    ],
    keywords: ['avtomat', 'qf', 'автомат', 'b', 'c', 'd', 'xarakteristika', 'uzish'],
    modules: 1,
    stripe: Color(0xFF5B6573),
    face: 'breaker',
    label: 'C16',
  ),
  RefItem(
    key: 'qd',
    code: 'QD',
    name: 'UZO (himoya o\'chirish qurilmasi)',
    category: 'Himoya',
    short: 'Tok yerga oqib ketganda o\'chiradi — odamni elektr urishidan saqlaydi',
    what:
        'Faza va noldagi toklarni solishtiradi. Agar farq (oqish toki) belgilangan qiymatdan oshsa — masalan, odam fazaga tegsa yoki izolyatsiya teshilsa — '
        '0,03 soniyada uzadi. UZO qisqa tutashuv va o\'ta yuklanishdan himoya qilmaydi, shuning uchun u bilan ketma-ket avtomat bo\'lishi shart.',
    where: 'Rozetka liniyalari, hammom, oshxona, kir yuvish mashinasi, suv isitgich, ko\'cha rozetkalari.',
    choose: [
      'Oqish toki: odamni himoya qilish uchun 30 mA (hammom uchun 10 mA ham bo\'ladi), yong\'indan himoya uchun 100–300 mA',
      'Nominal toki undan keyingi avtomatdan bir pog\'ona katta bo\'lsin (C16 uchun UZO 25 A)',
      'Turi: AC — oddiy; A — kir yuvish, induksion plita, invertorli texnika uchun',
    ],
    mistakes: [
      'UZO dan keyingi nolni boshqa guruh nollari bilan qo\'shib yuborish — UZO doim uzib turadi',
      'UZO yo\'q rozetka liniyalari',
      'Test tugmasini hech qachon bosmaslik — oyda bir marta tekshirish kerak',
    ],
    keywords: ['uzo', 'узо', 'oqish', 'qd', 'rcd', '30 ma', 'yerga oqish'],
    modules: 2,
    stripe: Color(0xFF3FB37F),
    face: 'uzo',
    label: '30mA',
  ),
  RefItem(
    key: 'qfd',
    code: 'QFD',
    name: 'Difavtomat',
    category: 'Himoya',
    short: 'Avtomat va UZO bitta korpusda',
    what:
        'Ham qisqa tutashuv va o\'ta yuklanishdan (avtomat sifatida), ham tok oqishidan (UZO sifatida) himoya qiladi. Shitda joyni tejaydi.',
    where: 'Alohida himoya kerak bo\'lgan bitta liniya: kir yuvish mashinasi, hammom, ko\'cha rozetkasi.',
    choose: [
      'Avtomat qismi oddiy avtomat kabi tanlanadi (C16, C20…)',
      'Oqish toki odatda 30 mA',
      'Ko\'p liniyaga bitta UZO + alohida avtomatlar arzonroq chiqadi',
    ],
    mistakes: [
      'Qaysi sabab bilan uzilganini bilmaslik — ko\'p modellarda bayroqcha ko\'rsatadi',
    ],
    keywords: ['difavtomat', 'дифавтомат', 'qfd', 'rcbo', 'dif'],
    modules: 2,
    stripe: Color(0xFF3FB37F),
    face: 'dif',
    label: 'C16',
  ),
  RefItem(
    key: 'kv',
    code: 'KV',
    name: 'Kuchlanish relesi',
    category: 'Himoya',
    short: 'Kuchlanish me\'yordan oshsa yoki tushsa, iste\'molchini uzadi',
    what:
        'Tarmoqdagi kuchlanishni doim o\'lchab turadi. Nol uzilib qolsa (fazaga 380 V gacha chiqishi mumkin) yoki kuchlanish juda pasaysa, '
        'uyni o\'chiradi va kuchlanish tiklangach o\'zi qayta yoqadi. Texnikani yonib ketishdan saqlaydi.',
    where: 'Kirish avtomatidan keyin, butun uy uchun yoki qimmat texnika liniyasiga.',
    choose: [
      'Toki kirish avtomatidan kam bo\'lmasin (C32 bo\'lsa — 40 A rele)',
      'Sozlash: yuqori chegara ~250 V, pastki ~170–190 V, qayta yoqish 10–60 s',
      '3 fazali uy uchun har fazaga alohida yoki 3 fazali rele',
    ],
    mistakes: [
      'Rele tokini kichik olish — rele kontaktlari kuyadi',
    ],
    keywords: ['kuchlanish relesi', 'rele', 'реле напряжения', 'kv', 'nol uzilishi', '380'],
    modules: 2,
    stripe: Color(0xFFF5B731),
    face: 'lcd',
    label: '230',
  ),
  RefItem(
    key: 'fv',
    code: 'FV',
    name: 'Impuls kuchlanish himoyasi (УЗИП)',
    category: 'Himoya',
    short: 'Chaqmoq va keskin kuchlanish sakrashlaridan himoya qiladi',
    what:
        'Juda qisqa, lekin kuchli kuchlanish impulslarini (chaqmoq, tarmoqdagi kommutatsiya) yerga o\'tkazib yuboradi. Oddiy holatda ishlamaydi.',
    where: 'Shit kirishida, yerga ulash (PE) yaxshi bo\'lgan obyektlarda; xususiy uylar, havo liniyasidan kirish.',
    choose: [
      'Klass: I — chaqmoq qaytargich bor binolar, II — oddiy uy va kvartira',
      'Oldidan saqlagich yoki avtomat qo\'yiladi (ishlab chiqaruvchi ko\'rsatgan)',
      'Yerga ulash qarshiligi past bo\'lishi shart',
    ],
    mistakes: [
      'Yerga ulash yo\'q joyga qo\'yish — foydasi yo\'q',
    ],
    keywords: ['uzip', 'узип', 'impuls', 'chaqmoq', 'fv', 'spd', 'перенапряжение'],
    modules: 1,
    stripe: Color(0xFFE5534B),
    face: 'led',
    label: 'FV',
  ),
  RefItem(
    key: 'km',
    code: 'KM',
    name: 'Kontaktor (modulli)',
    category: 'Avtomatika',
    short: 'Katta yuklamani kichik signal bilan masofadan yoqadi',
    what:
        'G\'altagiga 230 V berilganda kuchli kontaktlarini tutashtiradi. Taymer, termostat yoki tugma orqali katta quvvatli iste\'molchini boshqarish uchun ishlatiladi.',
    where: 'Suv isitgich (tungi tarif), yoritish guruhlari, nasos, isitish.',
    choose: [
      'Kontakt toki iste\'molchi tokidan katta (AC-1 — isitgich, AC-3 — dvigatel)',
      'G\'altak kuchlanishi: odatda 230 V',
      'Kontaktlar soni: 2NO, 4NO va h.k.',
    ],
    mistakes: [
      'Dvigatelga AC-1 bo\'yicha tanlash — kontaktlar tez kuyadi',
    ],
    keywords: ['kontaktor', 'контактор', 'km', 'magnit puskatel', 'puskatel'],
    modules: 2,
    stripe: Color(0xFF2F6FD6),
    face: 'contactor',
    label: '25A',
  ),
  RefItem(
    key: 'kk',
    code: 'KK',
    name: 'Issiqlik relesi',
    category: 'Avtomatika',
    short: 'Dvigatelni o\'ta yuklanishdan himoya qiladi',
    what:
        'Kontaktor bilan birga ishlaydi. Dvigatel toki sozlangan qiymatdan uzoq vaqt oshsa, kontaktor g\'altagini uzib, dvigatelni to\'xtatadi.',
    where: 'Nasos, kompressor, ventilyator, stanok dvigatellari.',
    choose: [
      'Sozlash diapazoni dvigatelning nominal tokini o\'z ichiga olsin',
      'Kontaktor seriyasiga mos bo\'lsin',
    ],
    mistakes: [
      'Tokni dvigatel shildigidagidan ancha katta sozlash',
    ],
    keywords: ['issiqlik relesi', 'тепловое реле', 'kk', 'dvigatel himoyasi', 'nasos'],
    modules: 2,
    stripe: Color(0xFF8A94A6),
    face: 'contactor',
    label: 'KK',
  ),
  RefItem(
    key: 'kt',
    code: 'KT',
    name: 'Vaqt relesi / taymer',
    category: 'Avtomatika',
    short: 'Belgilangan vaqtda yoqadi yoki o\'chiradi',
    what:
        'Kun davomidagi jadval (astrotaymer, sutkalik) yoki kechikish bilan ishlaydi. Ko\'pincha kontaktorni boshqaradi.',
    where: 'Ko\'cha yoritishi, suv isitgich, sug\'orish, ventilyatsiya.',
    choose: [
      'Kontakt toki kichik bo\'lsa — kontaktor orqali ulang',
      'Elektron taymerlarda batareya zaxirasi bo\'lsin',
    ],
    mistakes: [
      'Kuchli yuklamani taymer kontaktiga to\'g\'ridan-to\'g\'ri ulash',
    ],
    keywords: ['taymer', 'vaqt relesi', 'kt', 'реле времени', 'таймер'],
    modules: 1,
    stripe: Color(0xFF7C3AED),
    face: 'lcd',
    label: '12:00',
  ),
  RefItem(
    key: 'qs',
    code: 'QS',
    name: 'Yuklama uzgich (rubilnik)',
    category: 'Avtomatika',
    short: 'Shitni qo\'lda butunlay o\'chirish uchun',
    what:
        'Ko\'rinishi avtomatga o\'xshaydi, lekin ichida himoya yo\'q. Faqat yuklama ostida xavfsiz yoqib-o\'chirish uchun.',
    where: 'Shit kirishida (avtomatdan oldin yoki o\'rniga, agar oldinda himoya bo\'lsa).',
    choose: [
      'Toki kirish avtomatidan kam bo\'lmasin',
      'Qutblar soni: kirishga mos (2P yoki 4P)',
    ],
    mistakes: [
      'Uni himoya deb o\'ylash — qisqa tutashuvda uzmaydi',
    ],
    keywords: ['rubilnik', 'yuklama uzgich', 'qs', 'выключатель нагрузки', 'рубильник'],
    modules: 2,
    stripe: Color(0xFFE5534B),
    face: 'switch',
    label: '63A',
  ),
  RefItem(
    key: 'fu',
    code: 'FU',
    name: 'Saqlagich (predoxranitel)',
    category: 'Himoya',
    short: 'Ichidagi sim erib, zanjirni bir marta uzadi',
    what:
        'Qisqa tutashuvda ichidagi erigich sim eriydi va zanjirni uzadi. Keyin almashtirish kerak. Juda tez ishlaydi.',
    where: 'Hisoblagichdan oldin, УЗИП oldidan, boshqaruv zanjirlarida.',
    choose: [
      'Nominal tok va turi (gG — umumiy, aM — dvigatel)',
    ],
    mistakes: [
      'Kuygan saqlagichni sim bilan "tuzatish" — yong\'in xavfi',
    ],
    keywords: ['saqlagich', 'predoxranitel', 'предохранитель', 'fu', 'erigich'],
    modules: 1,
    stripe: Color(0xFF9AA3AE),
    face: 'fuse',
    label: '16A',
  ),
  RefItem(
    key: 'pi',
    code: 'PI',
    name: 'Elektr hisoblagich',
    category: 'O\'lchash',
    short: 'Iste\'mol qilingan energiyani (kVt·soat) hisoblaydi',
    what: 'Bir yoki uch fazali bo\'ladi. Zamonaviylari ko\'p tarifli va masofadan o\'qiladi.',
    where: 'Kirishda, kirish avtomatidan oldin yoki keyin — elektr ta\'minoti tashkiloti talabiga ko\'ra.',
    choose: [
      'Fazalar soni kirishga mos',
      'Maksimal toki kirish avtomatidan kam bo\'lmasin',
    ],
    mistakes: [
      'Plombani buzish — jarima',
    ],
    keywords: ['hisoblagich', 'schyotchik', 'счетчик', 'pi', 'kwh'],
    modules: 4,
    stripe: Color(0xFF1F6B44),
    face: 'meter',
    label: 'kWh',
  ),
  RefItem(
    key: 'hl',
    code: 'HL',
    name: 'Indikator lampa',
    category: 'O\'lchash',
    short: 'Fazada kuchlanish borligini ko\'rsatadi',
    what: 'Har bir fazaga bittadan qo\'yilsa, qaysi faza yo\'qligi darhol ko\'rinadi.',
    where: 'Shit kirishida, 3 fazali shitlarda.',
    choose: ['230 V, modulli, har fazaga alohida rang'],
    mistakes: ['Saqlagich yoki avtomatsiz ulash'],
    keywords: ['indikator', 'lampa', 'hl', 'faza bormi'],
    modules: 1,
    stripe: Color(0xFFE5534B),
    face: 'led',
    label: 'L1',
  ),
  RefItem(
    key: 'vvg',
    code: 'W',
    name: 'Kabel: ВВГнг-LS, NYM, ПВС, АВВГ',
    category: 'Kabel',
    short: 'Qaysi kabel qayerda ishlatiladi',
    what:
        'ВВГнг-LS — mis, yonishni tarqatmaydi va kam tutun chiqaradi: kvartira va uy uchun eng yaxshi. '
        'ВВГнг — mis, yonishni tarqatmaydi. NYM — mis, yumaloq, ichki montaj uchun qulay. '
        'ПВС — ko\'p tolali egiluvchan sim: uzaytirgich va ko\'chma texnika uchun, devor ichiga emas. '
        'АВВГ — alyuminiy: arzon, lekin turar joyda mis talab qilinadi.',
    where: 'Yoritish: 3×1,5. Rozetkalar: 3×2,5. Plita: 3×6 (1 faza) yoki 5×2,5 (3 faza). Konditsioner: 3×2,5.',
    choose: [
      'Kesimni tokka qarab tanlang, keyin kuchlanish tushishini (≤5%) tekshiring',
      'Tomirlar ranglari: L — jigarrang/qora/kulrang, N — ko\'k, PE — sariq-yashil',
      'Uzun liniyada kesimni bir pog\'ona oshiring',
    ],
    mistakes: [
      'Rozetka liniyasiga 3×1,5',
      'Mis va alyuminiyni to\'g\'ridan-to\'g\'ri burab ulash',
      'PE simini nol sifatida ishlatish',
    ],
    keywords: ['kabel', 'vvg', 'ввг', 'nym', 'pvs', 'пвс', 'avvg', 'аввг', 'sim', 'kesim', 'mm2'],
    modules: 0,
    stripe: Color(0xFF2B2F36),
    face: 'cable',
    label: '3×2,5',
  ),
  RefItem(
    key: 'nshvi',
    code: '',
    name: 'Nakonechnik НШВИ',
    category: 'Kabel',
    short: 'Ko\'p tolali sim uchini klemmaga to\'g\'ri ulash uchun',
    what:
        'Ko\'p tolali (ПВС, egiluvchan) sim uchiga kiygizilib, press-qisqich bilan qisiladi. Tolalar sochilmaydi, klemma yaxshi qisadi va qizimaydi.',
    where: 'Ko\'p tolali simlarni avtomat, UZO va shinalarga ulashda.',
    choose: [
      'O\'lcham sim kesimiga mos: 1,5 mm² — НШВИ 1,5-8, 2,5 mm² — НШВИ 2,5-8, 4 mm² — НШВИ 4-9, 6 mm² — НШВИ 6-12',
      'Ikki simni bitta klemmaga — НШВИ(2)',
    ],
    mistakes: [
      'Ko\'p tolali simni nakonechniksiz klemmaga burab qo\'yish',
      'Ombir bilan qisish (press-qisqich kerak)',
    ],
    keywords: ['nakonechnik', 'ншви', 'nshvi', 'gilza', 'ferrule'],
    modules: 0,
    stripe: Color(0xFFC98A3D),
    face: 'tip',
    label: '2,5',
  ),
];

RefItem? refByKey(String k) {
  for (final r in refItems) {
    if (r.key == k) return r;
  }
  return null;
}
