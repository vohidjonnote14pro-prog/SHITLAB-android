import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../pdfs.dart';
import '../store.dart';
import '../telegram.dart';
import '../theme.dart';
import '../widgets/app_builder.dart';
import '../widgets/ui.dart';
import 'docs.dart';

/// Pastki menyudagi "QR montaj" bo'limi.
class QrPage extends StatelessWidget {
  const QrPage({super.key});

  void _openDocs(BuildContext context) {
    if (app.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avval loyiha yarating')));
      return;
    }
    if (app.projects.length == 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocsScreen(projectId: app.projects.first.id)));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card2,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Qaysi obyekt uchun?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final p in app.projects)
              ListTile(
                title: Text(p.name),
                subtitle: Text(p.address.isEmpty ? '${p.loads.length} yuklama' : p.address),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocsScreen(projectId: p.id)));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBuilder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Header(title: 'QR montaj', subtitle: 'Montaj rasmlari va mijoz hujjatlari', back: false),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BigTile(
                        icon: Icons.photo_camera_outlined,
                        title: 'Montaj rasmlari',
                        sub: 'Kabel yo\'llari + QR',
                        accent: true,
                        onTap: () {
                          if (app.projects.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Avval loyiha yarating')));
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ObjectPhotosScreen(projectId: app.projects.first.id)));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BigTile(
                        icon: Icons.description_outlined,
                        title: 'Mijoz hujjatlari',
                        sub: 'Pasport, sxema, PDF',
                        onTap: () => _openDocs(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Box(
                  color: const Color(0xFF121820),
                  border: const Color(0xFF222A36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Qanday ishlaydi'),
                      const SizedBox(height: 10),
                      for (final s in const [
                        'Devor suvalishidan oldin kabel yo\'llarini xonalar bo\'yicha rasmga olasiz',
                        'Rasmlar Telegram kanalingizga yuboriladi, ilova QR stiker chiqaradi',
                        'Uy egasi QR\'ni skanerlasa, shu uyning rasmlari Telegramda ochiladi',
                      ].asMap().entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration:
                                    BoxDecoration(color: C.amberSoft, borderRadius: BorderRadius.circular(9)),
                                child: Text('${s.key + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: C.amber)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(s.value,
                                    style: const TextStyle(fontSize: 13, color: C.text2, height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _TelegramCard(),
                const SizedBox(height: 18),
                const Text('Obyektlar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text)),
                const SizedBox(height: 8),
                if (app.projects.isEmpty)
                  const Text('Hali loyiha yo\'q. "Loyihalar" bo\'limida yangi shit yarating.',
                      style: TextStyle(fontSize: 13, color: C.muted))
                else
                  for (final p in app.projects) ...[
                    _ObjectRow(project: p),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final bool accent;
  final VoidCallback onTap;
  const _BigTile({required this.icon, required this.title, required this.sub, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? C.amber : C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent ? C.amber : C.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: accent ? C.ink : C.amber),
              const SizedBox(height: 18),
              Text(title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accent ? C.ink : C.text)),
              Text(sub, style: TextStyle(fontSize: 12, color: accent ? const Color(0xBF14110A) : C.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObjectRow extends StatelessWidget {
  final Project project;
  const _ObjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final photos = project.photoRooms.fold<int>(0, (s, r) => s + r.photos.length);
    final sent = project.photoRooms.fold<int>(0, (s, r) => s + r.photos.where((x) => x.sent).length);
    final ready = photos > 0 && sent == photos;
    return Material(
      color: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: C.line)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ObjectPhotosScreen(projectId: project.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ready ? Colors.white : const Color(0xFF232A36),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ready ? Icons.qr_code_2 : Icons.photo_camera_outlined,
                    color: ready ? C.ink : C.muted, size: ready ? 34 : 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: C.text)),
                    Text('$photos ta rasm · ${project.photoRooms.length} xona',
                        style: const TextStyle(fontSize: 12, color: C.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ready ? const Color(0xFF16301F) : const Color(0xFF3A2E12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(ready ? 'QR tayyor' : (photos == 0 ? 'Bo\'sh' : 'Yuborilmagan'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ready ? const Color(0xFF5FD39A) : C.amber)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelegramCard extends StatefulWidget {
  const _TelegramCard();

  @override
  State<_TelegramCard> createState() => _TelegramCardState();
}

class _TelegramCardState extends State<_TelegramCard> {
  late bool _open = !app.tgOk;
  bool _busy = false;
  String? _result;
  bool _resultOk = false;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    try {
      final r = await Telegram.check();
      app.tgOk = true;
      _result = 'Tayyor: $r';
      _resultOk = true;
    } catch (e) {
      app.tgOk = false;
      _result = 'Xato: $e';
      _resultOk = false;
    }
    await app.saveSettings();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ok = app.tgOk && app.channelUser.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.send_rounded, color: Color(0xFF5BA3E0)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Telegram kanal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ok ? const Color(0xFF16301F) : const Color(0xFF3A2E12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(ok ? '@${app.channelUser}' : 'sozlanmagan',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: ok ? const Color(0xFF5FD39A) : C.amber)),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, color: C.muted),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1) Telegramda @BotFather orqali bot yarating va tokenini oling.\n'
                    '2) Ochiq kanal yarating (masalan @mening_montajim).\n'
                    '3) Botni kanalga administrator qilib qo\'shing.\n'
                    '4) Token va kanal nomini shu yerga yozib, "Tekshirish"ni bosing.',
                    style: TextStyle(fontSize: 12.5, color: C.soft, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: app.tgToken,
                    decoration: const InputDecoration(labelText: 'Bot token', hintText: '123456:ABC…'),
                    style: mono(13),
                    onChanged: (v) {
                      app.tgToken = v.trim();
                      app.tgOk = false;
                      app.saveSettings();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: app.tgChannel,
                    decoration: const InputDecoration(labelText: 'Kanal', hintText: '@kanal_nomi'),
                    onChanged: (v) {
                      app.tgChannel = v.trim();
                      app.tgOk = false;
                      app.saveSettings();
                    },
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: _busy ? 'Tekshirilmoqda…' : 'Tekshirish',
                    icon: Icons.verified_outlined,
                    onTap: _busy ? null : _check,
                  ),
                  if (_result != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_result!,
                          style: TextStyle(fontSize: 13, color: _resultOk ? C.okText : C.badText)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bitta obyektning montaj rasmlari (xonalar bo'yicha) va QR.
class ObjectPhotosScreen extends StatefulWidget {
  final String projectId;
  const ObjectPhotosScreen({super.key, required this.projectId});

  @override
  State<ObjectPhotosScreen> createState() => _ObjectPhotosScreenState();
}

class _ObjectPhotosScreenState extends State<ObjectPhotosScreen> {
  final _picker = ImagePicker();
  String? _sending;

  Future<String> _store(Project p, String src) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/photos/${p.id}');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final path = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(src).copy(path);
    return path;
  }

  Future<void> _add(Project p, PhotoRoom room, ImageSource source) async {
    try {
      final files = <XFile>[];
      if (source == ImageSource.camera) {
        final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 78, maxWidth: 1920);
        if (x != null) files.add(x);
      } else {
        files.addAll(await _picker.pickMultiImage(imageQuality: 78, maxWidth: 1920));
      }
      for (final f in files) {
        room.photos.add(PhotoItem(path: await _store(p, f.path)));
      }
      if (files.isNotEmpty) app.save(p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rasm olinmadi: $e')));
      }
    }
  }

  void _pickSource(Project p, PhotoRoom room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card2,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: C.amber),
              title: const Text('Kamera bilan olish'),
              onTap: () {
                Navigator.pop(ctx);
                _add(p, room, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: C.amber),
              title: const Text('Galereyadan tanlash (bir nechta)'),
              onTap: () {
                Navigator.pop(ctx);
                _add(p, room, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(Project p, PhotoRoom room) async {
    if (!app.tgOk || app.channelUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avval "QR montaj" bo\'limida Telegram kanalni sozlang')));
      return;
    }
    setState(() => _sending = room.id);
    try {
      final n = await Telegram.sendRoom(p, room);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(n == 0 ? 'Yangi rasm yo\'q' : '$n ta rasm kanalga yuborildi')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yuborilmadi: $e')));
    } finally {
      if (mounted) setState(() => _sending = null);
    }
  }

  Future<void> _addRoom(Project p) async {
    final c = TextEditingController(text: 'Xona ${p.photoRooms.length + 1}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.card2,
        title: const Text('Yangi xona'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Masalan: Oshxona'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bekor')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Qo\'shish')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      p.photoRooms.add(PhotoRoom(id: newId(), name: c.text.trim()));
      app.save(p);
    }
  }

  void _showQr(Project p, String link, String title, {String? room}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card2,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: QrImageView(data: link, size: 220, backgroundColor: Colors.white),
              ),
              const SizedBox(height: 10),
              SelectableText(link, style: mono(11, color: C.soft, weight: FontWeight.w500)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Ochib ko\'rish',
                      icon: Icons.open_in_new,
                      onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Stiker PDF',
                      icon: Icons.print_outlined,
                      onTap: () async {
                        final bytes = await buildSticker(p, link, room: room);
                        await Printing.sharePdf(bytes: bytes, filename: 'QR_${p.name.replaceAll(' ', '_')}.pdf');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBuilder(
      builder: (context) {
        final p = app.byId(widget.projectId);
        if (p == null) return const Scaffold(body: SafeArea(child: Header(title: 'Loyiha topilmadi')));
        final total = p.photoRooms.fold<int>(0, (s, r) => s + r.photos.length);
        final link = app.channelSearchLink(p.tag);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Header(
                  title: '${p.name} — montaj',
                  subtitle: '${p.address.isEmpty ? 'obyekt' : p.address} · $total ta rasm',
                  actions: [
                    if (app.projects.length > 1)
                      PopupMenuButton<String>(
                        color: C.card2,
                        tooltip: 'Boshqa obyekt',
                        icon: const Icon(Icons.swap_horiz, color: C.text2),
                        onSelected: (id) => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => ObjectPhotosScreen(projectId: id))),
                        itemBuilder: (_) => [
                          for (final x in app.projects) PopupMenuItem(value: x.id, child: Text(x.name)),
                        ],
                      ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    children: [
                      _objectQr(p, link),
                      const SizedBox(height: 14),
                      for (final room in p.photoRooms) ...[
                        _roomCard(p, room),
                        const SizedBox(height: 12),
                      ],
                      GhostButton(label: '+ Xona qo\'shish', icon: Icons.add, onTap: () => _addRoom(p)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _objectQr(Project p, String link) {
    if (link.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: C.amberSoft, borderRadius: BorderRadius.circular(18)),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: C.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'QR chiqishi uchun "QR montaj" bo\'limida Telegram kanalni sozlang. Rasmlarni hozir ham olib qo\'yaverishingiz mumkin.',
                style: TextStyle(fontSize: 13, color: C.text2, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showQr(p, link, 'Butun uy uchun QR'),
            child: QrImageView(data: link, size: 112, backgroundColor: Colors.white, padding: EdgeInsets.zero),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uy egasi uchun QR',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF14110A))),
                const SizedBox(height: 4),
                const Text('Skanerlansa, shu uyning barcha montaj rasmlari Telegramda ochiladi',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4B5361), height: 1.4)),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF14110A), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: () => _showQr(p, link, 'Butun uy uchun QR'),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Stiker / kattalashtirish', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomCard(Project p, PhotoRoom room) {
    final unsent = room.photos.where((x) => !x.sent).length;
    final link = app.channelSearchLink(roomTag(p, room));
    final sending = _sending == room.id;
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('pr-${room.id}'),
                  initialValue: room.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: C.text),
                  decoration: const InputDecoration(
                    filled: false,
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) {
                    room.name = v;
                    app.save(p);
                  },
                ),
              ),
              if (link.isNotEmpty)
                IconButton(
                  tooltip: 'Xona QR kodi',
                  onPressed: () => _showQr(p, link, '${room.name} — QR', room: room.name),
                  icon: const Icon(Icons.qr_code_2, color: C.text2),
                ),
              PopupMenuButton<String>(
                color: C.card2,
                icon: const Icon(Icons.more_vert, color: C.muted),
                onSelected: (v) {
                  if (v == 'del') {
                    p.photoRooms.remove(room);
                    app.save(p);
                  }
                },
                itemBuilder: (_) => const [PopupMenuItem(value: 'del', child: Text('Xonani o\'chirish'))],
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final ph in room.photos) _thumb(p, room, ph),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pickSource(p, room),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4A5363), width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: C.amber),
                      SizedBox(height: 4),
                      Text('Rasm', style: TextStyle(fontSize: 12, color: C.text2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('note-${room.id}'),
            initialValue: room.note,
            maxLines: 2,
            minLines: 1,
            decoration: const InputDecoration(hintText: 'Izoh: masalan, shiftdan 15 sm, 3×2,5'),
            onChanged: (v) {
              room.note = v;
              app.save(p);
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: sending
                ? 'Yuborilmoqda…'
                : (unsent == 0
                    ? (room.photos.isEmpty ? 'Avval rasm qo\'shing' : 'Hammasi yuborilgan')
                    : 'Telegramga yuborish ($unsent)'),
            icon: Icons.send_rounded,
            onTap: sending || unsent == 0 ? null : () => _send(p, room),
          ),
        ],
      ),
    );
  }

  Widget _thumb(Project p, PhotoRoom room, PhotoItem ph) {
    final f = File(ph.path);
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InteractiveViewer(
                child: Image.file(f, errorBuilder: (_, __, ___) => const SizedBox(height: 120, child: Center(child: Icon(Icons.broken_image, color: C.muted)))),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      room.photos.remove(ph);
                      app.save(p);
                      try {
                        if (f.existsSync()) f.deleteSync();
                      } catch (_) {}
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline, color: C.bad),
                    label: const Text('O\'chirish', style: TextStyle(color: C.bad)),
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
                ],
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              f,
              fit: BoxFit.cover,
              cacheWidth: 300,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF232A36), child: const Icon(Icons.broken_image, color: C.muted)),
            ),
            if (ph.sent)
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: C.ok, borderRadius: BorderRadius.circular(8)),
                  child: const Text('✓ kanalda', style: TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
