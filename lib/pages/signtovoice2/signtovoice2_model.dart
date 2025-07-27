import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'signtovoice2_widget.dart' show Signtovoice2Widget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'package:camera/camera.dart';

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen2Controller;

  // MediaPipe related state
  static const platform = MethodChannel('mediapipe_plugin');
  bool _isDetecting = false;
  bool _isInitialized = false;
  bool _isCameraReady = false;
  String _errorMessage = '';

  // Camera preview state
  CameraController? _cameraController;
  bool _isCameraOn = false;
  bool _isCameraInitialized = false;

  // Add state change callback
  void Function()? _stateChangeCallback;

  void setStateChangeCallback(void Function() callback) {
    _stateChangeCallback = callback;
  }

  void _notifyStateChange() {
    if (_stateChangeCallback != null) {
      try {
        _stateChangeCallback!();
      } catch (e) {
        print('Error in state change callback: $e');
      }
    }
  }

  bool get isDetecting => _isDetecting;

  bool get isInitialized => _isInitialized;

  bool get isCameraReady => _isCameraReady;

  bool get isCameraOn => _isCameraOn;

  bool get isCameraInitialized => _isCameraInitialized;

  CameraController? get cameraController => _cameraController;

  String get errorMessage => _errorMessage;

  // Store coordinate data
  List<List<Map<String, dynamic>>> _handLandmarks = [];
  List<List<Map<String, dynamic>>> _poseLandmarks = [];
  String _lastUpdateTime = '';

  List<List<Map<String, dynamic>>> get handLandmarks => _handLandmarks;

  List<List<Map<String, dynamic>>> get poseLandmarks => _poseLandmarks;

  String get lastUpdateTime => _lastUpdateTime;

  void resetState() {
    _errorMessage = '';
    _isInitialized = false;
    _isDetecting = false;
    _isCameraReady = false;
    _notifyStateChange();
  }

  // State field(s) for DropDown widget.
  String? _dropDownValue;

  set dropDownValue(String? value) {
    _dropDownValue = value;
    debugLogWidgetClass(this);
  }

  String? get dropDownValue => _dropDownValue;

  FormFieldController<String>? dropDownValueController;

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  final Map<String, DebugDataField> debugGeneratorVariables = {};
  final Map<String, DebugDataField> debugBackendQueries = {};
  final Map<String, FlutterFlowModel> widgetBuilderComponents = {};

  @override
  void initState(BuildContext context) {
    debugLogWidgetClass(this);
    _setupMethodChannelListener();
  }

  void _setupMethodChannelListener() {
    try {
      platform.setMethodCallHandler((call) async {
        try {
          switch (call.method) {
            case 'onHandLandmarks':
              if (call.arguments != null && call.arguments['hands'] != null) {
                final handsRaw = call.arguments['hands'] as List<dynamic>;
                _handLandmarks =
                    handsRaw.map<List<Map<String, dynamic>>>((hand) {
                  final handRaw = hand as List<dynamic>;
                  return handRaw.map<Map<String, dynamic>>((landmark) {
                    return Map<String, dynamic>.from(
                        landmark as Map<dynamic, dynamic>);
                  }).toList();
                }).toList();
                _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
                        call.arguments['timestamp'] ?? 0)
                    .toString();

                // Print all hand landmarks to console
                _handLandmarks.asMap().forEach((handIndex, hand) {
                  print('=== Hand $handIndex (${hand.length} landmarks) ===');
                  hand.asMap().forEach((landmarkIndex, landmark) {
                    print(
                        'Landmark $landmarkIndex: x=${landmark['x']}, y=${landmark['y']}, z=${landmark['z']}');
                  });
                });

                // Update text field with detected gesture
                if (_handLandmarks.isNotEmpty && textController != null) {
                  String detectedGesture = _analyzeGesture(_handLandmarks);
                  if (detectedGesture.isNotEmpty) {
                    textController!.text = detectedGesture;
                  }
                }

                _notifyStateChange();
                print(
                    'Received hand landmarks: ${_handLandmarks.length} hands detected');
              }
              break;

            case 'onPoseLandmarks':
              if (call.arguments != null && call.arguments['poses'] != null) {
                final posesRaw = call.arguments['poses'] as List<dynamic>;
                _poseLandmarks =
                    posesRaw.map<List<Map<String, dynamic>>>((pose) {
                  final poseRaw = pose as List<dynamic>;
                  return poseRaw.map<Map<String, dynamic>>((landmark) {
                    return Map<String, dynamic>.from(
                        landmark as Map<dynamic, dynamic>);
                  }).toList();
                }).toList();
                _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(
                        call.arguments['timestamp'] ?? 0)
                    .toString();

                // Print all pose landmarks to console
                _poseLandmarks.asMap().forEach((poseIndex, pose) {
                  print('=== Pose $poseIndex (${pose.length} landmarks) ===');
                  pose.asMap().forEach((landmarkIndex, landmark) {
                    print(
                        'Landmark $landmarkIndex: x=${landmark['x']}, y=${landmark['y']}, z=${landmark['z']}');
                  });
                });

                _notifyStateChange();
                print(
                    'Received pose landmarks: ${_poseLandmarks.length} poses detected');
              }
              break;

            case 'onError':
              _errorMessage = call.arguments?['error'] ?? 'Unknown error';
              _isDetecting = false;
              _isInitialized = false;
              _notifyStateChange();
              print('MediaPipe error: $_errorMessage');
              break;

            case 'onInitialized':
              _isInitialized = call.arguments?['success'] ?? false;
              _errorMessage = _isInitialized ? '' : 'Initialization failed';
              _notifyStateChange();
              print('MediaPipe initialized: $_isInitialized');
              break;

            case 'onCameraReady':
              _isCameraReady = call.arguments?['success'] ?? false;
              _notifyStateChange();
              print('Camera ready: $_isCameraReady');
              break;
          }
        } catch (e) {
          print('Error handling method channel call: $e');
          _errorMessage = 'Method channel error: $e';
          _notifyStateChange();
        }
      });
    } catch (e) {
      print('Error setting up method channel listener: $e');
      _errorMessage = 'Setup error: $e';
    }
  }

  String _analyzeGesture(List<List<Map<String, dynamic>>> hands) {
    try {
      if (hands.isNotEmpty) {
        return "Gesture detected - ${hands.length} hand(s)";
      }
    } catch (e) {
      print('Error analyzing gesture: $e');
    }
    return "";
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use back camera if available, otherwise use first camera
        final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420, // Explicitly set format
        );

        await _cameraController!.initialize();

        // Start image stream for MediaPipe processing
        if (_isDetecting) {
          await _cameraController!.startImageStream((CameraImage image) {
            _processCameraImage(image);
          });
        }

        _isCameraInitialized = true;
        _notifyStateChange();
        print(
            'Back camera initialized successfully with format: ${_cameraController!.description.name}');
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _errorMessage = 'Camera initialization failed: $e';
      _isCameraInitialized = false;
      _notifyStateChange();
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting && _isInitialized) {
      try {
        // Only process every 3rd frame to avoid overwhelming the system
        if (DateTime.now().millisecondsSinceEpoch % 3 != 0) return;

        // Convert CameraImage to format suitable for MediaPipe
        final imageData = {
          'width': image.width,
          'height': image.height,
          'format': image.format.group.name,
          'planes': image.planes
              .map((plane) => {
                    'bytes': plane.bytes,
                    'bytesPerPixel': plane.bytesPerPixel ?? 1,
                    'bytesPerRow': plane.bytesPerRow,
                  })
              .toList(),
        };

        // Send image data to native MediaPipe (non-blocking)
        platform.invokeMethod('processImage', imageData).catchError((e) {
          print('Error processing image: $e');
        });
      } catch (e) {
        print('Error in image processing: $e');
      }
    }
  }

  Future<void> _disposeCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _isCameraInitialized = false;
      _isCameraOn = false;
      _notifyStateChange();
      print('Camera disposed');
    } catch (e) {
      print('Error disposing camera: $e');
    }
  }

  Future<void> toggleDetection() async {
    try {
      if (_isDetecting) {
        // Stop detection
        try {
          await platform.invokeMethod('stopDetection');
        } catch (e) {
          print('Error stopping detection: $e');
        }
        _isDetecting = false;
        _handLandmarks.clear();
        _poseLandmarks.clear();
        _lastUpdateTime = '';
        _errorMessage = '';

        // Dispose camera
        await _disposeCamera();

        print('MediaPipe detection stopped');
      } else {
        // Check if initialized first
        if (!_isInitialized) {
          try {
            // Try to initialize MediaPipe first
            final result = await platform.invokeMethod('initialize');
            _isInitialized = result == true;
            if (!_isInitialized) {
              _errorMessage = 'Failed to initialize MediaPipe';
              _notifyStateChange();
              return;
            }
          } catch (e) {
            _errorMessage = 'Initialization error: $e';
            _isInitialized = false;
            _notifyStateChange();
            print('MediaPipe initialization error: $e');
            return;
          }
        }

        // Set detection flag first
        _isDetecting = true;
        _isCameraOn = true;
        _notifyStateChange();

        // Initialize camera with image stream
        await _initializeCamera();

        // Start MediaPipe detection
        try {
          await platform.invokeMethod('startDetection');
          _errorMessage = '';
          print(
              'MediaPipe detection started - landmarks will be printed to console');
        } catch (e) {
          _errorMessage = 'Start detection error: $e';
          _isDetecting = false;
          await _disposeCamera();
          print('Error starting detection: $e');
        }
      }
      _notifyStateChange();
    } catch (e) {
      print('Error toggling detection: $e');
      _isDetecting = false;
      _errorMessage = 'Toggle error: $e';
      _handLandmarks.clear();
      _poseLandmarks.clear();
      _lastUpdateTime = '';
      await _disposeCamera();
      _notifyStateChange();
    }
  }

  @override
  void dispose() {
    try {
      // Stop MediaPipe detection
      if (_isDetecting) {
        platform.invokeMethod('stopDetection').catchError((e) {
          print('Error stopping detection during dispose: $e');
        });
      }

      // Dispose camera
      _disposeCamera();

      signifyScreen2Controller?.finish();
      textFieldFocusNode?.dispose();
      textController?.dispose();
    } catch (e) {
      print('Error during dispose: $e');
    }
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        widgetStates: {
          'dropDownValue': debugSerializeParam(
            dropDownValue,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=signtovoice2',
            name: 'String',
            nullable: true,
          ),
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=signtovoice2',
            name: 'String',
            nullable: true,
          )
        },
        generatorVariables: debugGeneratorVariables,
        backendQueries: debugBackendQueries,
        componentStates: {
          ...widgetBuilderComponents.map(
            (key, value) => MapEntry(
              key,
              value.toWidgetClassDebugData(),
            ),
          ),
        }.withoutNulls,
        link:
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=signtovoice2',
        searchReference: 'reference=OgxzaWdudG92b2ljZTJQAVoMc2lnbnRvdm9pY2Uy',
        widgetClassName: 'signtovoice2',
      );
}
