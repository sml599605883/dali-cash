import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore(this._preferences) : _memory = null;

  SessionStore.memory() : _preferences = null, _memory = <String, Object?>{};

  static const sessionIdKey = 'session.id';
  static const phoneKey = 'session.phone';
  static const deviceNameKey = 'device_info.name';
  static const physicalSizeKey = 'device_info.physical_size';
  static const productDetailPromptKey = 'product_detail.prompt';
  static const productDetailIdentityConfirmationPromptKey =
      'product_detail.identity_confirmation_prompt';
  static const productDetailFacePromptKey = 'product_detail.face_prompt';
  static const productDetailOrderNoKey = 'product_detail.order_no';
  static const identitySceneStartTimeKey = 'report.identity_scene_start';

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _memory;
  String _productDetailPrompt = '';
  String _productDetailIdentityConfirmationPrompt = '';
  String _productDetailFacePrompt = '';
  String _productDetailOrderNo = '';

  Future<String> sessionId() => _string(sessionIdKey);

  Future<void> saveSessionId(String value) => _setString(sessionIdKey, value);

  Future<String> phone() => _string(phoneKey);

  Future<void> savePhone(String value) => _setString(phoneKey, value);

  Future<String> deviceName() => _string(deviceNameKey);

  Future<String> physicalSize() => _string(physicalSizeKey);

  String productDetailPrompt() => _productDetailPrompt;

  Future<void> saveProductDetailPrompt(String value) async {
    _productDetailPrompt = value.trim();
    await _setString(productDetailPromptKey, _productDetailPrompt);
  }

  String productDetailIdentityConfirmationPrompt() =>
      _productDetailIdentityConfirmationPrompt;

  Future<void> saveProductDetailIdentityConfirmationPrompt(String value) async {
    _productDetailIdentityConfirmationPrompt = value.trim();
    await _setString(
      productDetailIdentityConfirmationPromptKey,
      _productDetailIdentityConfirmationPrompt,
    );
  }

  String productDetailFacePrompt() => _productDetailFacePrompt;

  Future<void> saveProductDetailFacePrompt(String value) async {
    _productDetailFacePrompt = value.trim();
    await _setString(productDetailFacePromptKey, _productDetailFacePrompt);
  }

  String productDetailOrderNo() => _productDetailOrderNo;

  Future<void> saveProductDetailOrderNo(String value) async {
    _productDetailOrderNo = value.trim();
    await _setString(productDetailOrderNoKey, _productDetailOrderNo);
  }

  Future<int> identitySceneStartTime() => _int(identitySceneStartTimeKey);

  Future<void> saveIdentitySceneStartTime(int value) =>
      _setInt(identitySceneStartTimeKey, value);

  Future<void> saveDeviceInfo({
    required String deviceName,
    required String physicalSize,
  }) async {
    await _setString(deviceNameKey, deviceName);
    await _setString(physicalSizeKey, physicalSize);
  }

  Future<void> clearSession() => _clearPersistent(clearDeviceInfo: false);

  Future<void> clearPersistent() => _clearPersistent(clearDeviceInfo: true);

  Future<void> _clearPersistent({required bool clearDeviceInfo}) async {
    final memory = _memory;
    if (memory != null) {
      memory
        ..remove(sessionIdKey)
        ..remove(productDetailPromptKey)
        ..remove(productDetailIdentityConfirmationPromptKey)
        ..remove(productDetailFacePromptKey)
        ..remove(productDetailOrderNoKey);
      if (clearDeviceInfo) {
        memory
          ..remove(deviceNameKey)
          ..remove(physicalSizeKey);
      }
      _productDetailPrompt = '';
      _productDetailIdentityConfirmationPrompt = '';
      _productDetailFacePrompt = '';
      _productDetailOrderNo = '';
      memory.remove(identitySceneStartTimeKey);
      return;
    }
    await _preferences!.remove(sessionIdKey);
    if (clearDeviceInfo) {
      await _preferences.remove(deviceNameKey);
      await _preferences.remove(physicalSizeKey);
    }
    await _preferences.remove(productDetailPromptKey);
    await _preferences.remove(productDetailIdentityConfirmationPromptKey);
    await _preferences.remove(productDetailFacePromptKey);
    await _preferences.remove(productDetailOrderNoKey);
    await _preferences.remove(identitySceneStartTimeKey);
    _productDetailPrompt = '';
    _productDetailIdentityConfirmationPrompt = '';
    _productDetailFacePrompt = '';
    _productDetailOrderNo = '';
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

  Future<int> _int(String key) async {
    final memory = _memory;
    if (memory != null) return memory[key] as int? ?? 0;
    return await _preferences!.getInt(key) ?? 0;
  }

  Future<void> _setInt(String key, int value) async {
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    await _preferences!.setInt(key, value);
  }
}
