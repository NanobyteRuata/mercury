import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class EncryptionUtil {
  static final iv = IV.fromLength(16);

  static String encrypt(String key, String text) {
    String filledkey = fillKey( jsonDecode(jsonEncode(key)) + "");
    final encrypter = getEncrypterFromKey(filledkey);
    return encrypter.encrypt(text, iv: iv).base16;
  }

  static String decrypt(String key, String encryptedText) {
    String filledkey = fillKey( jsonDecode(jsonEncode(key)) + "");
    try {
      final encrypter = getEncrypterFromKey(filledkey);
      String decryptedText = encrypter
          .decrypt(Encrypted.fromBase16(encryptedText), iv: iv)
          .toString();
      return decryptedText;
    } catch (e) {
      return encryptedText;
    }
  }

  // key string must be 16 length long,
  // this method is to add "0" until it is 16 length long
  static String fillKey(String key) {
    while(key.length <= 16) {
      key = key + "0";
    }
    if(key.length > 16) {
      key = key.substring(0,16);
    }
    return key;
  }

  static Encrypter getEncrypterFromKey(String key) {
    return Encrypter(AES(Key.fromUtf8(key)));
  }
}
