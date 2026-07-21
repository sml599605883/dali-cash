import 'package:dali_cash/core/network/api_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const key = 'ba927fc9e96f9676';
  const iv = '16f7ddfc7aef7a2e';

  test('matches AES-CBC Base64 fixed vector', () {
    final crypto = ApiCrypto(key: key, iv: iv);

    expect(
      crypto.encryptText('{"device":"ios"}'),
      'la0NhwtZ17zyAExJBuKMBvUfeYgaVp3v0YmH+xbnnE0=',
    );
  });

  test('round trips encrypted report json', () {
    final crypto = ApiCrypto(key: key, iv: iv);
    const plain = '{"device":"ios","version":"18.0"}';

    expect(crypto.decryptText(crypto.encryptText(plain)), plain);
  });
}
