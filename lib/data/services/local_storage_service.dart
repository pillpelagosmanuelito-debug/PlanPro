import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia local en JSON.
///
/// Unica dependencia externa del proyecto. Se aisla detras de esta clase para
/// que cambiar a SQLite o a un backend remoto no obligue a tocar el dominio.
class LocalStorageService {
  static const String _sessionKey = 'pms_current_session';
  static const String _historyKey = 'pms_finished_sessions';
  static const String _seenIntroKey = 'pms_seen_intro';
  static const int _maxFinished = 20;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, dynamic>?> loadSession() async {
    final SharedPreferences p = await _prefs;
    final String? raw = p.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Un guardado corrupto no debe impedir jugar: se descarta en silencio.
      await p.remove(_sessionKey);
    }
    return null;
  }

  Future<void> saveSession(Map<String, dynamic> json) async {
    final SharedPreferences p = await _prefs;
    await p.setString(_sessionKey, jsonEncode(json));
  }

  Future<void> clearSession() async {
    final SharedPreferences p = await _prefs;
    await p.remove(_sessionKey);
  }

  Future<List<Map<String, dynamic>>> loadFinished() async {
    final SharedPreferences p = await _prefs;
    final List<String> raw = p.getStringList(_historyKey) ?? <String>[];
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final String item in raw) {
      try {
        final Object? decoded = jsonDecode(item);
        if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  Future<void> addFinished(Map<String, dynamic> summary) async {
    final SharedPreferences p = await _prefs;
    final List<String> raw = p.getStringList(_historyKey) ?? <String>[];
    raw.insert(0, jsonEncode(summary));
    while (raw.length > _maxFinished) {
      raw.removeLast();
    }
    await p.setStringList(_historyKey, raw);
  }

  Future<void> clearFinished() async {
    final SharedPreferences p = await _prefs;
    await p.remove(_historyKey);
  }

  Future<bool> hasSeenIntro() async {
    final SharedPreferences p = await _prefs;
    return p.getBool(_seenIntroKey) ?? false;
  }

  Future<void> markIntroSeen() async {
    final SharedPreferences p = await _prefs;
    await p.setBool(_seenIntroKey, true);
  }
}
