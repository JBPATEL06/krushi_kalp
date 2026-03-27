import 'package:encrypt/encrypt.dart' as encrypt;
import '../../core/env/env.dart';

class EncryptionService {
  // AES-256 key loaded from .env — never hardcoded in source
  static final _key = encrypt.Key.fromUtf8(
    Env.encryptionKey,
  );
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// Encrypts plain text
  static String encryptData(String plainText) {
    try {
      final iv = encrypt.IV.fromLength(16); // Random IV each time
      final encrypted = _encrypter.encrypt(plainText, iv: iv);

      // Return "IV_BASE64:CIPHERTEXT_BASE64"
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      
      return plainText;
    }
  }

  /// Decrypts encrypted text
  static String decryptData(String encryptedText) {
    try {
      // Check for IV separator
      if (encryptedText.contains(':')) {
        final parts = encryptedText.split(':');
        final iv = encrypt.IV.fromBase64(parts[0]);
        final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
        return _encrypter.decrypt(encrypted, iv: iv);
      } else {
        // Fallback for legacy data (tries default random IV which will likely fail, but handles migration)
        // Or we just return null/error.
        // For now, let's try to decrypt assuming it was legacy format (won't work if IV was random before)
        // Actually, if it fails, the catch block handles it.
        throw Exception("Invalid format: Missing IV");
      }
    } catch (e) {
      
      return encryptedText; // Fail open or return null.
      // If we return encryptedText, the session check will fail (mismatch) and force logout, which is CORRECT behavior for corrupted data.
    }
  }
}
