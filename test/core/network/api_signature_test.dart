import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dali_cash/core/client/client_bridge.dart';
import 'package:dali_cash/core/network/api_config.dart';
import 'package:dali_cash/core/network/api_signature.dart';
import 'package:dali_cash/core/session/session_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(ClientBridge.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('reads Kaibigan-style live common params for every request', () async {
    final store = SessionStore.memory();
    await store.saveSessionId('session-1');
    await store.saveDeviceInfo(deviceName: 'iPhone 17', physicalSize: '6.3');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getPlatformInfo');
          return <String, Object?>{
            'platform': 'iPhone17,1',
            'systemVersion': '18.0',
            'appVersion': '1.2.3',
            'buildNumber': '10',
            'deviceId': 'stable-idfv',
          };
        });
    final config = ApiConfig(
      clientBridge: ClientBridge(platform: ClientPlatform.ios),
      sessionStore: store,
      timestampProvider: () => 1000,
      randomDigitsProvider: (_) => '123456',
    );

    final first = await ApiSignature(
      config,
    ).buildSignedQuery(path: '/lutes/unsphered');
    await store.saveSessionId('session-2');
    final second = await ApiSignature(
      config,
    ).buildSignedQuery(path: '/lutes/unsphered');

    expect(first['crawdad'], '1.2.3');
    expect(first['extravagates'], 'iPhone 17');
    expect(first['ouzo'], 'stable-idfv');
    expect(first['glover'], '18.0');
    expect(first['vox'], 'appstore-ph-dali-cash-ios');
    expect(first['crestfallen'], 'session-1');
    expect(first['sempervivums'], 'stable-idfv');
    expect(second['crestfallen'], 'session-2');
  });

  test('builds Dali signed query with fixed vector', () async {
    const secret = 'test-secret';
    final common = <String, dynamic>{
      'crawdad': '1.2.3',
      'extravagates': 'iPhone15,2',
      'ouzo': 'device-id',
      'glover': '18.0',
      'vox': 'appstore-ph-dali-cash-ios',
      'crestfallen': 'session-id',
      'sempervivums': 'device-id',
    };
    final config = ApiConfig(
      signatureSecret: secret,
      commonParamsProvider: () async => common,
      timestampProvider: () => 1721433600000,
      randomDigitsProvider: (_) => '123456',
    );

    final query = await ApiSignature(
      config,
    ).buildSignedQuery(path: '/lutes/unsphered');

    final signInput = <String, dynamic>{
      ...common,
      'hardballs': '1721433600000',
      'homogeny': '/lutes/unsphered',
    };
    final keys = signInput.keys.toList()..sort();
    final source = keys.map((key) => '$key${signInput[key]}').join();
    final expected = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(source)).toString();

    expect(query['hardballs'], '1721433600000');
    expect(query['palefaces'], '123456');
    expect(query['dashy'], expected);
    expect(query.containsKey('homogeny'), isFalse);
  });

  test('signs clear path for absolute urls', () async {
    final config = ApiConfig(
      signatureSecret: 'test-secret',
      commonParamsProvider: () async => const <String, dynamic>{},
      timestampProvider: () => 1,
      randomDigitsProvider: (_) => '000000',
    );

    final relative = await ApiSignature(
      config,
    ).buildSignedQuery(path: '/lutes/unsphered');
    final absolute = await ApiSignature(
      config,
    ).buildSignedQuery(path: 'http://example.test/lutes/unsphered?ignored=1');

    expect(absolute['dashy'], relative['dashy']);
  });
}
