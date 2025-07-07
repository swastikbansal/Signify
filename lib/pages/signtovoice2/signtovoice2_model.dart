import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/walkthroughs/signify_screen_2.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'signtovoice2_widget.dart' show Signtovoice2Widget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen2Controller;

  // Camera related state
  CameraController? cameraController;
  bool isCameraInitialized = false;
  bool isCameraOn = false;
  List<CameraDescription> cameras = [];

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

  // Toggle camera on/off
  Future<void> toggleCamera() async {
    try {
      if (isCameraOn) {
        // Turn off camera
        await cameraController?.dispose();
        isCameraOn = false;
        isCameraInitialized = false;
      } else {
        // Turn on camera
        if (cameraController != null) {
          await cameraController!.initialize();
          isCameraInitialized = true;
          isCameraOn = true;
        }
      }
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  @override
  void dispose() {
    signifyScreen2Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
    cameraController?.dispose();
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
