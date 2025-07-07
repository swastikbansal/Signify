import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'signtovoice2_widget.dart' show Signtovoice2Widget;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import '/services/sign_language_detector.dart';

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen2Controller;

  // Camera related state
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isCameraOn = false;
  bool isProcessing = false;
  List<CameraDescription> cameras = [];

  // AI Detection
  SignLanguageDetector? _signDetector;
  String currentPrediction = "";
  bool isDetectionActive = false;

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
    _initializeCamera();
    _initializeAI();
  }

  // Camera initialization method
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        // Use rear camera (usually index 0)
        final rearCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        cameraController = CameraController(
          rearCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  // Initialize AI detection
  Future<void> _initializeAI() async {
    try {
      _signDetector = SignLanguageDetector();
      await _signDetector!.initialize();
      print('AI Sign Language Detector initialized');
    } catch (e) {
      print('Error initializing AI detector: $e');
    }
  }

  // Toggle camera on/off
  Future<void> toggleCamera() async {
    try {
      if (isCameraOn) {
        // Turn off camera and AI detection
        await _stopDetection();
        await cameraController?.dispose();
        cameraController = null;
        isCameraOn = false;
        isCameraInitialized = false;
      } else {
        // Turn on camera - create a new controller instance
        if (cameras.isNotEmpty) {
          final rearCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

          // Create a new controller instance
          cameraController = CameraController(
            rearCamera,
            ResolutionPreset.medium,
            enableAudio: false,
          );

          // Initialize the new controller
          await cameraController!.initialize();
          isCameraInitialized = true;
          isCameraOn = true;

          // Start AI detection
          await _startDetection();
        }
      }
    } catch (e) {
      print('Error toggling camera: $e');
      // Reset states on error
      isCameraOn = false;
      isCameraInitialized = false;
      cameraController = null;
      isDetectionActive = false;
    }
  }

  // Start AI detection
  Future<void> _startDetection() async {
    if (_signDetector?.isInitialized == true && cameraController != null) {
      isDetectionActive = true;

      // Start image stream processing
      await cameraController!.startImageStream((CameraImage image) async {
        if (!isProcessing && isDetectionActive) {
          isProcessing = true;

          try {
            // Process frame with AI
            final prediction = await _signDetector!.processFrame(image);

            if (prediction.isNotEmpty && prediction != currentPrediction) {
              currentPrediction = prediction;

              // Update text field with prediction
              if (textController != null) {
                textController!.text = currentPrediction;
              }
            }
          } catch (e) {
            print('Error processing frame: $e');
          } finally {
            isProcessing = false;
          }
        }
      });
    }
  }

  // Stop AI detection
  Future<void> _stopDetection() async {
    isDetectionActive = false;
    if (cameraController != null) {
      try {
        await cameraController!.stopImageStream();
      } catch (e) {
        print('Error stopping image stream: $e');
      }
    }
  }

  @override
  void dispose() {
    signifyScreen2Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
    cameraController?.dispose();
    _signDetector?.dispose();
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
