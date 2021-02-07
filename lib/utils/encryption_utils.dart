import 'package:encrypt/encrypt.dart';

class EncryptionUtil {
  static final iv = IV.fromLength(16);

  static String encrypt(String key, String text) {
    final encrypter = getEncrypterFromKey(key);
    return encrypter.encrypt(text, iv: iv).base16;
  }

  static String decrypt(String key, String encryptedText) {
    try {
      final encrypter = getEncrypterFromKey(key);
      return encrypter
          .decrypt(Encrypted.fromBase16(encryptedText), iv: iv)
          .toString();
    } catch (e) {
      return encryptedText;
    }
  }

  static Encrypter getEncrypterFromKey(String key) {
    return Encrypter(AES(Key.fromUtf8(key)));
  }
}
