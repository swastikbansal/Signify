import '/flutter_flow/flutter_flow_util.dart';
import 'voicetosign1_widget.dart' show Voicetosign1Widget;
import 'package:flutter/material.dart';

class Voicetosign1Model extends FlutterFlowModel<Voicetosign1Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
