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

  final SharedPreferencesAsync? _preferences;
  final Map<String, Object?>? _memory;
  String _productDetailPrompt = '';
  String _productDetailIdentityConfirmationPrompt = '';
  String _productDetailFacePrompt = '';

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
        ..remove(physicalSizeKey)
        ..remove(productDetailPromptKey)
        ..remove(productDetailIdentityConfirmationPromptKey)
        ..remove(productDetailFacePromptKey);
      _productDetailPrompt = '';
      _productDetailIdentityConfirmationPrompt = '';
      _productDetailFacePrompt = '';
      return;
    }
    await _preferences!.remove(sessionIdKey);
    await _preferences.remove(deviceNameKey);
    await _preferences.remove(physicalSizeKey);
    await _preferences.remove(productDetailPromptKey);
    await _preferences.remove(productDetailIdentityConfirmationPromptKey);
    await _preferences.remove(productDetailFacePromptKey);
    _productDetailPrompt = '';
    _productDetailIdentityConfirmationPrompt = '';
    _productDetailFacePrompt = '';
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
