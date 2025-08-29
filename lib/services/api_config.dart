/// API Configuration for Signify App
library;

/// This file contains all API-related configuration including
/// base URLs, timeouts, and environment settings.

enum ApiEnvironment { development, production, staging }

class ApiConfig {
  // Environment-specific base URLs
  static const Map<ApiEnvironment, String> _baseUrls = {
    ApiEnvironment.development:  'http://10.134.241.185:5000',
    ApiEnvironment.production: 'https://philosia-codecult-signify.hf.space',
  };

  static ApiEnvironment _currentEnvironment = ApiEnvironment.production;

  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration frameProcessingTimeout = Duration(seconds: 2);
  static const Duration uploadTimeout = Duration(seconds: 60);

  // API rate limiting
  static const int frameProcessingInterval =
      200; // milliseconds between frame API calls
  static const int maxRetryAttempts = 3;

  // Image processing settings
  static const int jpegQuality = 70;

  // API endpoints
  static const String processFrameEndpoint = '/processFrame';
  static const String customTrainEndpoint = '/customTrain';
  static const String switchModelEndpoint = '/switchModel';
  static const String predictEndpoint = '/predict';
  static const String healthEndpoint = '/health';
  static const String resetEndpoint = '/reset';

  /// Get the current base URL
  static String get baseUrl => _baseUrls[_currentEnvironment]!;

  /// Get the current environment
  static ApiEnvironment get currentEnvironment => _currentEnvironment;

  /// Switch to a different environment
  static void switchEnvironment(ApiEnvironment environment) {
    _currentEnvironment = environment;
    print('🔄 API Environment switched to: ${environment.name}');
    print('📡 New Base URL: ${_baseUrls[environment]}');
  }

  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    final base = baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$base$cleanEndpoint';
  }

  /// Set custom base URL for current environment (useful for testing)
  static void setCustomBaseUrl(String url) {
    _baseUrls[_currentEnvironment] = url;
    print('🔧 Custom Base URL set for ${_currentEnvironment.name}: $url');
  }

  /// Get timeout for specific operation type
  static Duration getTimeout(ApiOperationType type) {
    switch (type) {
      case ApiOperationType.frameProcessing:
        return frameProcessingTimeout;
      case ApiOperationType.fileUpload:
        return uploadTimeout;
      case ApiOperationType.standard:
        return defaultTimeout;
    }
  }

  /// Print current configuration (useful for debugging)
  static void printConfig() {
    print('📋 Current API Configuration:');
    print('  Environment: ${_currentEnvironment.name}');
    print('  Base URL: $baseUrl');
    print('  Default Timeout: ${defaultTimeout.inSeconds}s');
    print('  Frame Timeout: ${frameProcessingTimeout.inSeconds}s');
    print('  Upload Timeout: ${uploadTimeout.inSeconds}s');
    print('  Frame Interval: ${frameProcessingInterval}ms');
    print('  Max Retries: $maxRetryAttempts');
  }
}

enum ApiOperationType { standard, frameProcessing, fileUpload }

/// Request configuration for fine-grained control
class RequestConfig {
  final Duration? timeout;
  final int? maxRetries;
  final Map<String, String>? headers;
  final bool enableLogging;
  final bool enableRetry;

  const RequestConfig({
    this.timeout,
    this.maxRetries,
    this.headers,
    this.enableLogging = true,
    this.enableRetry = true,
  });

  /// Default config for frame processing (fast, no retries)
  static const RequestConfig frameProcessing = RequestConfig(
    timeout: ApiConfig.frameProcessingTimeout,
    maxRetries: 0, // No retries for real-time frame processing
    enableRetry: false,
    headers: {'Connection': 'keep-alive', 'Keep-Alive': 'timeout=30, max=100'},
  );

  /// Default config for model training (longer timeout, retries enabled)
  static const RequestConfig modelTraining = RequestConfig(
    timeout: ApiConfig.uploadTimeout,
    maxRetries: ApiConfig.maxRetryAttempts,
    enableRetry: true,
  );

  /// Default config for standard API calls
  static const RequestConfig standard = RequestConfig(
    timeout: ApiConfig.defaultTimeout,
    maxRetries: ApiConfig.maxRetryAttempts,
    enableRetry: true,
  );
}
