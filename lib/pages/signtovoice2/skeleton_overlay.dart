import 'package:flutter/material.dart';

/// MediaPipe Skeleton Painter - displays hand and pose landmarks
///
/// Coordinate Transformation Options:
/// - useCoordinateTransformation: true - Use aspect ratio aware scaling (default)
/// - useSimpleTransformation: true - Use direct 1:1 coordinate mapping (good for debugging)
/// - debugMode: true - Show debug information and canvas bounds
///
/// Usage example:
/// ```dart
/// SkeletonOverlay(
///   handLandmarks: handData,
///   poseLandmarks: poseData,
///   useSimpleTransformation: true, // Try this if coordinates are off
///   debugMode: true, // Enable to see coordinate info
/// )
/// ```
class MediaPipeSkeletonPainter extends CustomPainter {
  final List<List<Map<String, dynamic>>> handLandmarks;
  final List<List<Map<String, dynamic>>> poseLandmarks;
  final Size previewSize;
  final List<String>? handLabels;
  final double? cameraAspectRatio;
  final bool isFrontCamera;
  final bool useCoordinateTransformation;
  final bool useSimpleTransformation;
  final bool debugMode;

  MediaPipeSkeletonPainter({
    required this.handLandmarks,
    required this.poseLandmarks,
    required this.previewSize,
    this.handLabels,
    this.cameraAspectRatio,
    this.isFrontCamera = false,
    this.useCoordinateTransformation = true,
    this.useSimpleTransformation = false,
    this.debugMode = false,
  });

  // Hand landmark connections (MediaPipe hand model)
  static const List<List<int>> handConnections = [
    // Thumb
    [0, 1], [1, 2], [2, 3], [3, 4],
    // Index finger
    [0, 5], [5, 6], [6, 7], [7, 8],
    // Middle finger
    [0, 9], [9, 10], [10, 11], [11, 12],
    // Ring finger
    [0, 13], [13, 14], [14, 15], [15, 16],
    // Pinky
    [0, 17], [17, 18], [18, 19], [19, 20],
  ];

  // Pose landmark connections (MediaPipe pose model - key connections)
  static const List<List<int>> poseConnections = [
    // Face
    [0, 1], [1, 2], [2, 3], [3, 7],
    [0, 4], [4, 5], [5, 6], [6, 8],
    // Body
    [9, 10], // mouth
    [11, 12], // shoulders
    [11, 13], [13, 15], // left arm
    [12, 14], [14, 16], // right arm
    [11, 23], [12, 24], // torso
    [23, 24], // hips
    [23, 25], [25, 27], [27, 29], [29, 31], // left leg
    [24, 26], [26, 28], [28, 30], [30, 32], // right leg
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Debug information
    if (debugMode) {
      // Draw canvas bounds
      final boundsPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width, size.height), boundsPaint);

      // Draw coordinate info text
      final debugText = 'Canvas: ${size.width.toInt()}x${size.height.toInt()}\n'
          'Preview: ${previewSize.width.toInt()}x${previewSize.height.toInt()}\n'
          'Simple: $useSimpleTransformation';

      final debugPainter = TextPainter(
        text: TextSpan(
          text: debugText,
          style: TextStyle(color: Colors.yellow, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      debugPainter.layout();
      debugPainter.paint(canvas, Offset(10, 10));
    }

    // Paint for hand labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Helper method to transform coordinates
    Offset transformCoordinate(Map<String, dynamic> landmark, Size canvasSize) {
      double x = (landmark['x'] as num).toDouble();
      double y = (landmark['y'] as num).toDouble();

      if (!useCoordinateTransformation) {
        // Apply 90-degree counterclockwise rotation: (x,y) -> (1-y, x)
        double rotatedX = (1.0 - y) * canvasSize.width;
        double rotatedY = x * canvasSize.height;
        return Offset(rotatedX, rotatedY);
      }

      final double previewW = previewSize.width;
      final double previewH = previewSize.height;
      final double canvasW = canvasSize.width;
      final double canvasH = canvasSize.height;

      // Calculate aspect ratios and scaling
      final double previewAspectRatio = previewW / previewH;
      final double canvasAspectRatio = canvasW / canvasH;

      double scale;
      double offsetX = 0;
      double offsetY = 0;

      if (canvasAspectRatio > previewAspectRatio) {
        // Canvas is wider - letterbox horizontally
        scale = canvasH / previewH;
        final double scaledWidth = previewW * scale;
        offsetX = (canvasW - scaledWidth) / 2;
      } else {
        // Canvas is taller - letterbox vertically
        scale = canvasW / previewW;
        final double scaledHeight = previewH * scale;
        offsetY = (canvasH - scaledHeight) / 2;
      }

      // Transform normalized coordinates to canvas coordinates
      double px = (x * previewW * scale) + offsetX;
      double py = (y * previewH * scale) + offsetY;

      // Apply 90-degree counterclockwise rotation BEFORE other transformations
      // For 90° counterclockwise: (x,y) -> (canvas_height - y, x)
      double rotatedPx = canvasH - py;
      double rotatedPy = px;

      // Update px and py with rotated values
      px = rotatedPx;
      py = rotatedPy;

      // Fix the orientation transformations (simplified since we already rotated)
      if (previewH > previewW) {
        // Portrait mode adjustments after rotation
        px += offsetY;
        py -= offsetX;
      }

      // Front camera mirroring - apply after rotation
      if (isFrontCamera) {
        // Since we rotated 90° counterclockwise, mirroring logic changes
        if (previewH > previewW) {
          // In original portrait mode (now rotated), mirror horizontally
          px = canvasW - px;
        } else {
          // In original landscape mode (now rotated), mirror horizontally
          px = canvasW - px;
        }
      }

      // Clamp coordinates to canvas bounds to prevent off-screen rendering
      px = px.clamp(0.0, canvasW);
      py = py.clamp(0.0, canvasH);

      return Offset(px, py);
    } // Simplified transformation method - better for debugging

    Offset transformCoordinateSimple(
        Map<String, dynamic> landmark, Size canvasSize) {
      double x = (landmark['x'] as num).toDouble();
      double y = (landmark['y'] as num).toDouble();

      // Apply 90-degree counterclockwise rotation: (x,y) -> (1-y, x)
      double rotatedX = 1.0 - y;
      double rotatedY = x;

      // Simple direct mapping with basic scaling after rotation
      double px = rotatedX * canvasSize.width;
      double py = rotatedY * canvasSize.height;

      // Apply front camera mirroring (now affects X axis due to rotation)
      if (isFrontCamera) {
        px = canvasSize.width - px;
      }

      // Clamp to bounds
      px = px.clamp(0.0, canvasSize.width);
      py = py.clamp(0.0, canvasSize.height);

      return Offset(px, py);
    }

    // Choose transformation method
    Offset getTransformedCoordinate(
        Map<String, dynamic> landmark, Size canvasSize) {
      if (useSimpleTransformation) {
        return transformCoordinateSimple(landmark, canvasSize);
      } else {
        return transformCoordinate(landmark, canvasSize);
      }
    }

    // Draw hand landmarks and connections
    for (int handIndex = 0; handIndex < handLandmarks.length; handIndex++) {
      final hand = handLandmarks[handIndex];
      final handLabel = handLabels != null && handIndex < handLabels!.length
          ? handLabels![handIndex]
          : 'Hand ${handIndex + 1}';

      // Choose colors based on hand
      final isLeftHand = handLabel.toLowerCase().contains('left');
      final handLandmarkPaint = Paint()
        ..color = isLeftHand ? Colors.green : Colors.red
        ..style = PaintingStyle.fill;

      final handConnectionPaint = Paint()
        ..color = isLeftHand
            ? Colors.green.withOpacity(0.7)
            : Colors.red.withOpacity(0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw hand connections first (so they appear behind landmarks)
      for (final connection in handConnections) {
        if (connection[0] < hand.length && connection[1] < hand.length) {
          final point1 = hand[connection[0]];
          final point2 = hand[connection[1]];

          final offset1 = getTransformedCoordinate(point1, size);
          final offset2 = getTransformedCoordinate(point2, size);

          canvas.drawLine(
            offset1,
            offset2,
            handConnectionPaint,
          );
        }
      }

      // Draw hand landmarks
      for (int i = 0; i < hand.length; i++) {
        final landmark = hand[i];
        final offset = getTransformedCoordinate(landmark, size);

        // Different sizes for different landmark types
        double radius = 3.0;
        if (i == 0) radius = 5.0; // Wrist - larger
        if ([4, 8, 12, 16, 20].contains(i)) radius = 4.0; // Fingertips - medium

        canvas.drawCircle(offset, radius, handLandmarkPaint);
      }

      // Draw hand label
      if (hand.isNotEmpty) {
        final wrist = hand[0];
        final offset = getTransformedCoordinate(wrist, size);

        textPainter.text = TextSpan(
          text: handLabel,
          style: TextStyle(
            color: isLeftHand ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black,
              ),
            ],
          ),
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - 25));
      }
    }

    // Draw pose landmarks and connections
    if (poseLandmarks.isNotEmpty && poseLandmarks[0].isNotEmpty) {
      final pose = poseLandmarks[0];

      // Pose colors
      final poseLandmarkPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;

      final poseConnectionPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.6)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Draw pose connections first
      for (final connection in poseConnections) {
        if (connection[0] < pose.length && connection[1] < pose.length) {
          final point1 = pose[connection[0]];
          final point2 = pose[connection[1]];

          // Check visibility (MediaPipe includes visibility score)
          final visibility1 = (point1['visibility'] as double?) ?? 1.0;
          final visibility2 = (point2['visibility'] as double?) ?? 1.0;

          if (visibility1 > 0.3 && visibility2 > 0.3) {
            final offset1 = getTransformedCoordinate(point1, size);
            final offset2 = getTransformedCoordinate(point2, size);

            canvas.drawLine(
              offset1,
              offset2,
              poseConnectionPaint,
            );
          }
        }
      }

      // Draw pose landmarks
      for (int i = 0; i < pose.length; i++) {
        final landmark = pose[i];
        final visibility = (landmark['visibility'] as double?) ?? 1.0;

        if (visibility > 0.3) {
          final offset = getTransformedCoordinate(landmark, size);

          // Different sizes for different body parts
          double radius = 3.0;
          if ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10].contains(i))
            radius = 4.0; // Face/head
          if ([11, 12, 23, 24].contains(i)) radius = 5.0; // Key body points

          canvas.drawCircle(offset, radius, poseLandmarkPaint);
        }
      }
    }

    // Draw coordinate count info and debug information
    textPainter.text = TextSpan(
      text:
          'Hands: ${handLandmarks.length} | Pose: ${poseLandmarks.length}${handLabels != null ? ' | Labels: ${handLabels!.join(", ")}' : ''}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black,
          ),
        ],
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 20));

    // Draw camera and coordinate debug info
    textPainter.text = TextSpan(
      text:
          'Camera: ${isFrontCamera ? "Front" : "Back"} | Ratio: ${cameraAspectRatio?.toStringAsFixed(2) ?? "N/A"} | Canvas: ${(size.width / size.height).toStringAsFixed(2)} | Transform: ${useCoordinateTransformation ? "ON" : "OFF"}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 8,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black,
          ),
        ],
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(8, size.height - 40));

    // Draw legend for hand colors
    if (handLandmarks.isNotEmpty) {
      textPainter.text = TextSpan(
        text: 'Green: Left Hand | Red: Right Hand | Yellow: Pose',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, size.height - 60));
    }
  }

  @override
  bool shouldRepaint(covariant MediaPipeSkeletonPainter oldDelegate) {
    // Only repaint if data actually changed
    return handLandmarks != oldDelegate.handLandmarks ||
        poseLandmarks != oldDelegate.poseLandmarks ||
        handLabels != oldDelegate.handLabels;
  }
}

// Widget that displays the skeleton overlay
class SkeletonOverlay extends StatelessWidget {
  final List<List<Map<String, dynamic>>> handLandmarks;
  final List<List<Map<String, dynamic>>> poseLandmarks;
  final List<String>? handLabels;
  final double? cameraAspectRatio;
  final bool isFrontCamera;
  final bool useCoordinateTransformation;
  final bool useSimpleTransformation;
  final bool debugMode;
  final VoidCallback? onDebugTap;

  const SkeletonOverlay({
    Key? key,
    required this.handLandmarks,
    required this.poseLandmarks,
    this.handLabels,
    this.cameraAspectRatio,
    this.isFrontCamera = false,
    this.useCoordinateTransformation = true,
    this.useSimpleTransformation = true,
    this.debugMode = false,
    this.onDebugTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onDoubleTap: onDebugTap,
        child: CustomPaint(
          painter: MediaPipeSkeletonPainter(
            handLandmarks: handLandmarks,
            poseLandmarks: poseLandmarks,
            previewSize: previewSize(context),
            handLabels: handLabels,
            cameraAspectRatio: cameraAspectRatio,
            isFrontCamera: isFrontCamera,
            useCoordinateTransformation: useCoordinateTransformation,
            useSimpleTransformation: useSimpleTransformation,
            debugMode: debugMode,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  // Helper to get preview size (use camera preview size if available, else fallback to screen)
  Size previewSize(BuildContext context) {
    // You may want to pass the actual camera preview size from your camera plugin
    // For now, fallback to screen size
    return MediaQuery.of(context).size;
  }
}
