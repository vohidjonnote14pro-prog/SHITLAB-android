import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'store.dart';

class TgError implements Exception {
  final String message;
  TgError(this.message);
  @override
  String toString() => message;
}

/// Telegram Bot API orqali kanalga rasm yuborish.
class Telegram {
  static Uri _u(String method) => Uri.parse('https://api.telegram.org/bot${app.tgToken.trim()}/$method');

  static dynamic _parse(http.Response r) {
    Map<String, dynamic>? j;
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (j == null || j['ok'] != true) {
      final d = j?['description']?.toString() ?? 'Telegram javob bermadi (${r.statusCode})';
      throw TgError(_uz(d));
    }
    return j['result'];
  }

  static String _uz(String d) {
    if (d.contains('Unauthorized')) return 'Bot token noto\'g\'ri';
    if (d.contains('chat not found')) return 'Kanal topilmadi — nomini tekshiring';
    if (d.contains('not enough rights') || d.contains('administrator')) {
      return 'Bot kanalda administrator emas — uni kanalga admin qilib qo\'shing';
    }
    return d;
  }

  /// Token va kanalni tekshiradi. Natija: "@bot → Kanal nomi".
  static Future<String> check() async {
    if (app.tgToken.trim().isEmpty || app.channelUser.isEmpty) {
      throw TgError('Bot token va kanal nomini (@ bilan) kiriting');
    }
    try {
      final me = _parse(await http.get(_u('getMe')).timeout(const Duration(seconds: 15)));
      final ch = _parse(await http
          .post(_u('getChat'), body: {'chat_id': '@${app.channelUser}'}).timeout(const Duration(seconds: 15)));
      return '@${me['username']} → ${ch['title'] ?? '@${app.channelUser}'}';
    } on SocketException {
      throw TgError('Internet yo\'q');
    }
  }

  /// Xonaning yuborilmagan rasmlarini kanalga yuboradi.
  static Future<int> sendRoom(Project p, PhotoRoom room) async {
    final todo = room.photos.where((ph) => !ph.sent && File(ph.path).existsSync()).toList();
    if (todo.isEmpty) return 0;
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final cap = [
      '🏠 ${p.name} · ${room.name}',
      if (p.address.isNotEmpty) '📍 ${p.address}',
      '📅 ${two(d.day)}.${two(d.month)}.${d.year}${app.installer.isEmpty ? '' : ' · ⚡ ${app.installer}'}',
      if (room.note.trim().isNotEmpty) '📝 ${room.note.trim()}',
      '#${p.tag} #${roomTag(p, room)} #ShitLab',
    ].join('\n');

    var sent = 0;
    try {
      for (var start = 0; start < todo.length; start += 10) {
        final chunk = todo.sublist(start, start + 10 > todo.length ? todo.length : start + 10);
        if (chunk.length == 1) {
          final req = http.MultipartRequest('POST', _u('sendPhoto'))
            ..fields['chat_id'] = '@${app.channelUser}'
            ..fields['caption'] = cap
            ..files.add(await http.MultipartFile.fromPath('photo', chunk.first.path));
          final res = _parse(await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 90))));
          room.posts.add((res['message_id'] as num).toInt());
        } else {
          final media = <Map<String, dynamic>>[];
          final req = http.MultipartRequest('POST', _u('sendMediaGroup'))..fields['chat_id'] = '@${app.channelUser}';
          for (var k = 0; k < chunk.length; k++) {
            media.add({'type': 'photo', 'media': 'attach://p$k', if (k == 0) 'caption': cap});
            req.files.add(await http.MultipartFile.fromPath('p$k', chunk[k].path));
          }
          req.fields['media'] = jsonEncode(media);
          final res = _parse(await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 120))));
          if (res is List && res.isNotEmpty) room.posts.add((res.first['message_id'] as num).toInt());
        }
        for (final ph in chunk) {
          ph.sent = true;
        }
        sent += chunk.length;
        app.save(p);
      }
    } on SocketException {
      throw TgError('Internet yo\'q');
    }
    return sent;
  }
}

/// Xona uchun barqaror heshteg (xonalar o'chirilsa ham o'zgarmaydi).
String roomTag(Project p, PhotoRoom r) {
  final id = r.id.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
  return '${p.tag}r${id.length > 5 ? id.substring(id.length - 5) : id}';
}
