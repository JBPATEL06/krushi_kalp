import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/app_config.dart';
import '../../utils/retry_helper.dart';

class AppConfigService {
  static final _supabase = Supabase.instance.client;

  // Cache to avoid hitting DB constantly
  static final Map<String, AppConfig> _configCache = {};

  /// Fetch all configs and update cache
  static Future<void> fetchConfigs() async {
    try {
      
      final response = await RetryHelper.run(
        () => _supabase
            .from('app_config')
            .select()
            .timeout(const Duration(seconds: 10)),
      );

      final List<dynamic> data = response as List<dynamic>;
      

      final List<AppConfig> configs =
          data.map((e) => AppConfig.fromJson(e)).toList();

      _configCache.clear();
      for (var config in configs) {
        _configCache[config.key] = config;
        
      }
      
    } catch (e) {
      
    }
  }

  /// Get a specific config value (from cache or default)
  static dynamic getValue(String key, String field, {dynamic defaultValue}) {
    if (_configCache.containsKey(key)) {
      final val = _configCache[key]!.value[field];
      if (val == null) return defaultValue;

      // Type safety: handle String-to-Int/Bool conversions if necessary
      if (defaultValue is int && val is! int) {
        return int.tryParse(val.toString()) ?? defaultValue;
      }
      if (defaultValue is bool && val is! bool) {
        if (val.toString().toLowerCase() == 'true') return true;
        if (val.toString().toLowerCase() == 'false') return false;
        return defaultValue;
      }

      return val;
    }
    return defaultValue;
  }

  /// Update a config value in DB and Cache
  static Future<void> updateConfig(
      String key, Map<String, dynamic> newValue) async {
    try {
      // Use upsert so it creates the row if it doesn't exist
      await _supabase.from('app_config').upsert({
        'key': key,
        'value': newValue,
        'description':
            _configCache[key]?.description ?? 'Updated via Admin Panel'
      });

      // Update local cache immediately
      if (_configCache.containsKey(key)) {
        _configCache[key] = AppConfig(
            key: key,
            value: newValue,
            description: _configCache[key]!.description);
      } else {
        // Upsert to cache if it's a new key
        _configCache[key] = AppConfig(
            key: key, value: newValue, description: "Updated via Admin Panel");
      }
    } catch (e) {
      
      rethrow;
    }
  }

  // --- Specific Helpers ---

  // REPLACED: isReviewsEnabled -> areReviewsVisible & canWriteReviews

  static bool get areReviewsVisible =>
      getValue('feature_reviews', 'show_reviews', defaultValue: true);

  static bool get canWriteReviews =>
      getValue('feature_reviews', 'allow_writing', defaultValue: true);

  static bool get isMaintenanceMode =>
      getValue('app_status', 'maintenance_mode', defaultValue: false);

  static String get maintenanceMessage => getValue('app_status', 'message',
      defaultValue: "App is under maintenance. Please try again later.");

  static String get whatsappNumber =>
      getValue('contact_info', 'whatsapp', defaultValue: "");

  static String get email =>
      getValue('contact_info', 'email', defaultValue: "support@krushikalp.com");

  static String get telegramUsername =>
      getValue('contact_info', 'telegram', defaultValue: "krushi_kalp");

  static String get privacyPolicyUrl => getValue('legal_urls', 'privacy_policy',
      defaultValue: "https://krushikalp.netlify.app/privacy-policy");

  static String get termsUrl => getValue('legal_urls', 'terms_conditions',
      defaultValue: "https://krushikalp.netlify.app/terms-and-conditions");

  // --- Banner Settings ---

  static int get bannerInterval {
    final val = getValue('banner_settings', 'interval', defaultValue: 15);
    
    return val;
  }

  static bool get bannerAutoScroll {
    final val = getValue('banner_settings', 'auto_scroll', defaultValue: false);
    
    return val;
  }

  // --- Force Update ---

  /// The minimum version string users must have (e.g. "1.2.0").
  /// Returns null if no minimum is configured — meaning updates are not forced.
  static String? get minVersion =>
      getValue('app_status', 'min_version', defaultValue: null);
}
