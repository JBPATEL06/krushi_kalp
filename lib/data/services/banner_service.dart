import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // NEW
import '../../domain/models/home_banner.dart';

class BannerService {
  static final _supabase = Supabase.instance.client;

  static Future<List<HomeBanner>> fetchActiveBanners() async {
    try {
      final response = await _supabase
          .from('banners')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false);

      // if (response == null) return []; // Removed dead code

      return (response as List)
          .map((json) => HomeBanner.fromJson(json))
          .toList();
    } catch (e) {
      // Gracefully handle missing table or network errors
      debugPrint('Error fetching banners (returning empty list): $e');
      return [];
    }
  }

  static Stream<List<HomeBanner>> streamBanners() {
    return _supabase
        .from('banners')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('priority', ascending: false)
        .map((data) => data.map((json) => HomeBanner.fromJson(json)).toList());
  }
}
