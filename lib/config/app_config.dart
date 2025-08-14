/// Simple app configuration with security best practices
class AppConfig {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://qqyqwtoxjhgashwxyidg.supabase.co');

  static const String _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFxeXF3dG94amhnYXNod3h5aWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM2MjE5NjIsImV4cCI6MjA2OTE5Nzk2Mn0.IOB5ocrqZPKU6luezwhmLGXUkKgks9w0AM7X2-onI-c');

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
