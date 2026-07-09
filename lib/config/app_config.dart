/// Simple app configuration with security best practices
class AppConfig {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: '');

  static const String _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue: '');


  // Add validation for critical configs
  static String get supabaseUrl {
    if (_supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL is not configured');
    }
    return _supabaseUrl;
  }

  static String get supabaseAnonKey {
    if (_supabaseKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not configured');
    }
    return _supabaseKey;
  }

  // Security flags
  static const bool enableDebugLogs =
      bool.fromEnvironment('DEBUG_LOGS', defaultValue: false);
  static const bool enableCrashReporting =
      bool.fromEnvironment('CRASH_REPORTING', defaultValue: true);

  // Safe logging method
  static void secureLog(String message) {
    if (enableDebugLogs) {
      print(message);
    }
  }
}
