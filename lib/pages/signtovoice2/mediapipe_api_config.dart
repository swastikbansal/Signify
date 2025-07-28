// API Configuration helper for MediaPipe coordinates
// This file contains configuration constants and helper methods for the API integration

import 'dart:math';

class MediaPipeApiConfig {
  // Default API configuration
  static const String defaultApiUrl =
      'https://your-api-endpoint.com/api/mediapipe-data';
  static const int defaultApiCallInterval = 100; // milliseconds
  static const bool defaultApiEnabled = true;

  // Hand detection configuration for better second hand recognition
  static const double defaultMinDetectionConfidence = 0.6;
  static const double defaultMinTrackingConfidence = 0.4;
  static const int defaultMaxNumHands = 2;

  // Coordinate processing configuration
  static const bool defaultSendOnlyWhenBothHandsDetected = false;
  static const bool defaultLogCoordinates = true;

  // API data structure keys
  static const String timestampKey = 'timestamp';
  static const String leftHandCoordsKey = 'left_hand_coords';
  static const String rightHandCoordsKey = 'right_hand_coords';
  static const String poseCoordsKey = 'pose_coords';
  static const String handLabelsKey = 'hand_labels';

  // Helper method to create API payload
  static Map<String, dynamic> createApiPayload({
    required int timestamp,
    List<double>? leftHandCoords,
    List<double>? rightHandCoords,
    List<double>? poseCoords,
    List<String>? handLabels,
  }) {
    Map<String, dynamic> payload = {
      timestampKey: timestamp,
    };

    if (leftHandCoords != null) payload[leftHandCoordsKey] = leftHandCoords;
    if (rightHandCoords != null) payload[rightHandCoordsKey] = rightHandCoords;
    if (poseCoords != null) payload[poseCoordsKey] = poseCoords;
    if (handLabels != null) payload[handLabelsKey] = handLabels;

    return payload;
  }

  // Helper method to validate coordinate data
  static bool isValidCoordinateData(List<double>? coords) {
    return coords != null && coords.isNotEmpty && coords.length % 3 == 0;
  }

  // Helper method to format coordinates for logging
  static String formatCoordinatesForLogging(
      List<double>? coords, String label) {
    if (coords == null) return '$label: null';
    return '$label: ${coords.length ~/ 3} landmarks (${coords.length} values)';
  }
}

// Extension methods for better coordinate handling
extension CoordinateListExtension on List<double> {
  // Convert flat coordinate list to structured landmarks
  List<Map<String, double>> toStructuredLandmarks() {
    List<Map<String, double>> landmarks = [];
    for (int i = 0; i < length; i += 3) {
      if (i + 2 < length) {
        landmarks.add({
          'x': this[i],
          'y': this[i + 1],
          'z': this[i + 2],
        });
      }
    }
    return landmarks;
  }

  // Get specific landmark by index
  Map<String, double>? getLandmark(int index) {
    int startIndex = index * 3;
    if (startIndex + 2 < length) {
      return {
        'x': this[startIndex],
        'y': this[startIndex + 1],
        'z': this[startIndex + 2],
      };
    }
    return null;
  }

  // Calculate distance between two landmarks
  double distanceBetweenLandmarks(int index1, int index2) {
    var landmark1 = getLandmark(index1);
    var landmark2 = getLandmark(index2);

    if (landmark1 == null || landmark2 == null) return 0.0;

    double dx = landmark1['x']! - landmark2['x']!;
    double dy = landmark1['y']! - landmark2['y']!;
    double dz = landmark1['z']! - landmark2['z']!;

    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}
