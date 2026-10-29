import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Loyihalar telefon xotirasida saqlanadi.
class AppState extends ChangeNotifier {
  static const _key = 'shitlab_projects_v1';

  List<Project> projects = [];
  bool loaded = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List;
        projects = list.map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) {
      projects = [];
    }
    loaded = true;
    notifyListeners();
  }

  Project? byId(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  void add(Project p) {
    projects.insert(0, p);
    touch(p);
  }

  void touch(Project p) {
    p.updated = DateTime.now();
    projects.remove(p);
    projects.insert(0, p);
    _persist();
    notifyListeners();
  }

  void remove(Project p) {
    projects.remove(p);
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(projects.map((p) => p.toJson()).toList()));
    } catch (_) {}
  }
}

final app = AppState();

String savedLabel(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  final now = DateTime.now();
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  final time = '${two(d.hour)}:${two(d.minute)}';
  return sameDay ? 'bugun $time' : '${two(d.day)}.${two(d.month)}.${d.year} $time';
}
