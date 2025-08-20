import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Enhanced API service for sign language detection with improved performance and reliability
class EnhancedApiService {
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 500);
  static const Duration _apiTimeout = Duration(seconds: 10);

  final http.Client _httpClient = http.Client();
  final List<String> _apiEndpoints;
  int _currentEndpointIndex = 0;

  // Performance metrics
  int _successfulRequests = 0;
  int _failedRequests = 0;
  double _averageResponseTime = 0.0;

  // Frame deduplication
  String? _lastFrameHash;
  DateTime _lastApiCall = DateTime.now();

  EnhancedApiService({
    required List<String> apiEndpoints,
  }) : _apiEndpoints = apiEndpoints;

  /// Process frame with enhanced reliability and performance
  Future<Map<String, dynamic>?> processFrame(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.7,
  }) async {
    // Frame deduplication check
    final frameHash = _generateFrameHash(imageBytes);
    if (frameHash == _lastFrameHash &&
        DateTime.now().difference(_lastApiCall) <
            const Duration(milliseconds: 200)) {
      return null; // Skip duplicate frame
    }

    _lastFrameHash = frameHash;
    _lastApiCall = DateTime.now();

    final stopwatch = Stopwatch()..start();

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final endpoint = _getCurrentEndpoint();
        final request = http.MultipartRequest('POST', Uri.parse(endpoint));

        // Add image data
        request.files.add(
          http.MultipartFile.fromBytes(
            'frame',
            imageBytes,
            filename: 'frame.jpg',
          ),
        );

        // Add metadata
        request.fields['confidence_threshold'] = confidenceThreshold.toString();
        request.fields['timestamp'] =
            DateTime.now().millisecondsSinceEpoch.toString();

        final streamedResponse =
            await _httpClient.send(request).timeout(_apiTimeout);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final result = json.decode(response.body) as Map<String, dynamic>;

          // Update metrics
          stopwatch.stop();
          _updateMetrics(true, stopwatch.elapsedMilliseconds);

          return result;
        } else {
          throw Exception(
              'API returned ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('🔄 API attempt ${attempt + 1} failed: $e');

        if (attempt == _maxRetries - 1) {
          // All retries exhausted
          stopwatch.stop();
          _updateMetrics(false, stopwatch.elapsedMilliseconds);
          _rotateEndpoint(); // Try next endpoint next time
          return null;
        }

        // Exponential backoff
        await Future.delayed(_baseRetryDelay * (1 << attempt));
      }
    }

    return null;
  }

  /// Get current API endpoint with load balancing
  String _getCurrentEndpoint() {
    return _apiEndpoints[_currentEndpointIndex % _apiEndpoints.length];
  }

  /// Rotate to next endpoint for load balancing
  void _rotateEndpoint() {
    _currentEndpointIndex = (_currentEndpointIndex + 1) % _apiEndpoints.length;
    print('🔄 Switched to endpoint: ${_getCurrentEndpoint()}');
  }

  /// Generate simple hash for frame deduplication
  String _generateFrameHash(Uint8List bytes) {
    // Simple hash based on file size and some byte values
    if (bytes.isEmpty) return '';

    int hash = bytes.length;
    final step = bytes.length ~/ 10;

    for (int i = 0; i < bytes.length; i += step) {
      hash ^= bytes[i];
    }

    return hash.toString();
  }

  /// Update performance metrics
  void _updateMetrics(bool success, int responseTimeMs) {
    if (success) {
      _successfulRequests++;
      _averageResponseTime =
          (_averageResponseTime * (_successfulRequests - 1) + responseTimeMs) /
              _successfulRequests;
    } else {
      _failedRequests++;
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final totalRequests = _successfulRequests + _failedRequests;
    return {
      'total_requests': totalRequests,
      'successful_requests': _successfulRequests,
      'failed_requests': _failedRequests,
      'success_rate':
          totalRequests > 0 ? _successfulRequests / totalRequests : 0.0,
      'average_response_time_ms': _averageResponseTime,
      'current_endpoint': _getCurrentEndpoint(),
    };
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Enhanced camera frame processor for optimal API communication
class CameraFrameProcessor {
  static const int _targetWidth = 640; // Optimal for sign detection
  static const int _targetHeight = 480; // Maintains 4:3 aspect ratio
  static const int _jpegQuality = 85; // Higher quality for better detection

  /// Process camera frame for API with optimal settings
  static Future<Uint8List?> processForApi(CameraImage image) async {
    try {
      // Convert and resize frame for optimal API processing
      final processedBytes = await _convertAndResize(image);
      return processedBytes;
    } catch (e) {
      print('❌ Frame processing error: $e');
      return null;
    }
  }

  static Future<Uint8List> _convertAndResize(CameraImage image) async {
    late img.Image convertedImage;

    // Convert based on image format
    if (image.format.group == ImageFormatGroup.yuv420) {
      convertedImage = _convertYUV420toImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      convertedImage = _convertBGRA8888toImage(image);
    } else if (image.format.group == ImageFormatGroup.jpeg) {
      // Already JPEG, decode and potentially resize
      convertedImage = img.decodeImage(image.planes[0].bytes)!;
    } else {
      throw UnsupportedError('Unsupported image format: ${image.format.group}');
    }

    // Resize to optimal dimensions for API processing
    final resizedImage = img.copyResize(
      convertedImage,
      width: _targetWidth,
      height: _targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Encode to JPEG with specified quality
    final jpegBytes = img.encodeJpg(resizedImage, quality: _jpegQuality);
    return Uint8List.fromList(jpegBytes);
  }

  /// Convert YUV420 camera image to RGB Image
  static img.Image _convertYUV420toImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final convertedImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yPlane.bytesPerRow + x;
        final int uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;

        final int yValue = yPlane.bytes[yIndex];
        final int uValue = uPlane.bytes[uvIndex];
        final int vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final int g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return convertedImage;
  }

  /// Convert BGRA8888 camera image to RGB Image
  static img.Image _convertBGRA8888toImage(CameraImage image) {
    final convertedImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      format: img.Format.uint8,
    );
    return convertedImage;
  }
}
