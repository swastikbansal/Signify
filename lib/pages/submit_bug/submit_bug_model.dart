import '/flutter_flow/flutter_flow_util.dart';
import 'submit_bug_widget.dart' show SubmitBugWidget;
import 'package:flutter/material.dart';

class SubmitBugModel extends FlutterFlowModel<SubmitBugWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for bugSubmit widget.
  FocusNode? bugSubmitFocusNode;
  TextEditingController? bugSubmitTextController;
  String? Function(BuildContext, String?)? bugSubmitTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    bugSubmitFocusNode?.dispose();
    bugSubmitTextController?.dispose();
  }
}
