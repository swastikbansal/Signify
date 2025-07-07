import 'dart:math';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class SignLanguageDetector {
  // ML Kit components
  late PoseDetector _poseDetector;

  // TensorFlow Lite interpreters
  Interpreter? _leftHandModel;
  Interpreter? _rightHandModel;
  Interpreter? _poseModel;

  // Model labels
  List<String> _labels = [];

  // Detection state
  bool _isInitialized = false;
  List<double> _accumulatedProbabilities = [];
  int _frameCount = 0;
  String _currentPrediction = "";

  // Initialize the detector
  Future<void> initialize() async {
    try {
      // Initialize ML Kit pose detector
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(),
      );

      // Load TensorFlow Lite models
      await _loadModels();

      // Load labels
      await _loadLabels();

      _isInitialized = true;
      print('Sign Language Detector initialized successfully');
    } catch (e) {
      print('Error initializing Sign Language Detector: $e');
    }
  }

  Future<void> _loadModels() async {
    try {
      // Load models from assets
      _leftHandModel = await Interpreter.fromAsset(
          'assets/ml_models/left_hand_model.tflite');
      _rightHandModel = await Interpreter.fromAsset(
          'assets/ml_models/right_hand_model.tflite');
      _poseModel =
          await Interpreter.fromAsset('assets/ml_models/pose_model.tflite');

      print('Models loaded successfully');
    } catch (e) {
      print('Error loading models: $e');
      // For now, we'll continue without models for testing
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData =
          await rootBundle.loadString('assets/ml_models/labels.txt');
      _labels =
          labelsData.split('\n').where((label) => label.isNotEmpty).toList();

      // Initialize accumulated probabilities
      _accumulatedProbabilities = List.filled(_labels.length, 0.0);

      print('Labels loaded: ${_labels.length} classes');
    } catch (e) {
      print('Error loading labels: $e');
      // Default labels for testing (matching Python implementation)
      _labels = [
        'sun',
        'help',
        'teacher',
        'support',
        'paper',
        'love',
        'dance',
        'water',
        'accident',
        'yes',
        'thick',
        'high',
        'poor',
        'i',
        'my',
        'important_1',
        'important_2',
        'deaf',
        'winner',
        'eat',
        'pizza',
        'go',
        'isl',
        'friend',
        'school',
        'deep',
        'loud',
        'flat',
        'slow',
        'sad',
        'soft',
        'happy',
        'poot',
        'quiet',
        'book',
        'woman'
      ];
      _accumulatedProbabilities = List.filled(_labels.length, 0.0);
    }
  }

  // Process camera frame for sign detection
  Future<String> processFrame(CameraImage image) async {
    if (!_isInitialized) return "";

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) return "";

      // Detect pose only (no hand detection available in current ML Kit)
      final poses = await _poseDetector.processImage(inputImage);

      // Extract features and run inference
      await _runInference(poses.isNotEmpty ? poses.first : null);

      return _currentPrediction;
    } catch (e) {
      print('Error processing frame: $e');
      return "";
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Convert CameraImage to InputImage
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      const InputImageRotation imageRotation = InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  Future<void> _runInference(Pose? pose) async {
    List<double> leftHandProbs = List.filled(_labels.length, 0.0);
    List<double> rightHandProbs = List.filled(_labels.length, 0.0);
    List<double> poseProbs = List.filled(_labels.length, 0.0);

    int activeModels = 0;

    if (pose != null) {
      // Extract hand-like features from wrist/arm positions
      final leftHandFeatures =
          _extractHandFeaturesFromPose(pose, isLeftHand: true);
      final rightHandFeatures =
          _extractHandFeaturesFromPose(pose, isLeftHand: false);

      // Run inference for each hand model if available
      if (_leftHandModel != null && leftHandFeatures.isNotEmpty) {
        leftHandProbs = _runModelInference(_leftHandModel!, leftHandFeatures);
        activeModels++;
      }

      if (_rightHandModel != null && rightHandFeatures.isNotEmpty) {
        rightHandProbs =
            _runModelInference(_rightHandModel!, rightHandFeatures);
        activeModels++;
      }

      // Extract pose features
      if (_poseModel != null) {
        final poseFeatures = _extractPoseFeatures(pose);
        poseProbs = _runModelInference(_poseModel!, poseFeatures);
        activeModels++;
      }
    }

    // Combine probabilities (matching Python averaging logic)
    if (activeModels > 0) {
      final combinedProbs = List.generate(_labels.length, (i) {
        return (leftHandProbs[i] + rightHandProbs[i] + poseProbs[i]) /
            activeModels;
      });

      // Accumulate probabilities
      for (int i = 0; i < _labels.length; i++) {
        _accumulatedProbabilities[i] += combinedProbs[i];
      }

      _frameCount++;

      // Make prediction after 5 frames (matching Python logic)
      if (_frameCount >= 5) {
        _makePrediction();
        _resetAccumulation();
      }
    }
  }

  // Extract hand-like features from pose wrist/arm positions
  List<double> _extractHandFeaturesFromPose(Pose pose,
      {required bool isLeftHand}) {
    List<double> features = [];

    try {
      // Get relevant pose landmarks for hand estimation
      final shoulder = isLeftHand
          ? pose.landmarks[PoseLandmarkType.leftShoulder]
          : pose.landmarks[PoseLandmarkType.rightShoulder];
      final elbow = isLeftHand
          ? pose.landmarks[PoseLandmarkType.leftElbow]
          : pose.landmarks[PoseLandmarkType.rightElbow];
      final wrist = isLeftHand
          ? pose.landmarks[PoseLandmarkType.leftWrist]
          : pose.landmarks[PoseLandmarkType.rightWrist];
      final nose = pose.landmarks[PoseLandmarkType.nose];

      if (shoulder == null || elbow == null || wrist == null || nose == null) {
        return List.filled(23, 0.0); // Return default features
      }

      // Simulate hand landmark pairs using arm geometry
      // This is a simplified approach since we don't have actual hand landmarks
      final armVector = [
        wrist.x - elbow.x,
        wrist.y - elbow.y,
        wrist.z - elbow.z
      ];
      final forearmVector = [
        elbow.x - shoulder.x,
        elbow.y - shoulder.y,
        elbow.z - shoulder.z
      ];

      // Create simulated finger vectors based on wrist orientation
      final List<List<double>> simulatedFingerPairs = [];
      for (int i = 0; i < 6; i++) {
        // Simulate finger directions based on wrist position and arm orientation
        final offset = 0.1 * (i + 1); // Simulate finger spread
        final fingerVector = [
          armVector[0] * offset,
          armVector[1] * offset,
          armVector[2] * offset,
        ];
        simulatedFingerPairs.add(fingerVector);
      }

      // Calculate angles with coordinate axes for each simulated finger
      for (final fingerVector in simulatedFingerPairs) {
        final angleX = _calculateAngle(fingerVector, [1, 0, 0]);
        final angleY = _calculateAngle(fingerVector, [0, 1, 0]);
        final angleZ = _calculateAngle(fingerVector, [0, 0, 1]);
        features.addAll([angleX, angleY, angleZ]);
      }

      // Add normal vector features (simplified using arm vectors)
      final normalAngles =
          _calculateNormalAnglesFromVectors(armVector, forearmVector);
      features.addAll(normalAngles);

      // Add distance features (nose to wrist)
      final distanceX = (nose.x - wrist.x).abs();
      final distanceY = (nose.y - wrist.y).abs();
      features.addAll([distanceX, distanceY]);

      // Ensure we have exactly 23 features
      while (features.length < 23) {
        features.add(0.0);
      }
      if (features.length > 23) {
        features = features.sublist(0, 23);
      }
    } catch (e) {
      print('Error extracting hand features from pose: $e');
      features = List.filled(23, 0.0);
    }

    return features;
  }

  // Extract pose features matching Python implementation
  List<double> _extractPoseFeatures(Pose pose) {
    List<double> features = [];

    try {
      // Calculate angles matching Python extract_pose_features
      // angle_11_12_14: (11, 12, 14) - left shoulder, right shoulder, right elbow
      final angle1 = _calculateThreePointAngleSafe(
          pose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightElbow);
      features.add(angle1);

      // angle_12_14_16: (12, 11, 13) - right shoulder, left shoulder, left elbow
      final angle2 = _calculateThreePointAngleSafe(
          pose,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftElbow);
      features.add(angle2);

      // angle_11_13_15: (11, 13, 15) - left shoulder, left elbow, left wrist
      final angle3 = _calculateThreePointAngleSafe(
          pose,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftWrist);
      features.add(angle3);

      // angle_13_15_17: (12, 14, 16) - right shoulder, right elbow, right wrist
      final angle4 = _calculateThreePointAngleSafe(
          pose,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightWrist);
      features.add(angle4);

      // Normal vectors matching Python implementation
      // Using available pose landmarks instead of hand landmarks
      final normal1 = _calculateNormalAnglesSafe(
          pose,
          PoseLandmarkType.leftWrist,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftShoulder);
      features.addAll(normal1);

      final normal2 = _calculateNormalAnglesSafe(
          pose,
          PoseLandmarkType.rightWrist,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightShoulder);
      features.addAll(normal2);

      // Add distance between left wrist and right wrist
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      if (leftWrist != null && rightWrist != null) {
        final xDistance = (leftWrist.x - rightWrist.x).abs();
        final yDistance = (leftWrist.y - rightWrist.y).abs();
        features.addAll([xDistance, yDistance]);
      } else {
        features.addAll([0.0, 0.0]);
      }

      // Pad features to expected length
      while (features.length < 12) {
        features.add(0.0);
      }
    } catch (e) {
      print('Error extracting pose features: $e');
      features = List.filled(12, 0.0); // Expected feature count
    }

    return features;
  }

  // Calculate angle between two vectors (matching Python calculate_angle1)
  double _calculateAngle(List<double> vec1, List<double> vec2) {
    try {
      final dot = vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2];
      final norm1 =
          sqrt(vec1[0] * vec1[0] + vec1[1] * vec1[1] + vec1[2] * vec1[2]);
      final norm2 =
          sqrt(vec2[0] * vec2[0] + vec2[1] * vec2[1] + vec2[2] * vec2[2]);

      if (norm1 == 0 || norm2 == 0) return 0.0;

      final cosAngle = dot / (norm1 * norm2);
      return cosAngle.clamp(-1.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate angle between three points using pose landmarks
  double _calculateThreePointAngleSafe(Pose pose, PoseLandmarkType p1Type,
      PoseLandmarkType p2Type, PoseLandmarkType p3Type) {
    try {
      final p1 = pose.landmarks[p1Type];
      final p2 = pose.landmarks[p2Type];
      final p3 = pose.landmarks[p3Type];

      if (p1 == null || p2 == null || p3 == null) return 0.0;

      final v1 = [p1.x - p2.x, p1.y - p2.y, p1.z - p2.z];
      final v2 = [p3.x - p2.x, p3.y - p2.y, p3.z - p2.z];

      return _calculateAngle(v1, v2);
    } catch (e) {
      return 0.0;
    }
  }

  // Calculate normal angles from two vectors
  List<double> _calculateNormalAnglesFromVectors(
      List<double> v1, List<double> v2) {
    try {
      // Cross product for normal
      final normal = [
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0],
      ];

      // Normalize
      final norm = sqrt(normal[0] * normal[0] +
          normal[1] * normal[1] +
          normal[2] * normal[2]);
      if (norm == 0) return [0.0, 0.0, 0.0];

      for (int i = 0; i < 3; i++) {
        normal[i] /= norm;
      }

      // Calculate angles with axes (matching Python calculate_normal_angles)
      return [
        _calculateAngle(normal, [1, 0, 0]),
        _calculateAngle(normal, [0, 1, 0]),
        _calculateAngle(normal, [0, 0, 1]),
      ];
    } catch (e) {
      return [0.0, 0.0, 0.0];
    }
  }

  // Calculate normal angles for pose landmarks
  List<double> _calculateNormalAnglesSafe(Pose pose, PoseLandmarkType p1Type,
      PoseLandmarkType p2Type, PoseLandmarkType p3Type) {
    try {
      final p1 = pose.landmarks[p1Type];
      final p2 = pose.landmarks[p2Type];
      final p3 = pose.landmarks[p3Type];

      if (p1 == null || p2 == null || p3 == null) {
        return [-1.0, -1.0, -1.0]; // Default for missing landmarks
      }

      // Calculate normal vector (matching Python calculate_normal)
      final v1 = [p2.x - p1.x, p2.y - p1.y, p2.z - p1.z];
      final v2 = [p3.x - p1.x, p3.y - p1.y, p3.z - p1.z];

      return _calculateNormalAnglesFromVectors(v1, v2);
    } catch (e) {
      return [0.0, 0.0, 0.0];
    }
  }

  List<double> _runModelInference(Interpreter model, List<double> features) {
    try {
      // Prepare input
      final input = [features];
      final output = List.filled(1, List.filled(_labels.length, 0.0));

      // Run inference
      model.run(input, output);

      return output[0].cast<double>();
    } catch (e) {
      print('Error running model inference: $e');
      return List.filled(_labels.length, 0.0);
    }
  }

  // Apply individual thresholds matching Python calculating_percentage function
  List<double> _calculatePercentageWithThresholds(List<double> avg) {
    final Map<String, double> individualThreshold = {
      'sun': 0.9,
      'help': 0.9,
      'teacher': 0.9,
      'support': 0.9,
      'paper': 0.9,
      'love': 0.9,
      'dance': 0.9,
      'water': 0.9,
      'accident': 0.9,
      'yes': 0.9,
      'thick': 0.9,
      'high': 0.9,
      'poor': 0.9,
      'i': 0.9,
      'my': 0.9,
      'important_1': 0.9,
      'important_2': 0.9,
      'deaf': 0.9,
      'winner': 0.9,
      'eat': 0.9,
      'pizza': 0.9,
      'go': 0.9,
      'isl': 0.9,
      'friend': 0.9,
      'school': 0.9,
      'deep': 0.9,
      'loud': 0.9,
      'flat': 0.9,
      'slow': 0.9,
      'sad': 0.9,
      'soft': 0.9,
      'happy': 0.9,
      'poot': 0.9,
      'quiet': 0.9,
      'book': 0.9,
      'woman': 0.9,
    };

    List<double> thresholdPercentage = [];
    for (int i = 0; i < avg.length && i < _labels.length; i++) {
      final value = individualThreshold[_labels[i].toLowerCase()] ?? 0.9;
      thresholdPercentage.add(avg[i] * 100 / value);
    }
    return thresholdPercentage;
  }

  void _makePrediction() {
    // Apply thresholds like in Python
    final thresholdAdjustedProbs =
        _calculatePercentageWithThresholds(_accumulatedProbabilities);

    // Find the class with highest probability
    int maxIndex = 0;
    double maxProb = thresholdAdjustedProbs[0];

    for (int i = 1; i < thresholdAdjustedProbs.length; i++) {
      if (thresholdAdjustedProbs[i] > maxProb) {
        maxProb = thresholdAdjustedProbs[i];
        maxIndex = i;
      }
    }

    if (maxIndex < _labels.length) {
      _currentPrediction = _labels[maxIndex];
      print(
          'Predicted: $_currentPrediction (confidence: ${maxProb.toStringAsFixed(2)})');
    }
  }

  void _resetAccumulation() {
    _accumulatedProbabilities = List.filled(_labels.length, 0.0);
    _frameCount = 0;
  }

  String get currentPrediction => _currentPrediction;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _poseDetector.close();
    _leftHandModel?.close();
    _rightHandModel?.close();
    _poseModel?.close();
  }
}
