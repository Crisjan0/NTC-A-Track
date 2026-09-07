import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://xlkghytdnbwomwviouyt.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_sXg8BB-X3zvjbf2rEKwaow_VIegzSPg';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}