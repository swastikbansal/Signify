import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/walkthroughs/signify_screen_1.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'voicetosign1_widget.dart' show Voicetosign1Widget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Voicetosign1Model extends FlutterFlowModel<Voicetosign1Widget> {
  ///  Local state fields for this page.

  String _imgpath =
      'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Nnx8c2hvZXN8ZW58MHx8MHx8&auto=format&fit=crop&w=800&q=60';
  set imgpath(String value) {
    _imgpath = value;
    debugLogWidgetClass(this);
  }

  String get imgpath => _imgpath;

  String _title = 'Element Title';
  set title(String value) {
    _title = value;
    debugLogWidgetClass(this);
  }

  String get title => _title;

  String _description = 'Element Description';
  set description(String value) {
    _description = value;
    debugLogWidgetClass(this);
  }

  String get description => _description;

  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen1Controller;
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
  }

  @override
  void dispose() {
    signifyScreen1Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  @override
  WidgetClassDebugData toWidgetClassDebugData() => WidgetClassDebugData(
        localStates: {
          'imgpath': debugSerializeParam(
            imgpath,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QiEKEAoHaW1ncGF0aBIFcGs1NDQqBxIFZmFsc2VyBAgEIAFQAVoHaW1ncGF0aGIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          ),
          'title': debugSerializeParam(
            title,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QhoKDgoFdGl0bGUSBWJoM2Z0KgISAHIECAMgAVABWgV0aXRsZWIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          ),
          'description': debugSerializeParam(
            description,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
            searchReference:
                'reference=QiAKFAoLZGVzY3JpcHRpb24SBXdnbmJmKgISAHIECAMgAVABWgtkZXNjcmlwdGlvbmIMdm9pY2V0b3NpZ24x',
            name: 'String',
            nullable: false,
          )
        },
        widgetStates: {
          'textFieldText': debugSerializeParam(
            textController?.text,
            ParamType.String,
            link:
                'https://app.flutterflow.io/project/signify-hq88od?tab=uiBuilder&page=voicetosign1',
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
            'https://app.flutterflow.io/project/signify-hq88od/tab=uiBuilder&page=voicetosign1',
        searchReference: 'reference=Ogx2b2ljZXRvc2lnbjFQAVoMdm9pY2V0b3NpZ24x',
        widgetClassName: 'voicetosign1',
      );
}
