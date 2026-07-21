import 'package:encrypt/encrypt.dart';

class ApiCrypto {
  ApiCrypto({required String key, required String iv})
    : _key = Key.fromUtf8(key),
      _iv = IV.fromUtf8(iv);

  final Key _key;
  final IV _iv;

  String encryptText(String plainText) {
    return Encrypter(
      AES(_key, mode: AESMode.cbc),
    ).encrypt(plainText, iv: _iv).base64;
  }

  String decryptText(String cipherText) {
    return Encrypter(
      AES(_key, mode: AESMode.cbc),
    ).decrypt64(cipherText, iv: _iv);
  }
}
