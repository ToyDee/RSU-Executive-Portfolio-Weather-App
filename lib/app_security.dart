import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'config.dart' as config;

class AppSecurity {
  AppSecurity._(); // prevent instantiation

  static const int _saltBytes = 16;

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltBytes, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _sha256WithSalt(String plainText, String salt) {
    final bytes = utf8.encode(salt + plainText.trim());
    return sha256.convert(bytes).toString();
  }

  static String _legacyMd5(String plainText) {
    final bytes = utf8.encode(plainText.trim());
    return md5.convert(bytes).toString();
  }

  static bool _looksLikeMd5(String value) =>
      RegExp(r'^[a-f0-9]{32}$').hasMatch(value);

  static String hashPassword(String plainText) {
    final salt = _generateSalt();
    return '$salt:${_sha256WithSalt(plainText, salt)}';
  }


  static bool verifyPassword(String plainText, String storedValue) {
    if (storedValue.contains(':')) {
      final parts = storedValue.split(':');
      if (parts.length != 2) return false;
      return _sha256WithSalt(plainText, parts[0]) == parts[1];
    }
    return _legacyMd5(plainText) == storedValue;
  }

  static bool isLegacyHash(String storedValue) =>
      !storedValue.contains(':') && _looksLikeMd5(storedValue);


  static bool isPlainText(String storedValue) =>
      !storedValue.contains(':') && !_looksLikeMd5(storedValue);
}


class AppConfig {
  AppConfig._();

  static const String openWeatherApiKey = String.fromEnvironment(
    'OWM_API_KEY',
    defaultValue: config.openWeatherApiKey,
  );
}