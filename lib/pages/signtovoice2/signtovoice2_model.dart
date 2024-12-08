import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
    show TutorialCoachMark;
import 'signtovoice2_widget.dart' show Signtovoice2Widget;
import 'package:flutter/material.dart';

class Signtovoice2Model extends FlutterFlowModel<Signtovoice2Widget> {
  ///  State fields for stateful widgets in this page.

  TutorialCoachMark? signifyScreen2Controller;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    signifyScreen2Controller?.finish();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
