import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dali_report_data.dart';

class DaliReportStore {
  DaliReportStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync(),
      _memory = null;

  DaliReportStore.memory()
    : _preferences = null,
      _memory = <String, Object?>{};

  static const _loginAtKey = 'report.login_at';
  static const _locationKey = 'report.location';
  static const _adjustInitializedKey = 'report.attribution_initialized';

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _memory;

  Future<int> loginAt() => _int(_loginAtKey);

  Future<void> saveLoginAt(int value) => _setInt(_loginAtKey, value);

  Future<bool> isAdjustInitialized() => _bool(_adjustInitializedKey);

  Future<void> markAdjustInitialized() =>
      _setBool(_adjustInitializedKey, true);

  Future<void> saveLocation(DaliLocationSnapshot location) {
    return _setString(_locationKey, jsonEncode(location.toMap()));
  }

  Future<void> clearSessionReportState() => _remove(_locationKey);

  Future<DaliLocationSnapshot?> cachedLocation() async {
    final raw = await _string(_locationKey);
    if (raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final location = DaliLocationSnapshot.fromMap(decoded);
      return location.isValid ? location : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _string(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as String? ?? '';
    return await _preferences!.getString(key) ?? '';
  }

  Future<int> _int(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as int? ?? 0;
    return await _preferences!.getInt(key) ?? 0;
  }

  Future<bool> _bool(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as bool? ?? false;
    return await _preferences!.getBool(key) ?? false;
  }

  Future<void> _setString(String key, String value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setString(key, value);
  }

  Future<void> _setInt(String key, int value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setInt(key, value);
  }

  Future<void> _setBool(String key, bool value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setBool(key, value);
  }

  Future<void> _remove(String key) async {
    final memory = _memory;
    if (memory != null) {
      memory.remove(key);
      return;
    }
    await _preferences!.remove(key);
  }
}
