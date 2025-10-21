import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://wjcdutzlamxihrgkxkad.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqY2R1dHpsYW14aWhyZ2t4a2FkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MjM2MzUsImV4cCI6MjA3MzQ5OTYzNX0.GRj0ikI2hnF_ISO1af_q8GTGaG4DgWCvB7_JiHErZ3Y';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
