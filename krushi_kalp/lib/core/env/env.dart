import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'RAZORPAY_KEY_ID', obfuscate: true)
  static final String razorpayKeyId = _Env.razorpayKeyId;

  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID', obfuscate: true)
  static final String googleWebClientId = _Env.googleWebClientId;

  @EnviedField(varName: 'ENCRYPTION_KEY', obfuscate: true, defaultValue: 'FALLBACK_KEY_CHANGE_ME_32CHARS__')
  static final String encryptionKey = _Env.encryptionKey;
}
