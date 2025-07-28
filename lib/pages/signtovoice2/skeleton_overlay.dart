import 'package:flutter/material.dart';

class MediaPipeSkeletonPainter extends CustomPainter {
  final List<List<Map<String, dynamic>>> handLandmarks;
  final List<List<Map<String, dynamic>>> poseLandmarks;
  final Size previewSize;
  final List<String>? handLabels;
  final double? cameraAspectRatio;
  final bool isFrontCamera;
  final bool useCoordinateTransformation;

  MediaPipeSkeletonPainter({
    required this.handLandmarks,
    required this.poseLandmarks,
    required this.previewSize,
    this.handLabels,
    this.cameraAspectRatio,
    this.isFrontCamera = false,
    this.useCoordinateTransformation = true,
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
    // Paint for hand labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Helper method to transform coordinates
    Offset transformCoordinate(Map<String, dynamic> landmark, Size canvasSize) {
      double x = (landmark['x'] as num).toDouble();
      double y = (landmark['y'] as num).toDouble();

      if (!useCoordinateTransformation) {
        // Simple direct mapping without transformation
        return Offset(x * canvasSize.width, y * canvasSize.height);
      }

      // Handle coordinate transformation for different camera orientations
      // MediaPipe coordinates are normalized (0-1) but may need flipping/rotation

      // For portrait mode, rotate coordinates 90 degrees
      // MediaPipe typically outputs in landscape, so we rotate for portrait
      double tempX = x;
      x = 1.0 - y; // Rotate 90 degrees clockwise
      y = tempX;

      // For front camera, flip horizontally after rotation
      if (isFrontCamera) {
        x = 1.0 - x;
      }

      // Handle aspect ratio differences
      double scaledX = x * canvasSize.width;
      double scaledY = y * canvasSize.height;

      // If camera aspect ratio is different from canvas, we need to adjust
      if (cameraAspectRatio != null) {
        double canvasAspectRatio = canvasSize.width / canvasSize.height;

        if ((cameraAspectRatio! - canvasAspectRatio).abs() > 0.1) {
          // Significant aspect ratio difference, adjust coordinates
          if (cameraAspectRatio! > canvasAspectRatio) {
            // Camera is wider, scale height
            double scale = canvasAspectRatio / cameraAspectRatio!;
            scaledY = scaledY * scale + (canvasSize.height * (1 - scale)) / 2;
          } else {
            // Camera is taller, scale width
            double scale = cameraAspectRatio! / canvasAspectRatio;
            scaledX = scaledX * scale + (canvasSize.width * (1 - scale)) / 2;
          }
        }
      }

      return Offset(scaledX, scaledY);
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

          final offset1 = transformCoordinate(point1, size);
          final offset2 = transformCoordinate(point2, size);

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
        final offset = transformCoordinate(landmark, size);

        // Different sizes for different landmark types
        double radius = 3.0;
        if (i == 0) radius = 5.0; // Wrist - larger
        if ([4, 8, 12, 16, 20].contains(i)) radius = 4.0; // Fingertips - medium

        canvas.drawCircle(offset, radius, handLandmarkPaint);
      }

      // Draw hand label
      if (hand.isNotEmpty) {
        final wrist = hand[0];
        final offset = transformCoordinate(wrist, size);

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
            final offset1 = transformCoordinate(point1, size);
            final offset2 = transformCoordinate(point2, size);

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
          final offset = transformCoordinate(landmark, size);

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
  final VoidCallback? onDebugTap;

  const SkeletonOverlay({
    Key? key,
    required this.handLandmarks,
    required this.poseLandmarks,
    this.handLabels,
    this.cameraAspectRatio,
    this.isFrontCamera = false,
    this.useCoordinateTransformation = true,
    this.onDebugTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDebugTap,
      child: CustomPaint(
        painter: MediaPipeSkeletonPainter(
          handLandmarks: handLandmarks,
          poseLandmarks: poseLandmarks,
          previewSize: MediaQuery.of(context).size,
          handLabels: handLabels,
          cameraAspectRatio: cameraAspectRatio,
          isFrontCamera: isFrontCamera,
          useCoordinateTransformation: useCoordinateTransformation,
        ),
        size: Size.infinite,
      ),
    );
  }
}
