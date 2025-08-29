/// Unified API Service for Signify App
///
/// This service provides a centralized way to make API calls across the app.
/// It handles different request types, error handling, retries, and logging.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_models.dart';

/// Unified API Service - Singleton pattern for global access
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeHttpClient();
  }

  // HTTP client with connection pooling
  late http.Client _httpClient;

  // Rate limiting for frame processing
  int _lastFrameApiCall = 0;
  bool _frameApiInFlight = false;

  /// Initialize HTTP client with connection pooling
  void _initializeHttpClient() {
    _httpClient = http.Client();
    if (kDebugMode) {
      debugPrint('🔌 ApiService initialized with HTTP client');
    }
  }

  /// Dispose resources (call when app is closing)
  void dispose() {
    _httpClient.close();
    if (kDebugMode) {
      debugPrint('🔌 ApiService HTTP client disposed');
    }
  }

  /// Helper method to handle both List and Map JSON responses
  Map<String, dynamic> _normalizeJsonResponse(dynamic jsonData) {
    if (jsonData is Map<String, dynamic>) {
      return jsonData;
    } else if (jsonData is List) {
      // Wrap list response in a standard format
      return {
        'success': true,
        'data': jsonData,
        'message': 'List response normalized',
        'count': jsonData.length,
      };
    } else {
      // Handle other types by wrapping them
      return {
        'success': true,
        'data': jsonData,
        'message': 'Response normalized',
        'type': jsonData.runtimeType.toString(),
      };
    }
  }

  /// Enhanced ApiResponse factory that handles both List and Map responses
  ApiResponse<T> _createApiResponse<T>({
    required int statusCode,
    required String responseBody,
    required Duration responseTime,
    T Function(Map<String, dynamic>)? dataParser,
  }) {
    try {
      // First parse the JSON
      final jsonData = jsonDecode(responseBody);

      // Normalize the response to always be a Map
      final normalizedJson = _normalizeJsonResponse(jsonData);

      // Use the existing fromHttpResponse with normalized JSON
      return ApiResponse.fromHttpResponse(
        statusCode: statusCode,
        responseBody: jsonEncode(normalizedJson),
        responseTime: responseTime,
        dataParser: dataParser,
      );
    } catch (e) {
      // If JSON parsing fails, create an error response
      return ApiResponse.error(
        errorMessage: 'Failed to parse JSON response: $e',
        statusCode: statusCode,
      );
    }
  }

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    RequestConfig config = RequestConfig.standard,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final stopwatch = Stopwatch()..start();

    try {
      if (config.enableLogging) {
        debugPrint('GET ${uri.toString()}');
      }

      final response = await _httpClient
          .get(uri, headers: _buildHeaders(config.headers))
          .timeout(config.timeout ?? ApiConfig.defaultTimeout);

      stopwatch.stop();

      if (config.enableLogging) {
        debugPrint(
          '📥 GET Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        );
      }

      return _createApiResponse<T>(
        statusCode: response.statusCode,
        responseBody: response.body,
        responseTime: stopwatch.elapsed,
        dataParser: dataParser,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'Network connection failed: ${e.message}',
        endpoint: endpoint,
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'HTTP client error: ${e.message}',
        endpoint: endpoint,
      );
    } on TimeoutException {
      stopwatch.stop();
      throw TimeoutException(
        'Request timed out',
        config.timeout ?? ApiConfig.defaultTimeout,
        endpoint: endpoint,
      );
    } catch (e) {
      stopwatch.stop();
      throw NetworkException('Unexpected error: $e', endpoint: endpoint);
    }
  }

  /// POST request with JSON body
  Future<ApiResponse<T>> postJson<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
    RequestConfig config = RequestConfig.standard,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    return _executeWithRetry(
      () => _postJsonInternal(
        endpoint,
        data,
        queryParameters,
        config,
        dataParser,
      ),
      config,
    );
  }

  /// Internal POST JSON implementation
  Future<ApiResponse<T>> _postJsonInternal<T>(
    String endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
    RequestConfig config,
    T Function(Map<String, dynamic>)? dataParser,
  ) async {
    final uri = _buildUri(endpoint, queryParameters);
    final stopwatch = Stopwatch()..start();

    try {
      final jsonBody = data != null ? jsonEncode(data) : null;

      if (config.enableLogging) {
        debugPrint('POST ${uri.toString()}');
        if (jsonBody != null && kDebugMode) {
          debugPrint(
            '📋 Body: ${jsonBody.length > 200 ? '${jsonBody.substring(0, 200)}...' : jsonBody}',
          );
        }
      }

      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(
              config.headers,
              contentType: 'application/json',
            ),
            body: jsonBody,
          )
          .timeout(config.timeout ?? ApiConfig.defaultTimeout);

      stopwatch.stop();

      if (config.enableLogging) {
        debugPrint(
          '📥 POST Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        );
      }

      return _createApiResponse<T>(
        statusCode: response.statusCode,
        responseBody: response.body,
        responseTime: stopwatch.elapsed,
        dataParser: dataParser,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'Network connection failed: ${e.message}',
        endpoint: endpoint,
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'HTTP client error: ${e.message}',
        endpoint: endpoint,
      );
    } on TimeoutException {
      stopwatch.stop();
      throw TimeoutException(
        'Request timed out',
        config.timeout ?? ApiConfig.defaultTimeout,
        endpoint: endpoint,
      );
    } catch (e) {
      stopwatch.stop();
      throw NetworkException('Unexpected error: $e', endpoint: endpoint);
    }
  }

  /// POST request with multipart data (for file uploads)
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint, {
    Map<String, String>? fields,
    Map<String, Uint8List>? files,
    Map<String, String>? fileNames,
    Map<String, String>? queryParameters,
    RequestConfig config = RequestConfig.frameProcessing,
    T Function(Map<String, dynamic>)? dataParser,
  }) async {
    // Special rate limiting for frame processing
    if (endpoint.contains('processFrame') || endpoint.contains('frame')) {
      if (_frameApiInFlight) {
        return ApiResponse.error(
          errorMessage: 'Frame API call already in progress',
        );
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastFrameApiCall < ApiConfig.frameProcessingInterval) {
        return ApiResponse.error(errorMessage: 'Frame API call rate limited');
      }

      _lastFrameApiCall = currentTime;
      _frameApiInFlight = true;
    }

    try {
      return await _executeWithRetry(
        () => _postMultipartInternal(
          endpoint,
          fields,
          files,
          fileNames,
          queryParameters,
          config,
          dataParser,
        ),
        config,
      );
    } finally {
      if (endpoint.contains('processFrame') || endpoint.contains('frame')) {
        _frameApiInFlight = false;
      }
    }
  }

  /// Internal POST multipart implementation
  Future<ApiResponse<T>> _postMultipartInternal<T>(
    String endpoint,
    Map<String, String>? fields,
    Map<String, Uint8List>? files,
    Map<String, String>? fileNames,
    Map<String, String>? queryParameters,
    RequestConfig config,
    T Function(Map<String, dynamic>)? dataParser,
  ) async {
    final uri = _buildUri(endpoint, queryParameters);
    final stopwatch = Stopwatch()..start();

    try {
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(_buildHeaders(config.headers));

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        for (var entry in files.entries) {
          final fileName =
              fileNames?[entry.key] ??
              '${entry.key}_${DateTime.now().millisecondsSinceEpoch}';
          request.files.add(
            http.MultipartFile.fromBytes(
              entry.key,
              entry.value,
              filename: fileName,
            ),
          );
        }
      }

      if (config.enableLogging) {
        debugPrint('POST Multipart ${uri.toString()}');
        debugPrint('Files: ${files?.keys.join(', ') ?? 'none'}');
        debugPrint('Fields: ${fields?.keys.join(', ') ?? 'none'}');
      }

      final streamedResponse = await _httpClient
          .send(request)
          .timeout(config.timeout ?? ApiConfig.uploadTimeout);

      final responseBody = await streamedResponse.stream.bytesToString();
      stopwatch.stop();

      if (config.enableLogging) {
        debugPrint(
          'Multipart Response: ${streamedResponse.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
        );
      }

      return _createApiResponse<T>(
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        responseTime: stopwatch.elapsed,
        dataParser: dataParser,
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'Network connection failed: ${e.message}',
        endpoint: endpoint,
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      throw NetworkException(
        'HTTP client error: ${e.message}',
        endpoint: endpoint,
      );
    } on TimeoutException {
      stopwatch.stop();
      throw TimeoutException(
        'Request timed out',
        config.timeout ?? ApiConfig.uploadTimeout,
        endpoint: endpoint,
      );
    } catch (e) {
      stopwatch.stop();
      throw NetworkException('Unexpected error: $e', endpoint: endpoint);
    }
  }

  // Execute request with retry logic
  Future<ApiResponse<T>> _executeWithRetry<T>(
    Future<ApiResponse<T>> Function() requestFunction,
    RequestConfig config,
  ) async {
    if (!config.enableRetry) {
      return await requestFunction();
    }

    final maxRetries = config.maxRetries ?? ApiConfig.maxRetryAttempts;
    ApiResponse<T>? lastResponse;
    ApiException? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await requestFunction();

        // Return on success or non-retryable errors
        if (response.isSuccess || !_shouldRetry(response.statusCode)) {
          return response;
        }

        lastResponse = response;
      } catch (e) {
        if (e is ApiException) {
          lastException = e;
          if (!_shouldRetryException(e)) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Wait before retry (exponential backoff)
      if (attempt < maxRetries) {
        final delayMs = 500 * (1 << attempt); // 500ms, 1s, 2s, 4s...
        if (config.enableLogging) {
          debugPrint(
            '🔄 Retrying in ${delayMs}ms (attempt ${attempt + 1}/$maxRetries)',
          );
        }
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // All retries exhausted
    if (lastException != null) {
      throw lastException;
    }

    return lastResponse ??
        ApiResponse.error(errorMessage: 'All retry attempts failed');
  }

  /// Check if status code should trigger a retry
  bool _shouldRetry(int? statusCode) {
    if (statusCode == null) return true;

    // Retry on server errors (5xx) and some client errors
    return statusCode >= 500 ||
        statusCode == 408 || // Request Timeout
        statusCode == 429; // Too Many Requests
  }

  /// Check if exception should trigger a retry
  bool _shouldRetryException(ApiException exception) {
    return exception is NetworkException || exception is TimeoutException;
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    final fullUrl = ApiConfig.getFullUrl(endpoint);
    final uri = Uri.parse(fullUrl);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: {...uri.queryParameters, ...queryParameters},
      );
    }

    return uri;
  }

  /// Build headers with defaults
  Map<String, String> _buildHeaders(
    Map<String, String>? customHeaders, {
    String? contentType,
  }) {
    final headers = <String, String>{
      'User-Agent': 'Signify/1.0',
      if (contentType != null) 'Content-Type': contentType,
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Reset frame API rate limiting (useful for testing)
  void resetFrameApiLimiting() {
    _lastFrameApiCall = 0;
    _frameApiInFlight = false;
    if (kDebugMode) {
      debugPrint('🔄 Frame API rate limiting reset');
    }
  }

  /// Check if frame API is currently rate limited
  bool get isFrameApiRateLimited {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return _frameApiInFlight ||
        (currentTime - _lastFrameApiCall < ApiConfig.frameProcessingInterval);
  }

  /// Get current API configuration info
  String getConfigInfo() {
    return 'ApiService - Environment: ${ApiConfig.currentEnvironment.name}, '
        'Base URL: ${ApiConfig.baseUrl}, '
        'Frame API In Flight: $_frameApiInFlight';
  }
}

/// Convenient extension methods for specific API calls
extension SignifyApiExtensions on ApiService {
  /// Process camera frame for sign detection
  Future<ApiResponse<FrameProcessResponse>> processFrame({
    required Uint8List frameBytes,
    required String timestamp,
    required String cameraType,
    required int width,
    required int height,
    String filename = 'frame.jpg',
  }) async {
    return postMultipart<FrameProcessResponse>(
      ApiConfig.processFrameEndpoint,
      files: {'frame': frameBytes},
      fileNames: {'frame': filename},
      fields: {
        'timestamp': timestamp,
        'camera_type': cameraType,
        'width': width.toString(),
        'height': height.toString(),
      },
      config: RequestConfig.frameProcessing,
      dataParser: (json) {
        // With the global normalization, we can handle both cases here
        // If the original response was a list, it will be in json['data']
        if (json.containsKey('data') && json['data'] is List) {
          final List<dynamic> dataList = json['data'];
          if (dataList.isNotEmpty && dataList.first is Map<String, dynamic>) {
            return FrameProcessResponse.fromJson(dataList.first);
          } else {
            // Create a response object from the list
            return FrameProcessResponse.fromJson({
              'status': 'success',
              'data': dataList,
              'message': json['message'] ?? 'List response processed',
            });
          }
        } else {
          // Handle as regular object response
          return FrameProcessResponse.fromJson(json);
        }
      },
    );
  }

  /// Train custom model
  Future<ApiResponse<TrainingResponse>> trainCustomModel({
    List<String>? filePaths,
    List<String>? labels,
  }) async {
    return postJson<TrainingResponse>(
      ApiConfig.customTrainEndpoint,
      data: {
        if (filePaths != null) 'file_paths': filePaths,
        if (labels != null) 'labels': labels,
      },
      config: RequestConfig.modelTraining,
      dataParser: (json) => TrainingResponse.fromJson(json),
    );
  }

  /// Switch model type
  Future<ApiResponse<ModelSwitchResponse>> switchModel({
    required String modelType,
  }) async {
    return postJson<ModelSwitchResponse>(
      ApiConfig.switchModelEndpoint,
      data: {'modelType': modelType},
      config: RequestConfig.standard,
      dataParser: (json) => ModelSwitchResponse.fromJson(json),
    );
  }

  /// Health check
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return get<Map<String, dynamic>>(
      ApiConfig.healthEndpoint,
      config: RequestConfig.standard,
    );
  }

  /// Reset frame accumulation
  Future<ApiResponse<Map<String, dynamic>>> resetFrameAccumulation() async {
    return postJson<Map<String, dynamic>>(
      ApiConfig.resetEndpoint,
      config: RequestConfig.standard,
    );
  }
}
