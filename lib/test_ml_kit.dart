import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  // This file is just to test available classes
  final poseDetector = PoseDetector(options: PoseDetectorOptions());

  print('PoseDetector available: ${poseDetector.runtimeType}');

  // Clean up
  poseDetector.close();
}
