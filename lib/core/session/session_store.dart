import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore(this._preferences) : _memory = null;

  SessionStore.memory() : _preferences = null, _memory = <String, Object?>{};

  static const sessionIdKey = 'session.id';
  static const phoneKey = 'session.phone';
  static const deviceNameKey = 'device_info.name';
  static const physicalSizeKey = 'device_info.physical_size';

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _memory;

  Future<String> sessionId() => _string(sessionIdKey);

  Future<void> saveSessionId(String value) => _setString(sessionIdKey, value);

  Future<String> phone() => _string(phoneKey);

  Future<void> savePhone(String value) => _setString(phoneKey, value);

  Future<String> deviceName() => _string(deviceNameKey);

  Future<String> physicalSize() => _string(physicalSizeKey);

  Future<void> saveDeviceInfo({
    required String deviceName,
    required String physicalSize,
  }) async {
    await _setString(deviceNameKey, deviceName);
    await _setString(physicalSizeKey, physicalSize);
  }

  Future<void> clearPersistent() async {
    final memory = _memory;
    if (memory != null) {
      memory
        ..remove(sessionIdKey)
        ..remove(deviceNameKey)
        ..remove(physicalSizeKey);
      return;
    }
    await _preferences!.remove(sessionIdKey);
    await _preferences.remove(deviceNameKey);
    await _preferences.remove(physicalSizeKey);
  }

  Future<String> _string(String key) async {
    final memory = _memory;
    if (memory != null) {
      return memory[key] as String? ?? '';
    }
    return await _preferences!.getString(key) ?? '';
  }

  Future<void> _setString(String key, String value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setString(key, value);
  }
}
