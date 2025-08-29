/// API Response and Exception models for Signify App
///
/// This file contains all API response handling classes and
/// custom exceptions for consistent error management.
library;

import 'dart:convert';

/// Generic API response wrapper
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final Map<String, dynamic>? rawResponse;
  final Duration? responseTime;

  const ApiResponse({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    this.statusCode,
    this.rawResponse,
    this.responseTime,
  });

  /// Create a successful response
  factory ApiResponse.success({
    required T data,
    int? statusCode,
    Map<String, dynamic>? rawResponse,
    Duration? responseTime,
  }) {
    return ApiResponse<T>(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
      rawResponse: rawResponse,
      responseTime: responseTime,
    );
  }

  /// Create an error response
  factory ApiResponse.error({
    required String errorMessage,
    int? statusCode,
    Map<String, dynamic>? rawResponse,
    Duration? responseTime,
  }) {
    return ApiResponse<T>(
      isSuccess: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
      rawResponse: rawResponse,
      responseTime: responseTime,
    );
  }

  /// Create response from HTTP response
  factory ApiResponse.fromHttpResponse({
    required int statusCode,
    required String responseBody,
    required Duration responseTime,
    T Function(Map<String, dynamic>)? dataParser,
  }) {
    Map<String, dynamic>? jsonData;

    try {
      jsonData = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      return ApiResponse.error(
        errorMessage: 'Invalid JSON response: $e',
        statusCode: statusCode,
        responseTime: responseTime,
      );
    }

    if (statusCode >= 200 && statusCode < 300) {
      T? parsedData;

      if (dataParser != null) {
        try {
          parsedData = dataParser(jsonData);
        } catch (e) {
          return ApiResponse.error(
            errorMessage: 'Failed to parse response data: $e',
            statusCode: statusCode,
            rawResponse: jsonData,
            responseTime: responseTime,
          );
        }
      }

      return ApiResponse.success(
        data: parsedData ?? jsonData as T,
        statusCode: statusCode,
        rawResponse: jsonData,
        responseTime: responseTime,
      );
    } else {
      // Extract error message from response
      String errorMsg = 'Request failed with status $statusCode';
      if (jsonData.containsKey('message')) {
        errorMsg = jsonData['message'] as String;
      } else if (jsonData.containsKey('error')) {
        errorMsg = jsonData['error'] as String;
      }

      return ApiResponse.error(
        errorMessage: errorMsg,
        statusCode: statusCode,
        rawResponse: jsonData,
        responseTime: responseTime,
      );
    }
  }

  /// Check if the response indicates success
  bool get hasData => isSuccess && data != null;

  /// Get error message or default
  String getErrorMessage([String defaultMessage = 'Unknown error occurred']) {
    return errorMessage ?? defaultMessage;
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(statusCode: $statusCode, data: $data, time: ${responseTime?.inMilliseconds}ms)';
    } else {
      return 'ApiResponse.error(statusCode: $statusCode, error: $errorMessage, time: ${responseTime?.inMilliseconds}ms)';
    }
  }
}

 
/// Custom API exceptions
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  final DateTime timestamp;

  ApiException(
    this.message, {
    this.statusCode,
    this.endpoint,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '$runtimeType: $message (Status: $statusCode, Endpoint: $endpoint)';
  }
}

/// Network-related exceptions
class NetworkException extends ApiException {
  NetworkException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.timestamp,
  });
}

/// Server error exceptions (5xx)
class ServerException extends ApiException {
  ServerException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.timestamp,
  });
}

/// Client error exceptions (4xx)
class ClientException extends ApiException {
  ClientException(
    super.message, {
    super.statusCode,
    super.endpoint,
    super.timestamp,
  });
}

/// Timeout exceptions
class TimeoutException extends ApiException {
  final Duration timeout;

  TimeoutException(
    super.message,
    this.timeout, {
    super.statusCode,
    super.endpoint,
    super.timestamp,
  });

  @override
  String toString() {
    return '$runtimeType: $message (Timeout: ${timeout.inSeconds}s, Endpoint: $endpoint)';
  }
}

/// JSON parsing exceptions
class ParseException extends ApiException {
  final String originalResponse;

  ParseException(
    super.message,
    this.originalResponse, {
    super.statusCode,
    super.endpoint,
    super.timestamp,
  });
}

/// Specific response models for your API endpoints

/// Response model for frame processing
class FrameProcessResponse {
  final String status;
  final String? prediction;
  final String? message;
  final int? frameCount;
  final Map<String, dynamic>? additionalData;

  const FrameProcessResponse({
    required this.status,
    this.prediction,
    this.message,
    this.frameCount,
    this.additionalData,
  });

  factory FrameProcessResponse.fromJson(Map<String, dynamic> json) {
    return FrameProcessResponse(
      status: json['status'] as String? ?? 'unknown',
      prediction: json['prediction'] as String?,
      message: json['message'] as String?,
      frameCount: json['frame_count'] as int?,
      additionalData: json,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isCollecting => status == 'collecting';
  bool get hasPrediction =>
      prediction != null && prediction!.isNotEmpty && prediction != 'rest';
}

/// Response model for model training
class TrainingResponse {
  final String status;
  final bool success;
  final String? message;
  final Map<String, dynamic>? additionalData;

  const TrainingResponse({
    required this.status,
    required this.success,
    this.message,
    this.additionalData,
  });

  factory TrainingResponse.fromJson(Map<String, dynamic> json) {
    return TrainingResponse(
      status: json['status'] as String? ?? 'unknown',
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      additionalData: json,
    );
  }

  bool get isSuccess => status == 'success' || success;
}

/// Response model for model switching
class ModelSwitchResponse {
  final String status;
  final bool success;
  final String? message;
  final String? modelType;

  const ModelSwitchResponse({
    required this.status,
    required this.success,
    this.message,
    this.modelType,
  });

  factory ModelSwitchResponse.fromJson(Map<String, dynamic> json) {
    return ModelSwitchResponse(
      status: json['status'] as String? ?? 'unknown',
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      modelType: json['modelType'] as String?,
    );
  }

  bool get isSuccess => status == 'success' || success;
}
