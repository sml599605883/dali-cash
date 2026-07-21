import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../client/client_bridge.dart';
import 'api_config.dart';

class ApiSignature {
  ApiSignature(this.config);

  final ApiConfig config;

  Future<Map<String, dynamic>> buildSignedQuery({
    required String path,
    Map<String, dynamic> extraQuery = const <String, dynamic>{},
  }) async {
    final provider = config.commonParamsProvider;
    final common = Map<String, dynamic>.from(
      provider == null ? await _commonParams() : await provider(),
    );
    common['hardballs'] =
        '${config.timestampProvider?.call() ?? DateTime.now().millisecondsSinceEpoch}';

    final signInput = <String, dynamic>{
      ...common,
      'homogeny': _clearPath(path),
    };
    return <String, dynamic>{
      ...common,
      ...extraQuery,
      'palefaces': _randomDigits(6),
      'dashy': sign(signInput, config.signatureSecret),
    };
  }

  Future<Map<String, dynamic>> _commonParams() async {
    final platformInfo = await _getPlatformInfo();
    final deviceName = await config.sessionStore.deviceName();
    final sessionId = await config.sessionStore.sessionId();
    return <String, dynamic>{
      'crawdad': platformInfo?.appVersion ?? '',
      'extravagates': deviceName,
      'ouzo': platformInfo?.deviceId ?? '',
      'glover': platformInfo?.systemVersion ?? '',
      'vox': 'appstore-ph-dali-cash-ios',
      'crestfallen': sessionId,
      'sempervivums': platformInfo?.deviceId ?? '',
    };
  }

  Future<ClientPlatformInfo?> _getPlatformInfo() async {
    final bridge = config.clientBridge;
    if (!bridge.supportsNativeBridge) {
      return null;
    }
    try {
      return await bridge.getPlatformInfo();
    } on PlatformException {
      return null;
    } on UnsupportedError {
      return null;
    }
  }

  static String sign(Map<String, dynamic> params, String secret) {
    final keys = params.keys.toList()..sort();
    final source = keys.map((key) => '$key${params[key] ?? ''}').join();
    return Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(source)).toString();
  }

  String _randomDigits(int length) {
    return config.randomDigitsProvider?.call(length) ?? randomDigits(length);
  }

  static String randomDigits(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }

  static String _clearPath(String path) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return uri.path;
    }
    return path.split('?').first;
  }
}
